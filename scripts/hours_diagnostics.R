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

  # ── 2. Parallel trends -- event-study plot (hours) ───────────────────────────────────────────
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

  # Draws to whatever graphics device is already active -- deliberately no dev.new()/dev.off()
  # here, matching Diagnostics.R's own convention (see that file's header comment for why).
  tryCatch({
    # reg_pretrend_hours's formula has two i() terms in this order: i(ShnatSeker, ref=2019) (year
    # main effects, index 1) then i(ShnatSeker, Mother, ref=2019) (the Mother x Year interaction,
    # index 2 -- the actual parallel-trends test this plot is titled for). i.select = 2 selects
    # that second term; without it, iplot() would silently plot the year main effects instead.
    iplot(reg_pretrend_hours, i.select = 2, main = "Event-study (hours): Mother x Year (ref = 2019)")
  }, error = function(e) {
    message("iplot failed: ", e$message)
  })

  invisible(list(
    hours_by_period = hours_by_period,
    pretrend_table   = pretrend_table_hours,
    pretrend_model   = reg_pretrend_hours
  ))
}
