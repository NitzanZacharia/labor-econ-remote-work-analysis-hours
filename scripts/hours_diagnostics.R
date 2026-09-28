# hours_diagnostics.R
# Hours counterpart of run_diagnostics(): 2x2 cell means and the Mother x year event study on the
# employed, whose pre-period coefficients run_pretrend_joint_test() tests jointly.
library(tidyverse)
library(fixest)
source(file.path("scripts", "tidy_event_study_coefs.R"))

run_hours_diagnostics <- function(cleaned_df) {
  hours_df <- filter(cleaned_df, Employed == 1)

  # 1. Mean hours by Mother/Post cell
  message("=== 2x2 DiD mean weekly hours (Employed == 1) ===")
  hours_by_period <- hours_df %>%
    group_by(Mother, Post) %>%
    # n counts the rows the mean uses.
    summarise(mean_hours = mean(WorkHoursCont, na.rm = TRUE),
              n = sum(!is.na(WorkHoursCont)), .groups = "drop")
  print(hours_by_period)

  # 2. Event study: i(ShnatSeker, ref = 2019) supplies the year effects; 2019 is the reference in
  # both i() terms.
  message("=== Pre-trend test (event study, hours) ===")

  reg_pretrend_hours <- feols(
    as.formula(paste(
      "WorkHoursCont ~ Mother + i(ShnatSeker, ref = 2019) + i(ShnatSeker, Mother, ref = 2019) +",
      paste(DEFAULT_CONTROLS, collapse = " + ")
    )),
    data = hours_df, cluster = ~IDPUF
  )
  pretrend_table_hours <- etable(reg_pretrend_hours, digits = 4)
  print(pretrend_table_hours)

  # Tidy one-row-per-year frame of the Mother x year terms, selected by anchored name.
  pretrend_coefs_hours <- tidy_event_study_coefs(
    reg_pretrend_hours, term_suffix = "Mother", ref_year = 2019
  )
  print(as.data.frame(pretrend_coefs_hours %>%
                        select(year, estimate, std_error, p_value, ci_low, ci_high, period)))

  invisible(list(
    hours_by_period = hours_by_period,
    pretrend_table   = pretrend_table_hours,
    pretrend_coefs   = pretrend_coefs_hours,
    pretrend_model   = reg_pretrend_hours
  ))
}
