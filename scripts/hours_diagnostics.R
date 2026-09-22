# hours_diagnostics.R
# Hours-outcome (intensive-margin) counterpart to Diagnostics.R's run_diagnostics(), added for the
# hours pivot (docs/decisions/hours-ddd-pivot.md) so the project's now-primary dependent variable
# has a parallel-trends/pretrend check of its own -- parallel trends is a precondition for the
# causal claim of BOTH DDDs, but before this file existed only the secondary (Employed-outcome)
# pretrend model was ever built anywhere in the codebase.
#
# Restricted to Employed == 1 throughout (WorkHoursCont is only defined there, same subsample
# run_intensive_margin_reg()/run_hours_ddd_regression() use). Deliberately narrower in scope than
# run_diagnostics(): this file's purpose is specifically to produce a pretrend model for
# robustness/pretrend_wald_test.R's run_pretrend_joint_test() (already fully generic -- it takes
# any fitted model), not to replicate every one of run_diagnostics()'s sub-checks. The
# Employed-NA-specific missingness audits (run_diagnostics()'s §4-§6) have no meaningful hours
# analog and are intentionally omitted.
library(tidyverse)
library(fixest)
source(file.path("scripts", "tidy_event_study_coefs.R"))

run_hours_diagnostics <- function(cleaned_df) {
  hours_df <- filter(cleaned_df, Employed == 1)

  # ── 1. Mean hours by Mother/Post cell (hours analog of the 2x2 DiD table) ────────────────────
  message("=== 2x2 DiD mean weekly hours (Employed == 1) ===")
  hours_by_period <- hours_df %>%
    group_by(Mother, Post) %>%
    # n counts rows the mean is actually computed from, not all employed rows. With the hours
    # population harmonized to reference-week workers those differ by ~10%, and the old n = n()
    # reported a sample size inconsistent with its own mean -- and, via build_hours_descriptive_plots(),
    # inconsistent with the se sitting next to it in the same exported frame.
    summarise(mean_hours = mean(WorkHoursCont, na.rm = TRUE),
              n = sum(!is.na(WorkHoursCont)), .groups = "drop")
  print(hours_by_period)

  # ── 2. Parallel trends -- event study (hours) ────────────────────────────────────────────────
  # Same construction as run_diagnostics()'s pretrend model, WorkHoursCont in place of Employed,
  # fit on the Employed == 1 subsample. i(ShnatSeker, ref = 2019) supplies the year main effects
  # for the Post = 0 group; ref = 2019 sets the omitted reference period in both i() terms.
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

  # Tidy one-row-per-year frame of the Mother x Year interactions -- the actual parallel-trends
  # test this section exists for. main.R hands it to build_event_study_plot(); it also reaches
  # outputs/ as a CSV, which the etable() character matrix above cannot serve as.
  #
  # This replaced an iplot(reg_pretrend_hours, i.select = 2, ...) call that drew the same
  # coefficients to whatever device was active. Two reasons it went: iplot() returns nothing, so
  # the figure could only be captured by wrapping this whole function in a pdf()/dev.off() pair in
  # main.R and could never reach export_paper_figures(); and i.select = 2 is a positional index
  # into the formula's i() terms, so inserting or reordering a term would have silently plotted the
  # year main effects under a "Mother x Year" title. tidy_event_study_coefs() selects by anchored
  # coefficient name instead, which cannot drift that way.
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
