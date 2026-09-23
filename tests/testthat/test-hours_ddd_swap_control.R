# test-hours_ddd_swap_control.R
# run_hours_ddd_swap_control(): the external-index DDD on all occupations with the swapped
# occupations given their own Mother x Post structure. The synthetic panel injects the effect
# through the TRUE exposure, so when the external index is that exposure the external-score
# gradient should recover delta whether or not a subset of occupations is flagged as swapped.

test_that("run_hours_ddd_swap_control estimates both triple interactions on the full matched sample", {
  set.seed(31)
  fx <- make_hours_ddd_panel(delta = -3, n = 3000, n_occ = 12)
  swapped <- fx$exposure_index$occupation_code[c(2, 5, 9)]
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_swap_control(fx$panel, fx$exposure_index, swapped_codes = swapped)
  ))

  expect_true(all(c("table", "model", "coefs", "n_matched", "n_clusters", "n_swapped_occupations") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_setequal(res$coefs$term, c("Mother:Post:WFH_Exposure", "Mother:Post:Swapped"))
  expect_equal(res$n_clusters, 12L)
  expect_equal(res$n_swapped_occupations, 3L)
  expect_equal(res$n_matched, nrow(fx$panel))
  expect_equal(nobs(res$model), nrow(fx$panel))
  # The injected gradient survives the swapped-occupation terms.
  b <- res$coefs$estimate[res$coefs$term == "Mother:Post:WFH_Exposure"]
  s <- res$coefs$std_error[res$coefs$term == "Mother:Post:WFH_Exposure"]
  expect_lt(abs(b - (-3)), 4 * s)
  expect_true(all(is.finite(res$coefs$p_value)))
})

test_that("run_hours_ddd_swap_control refuses an empty or all-covering swapped set", {
  fx <- make_hours_ddd_panel(delta = -3, n = 600, n_occ = 6)
  expect_error(run_hours_ddd_swap_control(fx$panel, fx$exposure_index, swapped_codes = numeric(0)), "empty")
  expect_error(
    suppressWarnings(run_hours_ddd_swap_control(fx$panel, fx$exposure_index,
                                                swapped_codes = fx$exposure_index$occupation_code)),
    "constant"
  )
  # Codes that match no occupation in the data leave the indicator constant at zero too.
  expect_error(
    suppressWarnings(run_hours_ddd_swap_control(fx$panel, fx$exposure_index, swapped_codes = c(9001, 9002))),
    "constant"
  )
})

test_that("run_hours_ddd_swap_control validates its inputs", {
  fx <- make_hours_ddd_panel(delta = -3, n = 300, n_occ = 6)
  expect_error(run_hours_ddd_swap_control(fx$panel, fx$exposure_index, swapped_codes = 301, outcome = "nope"), "outcome")
  bad_index <- dplyr::rename(fx$exposure_index, code = occupation_code)
  expect_error(run_hours_ddd_swap_control(fx$panel, bad_index, swapped_codes = 301), "occupation_code")
})
