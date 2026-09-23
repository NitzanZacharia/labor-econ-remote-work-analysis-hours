# test-exposure_sorting_check.R
# run_exposure_sorting_check(): a DiD with the occupation-level exposure score (and a top-quartile
# indicator) as the OUTCOME. In the synthetic panel Mother and Post are drawn independently of
# occupation, so the sorting DiD is a known zero; the structural checks pin the shape.

sorting_fixture <- function(seed = 61, n = 3000, n_occ = 12, with_years = TRUE) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = -3, n = n, n_occ = n_occ, with_years = with_years)
  joined <- fx$panel %>% dplyr::inner_join(
    fx$exposure_index %>% dplyr::select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
    by = "MishlachYad_ISCO_08_2")
  breaks <- if (with_years) compute_occupation_exposure_breaks(joined) else
    quantile(joined$WFH_Exposure, probs = c(0, .25, .5, .75, 1))
  list(fx = fx, breaks = breaks)
}

test_that("run_exposure_sorting_check returns the two DiDs, pre-period levels and the event study", {
  s <- sorting_fixture()
  out <- capture.output(res <- suppressWarnings(
    run_exposure_sorting_check(s$fx$panel, s$fx$exposure_index, breaks = s$breaks)
  ))

  expect_true(all(c("table", "pre_levels", "event_study", "models", "ref_year") %in% names(res)))
  expect_equal(nrow(res$table), 2)
  expect_setequal(res$table$outcome, c("Occupation-level WFH exposure (mean)", "In top exposure quartile (share)"))
  expect_true(all(c("estimate", "std_error", "p_value", "n", "pre_mean_mothers", "pre_mean_childless",
                    "pre_sd_exposure", "estimate_per_pre_sd") %in% names(res$table)))
  expect_equal(nrow(res$pre_levels), 2)
  expect_s3_class(res$models$exposure, "fixest")
  expect_s3_class(res$models$top_quartile, "fixest")
  # Event study: one row per non-reference year.
  expect_equal(sort(res$event_study$year), c(2017, 2018, 2021, 2022, 2023))
  expect_true(all(res$event_study$period[res$event_study$year < 2019] == "Pre"))
  # No sorting was built in: the mean-exposure DiD is within four SEs of zero.
  exp_row <- res$table[res$table$outcome == "Occupation-level WFH exposure (mean)", ]
  expect_lt(abs(exp_row$estimate), 4 * exp_row$std_error)
  expect_equal(exp_row$estimate_per_pre_sd, exp_row$estimate / exp_row$pre_sd_exposure)
  # The top-quartile share sits in [0, 1] for both groups in the pre-period.
  expect_true(all(res$pre_levels$share_top >= 0 & res$pre_levels$share_top <= 1))
})

test_that("run_exposure_sorting_check restricts to rows with the outcome observed, and can be widened", {
  s <- sorting_fixture(seed = 62, n = 1500)
  panel <- s$fx$panel
  panel$WorkHoursCont[1:200] <- NA
  out <- capture.output(narrow <- suppressWarnings(
    run_exposure_sorting_check(panel, s$fx$exposure_index, breaks = s$breaks)))
  out <- capture.output(wide <- suppressWarnings(
    run_exposure_sorting_check(panel, s$fx$exposure_index, breaks = s$breaks, outcome_sample = NULL)))
  expect_equal(narrow$table$n[1], nrow(panel) - 200)
  expect_equal(wide$table$n[1], nrow(panel))
})

test_that("run_exposure_sorting_check skips the event study without a year column and validates breaks", {
  s <- sorting_fixture(seed = 63, n = 1200, with_years = FALSE)
  expect_message(
    out <- capture.output(res <- suppressWarnings(
      run_exposure_sorting_check(s$fx$panel, s$fx$exposure_index, breaks = s$breaks))),
    "event-study version is skipped"
  )
  expect_null(res$event_study)
  expect_null(res$models$event_study)
  expect_equal(nrow(res$table), 2)
  expect_error(run_exposure_sorting_check(s$fx$panel, s$fx$exposure_index, breaks = c(0, 0.5, 1)), "breaks")
})
