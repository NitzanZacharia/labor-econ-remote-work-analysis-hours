# test-calibration_threshold_sweep.R
# run_calibration_threshold_sweep(): recalibrates the exposure index at each gap threshold and
# refits the hours DDD. Built on the synthetic panel with a calibration population whose realized
# WFH is far from the external score for some occupations, so low thresholds swap them and high
# thresholds swap nothing.

make_sweep_fixture <- function(seed = 61) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = -3, n = 2000, n_occ = 8)
  codes <- fx$exposure_index$occupation_code
  # External scores; realized WFH gaps of ~0.8 for the first two occupations, ~0.4 for the third,
  # ~0 for the rest.
  external <- tibble::tibble(ISCO2 = codes, tele_ext = c(0.1, 0.1, 0.1, 0.5, 0.5, 0.5, 0.5, 0.5))
  realized_p <- c(0.9, 0.9, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
  pop <- purrr::map_dfr(seq_along(codes), function(i) tibble::tibble(
    ShnatSeker = rep(c(2022, 2023), length.out = 400), Employed = 1L,
    MishlachYad_ISCO_08_2 = codes[i],
    WFH = rep(c(1, 0), round(400 * c(realized_p[i], 1 - realized_p[i]))),
    IDPUF = 100000 * i + rep(seq_len(200), length.out = 400)
  ))
  list(panel = fx$panel, pop = pop, external = external, codes = codes)
}

test_that("run_calibration_threshold_sweep swaps fewer occupations as the threshold rises", {
  f <- make_sweep_fixture()
  out <- capture.output(res <- suppressWarnings(run_calibration_threshold_sweep(
    f$panel, f$pop, f$external, thresholds = c(0.3, 0.5, 0.7, 0.95)
  )))
  tb <- res$table
  expect_equal(nrow(tb), 4)
  expect_true(all(c("threshold", "n_swapped", "swapped_codes", "estimate", "se", "p_value", "n",
                    "n_clusters") %in% names(tb)))
  expect_true(all(diff(tb$n_swapped) <= 0))
  expect_equal(tb$n_swapped[tb$threshold == 0.3], 3L)
  expect_equal(tb$n_swapped[tb$threshold == 0.7], 2L)
  expect_equal(tb$n_swapped[tb$threshold == 0.95], 0L)
  expect_true(all(is.finite(tb$estimate)) && all(tb$se > 0))
  expect_true(all(tb$n_clusters == 8L))
})

test_that("a threshold above every gap reproduces the external-index DDD", {
  f <- make_sweep_fixture()
  out <- capture.output(res <- suppressWarnings(run_calibration_threshold_sweep(
    f$panel, f$pop, f$external, thresholds = 0.95
  )))
  out2 <- capture.output(ext <- suppressWarnings(run_hours_ddd_regression(
    f$panel, dplyr::transmute(f$external, occupation_code = ISCO2, wfh_exposure = tele_ext),
    run_mechanism = FALSE
  )))
  expect_equal(res$table$estimate, unname(coef(ext$model)[["Mother:Post:WFH_Exposure"]]))
  expect_equal(res$table$swapped_codes, "")
})

test_that("run_calibration_threshold_sweep rejects an empty threshold vector", {
  f <- make_sweep_fixture()
  expect_error(run_calibration_threshold_sweep(f$panel, f$pop, f$external, thresholds = numeric(0)),
               "thresholds")
})
