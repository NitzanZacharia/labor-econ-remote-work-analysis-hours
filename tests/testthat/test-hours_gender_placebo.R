# test-hours_gender_placebo.R
# Hours-outcome (intensive-margin) counterpart to test-gender_placebo.R, added alongside
# hours_gender_placebo.R for the hours pivot (docs/decisions/hours-ddd-pivot.md).

test_that("run_hours_gender_placebo skips the DDD placebo gracefully when no exposure is supplied (backward compatibility)", {
  # No exposure_index, and the default exposure_csv_path won't resolve from testthat's working
  # directory -- must NOT error, and the documented structure (cleaned_men, result, ddd_placebo)
  # must hold regardless.
  out <- capture.output(res <- suppressWarnings(run_hours_gender_placebo(fixtures_dir)))
  expect_type(res, "list")
  expect_true(all(c("cleaned_men", "result", "ddd_placebo") %in% names(res)))
  expect_true(all(res$cleaned_men$Min == 1))
  expect_s3_class(res$result$models$hours, "fixest")
  expect_null(res$ddd_placebo)
})

# The synthetic male panel comes from helper-setup.R's make_hours_ddd_panel(), shared with
# test-hours_ddd_regression.R; min_sex = 1 adds the Min column the male subsample needs.
make_hours_gender_ddd_fixtures <- function(delta = -3) {
  make_hours_ddd_panel(delta = delta, min_sex = 1)
}

test_that("run_hours_gender_ddd_placebo recovers the correct sign of a known injected effect", {
  set.seed(21)
  fx  <- make_hours_gender_ddd_fixtures(delta = -3)
  out <- capture.output(res <- suppressWarnings(
    run_hours_gender_ddd_placebo(fx$panel, fx$exposure_index)
  ))

  expect_type(res, "list")
  expect_true(all(c("n_employed", "n_matched", "model") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_true("Mother:Post:WFH_Exposure" %in% names(coef(res$model)))
  expect_lt(unname(coef(res$model)[["Mother:Post:WFH_Exposure"]]), 0)
  expect_equal(res$n_employed, nrow(fx$panel))
  expect_equal(res$n_matched, nrow(fx$panel))
  # `table` (the etable() output, for export_all_results() to pick up -- a raw fixest model object
  # is silently skipped by the exporter) must be populated whenever the model fits.
  expect_true(is.data.frame(res$table))
})

test_that("run_hours_gender_ddd_placebo excludes non-employed and occupation-unmatched rows", {
  set.seed(22)
  fx <- make_hours_gender_ddd_fixtures(delta = -3)

  extra_nonemployed <- fx$panel[1:5, ] %>% dplyr::mutate(Employed = 0L, WorkHoursCont = NA_real_)
  extra_unmatched    <- fx$panel[1:3, ] %>% dplyr::mutate(MishlachYad_ISCO_08_2 = 9999)
  panel2 <- dplyr::bind_rows(fx$panel, extra_nonemployed, extra_unmatched)

  out <- capture.output(res <- suppressWarnings(
    run_hours_gender_ddd_placebo(panel2, fx$exposure_index)
  ))

  expect_equal(res$n_employed, nrow(fx$panel) + nrow(extra_unmatched))
  expect_equal(res$n_matched, nrow(fx$panel))
})

test_that("run_hours_gender_ddd_placebo returns a NULL model (not an error) when no rows match an occupation", {
  fx <- make_hours_gender_ddd_fixtures(delta = -3)
  unmatched_only <- fx$panel %>% dplyr::mutate(MishlachYad_ISCO_08_2 = 9999)

  expect_no_error({
    out <- capture.output(res <- run_hours_gender_ddd_placebo(unmatched_only, fx$exposure_index))
  })
  expect_equal(res$n_matched, 0)
  expect_null(res$model)
  expect_null(res$table)
})
