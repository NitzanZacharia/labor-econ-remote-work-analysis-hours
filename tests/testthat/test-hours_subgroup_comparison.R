# test-hours_subgroup_comparison.R
# build_hours_subgroup_comparison() is a pure post-processing step over already-fitted models
# (no data cleaning/regression logic of its own), so these tests fit small synthetic fixest models
# directly rather than routing through the full data pipeline.

make_toy_model <- function(seed, term_coef = 1) {
  set.seed(seed)
  n <- 60
  df <- data.frame(
    y = rnorm(n),
    Mother = sample(0:1, n, replace = TRUE),
    Post   = sample(0:1, n, replace = TRUE)
  )
  df$y <- df$y + term_coef * df$Mother * df$Post
  fixest::feols(y ~ Mother * Post, data = df)
}

test_that("build_hours_subgroup_comparison extracts one coefficient + CI per model", {
  models <- list(
    "All women (primary)" = make_toy_model(1, term_coef = 2),
    "Jewish women"        = make_toy_model(2, term_coef = 1.5),
    "Arab women"          = make_toy_model(3, term_coef = 0.5)
  )
  out <- build_hours_subgroup_comparison(models, term = "Mother:Post", title = "Test")

  expect_type(out, "list")
  expect_s3_class(out$data, "data.frame")
  expect_equal(nrow(out$data), 3)
  expect_true(all(c("subgroup", "estimate", "se", "ci_low", "ci_high") %in% names(out$data)))
  expect_s3_class(out$plot, "ggplot")
})

test_that("build_hours_subgroup_comparison skips NULL models and models missing the term", {
  m_missing_term <- fixest::feols(y ~ x, data = data.frame(y = rnorm(30), x = rnorm(30)))
  models <- list(
    "All women (primary)" = make_toy_model(4, term_coef = 1),
    "Men (placebo)"       = NULL,
    "No such term"        = m_missing_term
  )
  out <- build_hours_subgroup_comparison(models, term = "Mother:Post", title = "Test")

  expect_equal(nrow(out$data), 1)
  expect_equal(as.character(out$data$subgroup), "All women (primary)")
})

test_that("build_hours_subgroup_comparison returns NULL when no model has the term", {
  models <- list("No such term" = fixest::feols(y ~ x, data = data.frame(y = rnorm(30), x = rnorm(30))))
  expect_null(build_hours_subgroup_comparison(models, term = "Mother:Post", title = "Test"))
})
