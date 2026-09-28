# ddd_mde_diagnostics.R
# Closed-form minimum detectable effect for a triple interaction:
# MDE = SE * (q(1 - alpha/2) + q(power)), so a null can be read as genuinely null or underpowered.
library(fixest)

# regressor: the interacted regressor's values on the estimation sample, so the MDE is also
# reported per SD and per IQR. df: degrees of freedom of the t reference the model's inference
# uses (39 for the hours DDD); NULL keeps the normal multiplier.
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

  # One-row data frame so the export layer writes it.
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
