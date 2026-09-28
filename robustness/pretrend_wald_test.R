# pretrend_wald_test.R
# Joint Wald test on the pre-2020 (2017, 2018) event-study coefficients of a fitted model, via
# fixest's wald(). keep selects the terms and is anchored with $ so the DiD pattern cannot also
# match the DDD's MotherWFH terms; label names the test in the exported row.
library(fixest)

run_pretrend_joint_test <- function(pretrend_model,
                                   keep  = "ShnatSeker::(2017|2018):Mother$",
                                   label = "Joint Wald, H0: pre-2020 Mother:year coefficients = 0") {
  w <- wald(pretrend_model, keep = keep)

  message(sprintf(
    "=== %s ===\nF(%d, %.0f) = %.4f, p = %.4f (%s)",
    label, w$df1, w$df2, w$stat, w$p, w$vcov
  ))

  # A one-row data frame so the statistic reaches outputs/.
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
