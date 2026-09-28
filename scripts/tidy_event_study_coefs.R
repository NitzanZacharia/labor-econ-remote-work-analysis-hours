# tidy_event_study_coefs.R
# Turns a fitted event study's i(ShnatSeker, <var>, ref) coefficients into a one-row-per-year
# frame. Shared by the DiD and DDD event studies. The $ anchor matters: an unanchored "Mother"
# also matches "MotherWFH".
library(tidyverse)
library(fixest)

tidy_event_study_coefs <- function(model, term_suffix, ref_year, factor_var = "ShnatSeker") {
  term_pattern <- sprintf("^%s::(\\d{4}):%s$", factor_var, term_suffix)
  es_terms <- grep(term_pattern, names(coef(model)), value = TRUE)

  if (length(es_terms) == 0) {
    stop("tidy_event_study_coefs: no '", term_suffix, "' event-study coefficients found (pattern: ",
         term_pattern, "). Coefficient names present: ",
         paste(names(coef(model)), collapse = ", "))
  }

  # t on G - 1 degrees of freedom, matching etable().
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
      period  = if_else(year < ref_year, "Pre", "Post")
    ) %>%
    arrange(year)
}
