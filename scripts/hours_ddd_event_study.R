# hours_ddd_event_study.R
# Year-by-year event-study version of the project's PRIMARY estimand: the hours DDD's
# Mother x Post x WFH_Exposure triple interaction (scripts/hours_ddd_regression.R). Where
# run_hours_ddd_regression() collapses the whole post-period into a single Post dummy, this replaces
# Post with a full set of survey-year interactions, so the triple difference is recovered separately
# for every year against the 2019 reference.
#
# Why this exists: the two DiD-level pre-trend models (run_diagnostics(), run_hours_diagnostics())
# ask whether mothers and non-mothers trended together, averaging over exposure. The DDD's
# identification rests on the stricter condition that the mother/non-mother gap trended together
# ACROSS exposure levels, and an exposure-correlated divergence that nets to zero across occupations
# is invisible to a DiD test. So the triple-interaction pre-period coefficients get a test of their
# own (docs/decisions/ddd-event-study.md).
#
# Specification -- the saturated triple-difference event study. All three lower-order year
# interactions are included alongside the triple one:
#
#   i(ShnatSeker, ref = 2019)                 year main effects
#   i(ShnatSeker, Mother, ref = 2019)         year x Mother          (the existing DiD event study)
#   i(ShnatSeker, WFH_Exposure, ref = 2019)   year x exposure
#   i(ShnatSeker, MotherWFH, ref = 2019)      year x Mother x exposure  <- the coefficients of interest
#
# Omitting any of the first three would not produce a triple difference at all: the
# year x MotherWFH terms would absorb whatever year-specific movement belongs to occupations'
# general exposure trend or to the unconditional motherhood gap, and would be a mislabelled
# two-way estimate. Mother, WFH_Exposure and Mother:WFH_Exposure enter as their own (time-invariant)
# main/two-way effects via `Mother * WFH_Exposure`.
#
# MotherWFH is a materialized Mother * WFH_Exposure product column rather than an inline
# interaction because fixest's i(f, var) takes a single variable, not an expression, for its second
# argument. The resulting coefficient names are "ShnatSeker::<year>:MotherWFH" -- verified
# empirically against the fixest version this project uses, not assumed.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "tidy_event_study_coefs.R"))

# The event-study coefficient suffix and the reference year are exposed as arguments rather than
# hardcoded because robustness/pretrend_wald_test.R has to build a `keep` regex that matches exactly
# these terms and nothing else. Two places agreeing on a literal string is precisely the coupling
# that rots silently; main.R passes the one this returns.
run_hours_ddd_event_study <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS,
                                     ref_year = 2019) {

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  # Identical join to run_hours_ddd_regression()'s -- same occupation-level exposure measure, same
  # inner_join() drop of disclosure-masked/unmapped ISCO codes, same explicit Employed == 1 filter.
  # Kept in step deliberately: an event study fit on a different sample than the pooled DDD it is
  # the diagnostic for would not be testing that DDD's assumption.
  df_es <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    ) %>%
    mutate(MotherWFH = Mother * WFH_Exposure)

  n_matched <- nrow(df_es)
  message(sprintf(
    "run_hours_ddd_event_study: %d of %d employed rows (%.1f%%) retained an occupation-level WFH_Exposure match (dropped: disclosure-masked or unmapped ISCO codes).",
    n_matched, n_employed, 100 * n_matched / n_employed
  ))

  formula_es <- as.formula(paste(
    "WorkHoursCont ~ Mother * WFH_Exposure",
    sprintf("i(ShnatSeker, ref = %d)", ref_year),
    sprintf("i(ShnatSeker, Mother, ref = %d)", ref_year),
    sprintf("i(ShnatSeker, WFH_Exposure, ref = %d)", ref_year),
    sprintf("i(ShnatSeker, MotherWFH, ref = %d)", ref_year),
    paste(controls, collapse = " + "),
    sep = " + "
  ))

  # cluster = ~MishlachYad_ISCO_08_2, matching run_hours_ddd_regression() rather than the ~IDPUF
  # used by the two DiD event studies. WFH_Exposure -- and therefore MotherWFH, the regressor whose
  # year interactions this whole function exists to test -- is assigned at the occupation level, so
  # occupation is the level the SEs have to be clustered at (a Moulton problem otherwise). Note this
  # leaves ~40 clusters, so the Wald test built on this vcov has ~40 denominator degrees of freedom;
  # that is reported rather than hidden, see run_pretrend_joint_test()'s df2.
  reg_es <- feols(formula_es, data = df_es, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(reg_es, "run_hours_ddd_event_study()'s triple-interaction event study")

  table_es <- etable(reg_es, headers = c("WorkHoursCont (hours DDD event study)"), digits = 4)
  print(table_es)

  # Tidy frame of just the triple-interaction terms, one row per non-reference year. This is what
  # the plot builder consumes and what reaches outputs/ as a CSV -- etable()'s table is a formatted
  # character matrix covering every coefficient in the model, which is fine for reading but useless
  # as data. The extraction is shared with run_hours_diagnostics()'s DiD-level event study; see
  # tidy_event_study_coefs.R for why it is one implementation rather than two.
  term_suffix <- "MotherWFH"
  coefs <- tidy_event_study_coefs(reg_es, term_suffix = term_suffix, ref_year = ref_year)

  message("=== Hours DDD event study: Mother x year x WFH_Exposure (ref = ", ref_year, ") ===")
  print(as.data.frame(coefs %>% select(year, estimate, std_error, p_value, ci_low, ci_high, period)))

  invisible(list(
    table       = table_es,
    model       = reg_es,
    coefs       = coefs,
    ref_year    = ref_year,
    # The literal suffix fixest gave the triple-interaction terms, so pretrend_wald_test.R's `keep`
    # regex can be built from it at the call site instead of being re-typed there.
    term_suffix = term_suffix,
    n_employed  = n_employed,
    n_matched   = n_matched
  ))
}
