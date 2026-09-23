# test-build_permutation_plot.R
# build_permutation_plot(): histogram of permutation draws with the observed t marked.

test_that("build_permutation_plot returns a ggplot and the finite draws it plotted", {
  set.seed(81)
  draws <- tibble::tibble(draw = 1:200, coef = rnorm(200), t_stat = c(rnorm(198), NA, Inf))
  res <- build_permutation_plot(draws, t_obs = 3.1, p_perm = 0.004)
  expect_s3_class(res$plot, "ggplot")
  expect_equal(nrow(res$data), 198)
})

test_that("build_permutation_plot returns NULL on missing or all-non-finite draws", {
  expect_message(res <- build_permutation_plot(NULL, t_obs = 1), "returning NULL")
  expect_null(res)
  expect_message(res2 <- build_permutation_plot(tibble::tibble(t_stat = c(NA, NA)), t_obs = 1),
                 "returning NULL")
  expect_null(res2)
})
