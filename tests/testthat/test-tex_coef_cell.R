# test-tex_coef_cell.R
# tex_coef_cell() prints a coefficient and its SE to a FIXED number of decimals (three by default,
# 2026-09-23), with the paper's star legend as \sym{} macros. The strings are pinned against
# formatC on the model's own coefficient, so the generated tables cannot drift from the fits.

make_cell_model <- function() {
  set.seed(71)
  n <- 3000
  df <- data.frame(
    x_big   = rnorm(n, 0, 1),
    x_small = rnorm(n, 0, 1),
    x_null  = rnorm(n, 0, 1),
    x_tiny  = rnorm(n, 0, 1),
    occ     = sample(1:30, n, replace = TRUE)
  )
  df$y <- 30 + 3.2 * df$x_big + 0.05 * df$x_small + 0 * df$x_null + 1e-4 * df$x_tiny +
    rnorm(n, 0, 1.5)
  fixest::feols(y ~ x_big + x_small + x_null + x_tiny, data = df, cluster = ~occ)
}

expected_cell <- function(m, v, digits = 3) {
  est <- unname(coef(m)[[v]]); s <- unname(fixest::se(m)[[v]]); p <- unname(fixest::pvalue(m)[[v]])
  star <- if (p < 0.001) "\\sym{***}" else if (p < 0.01) "\\sym{**}" else if (p < 0.05) "\\sym{*}" else if (p < 0.1) "\\sym{\\cdot}" else ""
  f <- function(x) sub("^-(0\\.0+)$", "\\1", formatC(x, digits = digits, format = "f"))
  c(paste0("$", f(est), "$", star), paste0("$(", f(s), ")$"))
}

test_that("tex_coef_cell prints fixed three-decimal strings with the paper's stars for every coefficient", {
  m <- make_cell_model()
  for (v in c("x_big", "x_small", "x_null", "x_tiny", "(Intercept)")) {
    expect_equal(tex_coef_cell(m, v), expected_cell(m, v), info = v)
  }
  # Three decimals exactly, whatever the magnitude: the intercept (~30) and x_tiny (~0) alike.
  for (v in c("x_big", "(Intercept)", "x_tiny")) {
    cell <- tex_coef_cell(m, v)
    expect_match(cell[1], "^\\$-?[0-9]+\\.[0-9]{3}\\$")
    expect_match(cell[2], "^\\$\\([0-9]+\\.[0-9]{3}\\)\\$$")
  }
})

test_that("the digits argument switches the fixed count, and a rounded-to-zero negative loses its sign", {
  m <- make_cell_model()
  cell4 <- tex_coef_cell(m, "x_big", digits = 4)
  expect_equal(cell4, expected_cell(m, "x_big", digits = 4))
  expect_match(cell4[1], "^\\$-?[0-9]+\\.[0-9]{4}\\$")
  cell1 <- tex_coef_cell(m, "x_small", digits = 1)
  expect_match(cell1[2], "^\\$\\([0-9]+\\.[0-9]\\)\\$$")
  # No cell ever starts with a negative zero.
  for (v in names(coef(m))) {
    for (d in 1:4) expect_false(grepl("^\\$-0\\.0+\\$", tex_coef_cell(m, v, digits = d)[1]), info = paste(v, d))
  }
})

test_that("tex_coef_cell wraps numbers in math mode and uses the paper's \\sym macro", {
  m <- make_cell_model()
  cell <- tex_coef_cell(m, "x_big")
  expect_match(cell[1], "^\\$-?[0-9.]+\\$(\\\\sym\\{[*]{1,3}\\}|\\\\sym\\{\\\\cdot\\})?$")
  expect_match(cell[2], "^\\$\\([0-9.]+\\)\\$$")
  expect_true(grepl("\\\\sym\\{\\*\\*\\*\\}", cell[1]))
  expect_false(grepl("sym", tex_coef_cell(m, "x_big", stars = FALSE)[1]))
})

test_that("tex_coef_cell returns two empty cells for a missing coefficient or a NULL model", {
  m <- make_cell_model()
  expect_equal(tex_coef_cell(m, "not_here"), c("", ""))
  expect_equal(tex_coef_cell(NULL, "x_big"), c("", ""))
})
