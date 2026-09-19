# pretrend_wald_test.R
# Phase 1c: joint significance test on the pre-2020 Mother:year interaction coefficients already
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
library(fixest)

run_pretrend_joint_test <- function(pretrend_model) {
  w <- wald(pretrend_model, keep = "ShnatSeker::(2017|2018):Mother")

  message(sprintf(
    "=== Joint Wald test, H0: pre-2020 Mother:year coefficients = 0 ===\nF(%d, %.0f) = %.4f, p = %.4f (%s)",
    w$df1, w$df2, w$stat, w$p, w$vcov
  ))

  # wald() returns a plain list of scalars, which export_all_results() skips silently -- so for
  # most of this project's life the paper's two joint Wald F-statistics existed only as the
  # message above and reached no file. A one-row data frame is the minimum shape the export layer
  # recognises, which is what makes these numbers reproducible from a committed artifact.
  tbl <- data.frame(
    statistic = "Joint Wald, H0: pre-2020 Mother:year coefficients = 0",
    F_stat    = unname(w$stat),
    df1       = unname(w$df1),
    df2       = unname(w$df2),
    p_value   = unname(w$p),
    vcov      = as.character(w$vcov),
    stringsAsFactors = FALSE
  )

  invisible(c(w, list(table = tbl)))
}
