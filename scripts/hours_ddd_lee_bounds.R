# hours_ddd_lee_bounds.R
# Lee bounds for the hours DDD, generalized from intensive_margin_lee_bounds.R. The regressor is
# the occupation-level score, undefined for the non-employed, so the selection counterfactual is
# computed within quartiles of the pre-period demographic-cell index, which is defined for
# everyone. Each quartile is trimmed on its own excess share and the triple-interaction formula is
# refit on the recombined samples. The point fit here additionally requires a matched cell, so it
# can differ slightly from run_hours_ddd_regression()'s.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "imbens_manski_ci.R"))
source(file.path("scripts", "lee_trim_proportion.R"))
source(file.path("scripts", "lee_trim_cell.R"))
source(file.path("robustness", "age_balance_robustness.R"))  # compute_pre_period_quartile_breaks()

MIN_CELL_WARN <- 30

run_hours_ddd_lee_bounds <- function(cleaned_df, exposure_index, exposure_cells,
                                      controls = DEFAULT_CONTROLS) {

  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  breaks <- compute_pre_period_quartile_breaks(cleaned_df, exposure_cells)

  # Full sample with a matched cell index, quartile-assigned: what the selection rates use.
  full_df <- cleaned_df %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    filter(!is.na(WFH_Exposure)) %>%
    assign_wfh_quartile(breaks) %>%
    rename(WFH_Exposure_Cell = WFH_Exposure)

  quartiles <- sort(unique(full_df$WFH_Exposure_Q))

  # Share whose hours are observed, not share employed.
  get_rate <- function(m, p, q) {
    sub <- full_df$WorkHoursCont[full_df$Mother == m & full_df$Post == p &
                                   full_df$WFH_Exposure_Q == q]
    if (length(sub) == 0) {
      stop("run_hours_ddd_lee_bounds: no rows found for Mother == ", m, ", Post == ", p,
           ", WFH_Exposure_Q == ", q, " -- all four (Mother, Post) cells must be present in ",
           "every quartile to compute the selection counterfactual.")
    }
    mean(!is.na(sub))
  }

  quartile_diag <- map_dfr(quartiles, function(q) {
    s00 <- get_rate(0, 0, q); s01 <- get_rate(0, 1, q); s10 <- get_rate(1, 0, q); s11 <- get_rate(1, 1, q)
    n11 <- sum(full_df$Mother == 1 & full_df$Post == 1 & full_df$WFH_Exposure_Q == q)
    tp  <- lee_trim_proportion(s00, s01, s10, s11)
    tibble(WFH_Exposure_Q = q, s00 = s00, s01 = s01, s10 = s10, s11 = s11,
           s11_counterfactual = tp$s11_counterfactual, n_mother1_post1 = n11,
           excess_selection = tp$excess_selection, trim_prop = tp$trim_prop)
  })

  message("run_hours_ddd_lee_bounds: selection (observed-hours) rates and trim proportions by WFH_Exposure quartile:")
  print(as.data.frame(quartile_diag), digits = 4)

  thin <- filter(quartile_diag, n_mother1_post1 < MIN_CELL_WARN)
  if (nrow(thin) > 0) {
    warning(sprintf(
      "run_hours_ddd_lee_bounds: %d quartile(s) have fewer than %d Mother=1,Post=1 rows (%s) -- their trim_prop/bounds may be noisy.",
      nrow(thin), MIN_CELL_WARN, paste(sprintf("Q%d: n=%d", thin$WFH_Exposure_Q, thin$n_mother1_post1), collapse = "; ")
    ))
  }

  # Employed, occupation-matched, observed-hours sample carrying each row's cell quartile.
  employed_df <- full_df %>%
    filter(Employed == 1, !is.na(WorkHoursCont)) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  other_cells <- filter(employed_df, !(Mother == 1 & Post == 1))

  # Each quartile is trimmed independently on its own trim_prop (lee_trim_cell.R).
  trim_by_quartile <- map(quartiles, function(q) {
    lee_trim_cell(filter(employed_df, Mother == 1, Post == 1, WFH_Exposure_Q == q),
                  trim_prop = quartile_diag$trim_prop[quartile_diag$WFH_Exposure_Q == q])
  })

  n_trimmed_by_quartile <- tibble(
    WFH_Exposure_Q = quartiles,
    n_cell   = map_int(trim_by_quartile, "n_cell"),
    n_trimmed = map_int(trim_by_quartile, "n_trim")
  )

  lower_df <- bind_rows(other_cells, bind_rows(map(trim_by_quartile, "lower")))
  upper_df <- bind_rows(other_cells, bind_rows(map(trim_by_quartile, "upper")))

  rhs    <- paste("Mother*Post*WFH_Exposure", paste(controls, collapse = " + "), sep = " + ")
  formula_hours <- as.formula(paste("WorkHoursCont ~", rhs))
  # Clustered on occupation, as the headline is.
  fit_on <- function(df) feols(formula_hours, data = df, cluster = ~MishlachYad_ISCO_08_2)

  point_reg <- fit_on(employed_df)
  lower_reg <- fit_on(lower_df)
  upper_reg <- fit_on(upper_df)

  co    <- function(m) unname(coef(m)[["Mother:Post:WFH_Exposure"]])
  se_of <- function(m) unname(se(m)[["Mother:Post:WFH_Exposure"]])

  se_lower <- se_of(lower_reg); se_point <- se_of(point_reg); se_upper <- se_of(upper_reg)
  z <- qnorm(0.975)
  bounds_table <- tibble(
    bound   = c("lower", "point (untrimmed)", "upper"),
    coef    = c(co(lower_reg), co(point_reg), co(upper_reg)),
    se      = c(se_lower, se_point, se_upper),
    ci_low  = c(co(lower_reg) - z * se_lower, co(point_reg) - z * se_point, co(upper_reg) - z * se_upper),
    ci_high = c(co(lower_reg) + z * se_lower, co(point_reg) + z * se_point, co(upper_reg) + z * se_upper),
    n_obs   = c(nobs(lower_reg), nobs(point_reg), nobs(upper_reg))
  )
  print(as.data.frame(bounds_table), digits = 4)

  im_ci <- imbens_manski_ci(co(lower_reg), co(upper_reg), se_lower, se_upper)
  message(sprintf(
    "run_hours_ddd_lee_bounds: 95%% Imbens-Manski CI for Mother:Post:WFH_Exposure's identified set = [%.4f, %.4f] (c_alpha = %.3f).",
    im_ci$lower, im_ci$upper, im_ci$c_alpha
  ))

  invisible(list(
    table       = bounds_table,
    models      = list(point = point_reg, lower = lower_reg, upper = upper_reg),
    diagnostics = list(
      quartile_selection_rates = quartile_diag,
      n_trimmed_by_quartile    = n_trimmed_by_quartile,
      n_trimmed_total          = sum(n_trimmed_by_quartile$n_trimmed)
    ),
    imbens_manski_ci = im_ci
  ))
}
