# test-tidy_event_study_coefs.R
# Unit tests for tidy_event_study_coefs(), the extractor shared by run_hours_diagnostics()'s
# DiD-level event study and run_hours_ddd_event_study()'s triple-interaction one. Fit directly
# against small synthetic models here rather than through either caller, following
# test-pretrend_wald_test.R's precedent: the shared fixture CSVs carry no pre-2020 survey year, so
# the pre-period rows these tests assert on would not exist.

make_both_families_model <- function() {
  set.seed(21)
  n <- 3000
  df <- data.frame(
    ShnatSeker = sample(c(2017, 2018, 2019, 2021, 2022, 2023), n, replace = TRUE),
    Mother     = sample(0:1, n, replace = TRUE),
    occ        = sample(sprintf("%02d", 11:40), n, replace = TRUE)
  )
  df$WFH_Exposure <- as.numeric(factor(df$occ)) / 30
  df$MotherWFH    <- df$Mother * df$WFH_Exposure
  df$WorkHoursCont <- rnorm(n, 40)
  fixest::feols(
    WorkHoursCont ~ Mother * WFH_Exposure + i(ShnatSeker, ref = 2019) +
      i(ShnatSeker, Mother, ref = 2019) + i(ShnatSeker, WFH_Exposure, ref = 2019) +
      i(ShnatSeker, MotherWFH, ref = 2019),
    data = df, cluster = ~occ
  )
}

test_that("tidy_event_study_coefs returns one row per non-reference year with the documented columns", {
  m <- make_both_families_model()
  out <- tidy_event_study_coefs(m, term_suffix = "MotherWFH", ref_year = 2019)

  expect_s3_class(out, "data.frame")
  expect_equal(out$year, c(2017, 2018, 2021, 2022, 2023))
  expect_false(2019 %in% out$year)
  expect_true(all(c("term", "year", "estimate", "std_error", "t_stat", "p_value",
                    "ci_low", "ci_high", "period") %in% names(out)))
  expect_true(all(out$std_error > 0))
})

test_that("the term pattern is anchored, so 'Mother' does not also collect 'MotherWFH' terms", {
  # This is the whole reason the extractor exists as one shared, tested function. The model here
  # carries both families at once; an unanchored pattern would return ten rows for term_suffix =
  # "Mother" and silently plot two estimands on one axis.
  m <- make_both_families_model()

  did <- tidy_event_study_coefs(m, term_suffix = "Mother",    ref_year = 2019)
  ddd <- tidy_event_study_coefs(m, term_suffix = "MotherWFH", ref_year = 2019)

  expect_equal(nrow(did), 5)
  expect_equal(nrow(ddd), 5)
  expect_true(all(grepl(":Mother$", did$term)))
  expect_true(all(grepl(":MotherWFH$", ddd$term)))
  expect_length(intersect(did$term, ddd$term), 0)
  # And the two families really are different numbers, not the same ones relabelled.
  expect_false(isTRUE(all.equal(did$estimate, ddd$estimate)))
})

test_that("estimates, SEs and p-values agree with the fitted model and with fixest's own coeftable", {
  m <- make_both_families_model()
  out <- tidy_event_study_coefs(m, term_suffix = "MotherWFH", ref_year = 2019)
  ct <- as.data.frame(summary(m)$coeftable)

  for (i in seq_len(nrow(out))) {
    term <- out$term[i]
    expect_equal(out$estimate[i], unname(coef(m)[[term]]))
    expect_equal(out$std_error[i], unname(fixest::se(m)[[term]]))
    # The t-on-(G-1) handling is the part most likely to drift toward a normal approximation; pin it
    # against what fixest itself reports for the same coefficient.
    expect_equal(out$p_value[i], ct[term, "Pr(>|t|)"], tolerance = 1e-10)
  }
})

test_that("period is assigned relative to the supplied ref_year, not a hardcoded 2019", {
  m <- make_both_families_model()

  out19 <- tidy_event_study_coefs(m, term_suffix = "Mother", ref_year = 2019)
  expect_equal(sort(out19$year[out19$period == "Pre"]), c(2017, 2018))

  # The model's omitted year is still 2019, but a caller labelling periods against a different
  # boundary must get that boundary honoured.
  out22 <- tidy_event_study_coefs(m, term_suffix = "Mother", ref_year = 2022)
  expect_equal(sort(out22$year[out22$period == "Pre"]), c(2017, 2018, 2021))
  expect_equal(out22$year[out22$period == "Post"], c(2022, 2023))
})

test_that("a suffix matching no coefficient fails loudly rather than returning an empty frame", {
  # A 0-row return would export an empty CSV and plot nothing, with no error anywhere -- exactly
  # the silent failure this function is supposed to make impossible.
  m <- make_both_families_model()
  expect_error(
    tidy_event_study_coefs(m, term_suffix = "NoSuchTerm", ref_year = 2019),
    "no 'NoSuchTerm' event-study coefficients found"
  )
})
