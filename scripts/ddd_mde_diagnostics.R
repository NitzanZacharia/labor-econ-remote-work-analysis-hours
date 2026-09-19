# ddd_mde_diagnostics.R
# Closed-form minimum-detectable-effect (MDE) diagnostic for the primary DDD's triple interaction.
# check_spec1_collinearity() (ddd_collinearity_diagnostics.R) already quantifies how much of
# WFH_Exposure's cross-cell variance survives after partialling out its own controls (~25.5% in
# Spec 1), and Spec 2 identifies the triple interaction off within-cell variation only -- this
# function turns those SEs into an interpretable "smallest true effect this design could reliably
# detect" number, so a null Mother:Post:WFH_Exposure coefficient can be read as "genuinely null" vs.
# "underpowered to see a plausible effect."
#
# Standard closed-form MDE for a linear-model coefficient (Duflo, Glennerster & Kremer 2007):
#   MDE = SE * (qnorm(1 - sig_level / 2) + qnorm(power))
# No simulation and no new dependency -- qnorm() is base R, matching this repo's existing
# base-R-only convention for statistical diagnostics (ddd_collinearity_diagnostics.R explicitly
# avoids adding car for the same reason).
library(fixest)

compute_ddd_mde <- function(model, coef_name = "Mother:Post:WFH_Exposure",
                             sig_level = 0.05, power = 0.8, baseline_rate = NULL) {
  se_vec <- fixest::se(model)
  if (!coef_name %in% names(se_vec) || is.na(se_vec[[coef_name]])) {
    stop(sprintf(
      "compute_ddd_mde: '%s' not found (or NA) in the fitted model's SEs -- was it dropped by collinearity?",
      coef_name
    ))
  }
  se             <- unname(se_vec[[coef_name]])
  point_estimate <- unname(coef(model)[[coef_name]])
  mde            <- se * (qnorm(1 - sig_level / 2) + qnorm(power))

  message(sprintf(
    paste0(
      "compute_ddd_mde: %s point estimate = %.4f, SE = %.4f -> MDE (alpha=%.2f, power=%.0f%%) = %.4f",
      "%s"
    ),
    coef_name, point_estimate, se, sig_level, power * 100, mde,
    if (!is.null(baseline_rate)) {
      # "baseline" deliberately left unnamed: main.R passes the baseline employment rate for the
      # employment DDD but mean weekly hours for the hours DDD, and hardcoding "employment rate"
      # here printed "baseline employment rate = 38.2446" for the hours call, which reads as a bug.
      sprintf(" (baseline = %.4f, i.e. MDE is %.1f%% of baseline)",
              baseline_rate, 100 * mde / baseline_rate)
    } else ""
  ))

  # Returned as a one-row data frame as well as the scalar list, so export_all_results() can write
  # it: the layer only recognises data frames and ggplots, so a list of scalars reaches no file.
  # The paper cites all three MDEs (2.6059 for hours, 0.2031/0.2022 for employment) and none of
  # them was on disk before 2026-09-19. Same fix as run_pretrend_joint_test()'s.
  tbl <- data.frame(
    coef_name      = coef_name,
    point_estimate = unname(point_estimate),
    se             = unname(se),
    sig_level      = sig_level,
    power          = power,
    mde            = unname(mde),
    baseline       = if (is.null(baseline_rate)) NA_real_ else unname(baseline_rate),
    mde_pct_of_baseline = if (is.null(baseline_rate)) NA_real_ else 100 * mde / baseline_rate,
    within_mde     = abs(point_estimate) < mde,
    stringsAsFactors = FALSE
  )

  invisible(list(
    table          = tbl,
    coef_name      = coef_name,
    point_estimate = point_estimate,
    se             = se,
    sig_level      = sig_level,
    power          = power,
    mde            = mde,
    within_mde     = abs(point_estimate) < mde
  ))
}
