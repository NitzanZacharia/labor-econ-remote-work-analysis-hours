# intensive_margin_lee_bounds.R
# Lee (2009) trimming bounds for the hours DiD. Employment is itself an outcome, so the employed
# post-period mothers may differ in composition from the pre-period ones. Selection rates
# s_ab = P(hours observed | Mother = a, Post = b) give the parallel-trends counterfactual
# s11* = s10 + (s01 - s00); if s11 exceeds it, the excess share is trimmed from the top (lower
# bound) or bottom (upper bound) of the (1, 1) cell's hours distribution and Mother:Post is
# re-estimated. Handles excess selection in that cell only, under monotone selection; rates are
# unweighted like every regression here.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "imbens_manski_ci.R"))
source(file.path("scripts", "lee_trim_proportion.R"))
source(file.path("scripts", "lee_trim_cell.R"))

run_intensive_margin_lee_bounds <- function(cleaned_df, controls = DEFAULT_CONTROLS) {

  # The rate is the share whose hours are observed (reference-week workers), not the share employed.
  sel_rates <- cleaned_df %>%
    group_by(Mother, Post) %>%
    summarise(selection_rate = mean(!is.na(WorkHoursCont)), n = n(), .groups = "drop")

  get_rate <- function(m, p) {
    rate <- sel_rates$selection_rate[sel_rates$Mother == m & sel_rates$Post == p]
    if (length(rate) == 0) {
      stop("run_intensive_margin_lee_bounds: no rows found for Mother == ", m, ", Post == ", p,
           " -- all four (Mother, Post) cells must be present to compute the selection ",
           "counterfactual.")
    }
    rate
  }
  s00 <- get_rate(0, 0); s01 <- get_rate(0, 1); s10 <- get_rate(1, 0); s11 <- get_rate(1, 1)
  tp <- lee_trim_proportion(s00, s01, s10, s11)
  s11_counterfactual <- tp$s11_counterfactual
  excess             <- tp$excess_selection
  trim_prop          <- tp$trim_prop

  message(sprintf(
    paste0(
      "run_intensive_margin_lee_bounds: selection (observed-hours) rates -- ",
      "Mother=0,Post=0: %.4f | Mother=0,Post=1: %.4f | Mother=1,Post=0: %.4f | ",
      "Mother=1,Post=1: %.4f (parallel-trends counterfactual: %.4f).\n  %s"
    ),
    s00, s01, s10, s11, s11_counterfactual,
    if (excess) {
      sprintf("Excess selection detected in Mother=1,Post=1: trimming %.2f%% of that cell.",
              100 * trim_prop)
    } else {
      paste("No excess selection in Mother=1,Post=1 relative to the parallel-trends",
            "counterfactual -- bounds collapse to the untrimmed point estimate.")
    }
  ))

  rhs           <- paste("Mother + Post + Mother:Post", paste(controls, collapse = " + "), sep = " + ")
  formula_hours <- as.formula(paste("WorkHoursCont ~", rhs))
  fit_on        <- function(df) feols(formula_hours, data = df, cluster = ~IDPUF)

  # Restrict to rows with an observed outcome before trimming: arrange() sorts NA last.
  employed_df <- filter(cleaned_df, Employed == 1, !is.na(WorkHoursCont))
  point_reg   <- fit_on(employed_df)

  if (!excess || trim_prop <= 0) {
    lower_reg <- point_reg
    upper_reg <- point_reg
    n_trimmed <- 0L
  } else {
    treated_cell <- filter(employed_df, Mother == 1, Post == 1)
    other_cells  <- filter(employed_df, !(Mother == 1 & Post == 1))
    # Lower bound drops the highest-hours rows, upper bound the lowest (lee_trim_cell.R).
    trimmed <- lee_trim_cell(treated_cell, trim_prop)

    lower_reg <- fit_on(bind_rows(other_cells, trimmed$lower))
    upper_reg <- fit_on(bind_rows(other_cells, trimmed$upper))
    n_trimmed <- trimmed$n_trim
  }

  # Mother:Post is dropped for collinearity if the whole (1, 1) cell is trimmed away; fail
  # informatively.
  extract <- function(m, fn) {
    val <- fn(m)["Mother:Post"]
    if (is.na(val)) {
      stop("run_intensive_margin_lee_bounds: Mother:Post is not estimable in this bound's trimmed ",
           "sample (dropped for collinearity) -- this happens when the entire Mother=1,Post=1 cell ",
           "has been trimmed away (trim_prop == 1), leaving no data to identify the interaction.")
    }
    unname(val)
  }
  co    <- function(m) extract(m, coef)
  se_of <- function(m) extract(m, se)

  se_lower <- se_of(lower_reg)
  se_point <- se_of(point_reg)
  se_upper <- se_of(upper_reg)

  z <- qnorm(0.975)
  bounds_table <- tibble(
    bound            = c("lower", "point (untrimmed)", "upper"),
    mother_post_coef = c(co(lower_reg), co(point_reg), co(upper_reg)),
    se               = c(se_lower, se_point, se_upper),
    ci_low           = c(co(lower_reg) - z * se_lower, co(point_reg) - z * se_point,
                          co(upper_reg) - z * se_upper),
    ci_high          = c(co(lower_reg) + z * se_lower, co(point_reg) + z * se_point,
                          co(upper_reg) + z * se_upper)
  )
  print(as.data.frame(bounds_table), digits = 4)

  # Imbens-Manski interval for the identified set.
  im_ci <- imbens_manski_ci(co(lower_reg), co(upper_reg), se_lower, se_upper)
  message(sprintf(
    "run_intensive_margin_lee_bounds: 95%% Imbens-Manski CI for the identified set = [%.4f, %.4f] (c_alpha = %.3f).",
    im_ci$lower, im_ci$upper, im_ci$c_alpha
  ))

  return(invisible(list(
    table       = bounds_table,
    models      = list(point = point_reg, lower = lower_reg, upper = upper_reg),
    diagnostics = list(
      selection_rates    = sel_rates,
      s11_counterfactual = s11_counterfactual,
      excess_selection   = excess,
      trim_prop          = trim_prop,
      n_trimmed          = n_trimmed
    ),
    imbens_manski_ci = im_ci
  )))
}
