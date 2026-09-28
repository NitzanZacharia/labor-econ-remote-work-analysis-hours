# test-hours_ddd_marital_interacted.R
# run_hours_ddd_marital_interacted(): the hours DDD with marital status x Post x WFH_Exposure
# added. On the synthetic panel marital status is independent of the injected effect, so the
# triple interaction should still recover delta and the marital terms should be estimated.

test_that("run_hours_ddd_marital_interacted adds the marital interaction terms and keeps the gradient", {
  set.seed(51)
  fx <- make_hours_ddd_panel(delta = -3, n = 3000, n_occ = 12)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_marital_interacted(fx$panel, fx$exposure_index)
  ))

  expect_true(all(c("model", "n_clusters", "n_matched") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_equal(res$n_clusters, 12L)
  expect_equal(res$n_matched, nrow(fx$panel))
  cn <- names(coef(res$model))
  expect_true("Mother:Post:WFH_Exposure" %in% cn)
  expect_true(any(grepl("^Post:WFH_Exposure:MatzavMishpachti", cn)))
  expect_true(any(grepl("^WFH_Exposure:MatzavMishpachti", cn)))
  b <- unname(coef(res$model)[["Mother:Post:WFH_Exposure"]])
  s <- unname(se(res$model)[["Mother:Post:WFH_Exposure"]])
  expect_lt(abs(b - (-3)), 4 * s)
})

test_that("run_hours_ddd_marital_interacted validates its inputs", {
  fx <- make_hours_ddd_panel(delta = -3, n = 300, n_occ = 6)
  expect_error(run_hours_ddd_marital_interacted(fx$panel, fx$exposure_index, outcome = "nope"), "outcome")
  expect_error(
    run_hours_ddd_marital_interacted(dplyr::select(fx$panel, -MatzavMishpachti), fx$exposure_index),
    "MatzavMishpachti"
  )
})
