# test-hours_ddd_inference.R
# robustness/hours_ddd_inference.R: the wild cluster bootstrap wrapper and the permutation test on
# the primary hours DDD, both against the shared synthetic panel. The bootstrap tests skip when
# fwildclusterboot is absent, since it is an optional dependency (README.md).

fit_pooled <- function(fx) {
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_regression(fx$panel, fx$exposure_index)))
  res$model
}

test_that("run_hours_ddd_wild_bootstrap returns the documented one-row frame and is seed-reproducible", {
  skip_if_not_installed("fwildclusterboot")
  skip_if_not_installed("dqrng")
  set.seed(41)
  fx <- make_hours_ddd_panel(delta = -3, n = 800, n_occ = 12)
  m  <- fit_pooled(fx)

  r1 <- suppressMessages(run_hours_ddd_wild_bootstrap(m, "Mother:Post:WFH_Exposure", B = 199, seed = 7,
                                                      label = "headline"))
  r2 <- suppressMessages(run_hours_ddd_wild_bootstrap(m, "Mother:Post:WFH_Exposure", B = 199, seed = 7,
                                                      label = "headline"))

  expect_s3_class(r1$table, "data.frame")
  expect_equal(nrow(r1$table), 1)
  expect_true(all(c("label", "param", "estimate", "t_stat", "p_boot", "ci_low", "ci_high", "B",
                    "n_clusters", "weights", "seed") %in% names(r1$table)))
  expect_true(r1$table$p_boot >= 0 && r1$table$p_boot <= 1)
  expect_equal(r1$table$n_clusters, 12L)
  expect_equal(r1$table$B, 199L)
  expect_equal(r1$table$p_boot, r2$table$p_boot)
  expect_equal(r1$table$estimate, unname(coef(m)[["Mother:Post:WFH_Exposure"]]))
})

test_that("run_hours_ddd_wild_bootstrap handles a linear combination of two coefficients", {
  skip_if_not_installed("fwildclusterboot")
  skip_if_not_installed("dqrng")
  set.seed(42)
  fx <- make_hours_ddd_panel(delta = -3, n = 800, n_occ = 12)
  m  <- fit_pooled(fx)
  r <- suppressMessages(run_hours_ddd_wild_bootstrap(
    m, c("Mother:Post", "Mother:Post:WFH_Exposure"), R = c(1, 1), r = 0, B = 199, seed = 7,
    label = "sum"
  ))
  expect_equal(r$table$param, "Mother:Post + Mother:Post:WFH_Exposure")
  expect_equal(r$table$estimate,
               unname(coef(m)[["Mother:Post"]] + coef(m)[["Mother:Post:WFH_Exposure"]]))
})

test_that("run_hours_ddd_wild_bootstrap refuses a coefficient the model does not have", {
  skip_if_not_installed("fwildclusterboot")
  set.seed(43)
  fx <- make_hours_ddd_panel(delta = -3, n = 400, n_occ = 10)
  m  <- fit_pooled(fx)
  expect_error(run_hours_ddd_wild_bootstrap(m, "NotAThing", B = 99), "not in the model")
})

test_that("the permutation test rejects a strong planted effect and not a null one, and is seed-reproducible", {
  set.seed(44)
  fx_effect <- make_hours_ddd_panel(delta = -8, n = 1200, n_occ = 12)
  out <- capture.output(res_effect <- suppressMessages(
    run_hours_ddd_permutation_test(fx_effect$panel, fx_effect$exposure_index, n_perm = 199, seed = 9,
                                   report_every = 0)
  ))
  expect_true(all(c("table", "draws", "model") %in% names(res_effect)))
  expect_true(all(c("coef_name", "estimate", "t_stat", "p_perm", "p_perm_coef", "n_perm",
                    "n_perm_valid", "seed", "n_clusters", "p_perm_mc_se") %in% names(res_effect$table)))
  expect_equal(nrow(res_effect$draws), 199)
  expect_lt(res_effect$table$p_perm, 0.05)
  expect_equal(res_effect$table$n_clusters, 12L)

  set.seed(45)
  fx_null <- make_hours_ddd_panel(delta = 0, n = 1200, n_occ = 12)
  out <- capture.output(res_null <- suppressMessages(
    run_hours_ddd_permutation_test(fx_null$panel, fx_null$exposure_index, n_perm = 199, seed = 9,
                                   report_every = 0)
  ))
  expect_gt(res_null$table$p_perm, 0.05)

  out <- capture.output(res_again <- suppressMessages(
    run_hours_ddd_permutation_test(fx_null$panel, fx_null$exposure_index, n_perm = 199, seed = 9,
                                   report_every = 0)
  ))
  expect_equal(res_again$draws$t_stat, res_null$draws$t_stat)
})

test_that("the permutation p follows the Phipson-Smyth count and never reaches zero", {
  set.seed(46)
  fx <- make_hours_ddd_panel(delta = -8, n = 800, n_occ = 12)
  out <- capture.output(res <- suppressMessages(
    run_hours_ddd_permutation_test(fx$panel, fx$exposure_index, n_perm = 49, seed = 3, report_every = 0)
  ))
  n_ge <- sum(abs(res$draws$t_stat) >= abs(res$table$t_stat))
  expect_equal(res$table$p_perm, (1 + n_ge) / (1 + 49))
  expect_gt(res$table$p_perm, 0)
})
