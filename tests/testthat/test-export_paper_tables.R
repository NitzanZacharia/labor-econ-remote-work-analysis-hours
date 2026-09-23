# test-export_paper_tables.R
# export_paper_tables(): one .tex per table key plus auto_notes.tex. Every test writes under
# tempdir(), never to the repo's paper/tables/.

tmp_dir <- function(suffix) file.path(tempdir(), paste0("tables-", as.integer(Sys.time()), "-", suffix))

test_that("one file per table is written, named for its key, plus the notes macros", {
  out_dir <- tmp_dir("a")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  blocks <- list(
    tables = list(
      tab_one = c("\\begin{tabular}{lc}", "a & 1 \\\\", "\\end{tabular}"),
      tab_two = c("\\begin{tabular}{lc}", "b & 2 \\\\", "\\end{tabular}")
    ),
    notes = c(autonoteOne = "Column (1): no coefficient dropped for collinearity.")
  )
  written <- export_paper_tables(blocks, output_dir = out_dir)

  expect_setequal(basename(written), c("tab_one.tex", "tab_two.tex", "auto_notes.tex"))
  expect_equal(readLines(file.path(out_dir, "tab_one.tex")), blocks$tables$tab_one)
  notes <- readLines(file.path(out_dir, "auto_notes.tex"))
  expect_true(any(grepl("^\\\\newcommand\\{\\\\autonoteOne\\}\\{Column \\(1\\)", notes)))
})

test_that("a note whose name is not a valid macro name is refused, and a malformed input errors", {
  out_dir <- tmp_dir("b")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
  bad <- list(tables = list(t = "\\begin{tabular}{l}\\end{tabular}"), notes = c(note1 = "x"))
  expect_error(export_paper_tables(bad, output_dir = out_dir), "letters only")
  expect_error(export_paper_tables(list(nope = 1), output_dir = out_dir), "tables")
})

test_that("a non-character table entry is skipped with a message rather than written", {
  out_dir <- tmp_dir("c")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
  blocks <- list(tables = list(good = "\\begin{tabular}{l}\\end{tabular}", bad = 42))
  expect_message(written <- export_paper_tables(blocks, output_dir = out_dir), "skipping 'bad'")
  expect_equal(basename(written), "good.tex")
})
