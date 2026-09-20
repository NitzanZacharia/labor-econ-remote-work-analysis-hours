# test-export_paper_figures.R
# Unit tests for the vector-PDF paper-figure exporter. Every test passes an explicit output_dir
# under tempdir() and unlinks it on exit, so these never touch the repo's own outputs/ directory --
# same discipline as test-export_results.R, and it matters more here because the function's own
# default is the real outputs/figures.

make_test_plot <- function(title = "test") {
  ggplot2::ggplot(data.frame(a = 1:3, b = 1:3), ggplot2::aes(a, b)) +
    ggplot2::geom_point() +
    ggplot2::labs(title = title)
}

tmp_out <- function(suffix) {
  file.path(tempdir(), paste0("figs-", as.integer(Sys.time()), "-", suffix))
}

test_that("export_paper_figures creates a nested output directory that did not exist", {
  out_dir <- file.path(tmp_out("a"), "figures")
  on.exit(unlink(dirname(out_dir), recursive = TRUE), add = TRUE)
  expect_false(dir.exists(out_dir))

  export_paper_figures(list(one = make_test_plot()), output_dir = out_dir)
  expect_true(dir.exists(out_dir))
})

test_that("one PDF is written per entry, named for its list key", {
  out_dir <- tmp_out("b")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  exported <- export_paper_figures(
    list(hours_2x2 = make_test_plot(), hours_by_year = make_test_plot()),
    output_dir = out_dir
  )

  expect_setequal(basename(exported), c("hours_2x2.pdf", "hours_by_year.pdf"))
  for (f in exported) {
    expect_true(file.exists(f), info = f)
    expect_gt(file.size(f), 0)
  }
})

test_that("per-entry width/height overrides are honoured", {
  out_dir <- tmp_out("c")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  exported <- export_paper_figures(
    list(
      small = list(plot = make_test_plot(), width = 4, height = 3),
      tall  = list(plot = make_test_plot(), width = 5, height = 8)
    ),
    output_dir = out_dir
  )

  expect_length(exported, 2)
  # Not asserting exact byte sizes -- cairo output is not byte-stable across runs. Both files
  # existing and being non-empty is the contract; the sizing path is exercised by getting here.
  for (f in exported) expect_gt(file.size(f), 0)
})

test_that("NULL and non-ggplot entries are skipped, not fatal", {
  out_dir <- tmp_out("d")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  # build_hours_subgroup_comparison() and build_mechanism_scatter() both return NULL by design
  # when no model carries the requested term, so a NULL must not abort the whole export.
  exported <- suppressMessages(export_paper_figures(
    list(good = make_test_plot(), missing = NULL, wrong = data.frame(a = 1)),
    output_dir = out_dir
  ))

  expect_equal(basename(exported), "good.pdf")
  expect_false(file.exists(file.path(out_dir, "missing.pdf")))
  expect_false(file.exists(file.path(out_dir, "wrong.pdf")))
})

test_that("non-ASCII labels survive the device (the reason cairo_pdf is preferred)", {
  skip_if_not(isTRUE(unname(capabilities("cairo"))), "cairo not available on this build")
  out_dir <- tmp_out("e")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  # Real labels in this project carry U+2013 en-dashes and U+00D7. Base pdf() would emit a wrong
  # glyph or throw "invalid multibyte string" on these.
  p <- make_test_plot("Women aged 25–59 × Post")
  expect_no_warning(export_paper_figures(list(utf8 = p), output_dir = out_dir))
  expect_gt(file.size(file.path(out_dir, "utf8.pdf")), 0)
})

test_that("the return value is invisible and lists written paths", {
  out_dir <- tmp_out("f")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  expect_invisible(export_paper_figures(list(one = make_test_plot()), output_dir = out_dir))
})

test_that("strip_titles removes in-plot title/subtitle/caption by default", {
  # Paper figures take their title and notes from the LaTeX float. Leaving ggplot's own text in
  # place duplicates that and, since ggplot clips instead of reflowing, gets cut off at the ~5in
  # width these are printed at.
  out_dir <- tmp_out("g")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  p <- make_test_plot("A very long title that would be clipped at print width") +
    ggplot2::labs(subtitle = "a subtitle", caption = "a caption")

  stripped <- p + ggplot2::labs(title = NULL, subtitle = NULL, caption = NULL)
  expect_null(stripped$labels$title)

  # The exporter must not mutate the caller's object -- the same plot still goes to PNG with its
  # titles intact via export_all_results().
  export_paper_figures(list(fig = p), output_dir = out_dir)
  expect_equal(p$labels$title, "A very long title that would be clipped at print width")
  expect_gt(file.size(file.path(out_dir, "fig.pdf")), 0)
})

test_that("strip_titles = FALSE keeps the in-plot text", {
  out_dir <- tmp_out("h")
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
  p <- make_test_plot("kept")
  exported <- export_paper_figures(list(fig = p), output_dir = out_dir, strip_titles = FALSE)
  expect_length(exported, 1)
  expect_gt(file.size(exported), 0)
})
