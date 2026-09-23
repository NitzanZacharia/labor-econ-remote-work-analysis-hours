# test-tex_coef_cell.R
# tex_coef_cell() must print exactly what etable(digits = 4) prints for the same coefficient --
# that is the property that lets the generated tables replace the hand-typed ones without a
# single number changing. Pinned against etable's own string so a fixest upgrade that changes
# its formatter fails here rather than silently in the paper.

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

etable_cell <- function(m, row_label) {
  et <- fixest::etable(m, digits = 4)
  labels <- rownames(et)
  if (is.null(labels) || !row_label %in% labels) labels <- et[[1]]
  idx <- which(labels == row_label)
  as.character(et[idx, ncol(et)])
}

strip_tex <- function(cell) {
  # "$3.224$\sym{**}" -> "3.224**" ; "$(1.022)$" -> "(1.022)" ; "\sym{\cdot}" -> "."
  x <- gsub("\\\\sym\\{\\\\cdot\\}", ".", cell)
  x <- gsub("\\\\sym\\{([*]+)\\}", "\\1", x)
  gsub("\\$", "", x)
}

test_that("tex_coef_cell reproduces etable's coefficient and SE strings for every star level", {
  m <- make_cell_model()
  for (v in c("x_big", "x_small", "x_null", "x_tiny", "(Intercept)")) {
    cell <- tex_coef_cell(m, v)
    row_label <- if (v == "(Intercept)") "Constant" else v
    expected <- etable_cell(m, row_label)
    expect_equal(paste(strip_tex(cell[1]), strip_tex(cell[2])), expected, info = v)
  }
})

test_that("tex_coef_cell wraps numbers in math mode and uses the paper's \\sym macro", {
  m <- make_cell_model()
  cell <- tex_coef_cell(m, "x_big")
  expect_match(cell[1], "^\\$-?[0-9.e-]+\\$(\\\\sym\\{[*]{1,3}\\}|\\\\sym\\{\\\\cdot\\})?$")
  expect_match(cell[2], "^\\$\\([0-9.e-]+\\)\\$$")
  expect_true(grepl("\\\\sym\\{\\*\\*\\*\\}", cell[1]))
})

test_that("tex_coef_cell returns two empty cells for a missing coefficient or a NULL model", {
  m <- make_cell_model()
  expect_equal(tex_coef_cell(m, "not_here"), c("", ""))
  expect_equal(tex_coef_cell(NULL, "x_big"), c("", ""))
})

test_that("stars = FALSE drops the marker but keeps the number", {
  m <- make_cell_model()
  with_stars <- tex_coef_cell(m, "x_big")
  no_stars   <- tex_coef_cell(m, "x_big", stars = FALSE)
  expect_false(grepl("sym", no_stars[1]))
  expect_equal(strip_tex(no_stars[1]), sub("[*]+$", "", strip_tex(with_stars[1])))
})
