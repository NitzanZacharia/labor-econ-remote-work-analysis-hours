# pretrend_wald_test.R
# Joint significance test on the pre-2020 Mother:year interaction coefficients already
# estimated by Diagnostics.R's event-study regression (run_diagnostics()'s pretrend_model,
# i(ShnatSeker, Mother, ref=2019)). Diagnostics.R itself only reports each coefficient
# individually (etable()); parallel trends requires them to be jointly, not just individually,
# indistinguishable from zero, which is what this adds via fixest's own wald().
#
# Pre-2020 here means ShnatSeker %in% c(2017, 2018) -- 2019 is the omitted reference year and 2020
# itself is excluded from this project's sample entirely, so those are the only two pre-period
# interaction terms fixest's i() produces. Confirmed against a scratch fixest model that
# i(ShnatSeker, Mother, ref=2019) names them "ShnatSeker::2017:Mother" and
# "ShnatSeker::2018:Mother" (not "Mother:ShnatSeker::...").
#
# `keep` selects the coefficients under test and `label` names the test in the exported row. The
# third caller, scripts/hours_ddd_event_study.R, tests the TRIPLE interaction's terms, named
# "ShnatSeker::<year>:MotherWFH", which is why:
#
#   1. The default `keep` is anchored with `$`. Unanchored, "ShnatSeker::(2017|2018):Mother" also
#      matches "ShnatSeker::2017:MotherWFH", so the DDD event-study model would silently be tested
#      on 4 restrictions spanning two estimands while still looking like a well-formed pre-trend
#      test. The anchor changes nothing for the two DiD models, which have no MotherWFH term.
#   2. `label` is written into the exported one-row table below; a DDD pre-trend F-statistic filed
#      under "Mother:year coefficients = 0" would misreport which assumption was tested.
library(fixest)

run_pretrend_joint_test <- function(pretrend_model,
                                   keep  = "ShnatSeker::(2017|2018):Mother$",
                                   label = "Joint Wald, H0: pre-2020 Mother:year coefficients = 0") {
  w <- wald(pretrend_model, keep = keep)

  message(sprintf(
    "=== %s ===\nF(%d, %.0f) = %.4f, p = %.4f (%s)",
    label, w$df1, w$df2, w$stat, w$p, w$vcov
  ))

  # wald() returns a plain list of scalars, which export_all_results() skips silently -- so for
  # most of this project's life the paper's two joint Wald F-statistics existed only as the
  # message above and reached no file. A one-row data frame is the minimum shape the export layer
  # recognises, which is what makes these numbers reproducible from a committed artifact.
  tbl <- data.frame(
    statistic = label,
    F_stat    = unname(w$stat),
    df1       = unname(w$df1),
    df2       = unname(w$df2),
    p_value   = unname(w$p),
    vcov      = as.character(w$vcov),
    stringsAsFactors = FALSE
  )

  invisible(c(w, list(table = tbl)))
}
