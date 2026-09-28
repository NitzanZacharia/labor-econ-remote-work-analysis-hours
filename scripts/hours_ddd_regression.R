# hours_ddd_regression.R
# Primary triple difference: usual weekly hours on Mother x Post x WFH_Exposure, with the
# occupation-level exposure score joined by two-digit ISCO code, on the employed. Conditioning on
# employment is intrinsic to an hours outcome; the selection it introduces is bounded separately
# by run_hours_ddd_lee_bounds(). Also fits a per-occupation second stage (a repo diagnostic).
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "intensive_margin_regression.R"))

# outcome allows the same specification on an alternative coding of hours; run_mechanism switches
# off the per-occupation second stage.
run_hours_ddd_regression <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS,
                                     outcome = "WorkHoursCont",
                                     run_mechanism = identical(outcome, "WorkHoursCont")) {

  if (!outcome %in% names(cleaned_df)) {
    stop("run_hours_ddd_regression: outcome column '", outcome, "' is not in cleaned_df.")
  }

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  # Join each employed row's occupation-level exposure; rows without a matched code drop out.
  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  n_matched  <- nrow(df_ddd)
  # Occupation is the cluster; the count is returned for the robustness table.
  n_clusters <- n_distinct(df_ddd$MishlachYad_ISCO_08_2)
  message(sprintf(
    "run_hours_ddd_regression: %d of %d employed rows (%.1f%%) retained an occupation-level WFH_Exposure match (dropped: disclosure-masked or unmapped ISCO codes); %d occupation clusters.",
    n_matched, n_employed, 100 * n_matched / n_employed, n_clusters
  ))

  rhs_ddd <- paste(
    "Mother*Post*WFH_Exposure",
    paste(controls, collapse = " + "),
    sep = " + "
  )
  formula_ddd <- as.formula(paste(outcome, "~", rhs_ddd))
  # Clustered on occupation, the level the regressor varies at.
  reg_ddd <- feols(formula_ddd, data = df_ddd, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(reg_ddd, "run_hours_ddd_regression()'s triple interaction")

  table_ddd <- etable(reg_ddd, headers = c(paste0(outcome, " (hours DDD)")), digits = 4)
  print(table_ddd)

  if (!isTRUE(run_mechanism)) {
    return(invisible(list(
      table           = table_ddd,
      model           = reg_ddd,
      n_employed      = n_employed,
      n_matched       = n_matched,
      n_clusters      = n_clusters,
      exposure_vector = df_ddd$WFH_Exposure,
      models          = list(ddd = reg_ddd, mechanism = NULL),
      mechanism_data  = NULL,
      dropped_occupations = NULL,
      outcome         = outcome
    )))
  }

  # Second stage: each occupation's own Mother:Post estimate regressed on its exposure,
  # precision-weighted.
  occ_stats <- bind_rows(lapply(exposure_index$occupation_code, function(code) {
    df_occ <- filter(df_ddd, MishlachYad_ISCO_08_2 == code)
    fit <- tryCatch({
      out <- capture.output(res <- suppressWarnings(run_intensive_margin_reg(df_occ)))
      res
    }, error = function(e) NULL)
    if (is.null(fit) || !"Mother:Post" %in% names(coef(fit$models$hours))) {
      return(tibble(occupation_code = code, beta_j = NA_real_, se_j = NA_real_))
    }
    m <- fit$models$hours
    tibble(
      occupation_code = code,
      beta_j = unname(coef(m)[["Mother:Post"]]),
      se_j   = unname(se(m)[["Mother:Post"]])
    )
  }))

  joined <- exposure_index %>% left_join(occ_stats, by = "occupation_code")
  is_dropped   <- is.na(joined$beta_j) | is.na(joined$se_j) | joined$se_j <= 0
  mechanism_df <- joined[!is_dropped, ]
  dropped_df   <- joined[is_dropped, ]

  n_dropped <- nrow(dropped_df)
  if (n_dropped > 0) {
    message(n_dropped, " of ", nrow(exposure_index), " occupation(s) dropped from the hours ",
            "mechanism regression (Mother:Post or its SE could not be estimated -- insufficient ",
            "data or a degenerate fit).")
    message(sprintf(
      "  wfh_exposure -- dropped occupations: mean = %.3f (n = %d); retained occupations: mean = %.3f (n = %d).",
      mean(dropped_df$wfh_exposure), n_dropped,
      mean(mechanism_df$wfh_exposure), nrow(mechanism_df)
    ))
  }

  reg_mechanism <- lm(beta_j ~ wfh_exposure, data = mechanism_df, weights = 1 / se_j^2)
  print(summary(reg_mechanism))

  invisible(list(
    table      = table_ddd,
    model      = reg_ddd,
    n_employed = n_employed,
    n_matched  = n_matched,
    n_clusters = n_clusters,
    # The regressor's values on the estimation sample, for the per-SD MDE.
    exposure_vector = df_ddd$WFH_Exposure,
    models     = list(ddd = reg_ddd, mechanism = reg_mechanism),
    mechanism_data = mechanism_df,
    dropped_occupations = list(
      data                   = dropped_df,
      n_dropped              = n_dropped,
      mean_exposure_dropped  = if (n_dropped > 0) mean(dropped_df$wfh_exposure) else NA_real_,
      mean_exposure_retained = mean(mechanism_df$wfh_exposure)
    ),
    outcome = outcome
  ))
}
