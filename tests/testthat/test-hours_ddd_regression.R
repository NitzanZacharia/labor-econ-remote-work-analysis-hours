# test-hours_ddd_regression.R
# Unit tests for run_hours_ddd_regression() -- the primary (intensive-margin, WorkHoursCont) DDD,
# using the PURE occupation-level WFH exposure measure (joined by MishlachYad_ISCO_08_2) rather
# than the demographic-cell-based WFH_Exposure the secondary (employment) DDD uses. See
# docs/decisions/hours-ddd-pivot.md.

# The synthetic panel builder lives in helper-setup.R as make_hours_ddd_panel(), shared with
# test-hours_gender_placebo.R. Controls, Mother and Post are all independently sampled rather than
# built from rep()-based row patterns -- an earlier version used rep() patterns for both and they
# shared the same period/phase, making several controls exactly collinear with Mother across the
# whole panel.
make_hours_ddd_fixtures <- function(delta = -3) make_hours_ddd_panel(delta = delta)

test_that("run_hours_ddd_regression recovers the correct sign of a known injected effect", {
  set.seed(11)
  fx  <- make_hours_ddd_fixtures(delta = -3)
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_regression(fx$panel, fx$exposure_index)))

  expect_type(res, "list")
  expect_true(all(c("table", "model", "n_employed", "n_matched") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_true("Mother:Post:WFH_Exposure" %in% names(coef(res$model)))
  expect_lt(unname(coef(res$model)[["Mother:Post:WFH_Exposure"]]), 0)
  expect_equal(res$n_employed, nrow(fx$panel))
  expect_equal(res$n_matched, nrow(fx$panel))
})

test_that("run_hours_ddd_regression excludes non-employed and occupation-unmatched rows", {
  set.seed(12)
  fx <- make_hours_ddd_fixtures(delta = -3)

  extra_nonemployed <- fx$panel[1:5, ] %>% dplyr::mutate(Employed = 0L, WorkHoursCont = NA_real_)
  extra_unmatched    <- fx$panel[1:3, ] %>% dplyr::mutate(MishlachYad_ISCO_08_2 = 9999)
  panel2 <- dplyr::bind_rows(fx$panel, extra_nonemployed, extra_unmatched)

  out <- capture.output(res <- suppressWarnings(run_hours_ddd_regression(panel2, fx$exposure_index)))

  expect_equal(res$n_employed, nrow(fx$panel) + nrow(extra_unmatched))
  expect_equal(res$n_matched, nrow(fx$panel))
})

test_that("run_hours_ddd_regression flags unexpected collinear drops", {
  fx <- make_hours_ddd_fixtures(delta = -3)
  out <- capture.output(
    expect_no_warning(res <- run_hours_ddd_regression(fx$panel, fx$exposure_index))
  )
})

test_that("run_hours_ddd_regression's second-stage mechanism regression recovers the known per-occupation slope", {
  # Model 1's injected effect (delta * Mother * Post * wfh_exposure) means each occupation's own
  # Mother:Post coefficient (beta_j) should scale with that occupation's wfh_exposure -- i.e. the
  # mechanism regression's slope on wfh_exposure should recover the same sign as delta.
  set.seed(13)
  fx  <- make_hours_ddd_fixtures(delta = -3)
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_regression(fx$panel, fx$exposure_index)))

  expect_true(all(c("models", "mechanism_data", "dropped_occupations") %in% names(res)))
  expect_s3_class(res$models$ddd, "fixest")
  expect_s3_class(res$models$mechanism, "lm")
  expect_lt(unname(coef(res$models$mechanism)[["wfh_exposure"]]), 0)
  expect_equal(res$dropped_occupations$n_dropped, nrow(res$dropped_occupations$data))
})

# ── `outcome` / `run_mechanism` (2026-09-22 grade-report response, item M3) ──────────────────
test_that("the outcome argument switches the dependent variable and run_mechanism = FALSE skips the second stage", {
  set.seed(14)
  fx <- make_hours_ddd_fixtures(delta = -3)
  panel <- dplyr::mutate(fx$panel, FullTime = as.integer(WorkHoursCont >= 40))

  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_regression(panel, fx$exposure_index, outcome = "FullTime")
  ))
  expect_equal(res$outcome, "FullTime")
  expect_equal(as.character(res$model$fml[[2]]), "FullTime")
  expect_true("Mother:Post:WFH_Exposure" %in% names(coef(res$model)))
  # A binary outcome has no per-occupation hours mechanism stage.
  expect_null(res$models$mechanism)
  expect_null(res$mechanism_data)

  out <- capture.output(res_default <- suppressWarnings(run_hours_ddd_regression(fx$panel, fx$exposure_index)))
  expect_equal(res_default$outcome, "WorkHoursCont")
  expect_s3_class(res_default$models$mechanism, "lm")

  expect_error(run_hours_ddd_regression(fx$panel, fx$exposure_index, outcome = "Nope"), "not in cleaned_df")
})
