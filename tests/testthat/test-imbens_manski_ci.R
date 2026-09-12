# test-imbens_manski_ci.R
# imbens_manski_ci.R has no dedicated unit test elsewhere -- it's only ever exercised indirectly as
# a black box through intensive_margin_lee_bounds.R and hours_ddd_lee_bounds.R, and even then only
# the delta == 0 ("no excess selection") branch is asserted anywhere (c_alpha == qnorm(0.975)).
# This file closes that gap directly: the delta > 0 branch's actual c_alpha/CI values, and the
# denom <= 0 / non-finite-denominator fallback branch (imbens_manski_ci.R:16-19), neither of which
# is exercised by any other test in this suite.

test_that("delta == 0 (no excess selection) collapses to the ordinary +-z*se interval", {
  ci <- imbens_manski_ci(theta_L = 3, theta_U = 3, se_L = 1, se_U = 2, conf_level = 0.95)

  expect_equal(ci$c_alpha, qnorm(0.975))
  expect_equal(ci$lower, 3 - qnorm(0.975) * 1)
  expect_equal(ci$upper, 3 + qnorm(0.975) * 2)
})

test_that("conf_level other than 0.95 is respected in the delta == 0 branch", {
  ci <- imbens_manski_ci(theta_L = 0, theta_U = 0, se_L = 1, se_U = 1, conf_level = 0.90)
  expect_equal(ci$c_alpha, qnorm(0.95))
})

test_that("delta > 0 solves the documented Imbens-Manski (2004) defining equation", {
  # Independently re-derive the expected c_alpha from the equation stated in imbens_manski_ci.R's
  # own header comment (Phi(c + delta/denom) - Phi(-c) = conf_level), rather than calling the
  # function under test -- this is a genuine hand-computable reference, not a tautological check.
  theta_L <- 0; theta_U <- 1; se_L <- 1; se_U <- 1; conf_level <- 0.95
  delta <- theta_U - theta_L
  denom <- max(se_L, se_U)
  reference_target <- function(c) pnorm(c + delta / denom) - pnorm(-c) - conf_level
  expected_c_alpha <- uniroot(reference_target, interval = c(0, 20))$root

  ci <- imbens_manski_ci(theta_L, theta_U, se_L, se_U, conf_level)

  expect_equal(ci$c_alpha, expected_c_alpha, tolerance = 1e-6)
  expect_equal(ci$lower, theta_L - expected_c_alpha * se_L, tolerance = 1e-6)
  expect_equal(ci$upper, theta_U + expected_c_alpha * se_U, tolerance = 1e-6)
  # A real excess-selection case: the returned c_alpha must be strictly larger than the ordinary
  # (delta == 0) z-value -- the whole point of the Imbens-Manski correction is a wider interval
  # than treating theta_L/theta_U as if they had no partial-identification gap between them.
  expect_gt(ci$c_alpha, qnorm(1 - (1 - conf_level) / 2))
})

test_that("delta > 0 with asymmetric SEs still solves the defining equation (denom = max(se_L, se_U))", {
  theta_L <- -2; theta_U <- 4; se_L <- 0.5; se_U <- 2; conf_level <- 0.95
  delta <- theta_U - theta_L
  denom <- max(se_L, se_U)
  reference_target <- function(c) pnorm(c + delta / denom) - pnorm(-c) - conf_level
  expected_c_alpha <- uniroot(reference_target, interval = c(0, 20))$root

  ci <- imbens_manski_ci(theta_L, theta_U, se_L, se_U, conf_level)

  expect_equal(ci$c_alpha, expected_c_alpha, tolerance = 1e-6)
  expect_equal(ci$lower, theta_L - expected_c_alpha * se_L, tolerance = 1e-6)
  expect_equal(ci$upper, theta_U + expected_c_alpha * se_U, tolerance = 1e-6)
})

test_that("a zero denominator (both SEs zero) falls back to the ordinary z-interval with se=0 collapsing to point estimates", {
  ci <- imbens_manski_ci(theta_L = 2, theta_U = 5, se_L = 0, se_U = 0, conf_level = 0.95)

  expect_equal(ci$c_alpha, qnorm(0.975))
  expect_equal(ci$lower, 2)
  expect_equal(ci$upper, 5)
})

test_that("a non-finite denominator (Inf SE) falls back to the ordinary z-interval rather than erroring", {
  ci <- imbens_manski_ci(theta_L = 1, theta_U = 3, se_L = 1, se_U = Inf, conf_level = 0.95)

  expect_equal(ci$c_alpha, qnorm(0.975))
  expect_equal(ci$lower, 1 - qnorm(0.975) * 1)
  expect_true(is.infinite(ci$upper))
})
