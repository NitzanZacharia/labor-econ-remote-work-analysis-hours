# test-clustered_se.R
# clustered_se() replaced hand-computed SEs throughout the descriptive layer. The property that
# matters is that it changes ONLY the standard error: every quantity it is used for is a saturated
# difference in means, so the point estimate must reproduce the arithmetic it replaced exactly.

make_clustered_panel <- function(seed = 1, n_people = 80, reps = 4) {
  set.seed(seed)
  people <- tibble::tibble(
    IDPUF  = seq_len(n_people),
    Mother = rep(c(0, 1), length.out = n_people),
    # A person-level shock is what makes clustering bite: without it the clustered and iid SEs
    # coincide and the test would pass for the wrong reason.
    person_effect = rnorm(n_people, sd = 4)
  )
  tidyr::crossing(people, rep = seq_len(reps)) %>%
    dplyr::mutate(
      Post = rep(c(0L, 1L), length.out = dplyr::n()),
      y    = 40 + person_effect + 2 * Mother * Post + rnorm(dplyr::n(), sd = 1)
    )
}

test_that("the intercept model returns the cell mean exactly", {
  d <- make_clustered_panel()
  out <- clustered_se(d, y ~ 1, "(Intercept)")
  expect_equal(out$estimate, mean(d$y))
  expect_equal(out$n, nrow(d))
})

test_that("a single regressor returns the exact difference in means", {
  d <- make_clustered_panel()
  out <- clustered_se(d, y ~ Mother, "Mother")
  expect_equal(out$estimate, mean(d$y[d$Mother == 1]) - mean(d$y[d$Mother == 0]))
})

test_that("the saturated 2x2 returns the exact difference-in-differences", {
  # This is the property the dose-response and the raw 2x2 rely on: swapping hand arithmetic for
  # feols must not move the point estimate.
  d <- make_clustered_panel()
  cell <- function(m, p) mean(d$y[d$Mother == m & d$Post == p])
  expected <- (cell(1, 1) - cell(1, 0)) - (cell(0, 1) - cell(0, 0))
  out <- clustered_se(d, y ~ Mother * Post, "Mother:Post")
  expect_equal(out$estimate, expected)
})

test_that("clustering widens the standard error relative to iid", {
  # The whole point of the change. With a person-level shock and 4 rows each, the clustered SE
  # should be materially larger than the naive one.
  d <- make_clustered_panel()
  clustered <- clustered_se(d, y ~ 1, "(Intercept)")$se
  iid <- sd(d$y) / sqrt(nrow(d))
  expect_gt(clustered, iid)
})

test_that("a missing term returns NA rather than erroring", {
  # Per-cell/quartile fits can degenerate on thin data; one bad cell must not abort a figure.
  d <- make_clustered_panel()
  d$constant_col <- 1
  out <- clustered_se(d, y ~ 1, "NoSuchTerm")
  expect_true(is.na(out$estimate))
  expect_true(is.na(out$se))
})
