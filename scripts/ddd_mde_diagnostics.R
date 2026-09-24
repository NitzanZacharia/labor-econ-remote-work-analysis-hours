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

# `regressor` (optional): the numeric vector of the interacted regressor -- WFH_Exposure -- on the
# estimation sample. Supply it and the MDE is ALSO reported per standard deviation and per
# interquartile range of that regressor, not only per unit.
#
# Why this matters. The MDE is a coefficient: an effect per ONE UNIT of the
# regressor. Comparing it to a baseline rate silently assumes the regressor moves a full unit.
# WFH_Exposure never does: on the analysis sample its weighted SD is 0.081, its IQR 0.105, and its
# entire observed range is 0 to 0.75. Reporting only the per-unit figure made the employment DDD
# look ~8-10x underpowered against the literature when the honest per-SD comparison is ~2-3x. The
# scale-free ratio MDE/|point estimate| is unaffected by any of this and remains the strongest
# statement of the power problem.
# `df` (docs/decisions/grade-report-2-response.md, MDE note): the degrees of freedom of the t
# reference distribution the model's inference actually uses. With forty occupation clusters the
# hours DDD's p-values come from t(39), and the normal multiplier (2.80) understates the
# detectable effect relative to the t one (2.87). When supplied, BOTH terms use qt(); NULL keeps
# the normal closed form, which is exact for the individual-clustered employment specifications
# (tens of thousands of clusters) and is what every existing caller gets.
compute_ddd_mde <- function(model, coef_name = "Mother:Post:WFH_Exposure",
                             sig_level = 0.05, power = 0.8, baseline_rate = NULL,
                             regressor = NULL, df = NULL) {
  se_vec <- fixest::se(model)
  if (!coef_name %in% names(se_vec) || is.na(se_vec[[coef_name]])) {
    stop(sprintf(
      "compute_ddd_mde: '%s' not found (or NA) in the fitted model's SEs -- was it dropped by collinearity?",
      coef_name
    ))
  }
  if (!is.null(df) && (!is.numeric(df) || length(df) != 1 || !is.finite(df) || df <= 0)) {
    stop("compute_ddd_mde: `df` must be a single positive number (or NULL for the normal multiplier).")
  }
  se             <- unname(se_vec[[coef_name]])
  point_estimate <- unname(coef(model)[[coef_name]])
  multiplier     <- if (is.null(df)) {
    qnorm(1 - sig_level / 2) + qnorm(power)
  } else {
    qt(1 - sig_level / 2, df = df) + qt(power, df = df)
  }
  mde            <- se * multiplier

  # Scale the MDE by how much the regressor actually moves, when the caller supplies it.
  reg_sd <- reg_iqr <- mde_per_sd <- mde_per_iqr <- NA_real_
  if (!is.null(regressor)) {
    r <- as.numeric(regressor)
    r <- r[is.finite(r)]
    if (length(r) > 1) {
      reg_sd      <- stats::sd(r)
      reg_iqr     <- unname(diff(stats::quantile(r, c(0.25, 0.75))))
      mde_per_sd  <- mde * reg_sd
      mde_per_iqr <- mde * reg_iqr
    }
  }

  message(sprintf(
    paste0(
      "compute_ddd_mde: %s point estimate = %.4f, SE = %.4f -> MDE (alpha=%.2f, power=%.0f%%, ",
      "multiplier %.4f%s) = %.4f",
      "%s"
    ),
    coef_name, point_estimate, se, sig_level, power * 100, multiplier,
    if (is.null(df)) ", normal" else sprintf(", t(%g)", df), mde,
    if (!is.null(baseline_rate)) {
      # "baseline" deliberately left unnamed: main.R passes the baseline employment rate for the
      # employment DDD but mean weekly hours for the hours DDD, and hardcoding "employment rate"
      # here printed "baseline employment rate = 38.2446" for the hours call, which reads as a bug.
      sprintf(" (baseline = %.4f, i.e. MDE is %.1f%% of baseline)",
              baseline_rate, 100 * mde / baseline_rate)
    } else ""
  ))

  if (!is.na(mde_per_sd)) {
    message(sprintf(
      paste0(
        "  regressor SD = %.4f, IQR = %.4f -> MDE per SD = %.4f, per IQR = %.4f%s\n",
        "  (the per-unit MDE above assumes a 1-unit move in a regressor whose SD is %.4f; ",
        "prefer the per-SD figure when comparing against the literature)"
      ),
      reg_sd, reg_iqr, mde_per_sd, mde_per_iqr,
      if (!is.null(baseline_rate)) {
        sprintf(" (%.1f%% and %.1f%% of baseline)",
                100 * mde_per_sd / baseline_rate, 100 * mde_per_iqr / baseline_rate)
      } else "",
      reg_sd
    ))
  }

  # Returned as a one-row data frame as well as the scalar list, so export_all_results() can write
  # it: the layer only recognises data frames and ggplots, so a list of scalars reaches no file.
  # The paper cites all three MDEs, so they have to be on disk. Same pattern as
  # run_pretrend_joint_test().
  tbl <- data.frame(
    coef_name      = coef_name,
    point_estimate = unname(point_estimate),
    se             = unname(se),
    sig_level      = sig_level,
    power          = power,
    df             = if (is.null(df)) NA_real_ else df,
    multiplier     = unname(multiplier),
    mde            = unname(mde),
    baseline       = if (is.null(baseline_rate)) NA_real_ else unname(baseline_rate),
    mde_pct_of_baseline = if (is.null(baseline_rate)) NA_real_ else 100 * mde / baseline_rate,
    regressor_sd   = reg_sd,
    regressor_iqr  = reg_iqr,
    mde_per_sd     = mde_per_sd,
    mde_per_iqr    = mde_per_iqr,
    mde_per_sd_pct_of_baseline =
      if (is.null(baseline_rate)) NA_real_ else 100 * mde_per_sd / baseline_rate,
    mde_per_iqr_pct_of_baseline =
      if (is.null(baseline_rate)) NA_real_ else 100 * mde_per_iqr / baseline_rate,
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
    df             = df,
    multiplier     = multiplier,
    mde            = mde,
    mde_per_sd     = mde_per_sd,
    mde_per_iqr    = mde_per_iqr,
    within_mde     = abs(point_estimate) < mde
  ))
}
