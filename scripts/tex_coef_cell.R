# tex_coef_cell.R
# One regression coefficient as the two LaTeX cells the paper's tables print: the estimate with
# its significance marker on one line, the standard error in parentheses on the next. Part of the
# generated-table layer added for the 2026-09-22 grade-report response (item C1;
# docs/decisions/grade-report-response.md).
#
# Cells are built FROM THE FITTED MODEL, keyed on the coefficient's name as fixest reports it
# ("Mother:Post:WFH_Exposure", "ShnatSeker::2017:MotherWFH"), never parsed back out of an
# etable() string: etable labels change with `dict`, `interaction.combine` and i() ("Mother x Post
# x WFH_Exposure_Q = 4"), and the p < 0.1 marker is a bare dot glued to the number, which a naive
# number regex swallows. Formatting uses fixest's own number formatter so the generated cell is
# character-for-character what etable(digits = 4) prints to the console and to outputs/*.csv --
# the paper was verified against those files, and this keeps it so. The formatter is internal to
# fixest, so tests/testthat/test-tex_coef_cell.R pins each cell against etable()'s string and will
# fail loudly if a fixest upgrade changes it.
#
# Stars follow the paper's legend (Results, first paragraph), which is fixest's console default:
# *** p<0.001, ** p<0.01, * p<0.05, and a centred dot for p<0.1, typeset via the \sym{} macro
# paper.tex defines.
library(fixest)

tex_coef_cell <- function(model, name, digits = 4, stars = TRUE) {
  if (is.null(model) || !(name %in% names(stats::coef(model)))) {
    return(c("", ""))
  }

  est <- unname(stats::coef(model)[[name]])
  s   <- unname(fixest::se(model)[[name]])
  p   <- unname(fixest::pvalue(model)[[name]])

  fmt <- get("format_number", envir = asNamespace("fixest"))

  star <- ""
  if (isTRUE(stars) && is.finite(p)) {
    star <- if (p < 0.001) "\\sym{***}"
            else if (p < 0.01) "\\sym{**}"
            else if (p < 0.05) "\\sym{*}"
            else if (p < 0.1) "\\sym{\\cdot}"
            else ""
  }

  c(
    paste0("$", fmt(est, digits = digits), "$", star),
    paste0("$(", fmt(s, digits = digits), ")$")
  )
}
