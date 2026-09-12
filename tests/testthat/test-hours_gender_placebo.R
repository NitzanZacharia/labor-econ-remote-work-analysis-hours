# test-hours_gender_placebo.R
# Hours-outcome (intensive-margin) counterpart to test-gender_placebo.R, added alongside
# hours_gender_placebo.R for the hours pivot (docs/decisions/hours-ddd-pivot.md).

test_that("run_hours_gender_placebo skips the DDD placebo gracefully when no exposure is supplied (backward compatibility)", {
  # No exposure_index, and the default exposure_csv_path won't resolve from testthat's working
  # directory -- must NOT error, and the documented structure (cleaned_men, result, ddd_placebo)
  # must hold regardless.
  out <- capture.output(res <- suppressWarnings(run_hours_gender_placebo(fixtures_dir)))
  expect_type(res, "list")
  expect_true(all(c("cleaned_men", "result", "ddd_placebo") %in% names(res)))
  expect_true(all(res$cleaned_men$Min == 1))
  expect_s3_class(res$result$models$hours, "fixest")
  expect_null(res$ddd_placebo)
})

# 10 occupations with distinct, evenly-spaced occupation-level exposure -- same template as
# test-hours_ddd_regression.R's make_hours_ddd_fixtures(), with Min = 1 (male subsample) added.
make_hours_gender_ddd_fixtures <- function(delta = -3) {
  n_occ     <- 10
  occ_codes <- 300 + seq_len(n_occ)
  exposure_index <- tibble::tibble(
    occupation_code = occ_codes,
    wfh_exposure    = seq(0.05, 0.95, length.out = n_occ)
  )

  n <- 400
  occ_i <- sample(seq_len(n_occ), n, replace = TRUE)
  panel <- tibble::tibble(
    Min = 1,
    MishlachYad_ISCO_08_2 = occ_codes[occ_i],
    .wfh                  = exposure_index$wfh_exposure[occ_i],
    MatzavMishpachti = factor(sample(1:5, n, replace = TRUE)),
    Dat              = factor(sample(1:5, n, replace = TRUE)),
    GilNK            = factor(sample(3:7, n, replace = TRUE)),
    MachozMegurim    = factor(sample(1:7, n, replace = TRUE)),
    TeudaGvoha       = factor(sample(c("A", "B", "C"), n, replace = TRUE)),
    Mother   = sample(0:1, n, replace = TRUE),
    Post     = sample(0:1, n, replace = TRUE),
    Employed = 1L
  ) %>%
    dplyr::mutate(
      WorkHoursCont = 40 + delta * Mother * Post * .wfh + stats::rnorm(dplyr::n(), 0, 0.5),
      IDPUF = dplyr::row_number()
    ) %>%
    dplyr::select(-.wfh)

  list(panel = panel, exposure_index = exposure_index)
}

test_that("run_hours_gender_ddd_placebo recovers the correct sign of a known injected effect", {
  set.seed(21)
  fx  <- make_hours_gender_ddd_fixtures(delta = -3)
  out <- capture.output(res <- suppressWarnings(
    run_hours_gender_ddd_placebo(fx$panel, fx$exposure_index)
  ))

  expect_type(res, "list")
  expect_true(all(c("n_employed", "n_matched", "model") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_true("Mother:Post:WFH_Exposure" %in% names(coef(res$model)))
  expect_lt(unname(coef(res$model)[["Mother:Post:WFH_Exposure"]]), 0)
  expect_equal(res$n_employed, nrow(fx$panel))
  expect_equal(res$n_matched, nrow(fx$panel))
})

test_that("run_hours_gender_ddd_placebo excludes non-employed and occupation-unmatched rows", {
  set.seed(22)
  fx <- make_hours_gender_ddd_fixtures(delta = -3)

  extra_nonemployed <- fx$panel[1:5, ] %>% dplyr::mutate(Employed = 0L, WorkHoursCont = NA_real_)
  extra_unmatched    <- fx$panel[1:3, ] %>% dplyr::mutate(MishlachYad_ISCO_08_2 = 9999)
  panel2 <- dplyr::bind_rows(fx$panel, extra_nonemployed, extra_unmatched)

  out <- capture.output(res <- suppressWarnings(
    run_hours_gender_ddd_placebo(panel2, fx$exposure_index)
  ))

  expect_equal(res$n_employed, nrow(fx$panel) + nrow(extra_unmatched))
  expect_equal(res$n_matched, nrow(fx$panel))
})

test_that("run_hours_gender_ddd_placebo returns a NULL model (not an error) when no rows match an occupation", {
  fx <- make_hours_gender_ddd_fixtures(delta = -3)
  unmatched_only <- fx$panel %>% dplyr::mutate(MishlachYad_ISCO_08_2 = 9999)

  expect_no_error({
    out <- capture.output(res <- run_hours_gender_ddd_placebo(unmatched_only, fx$exposure_index))
  })
  expect_equal(res$n_matched, 0)
  expect_null(res$model)
})
