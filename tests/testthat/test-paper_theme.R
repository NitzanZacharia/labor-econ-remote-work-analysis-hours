# test-paper_theme.R
# theme_paper()/PAPER_PALETTE are pure presentation, so these tests do not render anything. They
# pin the two properties that are silent when broken: the semantic collision the palette exists to
# resolve, and the label names the scales key on (a mismatch there produces grey NA swatches in a
# finished figure rather than an error anywhere).

test_that("theme_paper returns a ggplot theme and honours base_size", {
  expect_s3_class(theme_paper(), "theme")
  expect_false(identical(theme_paper(12), theme_paper(14)))
})

test_that("every PAPER_PALETTE colour is a valid hex or a named R colour", {
  flat <- unlist(PAPER_PALETTE, use.names = FALSE)
  ok <- grepl("^#[0-9A-Fa-f]{6}$", flat) | flat %in% grDevices::colours()
  expect_true(all(ok), info = paste("bad colour value(s):", paste(flat[!ok], collapse = ", ")))
})

test_that("mother_status and period share no colour", {
  # The reason this file exists: before the shared palette, #D85A30/#378ADD meant Mothers/
  # Non-mothers in comparative_statistics.R and Post-2021/Pre-2021 in employment_by_child_age.R.
  # With both figures in one paper, one hue would have carried two meanings.
  expect_length(
    intersect(unname(PAPER_PALETTE$mother_status), unname(PAPER_PALETTE$period)),
    0
  )
})

test_that("palette names match the factor labels the plot scripts actually emit", {
  # scale_*_manual matches on these strings. A rename on either side fails silently as grey NA.
  expect_setequal(names(PAPER_PALETTE$mother_status), c("Mothers", "Non-mothers"))
  expect_setequal(names(PAPER_PALETTE$period), c("Pre-2021", "Post-2021"))
  expect_setequal(names(PAPER_PALETTE$adjustment), c("Raw", "Adjusted (controls)"))
})

test_that("adjustment is ordered Raw before Adjusted", {
  # employment_by_child_age.R takes its legend order from names(PAPER_PALETTE$adjustment) to stop
  # ggplot sorting it alphabetically, which put "Adjusted (controls)" first.
  expect_equal(names(PAPER_PALETTE$adjustment)[1], "Raw")
})
