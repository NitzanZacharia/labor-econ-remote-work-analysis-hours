# hours_ddd_regression.R
# The primary triple-interaction DDD (Mother*Post*WFH_Exposure) on the hours-worked outcome,
# restricted (by construction) to the Employed == 1 subsample. See
# docs/decisions/hours-ddd-pivot.md for the full rationale.
#
# The exposure regressor here is the PURE occupation-level measure (exposure_calibrated's
# wfh_exposure_calibrated, joined by MishlachYad_ISCO_08_2 -- ~40 ISCO-2 groups), not the
# demographic-cell-based WFH_Exposure the extensive-margin primary DDD uses. That measure was
# rejected for the extensive margin specifically because occupation is undefined for the
# non-employed, and Employed (the extensive DDD's own outcome) would then be conditioned on itself
# (docs/decisions/exposure-cell-granularity-fix.md). WorkHoursCont is already, by construction,
# undefined for anyone with Employed != 1 (data_processing.R:184-193) -- conditioning the hours
# regression on employment is baked into the question itself, not introduced by this exposure
# choice. Dropping non-employed rows still introduces a real selection-on-a-mediator problem for
# the hours estimate (if WFH differentially pulls marginal mothers into employment, the post-period
# employed-mother sample isn't compositionally comparable to the pre-period one) -- that's bounded
# separately by hours_ddd_lee_bounds.R's run_hours_ddd_lee_bounds(), run alongside this point
# estimate, not instead of it.
#
# Also includes a second-stage occupation-by-occupation mechanism regression (added for the
# gender/robustness-parity pass following the hours pivot): per-occupation Mother:Post estimates
# from run_intensive_margin_reg(), precision-weighted against occupation-level exposure -- see
# below.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "intensive_margin_regression.R"))

run_hours_ddd_regression <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS) {

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  # Attach each employed row's occupation-level WFH exposure by joining on the occupation code.
  # inner_join() already drops rows with no occupation code (non-employed, or a disclosure-masked
  # ISCO for the employed) -- the explicit filter(Employed == 1) is kept anyway for readability and
  # as a defensive check, since WorkHoursCont being NA for Employed != 1 rows would otherwise make
  # their exclusion implicit rather than stated.
  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  n_matched <- nrow(df_ddd)
  message(sprintf(
    "run_hours_ddd_regression: %d of %d employed rows (%.1f%%) retained an occupation-level WFH_Exposure match (dropped: disclosure-masked or unmapped ISCO codes).",
    n_matched, n_employed, 100 * n_matched / n_employed
  ))

  rhs_ddd <- paste(
    "Mother*Post*WFH_Exposure",
    paste(controls, collapse = " + "),
    sep = " + "
  )
  formula_ddd <- as.formula(paste("WorkHoursCont ~", rhs_ddd))
  # WFH_Exposure is assigned at the occupation level (~40 ISCO-2 groups), not the individual --
  # cluster on the occupation code, the level the regressor of interest actually varies at, not
  # IDPUF (a Moulton problem otherwise).
  reg_ddd <- feols(formula_ddd, data = df_ddd, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(reg_ddd, "run_hours_ddd_regression()'s triple interaction")

  table_ddd <- etable(reg_ddd, headers = c("WorkHoursCont (hours DDD)"), digits = 4)
  print(table_ddd)

  # ── Model 2: second-stage mechanism regression ──────────────────────────────
  # For each occupation, fits run_intensive_margin_reg() (WorkHoursCont, Employed==1) on that
  # occupation's own subset and extracts its Mother:Post estimate (beta_j) and cluster-robust SE
  # (se_j). beta_j's precision varies enormously across occupations, so the second-stage
  # regression of beta_j on wfh_exposure is precision-weighted (1/se_j^2) rather than unweighted --
  # the usual approach for a two-step meta-regression on generated regressands. Occupations with
  # too little data to fit are dropped from the mechanism regression rather than erroring the
  # whole function.
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
    # The regressor's own values on the estimation sample, so compute_ddd_mde() can report the MDE
    # per SD/IQR of exposure rather than only per unit. A bare numeric vector, not a data frame,
    # so export_all_results() ignores it (it is row-level and has no business in outputs/).
    exposure_vector = df_ddd$WFH_Exposure,
    models     = list(ddd = reg_ddd, mechanism = reg_mechanism),
    mechanism_data = mechanism_df,
    dropped_occupations = list(
      data                   = dropped_df,
      n_dropped              = n_dropped,
      mean_exposure_dropped  = if (n_dropped > 0) mean(dropped_df$wfh_exposure) else NA_real_,
      mean_exposure_retained = mean(mechanism_df$wfh_exposure)
    )
  ))
}
