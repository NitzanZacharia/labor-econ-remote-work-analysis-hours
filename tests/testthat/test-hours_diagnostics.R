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
  expect_true(all(c("hours_by_period", "pretrend_table", "pretrend_coefs",
                    "pretrend_model") %in% names(res)))
  expect_s3_class(res$pretrend_model, "fixest")
})

test_that("run_hours_diagnostics returns tidy event-study coefficients for the plot builder", {
  # Replaced an iplot() side effect that returned nothing and could only be captured by wrapping the
  # whole function in a device. These coefficients are what build_event_study_plot() draws and what
  # reaches outputs/ as a CSV.
  with_null_device({
    out <- capture.output(res <- suppressWarnings(run_hours_diagnostics(cleaned)))
  })

  expect_s3_class(res$pretrend_coefs, "data.frame")
  expect_true(all(c("year", "estimate", "std_error", "ci_low", "ci_high", "period")
                  %in% names(res$pretrend_coefs)))
  # Every returned year is an observed, non-reference year. A subset rather than a setequal check:
  # on this small fixture some later years' Mother x year terms are dropped by collinearity and so
  # have no coefficient to extract, which is a property of the fixture, not of the extraction.
  expect_false(2019 %in% res$pretrend_coefs$year)
  expect_true(all(res$pretrend_coefs$year %in% setdiff(unique(cleaned$ShnatSeker), 2019)))
  expect_gt(nrow(res$pretrend_coefs), 0)
  # Whatever survived, the frame must agree with the model's own surviving coefficients exactly.
  expect_setequal(
    res$pretrend_coefs$term,
    grep("^ShnatSeker::\\d{4}:Mother$", names(coef(res$pretrend_model)), value = TRUE)
  )
  # Only the Mother x year terms, never the year main effects sitting beside them in the same model.
  expect_true(all(grepl(":Mother$", res$pretrend_coefs$term)))
  # The frame must describe the model actually returned, not a separately-fit one.
  for (i in seq_len(nrow(res$pretrend_coefs))) {
    expect_equal(res$pretrend_coefs$estimate[i],
                 unname(coef(res$pretrend_model)[[res$pretrend_coefs$term[i]]]))
  }
})

test_that("run_hours_diagnostics no longer draws to a graphics device", {
  # The port removed the iplot() call; main.R correspondingly dropped its pdf()/dev.off() wrapper.
  # If a draw call came back, it would silently leak an Rplots.pdf into the repo root on a real run.
  before <- grDevices::dev.cur()
  out <- capture.output(res <- suppressWarnings(run_hours_diagnostics(cleaned)))
  expect_equal(grDevices::dev.cur(), before)
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
