# test-hours_ddd_saturated.R
# run_hours_ddd_saturated(): the occupation x year, occupation x mother, mother x year
# fixed-effects version of the primary hours DDD. Against the shared synthetic panel with a
# planted triple effect (helper-setup.R's make_hours_ddd_panel(with_years = TRUE)).

test_that("run_hours_ddd_saturated recovers the sign of a planted triple effect and estimates only the triple term", {
  set.seed(21)
  fx  <- make_hours_ddd_panel(delta = -3, n = 1500, n_occ = 12, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_saturated(fx$panel, fx$exposure_index)))

  expect_true(all(c("table", "model", "n_employed", "n_matched", "fixed_effects") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_true("Mother:Post:WFH_Exposure" %in% names(coef(res$model)))
  expect_lt(unname(coef(res$model)[["Mother:Post:WFH_Exposure"]]), 0)
  # The lower-order terms are absorbed by the fixed effects, not estimated.
  expect_false("Mother:Post" %in% names(coef(res$model)))
  expect_false("WFH_Exposure" %in% names(coef(res$model)))
  expect_setequal(names(res$model$fixef_sizes),
                  c("MishlachYad_ISCO_08_2^ShnatSeker", "MishlachYad_ISCO_08_2^Mother", "Mother^ShnatSeker"))
})

test_that("run_hours_ddd_saturated and the pooled DDD agree on the sign and rough size of the planted effect", {
  set.seed(22)
  fx <- make_hours_ddd_panel(delta = 4, n = 2000, n_occ = 12, with_years = TRUE)
  out <- capture.output(sat <- suppressWarnings(run_hours_ddd_saturated(fx$panel, fx$exposure_index)))
  out <- capture.output(pooled <- suppressWarnings(run_hours_ddd_regression(fx$panel, fx$exposure_index)))

  b_sat <- unname(coef(sat$model)[["Mother:Post:WFH_Exposure"]])
  b_pool <- unname(coef(pooled$model)[["Mother:Post:WFH_Exposure"]])
  expect_gt(b_sat, 0)
  expect_lt(abs(b_sat - b_pool), 1.5)
})

test_that("run_hours_ddd_saturated does not warn about collinearity on a well-formed panel", {
  set.seed(23)
  fx <- make_hours_ddd_panel(delta = -3, n = 1500, n_occ = 12, with_years = TRUE)
  out <- capture.output(expect_no_warning(run_hours_ddd_saturated(fx$panel, fx$exposure_index)))
})
