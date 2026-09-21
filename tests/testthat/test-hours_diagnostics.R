# test-hours_diagnostics.R
# Hours-outcome (intensive-margin) counterpart to test-diagnostics.R, added alongside
# hours_diagnostics.R for the hours pivot (docs/decisions/hours-ddd-pivot.md). Graphics calls are
# redirected to a null device (see helper-setup.R) so this runs headlessly.

cleaned <- load_and_clean_data(fixtures_dir)

test_that("run_hours_diagnostics returns the documented structure without error on fixture data", {
  with_null_device({
    out <- capture.output(res <- suppressWarnings(run_hours_diagnostics(cleaned)))
  })

  expect_type(res, "list")
  expect_true(all(c("hours_by_period", "pretrend_table", "pretrend_model") %in% names(res)))
  expect_s3_class(res$pretrend_model, "fixest")
})

test_that("2019 is the omitted reference year in the hours event-study model", {
  with_null_device({
    out <- capture.output(res <- suppressWarnings(run_hours_diagnostics(cleaned)))
  })
  coefs <- names(coef(res$pretrend_model))
  expect_false(any(grepl("2019", coefs)))
})

test_that("run_hours_diagnostics is restricted to the hours estimation sample", {
  with_null_device({
    out <- capture.output(res <- suppressWarnings(run_hours_diagnostics(cleaned)))
  })
  # n counts the rows each cell mean is computed from, not every employed row. Those differ by the
  # ~10%/year who were employed but absent from the reference week and so have no usual-hours value
  # (docs/decisions/hours-population-harmonization.md). Asserting against the employed count would
  # re-pin the inconsistency this was changed to remove.
  expect_equal(sum(res$hours_by_period$n), sum(!is.na(cleaned$WorkHoursCont)))
  expect_lt(sum(res$hours_by_period$n), sum(cleaned$Employed == 1, na.rm = TRUE))
})
