# test-hours_ddd_event_study.R
# Unit tests for run_hours_ddd_event_study(), the year-by-year version of the primary hours DDD.
# Built on helper-setup.R's shared make_hours_ddd_panel(with_years = TRUE) rather than the fixture
# CSVs, for the same reason test-pretrend_wald_test.R builds its own: the shared fixtures cover no
# pre-2020 survey year at all, so every pre-period event-study coefficient the tests below assert on
# would simply not exist.

test_that("run_hours_ddd_event_study returns the documented structure and one coefficient per non-reference year", {
  set.seed(11)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)

  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index)
  ))

  expect_type(res, "list")
  expect_true(all(c("table", "model", "coefs", "ref_year", "term_suffix",
                    "n_employed", "n_matched") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_s3_class(res$coefs, "data.frame")

  # 6 survey years in the panel, 2019 omitted as the reference => 5 estimated years.
  expect_equal(sort(res$coefs$year), c(2017, 2018, 2021, 2022, 2023))
  expect_false(2019 %in% res$coefs$year)
  expect_true(all(c("term", "year", "estimate", "std_error", "t_stat", "p_value",
                    "ci_low", "ci_high", "period") %in% names(res$coefs)))
  expect_true(all(is.finite(res$coefs$estimate)))
  expect_true(all(res$coefs$std_error > 0))
})

test_that("the specification is a genuine triple difference: all three lower-order year interactions are present", {
  set.seed(12)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index)
  ))
  coefs <- names(coef(res$model))

  # Without each of these, the year x MotherWFH terms would absorb movement belonging to the year
  # main effects, the unconditional motherhood gap, or occupations' general exposure trend -- and
  # would be a mislabelled two-way estimate rather than a triple difference. This is the test that
  # would catch someone "simplifying" the formula in hours_ddd_event_study.R.
  expect_true(any(grepl("^ShnatSeker::2017$", coefs)))                 # year main effect
  expect_true(any(grepl("^ShnatSeker::2017:Mother$", coefs)))           # year x Mother
  expect_true(any(grepl("^ShnatSeker::2017:WFH_Exposure$", coefs)))     # year x exposure
  expect_true(any(grepl("^ShnatSeker::2017:MotherWFH$", coefs)))        # year x Mother x exposure
  # Time-invariant lower-order terms from `Mother * WFH_Exposure`.
  expect_true(all(c("Mother", "WFH_Exposure", "Mother:WFH_Exposure") %in% coefs))
})

test_that("standard errors are clustered on occupation, matching run_hours_ddd_regression()", {
  set.seed(13)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index)
  ))

  # The regressor of interest varies at the occupation level, so occupation -- not IDPUF, which the
  # two DiD event studies use -- is the clustering level. Asserted against the fitted model's own
  # recorded vcov (fixest tags the matrix with a "vcov_type" attribute naming the cluster variable)
  # rather than by re-reading the source text.
  expect_match(attr(vcov(res$model), "vcov_type"), "MishlachYad_ISCO_08_2", fixed = TRUE)
  expect_equal(unname(attr(vcov(res$model), "G")), 10)

  # 10 occupations in the fixture => G - 1 = 9 denominator df, and the exported CIs/p-values must be
  # built on that t distribution rather than on the normal.
  expect_equal(degrees_freedom(res$model, type = "t"), 9)
  expect_equal(
    res$coefs$ci_high,
    res$coefs$estimate + qt(0.975, df = 9) * res$coefs$std_error
  )
})

test_that("exported estimates and SEs match the fitted model's own coefficients", {
  set.seed(14)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index)
  ))

  # Guards the tidy-frame construction (the grep/sub on coefficient names) against silently pairing
  # a year with another year's estimate -- the kind of off-by-one a row-order change would introduce
  # and no other assertion here would notice.
  for (i in seq_len(nrow(res$coefs))) {
    term <- res$coefs$term[i]
    expect_equal(res$coefs$estimate[i], unname(coef(res$model)[[term]]))
    expect_equal(res$coefs$std_error[i], unname(fixest::se(res$model)[[term]]))
    expect_equal(res$coefs$term[i], paste0("ShnatSeker::", res$coefs$year[i], ":MotherWFH"))
  }
})

test_that("the post-period event-study coefficients recover the injected DDD effect", {
  # make_hours_ddd_panel() injects WorkHoursCont = 40 + delta * Mother * Post * exposure, i.e. the
  # same triple-difference effect in every post year and exactly zero in every pre year. A correctly
  # specified event study must therefore return ~delta for each post year and ~0 for each pre year.
  # This is the test that distinguishes a correct triple difference from a formula that merely fits.
  set.seed(15)
  p <- make_hours_ddd_panel(delta = -6, n = 4000, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index)
  ))

  post <- dplyr::filter(res$coefs, period == "Post")
  pre  <- dplyr::filter(res$coefs, period == "Pre")

  expect_equal(nrow(post), 3)
  expect_equal(nrow(pre), 2)
  expect_true(all(abs(post$estimate - (-6)) < 1))
  expect_true(all(abs(pre$estimate) < 1))
})

test_that("period splits pre/post at the reference year and ref_year is echoed back", {
  set.seed(16)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index)
  ))

  expect_equal(res$ref_year, 2019)
  expect_equal(res$term_suffix, "MotherWFH")
  expect_equal(sort(res$coefs$year[res$coefs$period == "Pre"]), c(2017, 2018))
  expect_equal(sort(res$coefs$year[res$coefs$period == "Post"]), c(2021, 2022, 2023))
})

test_that("run_hours_ddd_event_study is restricted to employed rows with a matched occupation", {
  set.seed(17)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)

  # Two rows the estimation sample must exclude: a non-employed row, and an employed row whose ISCO
  # code is in no exposure index (the disclosure-masked/unmapped case inner_join() drops).
  panel <- p$panel
  panel$Employed[1] <- 0L
  panel$MishlachYad_ISCO_08_2[2] <- 999

  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(panel, p$exposure_index)
  ))

  expect_equal(res$n_employed, sum(panel$Employed == 1))
  expect_equal(res$n_matched, nobs(res$model))
  expect_lt(res$n_matched, res$n_employed)
})

test_that("an unrecognised reference year still produces coefficients for every observed year", {
  # ref_year is a parameter, so a caller can move the reference. 2018 is a real year in the panel:
  # the omitted year must follow the argument rather than staying pinned to a hardcoded 2019.
  set.seed(18)
  p <- make_hours_ddd_panel(delta = -3, n = 1200, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_event_study(p$panel, p$exposure_index, ref_year = 2018)
  ))

  expect_equal(res$ref_year, 2018)
  expect_false(2018 %in% res$coefs$year)
  expect_true(2019 %in% res$coefs$year)
  # `period` is defined relative to ref_year, so with ref = 2018 only 2017 is a pre-period year.
  expect_equal(res$coefs$year[res$coefs$period == "Pre"], 2017)
})
