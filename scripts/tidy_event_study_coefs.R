# tidy_event_study_coefs.R
# Turns a fitted fixest event study's i(ShnatSeker, <var>, ref = ...) coefficients into the tidy
# one-row-per-year frame that build_event_study_plot() draws and that export_all_results() writes
# to outputs/ as a CSV.
#
# Shared by both event studies rather than living in either: run_hours_ddd_event_study() needs it
# for the triple-interaction terms ("ShnatSeker::<year>:MotherWFH") and run_hours_diagnostics()
# needs exactly the same arithmetic for the DiD-level ones ("ShnatSeker::<year>:Mother"). The two
# differ only in which suffix they select, so a second copy would be a place for the t-vs-normal
# handling below to drift between the figure the paper prints for the DiD and the one it prints
# for the DDD.
#
# The `$` anchor on the term pattern is load-bearing, not tidiness: unanchored, a suffix of "Mother"
# also matches "...:MotherWFH", so extracting the DiD event study out of a model that happens to
# contain both families of terms would silently return five extra rows. Same hazard, and same fix,
# as the `keep` regex in robustness/pretrend_wald_test.R -- see docs/decisions/ddd-event-study.md.
library(tidyverse)
library(fixest)

tidy_event_study_coefs <- function(model, term_suffix, ref_year, factor_var = "ShnatSeker") {
  term_pattern <- sprintf("^%s::(\\d{4}):%s$", factor_var, term_suffix)
  es_terms <- grep(term_pattern, names(coef(model)), value = TRUE)

  if (length(es_terms) == 0) {
    # Defensive, not expected: the terms could only vanish if the formula or fixest's naming
    # changed. Erroring beats returning an empty frame that quietly exports a 0-row CSV and plots
    # nothing -- this frame is the caller's entire result.
    stop("tidy_event_study_coefs: no '", term_suffix, "' event-study coefficients found (pattern: ",
         term_pattern, "). Coefficient names present: ",
         paste(names(coef(model)), collapse = ", "))
  }

  # fixest's clustered vcov gives a t distribution on G - 1 df, not a normal. Using qt/pt here
  # rather than 1.96/pnorm keeps the exported p-values and CIs identical to what etable() prints
  # for the same coefficients. It matters at the DDD's ~40 occupation clusters (t_.975 = 2.02) and
  # is harmless at the DiD's tens of thousands, where the two coincide to four decimals.
  df_t <- degrees_freedom(model, type = "t")

  tibble(
    term      = es_terms,
    year      = as.integer(sub(term_pattern, "\\1", es_terms)),
    estimate  = unname(coef(model)[es_terms]),
    std_error = unname(se(model)[es_terms])
  ) %>%
    mutate(
      t_stat  = estimate / std_error,
      p_value = 2 * pt(abs(t_stat), df = df_t, lower.tail = FALSE),
      ci_low  = estimate - qt(0.975, df = df_t) * std_error,
      ci_high = estimate + qt(0.975, df = df_t) * std_error,
      # Pre/post relative to the omitted reference year, which by construction has no row here --
      # build_event_study_plot() re-inserts it as a pinned zero.
      period  = if_else(year < ref_year, "Pre", "Post")
    ) %>%
    arrange(year)
}
