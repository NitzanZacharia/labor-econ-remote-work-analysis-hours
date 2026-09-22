# hours_ddd_event_study.R
# Year-by-year event-study version of the project's PRIMARY estimand: the hours DDD's
# Mother x Post x WFH_Exposure triple interaction (scripts/hours_ddd_regression.R). Where
# run_hours_ddd_regression() collapses the whole post-period into a single Post dummy, this replaces
# Post with a full set of survey-year interactions, so the triple difference is recovered separately
# for every year against the 2019 reference.
#
# Why this exists: parallel trends is the identifying assumption of the DDD, but until this file the
# repo tested it only at the DiD level -- run_diagnostics() (Employed x Mother x year) and
# run_hours_diagnostics() (WorkHoursCont x Mother x year), each passed to
# run_pretrend_joint_test(). Both ask whether mothers and non-mothers trended together. Neither asks
# the question the DDD's identification actually rests on: whether the mother/non-mother gap trended
# together ACROSS WFH exposure levels in the pre-period. A DiD pre-trend can pass while the DDD's
# own pre-trend fails (the two-way test averages over exposure, so an exposure-correlated divergence
# that nets to zero across occupations is invisible to it), which is why the triple-interaction
# pre-period coefficients need a test of their own rather than inheriting the DiD's verdict.
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
  # as data. SEs come from se() (the clustered vcov above), not from the model's internals, so the
  # exported numbers are the same ones etable() printed.
  term_suffix <- "MotherWFH"
  term_pattern <- sprintf("^ShnatSeker::(\\d{4}):%s$", term_suffix)
  es_terms <- grep(term_pattern, names(coef(reg_es)), value = TRUE)

  if (length(es_terms) == 0) {
    # Defensive, not expected: every term could only vanish if the formula or fixest's naming
    # changed. Erroring here (rather than returning an empty frame that quietly exports a 0-row CSV
    # and plots nothing) is the right trade -- this is the function's entire output.
    stop("run_hours_ddd_event_study: no '", term_suffix, "' event-study coefficients found in the ",
         "fitted model. Coefficient names present: ", paste(names(coef(reg_es)), collapse = ", "))
  }

  est <- coef(reg_es)[es_terms]
  ses <- se(reg_es)[es_terms]

  coefs <- tibble(
    term     = es_terms,
    year     = as.integer(sub(term_pattern, "\\1", es_terms)),
    estimate = unname(est),
    std_error = unname(ses)
  ) %>%
    mutate(
      t_stat  = estimate / std_error,
      # fixest's clustered vcov gives a t distribution on G - 1 df, not a normal. Using qt/pt here
      # rather than 1.96/pnorm keeps the exported p-values and CIs consistent with what etable()
      # prints above for the same coefficients, and matters at ~40 clusters (t_.975 = 2.02, not 1.96).
      p_value = 2 * pt(abs(t_stat), df = degrees_freedom(reg_es, type = "t"), lower.tail = FALSE),
      ci_low  = estimate - qt(0.975, df = degrees_freedom(reg_es, type = "t")) * std_error,
      ci_high = estimate + qt(0.975, df = degrees_freedom(reg_es, type = "t")) * std_error,
      # Pre/post relative to the treatment boundary. ref_year itself is omitted from the model, so
      # it never appears here -- the plot builder re-inserts it as a pinned zero.
      period  = if_else(year < ref_year, "Pre", "Post")
    ) %>%
    arrange(year)

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
