# occupation_exposure_breaks.R
# Quartile breakpoints of the OCCUPATION-LEVEL WFH exposure measure, computed on the pre-period
# (2017-2019) rows and meant to be applied to every year.
#
# Why this is its own file. Until the 2026-09-22 grade-report response, the same five lines lived
# inline in build_hours_dose_response() (Figure 2) and again in build_absence_by_exposure_quartile()
# (the Limitations footnote), and the quartile-binned DDD added for Table 2 needed a third copy.
# Three copies of one rule is exactly the drift the exposure-cell memo warns about: the breakpoints
# define which occupations count as "most teleworkable", so the figure, the footnote and the
# regression must agree on them or the paper compares bins that are not the same bins. main.R now
# computes the breaks once (via build_hours_dose_response()) and hands the same object to every
# consumer; this function is what each of them calls when none are supplied.
#
# The rule itself is unchanged: quantiles of the row-level pre-period distribution (so the bins
# are worker-weighted, not occupation-weighted -- an occupation with many workers fills more of a
# bin), with the duplicate-break guard that stops cut() from silently producing fewer than four
# bins when a mass point sits on a boundary. assign_wfh_quartile() in
# robustness/age_balance_robustness.R is the matching cut() step and is reused unchanged.
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
