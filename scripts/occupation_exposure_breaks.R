# occupation_exposure_breaks.R
# Quartile edges of the occupation-level exposure score on the pre-period rows (worker-weighted),
# shared by the dose-response figure, the binned DDD and the absence shares so all three use the
# same bins. Duplicate edges stop cut() from silently producing fewer than four bins.
library(tidyverse)

compute_occupation_exposure_breaks <- function(df, exposure_col = "WFH_Exposure",
                                               pre_period_before = 2020,
                                               caller = "compute_occupation_exposure_breaks") {
  if (!exposure_col %in% names(df)) {
    stop(caller, ": no '", exposure_col, "' column in the supplied frame.")
  }
  if (!"ShnatSeker" %in% names(df)) {
    stop(caller, ": no 'ShnatSeker' column -- the pre-period cannot be identified.")
  }

  pre_exposure <- df %>%
    filter(ShnatSeker < pre_period_before) %>%
    pull(.data[[exposure_col]])
  pre_exposure <- pre_exposure[!is.na(pre_exposure)]

  if (length(pre_exposure) == 0) {
    stop(caller, ": no non-missing pre-period '", exposure_col, "' values to compute quartiles on.")
  }

  breaks <- quantile(pre_exposure, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
  if (any(duplicated(breaks))) {
    stop(caller, ": duplicate quartile breakpoints (a mass point sits exactly on a boundary) -- ",
         "cut() would silently produce fewer than 4 bins. Inspect the pre-period ", exposure_col,
         " distribution before proceeding.")
  }
  breaks
}
