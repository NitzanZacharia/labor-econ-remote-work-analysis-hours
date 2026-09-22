# test-build_ddd_event_study_plot.R
# Unit tests for build_ddd_event_study_plot(). Built against a hand-written coefficient frame rather
# than by fitting run_hours_ddd_event_study() -- the builder's contract is "given a tidy coefficient
# frame, produce a ggplot", and the fitting path is covered by test-hours_ddd_event_study.R.

make_es_coefs <- function() {
  tibble::tibble(
    term      = paste0("ShnatSeker::", c(2017, 2018, 2021, 2022, 2023), ":MotherWFH"),
    year      = c(2017, 2018, 2021, 2022, 2023),
    estimate  = c(0.20, -0.10, 2.50, 3.10, 3.40),
    std_error = c(0.90, 0.85, 1.05, 1.10, 1.20)
  ) %>%
    dplyr::mutate(
      ci_low  = estimate - 1.96 * std_error,
      ci_high = estimate + 1.96 * std_error,
      period  = dplyr::if_else(year < 2019, "Pre", "Post")
    )
}

test_that("build_ddd_event_study_plot returns a ggplot plus the frame it was drawn from", {
  res <- build_ddd_event_study_plot(make_es_coefs())

  expect_type(res, "list")
  expect_true(all(c("data", "plot") %in% names(res)))
  expect_s3_class(res$plot, "ggplot")
})

test_that("the omitted reference year is re-inserted as an exact, zero-width zero", {
  res <- build_ddd_event_study_plot(make_es_coefs(), ref_year = 2019)

  # 5 estimated years + the pinned reference => 6 plotted points.
  expect_equal(nrow(res$data), 6)
  ref <- dplyr::filter(res$data, year == 2019)
  expect_equal(nrow(ref), 1)
  expect_equal(ref$estimate, 0)
  expect_equal(ref$ci_low, 0)
  expect_equal(ref$ci_high, 0)
  expect_true(ref$is_reference)
  # Every other row must NOT be flagged -- the hollow-point styling keys off this column, so a
  # mis-set flag would silently render an estimated year as though it were pinned by construction.
  expect_false(any(dplyr::filter(res$data, year != 2019)$is_reference))
})

test_that("the zero line and the treatment-boundary rule are both drawn", {
  res <- build_ddd_event_study_plot(make_es_coefs(), ref_year = 2019, treatment_year = 2021)

  hlines <- Filter(function(l) inherits(l$geom, "GeomHline"), res$plot$layers)
  vlines <- Filter(function(l) inherits(l$geom, "GeomVline"), res$plot$layers)
  expect_length(hlines, 1)
  expect_length(vlines, 1)

  expect_equal(hlines[[1]]$data$yintercept, 0)
  # 2020 -- the midpoint of the 2019/2021 gap. The rule has to land in the gap rather than on a
  # plotted estimate, which is what pins this to the midpoint rather than to treatment_year itself.
  expect_equal(vlines[[1]]$data$xintercept, 2020)
})

test_that("the x axis breaks only at years actually in the data", {
  res <- build_ddd_event_study_plot(make_es_coefs(), ref_year = 2019)

  breaks <- ggplot2::layer_scales(res$plot)$x$get_breaks()
  breaks <- breaks[!is.na(breaks)]
  # 2020 is excluded from this project's sample entirely; a default continuous axis would invent a
  # tick for it and imply an estimate that was never fit.
  expect_equal(sort(as.numeric(breaks)), c(2017, 2018, 2019, 2021, 2022, 2023))
  expect_false(2020 %in% breaks)
})

test_that("the treatment boundary follows treatment_year rather than being hardcoded", {
  res <- build_ddd_event_study_plot(make_es_coefs(), ref_year = 2019, treatment_year = 2023)
  vlines <- Filter(function(l) inherits(l$geom, "GeomVline"), res$plot$layers)
  expect_equal(vlines[[1]]$data$xintercept, 2021)
})

test_that("an empty or NULL coefficient frame returns NULL rather than erroring", {
  # Matches the non-destructive convention build_hours_subgroup_comparison() and
  # build_mechanism_scatter() already follow: this runs inside a long pipeline, and one absent
  # figure should not discard every other one.
  expect_message(expect_null(build_ddd_event_study_plot(NULL)), "no event-study coefficients")
  expect_message(
    expect_null(build_ddd_event_study_plot(make_es_coefs()[0, ])),
    "no event-study coefficients"
  )
})

test_that("a coefficient frame missing a required column fails loudly", {
  # The opposite call: a frame that is present but structurally wrong is a programming error, not an
  # absent result, and silently dropping it would export a plot with no intervals on it.
  bad <- dplyr::select(make_es_coefs(), -ci_low)
  expect_error(build_ddd_event_study_plot(bad), "missing required column")
})
