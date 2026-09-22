# test-build_mechanism_scatter.R
# build_mechanism_scatter() is pure post-processing over an already-fitted second stage, so these
# tests build a small synthetic occupation-level frame directly rather than routing through the
# full pipeline -- same approach as test-hours_subgroup_comparison.R.

make_mechanism_df <- function(seed = 1, n = 20, slope = 4) {
  set.seed(seed)
  wfh <- seq(0.05, 0.95, length.out = n)
  # Heteroskedastic by construction: the weighting is the whole point of the second stage, so a
  # constant-SE fixture would let an unweighted fit pass the slope assertion by accident.
  se  <- runif(n, 0.2, 2.0)
  tibble::tibble(
    occupation_code = seq_len(n),
    wfh_exposure    = wfh,
    beta_j          = slope * wfh + rnorm(n, sd = se),
    se_j            = se
  )
}

test_that("build_mechanism_scatter returns data, fit_line and a ggplot", {
  df  <- make_mechanism_df()
  fit <- lm(beta_j ~ wfh_exposure, data = df, weights = 1 / se_j^2)
  out <- build_mechanism_scatter(df, fit = fit)

  expect_true(all(c("data", "fit_line", "plot") %in% names(out)))
  expect_s3_class(out$plot, "ggplot")
  expect_s3_class(out$data, "data.frame")
  expect_equal(nrow(out$data), nrow(df))
  expect_true(all(c("ci_low", "ci_high", "precision") %in% names(out$data)))
})

test_that("the drawn line is the precision-weighted fit, not an unweighted one", {
  # The guard that matters in this file. geom_smooth(method = "lm") would fit UNWEIGHTED and draw
  # a visibly different line from the slope the paper's text reports, with nothing to flag it.
  df  <- make_mechanism_df()
  fit <- lm(beta_j ~ wfh_exposure, data = df, weights = 1 / se_j^2)
  out <- build_mechanism_scatter(df, fit = fit)

  drawn_slope <- diff(out$fit_line$beta_j) / diff(out$fit_line$wfh_exposure)
  expect_equal(drawn_slope, unname(coef(fit)[2]))

  unweighted <- unname(coef(lm(beta_j ~ wfh_exposure, data = df))[2])
  expect_false(isTRUE(all.equal(drawn_slope, unweighted)))
})

test_that("fit_line spans the observed exposure range", {
  df  <- make_mechanism_df()
  fit <- lm(beta_j ~ wfh_exposure, data = df, weights = 1 / se_j^2)
  out <- build_mechanism_scatter(df, fit = fit)

  expect_equal(sort(out$fit_line$wfh_exposure), range(df$wfh_exposure))
})

test_that("precision is 1/se_j, since the frame carries no sample-size column", {
  df  <- make_mechanism_df()
  out <- build_mechanism_scatter(df, fit = NULL)
  expect_equal(out$data$precision, 1 / df$se_j)
  expect_false("n" %in% names(df))
})

test_that("a NULL or empty frame returns NULL rather than erroring", {
  expect_message(expect_null(build_mechanism_scatter(NULL)))
  expect_message(expect_null(build_mechanism_scatter(make_mechanism_df()[0, ])))
})

test_that("a fitted model supplies the subtitle when none is given", {
  df  <- make_mechanism_df()
  fit <- lm(beta_j ~ wfh_exposure, data = df, weights = 1 / se_j^2)
  out <- build_mechanism_scatter(df, fit = fit)
  # Built from the model rather than typed by hand, so caption and estimate cannot drift apart.
  expect_match(out$plot$labels$subtitle, "slope")
  expect_match(out$plot$labels$subtitle, "20 occupations")
})
