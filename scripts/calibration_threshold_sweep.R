# calibration_threshold_sweep.R
# Sensitivity of the hours DDD to the calibration rule's gap threshold. For each threshold the
# external index is recalibrated with calibrate_isco_exposure(gap_threshold = t) and the primary
# DDD refit; above the largest gap nothing swaps and the row is the external-index estimate.
# The 0.5 row is the headline. Appendix table tab:calibration-sweep.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))
source(file.path("scripts", "hours_ddd_regression.R"))

run_calibration_threshold_sweep <- function(cleaned_df, exposure_population_df, exposure_external,
                                            thresholds = seq(0.30, 0.90, by = 0.05),
                                            controls = DEFAULT_CONTROLS,
                                            coef_name = "Mother:Post:WFH_Exposure") {
  if (length(thresholds) == 0 || any(!is.finite(thresholds))) {
    stop("run_calibration_threshold_sweep: thresholds must be a non-empty numeric vector.")
  }

  rows <- lapply(thresholds, function(t) {
    idx <- suppressMessages(
      calibrate_isco_exposure(exposure_population_df, exposure_external, gap_threshold = t)
    )
    swapped <- sort(idx$ISCO2[idx$swap])
    out <- capture.output(res <- suppressWarnings(suppressMessages(run_hours_ddd_regression(
      cleaned_df,
      idx %>% select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated),
      controls = controls, run_mechanism = FALSE
    ))))
    m <- res$model
    if (!coef_name %in% names(coef(m))) {
      stop("run_calibration_threshold_sweep: '", coef_name, "' not estimated at threshold ", t, ".")
    }
    tibble(
      threshold     = t,
      n_swapped     = length(swapped),
      swapped_codes = paste(swapped, collapse = ", "),
      estimate      = unname(coef(m)[[coef_name]]),
      se            = unname(se(m)[[coef_name]]),
      p_value       = unname(pvalue(m)[[coef_name]]),
      n             = as.integer(nobs(m)),
      n_clusters    = as.integer(res$n_clusters)
    )
  })
  table <- bind_rows(rows)

  message("run_calibration_threshold_sweep: hours DDD triple interaction by calibration gap threshold:")
  print(as.data.frame(table %>% select(-swapped_codes)), digits = 4)

  invisible(list(table = table))
}
