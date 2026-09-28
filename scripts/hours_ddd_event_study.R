# hours_ddd_event_study.R
# Event-study form of the hours DDD: Post replaced by survey-year interactions at every level
# (year, year x Mother, year x exposure, year x Mother x exposure), so the triple difference is
# recovered year by year against 2019. The DiD-level pre-trend tests average over exposure; this
# tests the pre-period coefficients of the triple interaction itself. MotherWFH is a materialized
# product because i(f, var) takes a single variable.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "tidy_event_study_coefs.R"))

# term_suffix and ref_year are returned so the Wald test's keep regex is built from them.
run_hours_ddd_event_study <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS,
                                     ref_year = 2019) {

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  # Same join and sample as run_hours_ddd_regression().
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

  # Clustered on occupation, as the pooled DDD is; about 40 clusters.
  reg_es <- feols(formula_es, data = df_es, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(reg_es, "run_hours_ddd_event_study()'s triple-interaction event study")

  table_es <- etable(reg_es, headers = c("WorkHoursCont (hours DDD event study)"), digits = 4)
  print(table_es)

  # Tidy frame of the triple-interaction terms, one row per non-reference year.
  term_suffix <- "MotherWFH"
  coefs <- tidy_event_study_coefs(reg_es, term_suffix = term_suffix, ref_year = ref_year)

  message("=== Hours DDD event study: Mother x year x WFH_Exposure (ref = ", ref_year, ") ===")
  print(as.data.frame(coefs %>% select(year, estimate, std_error, p_value, ci_low, ci_high, period)))

  invisible(list(
    table       = table_es,
    model       = reg_es,
    coefs       = coefs,
    ref_year    = ref_year,
    term_suffix = term_suffix,
    n_employed  = n_employed,
    n_matched   = n_matched
  ))
}
