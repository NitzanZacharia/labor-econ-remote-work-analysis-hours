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
# number regex swallows.
#
# Number format (changed 2026-09-23, grade-report-2 item on table formatting): a FIXED number of
# decimals per cell -- `digits` decimal places, default three -- rather than fixest's four
# significant digits. The significant-digit rule printed 3.224, 0.9495 and 0.2280 in one column;
# fixed decimals are the convention regression tables follow. The employment table passes
# digits = 4 because its coefficients are on a probability scale. The formatter is base R's
# formatC(format = "f"); tests/testthat/test-tex_coef_cell.R pins the exact strings.
#
# Stars follow the paper's legend (Results, first paragraph), which is fixest's console default:
# *** p<0.001, ** p<0.01, * p<0.05, and a centred dot for p<0.1, typeset via the \sym{} macro
# paper.tex defines.
library(fixest)

tex_coef_cell <- function(model, name, digits = 3, stars = TRUE) {
  if (is.null(model) || !(name %in% names(stats::coef(model)))) {
    return(c("", ""))
  }

  est <- unname(stats::coef(model)[[name]])
  s   <- unname(fixest::se(model)[[name]])
  p   <- unname(fixest::pvalue(model)[[name]])

  fmt <- function(x) {
    out <- formatC(x, digits = digits, format = "f")
    # formatC prints a rounded-to-zero negative as "-0.000"; the sign carries no information.
    sub("^-(0\\.0+)$", "\\1", out)
  }

  star <- ""
  if (isTRUE(stars) && is.finite(p)) {
    star <- if (p < 0.001) "\\sym{***}"
            else if (p < 0.01) "\\sym{**}"
            else if (p < 0.05) "\\sym{*}"
            else if (p < 0.1) "\\sym{\\cdot}"
            else ""
  }

  c(
    paste0("$", fmt(est), "$", star),
    paste0("$(", fmt(s), ")$")
  )
}
