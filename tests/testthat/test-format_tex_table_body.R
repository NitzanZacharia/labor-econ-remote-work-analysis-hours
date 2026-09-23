# test-format_tex_table_body.R
# format_tex_table_body(): the cells-to-tabular writer. Pins the structural guarantees the paper
# relies on -- balanced environment, one row per input row, the right number of & per row,
# spanning cells consuming their neighbours, rules where asked.

test_that("a plain table has balanced tabular tags, a header block and one line per row", {
  cells <- rbind(c("a", "1", "2"), c("b", "3", "4"))
  out <- format_tex_table_body(cells, colspec = "lcc", header = list(c("", "X", "Y")))

  expect_equal(out[1], "\\begin{tabular}{lcc}")
  expect_equal(out[2], "\\toprule")
  expect_equal(out[3], " & X & Y \\\\")
  expect_equal(out[4], "\\midrule")
  expect_equal(out[5], "a & 1 & 2 \\\\")
  expect_equal(out[6], "b & 3 & 4 \\\\")
  expect_equal(tail(out, 2), c("\\bottomrule", "\\end{tabular}"))
  body <- out[5:6]
  expect_true(all(lengths(regmatches(body, gregexpr("&", body))) == 2))
})

test_that("a \\multicolumn cell consumes its NA neighbours and NA prints as empty", {
  cells <- rbind(
    c("\\multicolumn{3}{l}{\\emph{Panel A}}", NA, NA),
    c("x", NA, "5")
  )
  out <- format_tex_table_body(cells, colspec = "lcc")
  expect_equal(out[3], "\\multicolumn{3}{l}{\\emph{Panel A}} \\\\")
  expect_equal(out[4], "x &  & 5 \\\\")
})

test_that("a spanning cell followed by a non-empty cell is refused", {
  cells <- rbind(c("\\multicolumn{2}{c}{span}", "oops", "5"))
  expect_error(format_tex_table_body(cells, colspec = "lcc"), "would overwrite")
})

test_that("midrule and addlinespace are inserted after the requested rows, and raw header lines pass through", {
  cells <- rbind(c("a", "1"), c("b", "2"), c("c", "3"))
  out <- format_tex_table_body(
    cells, colspec = "lc",
    header = list(c("", "\\multicolumn{1}{c}{H}"), "\\cmidrule(lr){2-2}", c("k", "v")),
    midrule_after = 1, addlinespace_after = 2
  )
  expect_equal(out[3], " & \\multicolumn{1}{c}{H} \\\\")
  expect_equal(out[4], "\\cmidrule(lr){2-2}")
  expect_equal(out[5], "k & v \\\\")
  expect_equal(out[6], "\\midrule")
  i_a <- which(out == "a & 1 \\\\")
  expect_equal(out[i_a + 1], "\\midrule")
  i_b <- which(out == "b & 2 \\\\")
  expect_equal(out[i_b + 1], "\\addlinespace")
})

test_that("a colspec that disagrees with the cell count is an error", {
  cells <- rbind(c("a", "1", "2"))
  expect_error(format_tex_table_body(cells, colspec = "lc"), "declares 2 columns")
  expect_silent(format_tex_table_body(cells, colspec = "lp{3cm}c"))
})
