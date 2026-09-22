# test-employment_by_child_age.R
# Priority 2: the recycled-predictions margins block (map_dfr over ChildAgeBin levels,
# re-leveling a temp copy of the data, predict(), average) is complex enough logic to regress
# silently -- this checks the full function runs and returns the documented structure over all
# 5 child-age bins the fixtures are designed to cover.

cleaned <- load_and_clean_data(fixtures_dir)

test_that("employment_by_child_age returns the documented structure on fixture data", {
  out <- capture.output(res <- employment_by_child_age(cleaned))

  expect_type(res, "list")
  expect_true(all(c("emp_raw", "emp_by_period", "model", "plots") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_true(all(c("raw", "period", "adjusted") %in% names(res$plots)))
  for (p in res$plots) expect_s3_class(p, "ggplot")

  # fixtures are designed to cover all 5 GilYeledTzairMBNK bins (1-5)
  expect_equal(nrow(res$emp_raw), 5)
})

test_that("raw and adjusted employment rates are finite", {
  out <- capture.output(res <- employment_by_child_age(cleaned))
  expect_true(all(is.finite(res$emp_raw$emp_rate)))
})

test_that("emp_by_period carries cluster-robust confidence intervals inside [0, 1]", {
  # The pre/post profiles are plotted with error bars, so the bounds have to exist and be valid
  # proportions. The SE is clustered by IDPUF rather than binomial (see scripts/clustered_se.R):
  # the LFS repeats individuals, so sqrt(p(1-p)/n) understated these by roughly 1.6x.
  #
  # Degenerate cells are expected HERE and only here: the shared fixture is ~20 rows, so several
  # bin x period cells hold one or two observations and feols cannot fit them. clustered_se()
  # returns NA for those by design, so the bound checks run on the cells that did fit.
  out <- capture.output(res <- employment_by_child_age(cleaned))
  p <- res$emp_by_period

  expect_true(all(c("se", "ci_low", "ci_high") %in% names(p)))
  fitted <- p[!is.na(p$se), ]
  expect_gt(nrow(fitted), 0)
  expect_true(all(fitted$ci_low >= 0))
  expect_true(all(fitted$ci_high <= 1))
  expect_true(all(fitted$ci_low <= fitted$emp_rate))
  expect_true(all(fitted$ci_high >= fitted$emp_rate))
})

test_that("adjusted_rates is exported alongside the raw rates", {
  # The paper quotes the adjusted 15-17 figure in its descriptive section; before this it existed
  # only as an in-script prediction and had no reproducible source on disk.
  out <- capture.output(res <- employment_by_child_age(cleaned))

  expect_true("adjusted_rates" %in% names(res))
  expect_true(all(c("ChildAgeBin", "emp_rate", "adj_emp") %in% names(res$adjusted_rates)))
  expect_equal(nrow(res$adjusted_rates), 5)
  expect_true(all(is.finite(res$adjusted_rates$adj_emp)))
})
