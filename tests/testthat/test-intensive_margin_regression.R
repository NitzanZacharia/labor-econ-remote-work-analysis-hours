# test-intensive_margin_regression.R
# Checkpoint 4: contract tests for run_intensive_margin_reg(), mirroring
# test-basic_regression.R's pattern: structure/class/coefficient-name
# checks on the fixture data, plus an exact hand-computable DiD check on a synthetic saturated 2x2
# design (no simulation/randomness needed).

cleaned <- load_and_clean_data(fixtures_dir)

test_that("run_intensive_margin_reg returns the documented structure and fits on fixture data", {
  out <- capture.output(res <- run_intensive_margin_reg(cleaned))
  expect_type(res, "list")
  expect_true(all(c("table", "models") %in% names(res)))
  expect_s3_class(res$models$hours, "fixest")

  coefs <- names(coef(res$models$hours))
  expect_true("Mother" %in% coefs)
  expect_true("Post" %in% coefs)
})

test_that("run_intensive_margin_reg is estimated only on Employed == 1", {
  out <- capture.output(res <- run_intensive_margin_reg(cleaned))
  expected_n <- sum(cleaned$Employed == 1 & !is.na(cleaned$WorkHoursCont))
  expect_lte(nobs(res$models$hours), expected_n)
})

test_that("run_intensive_margin_reg recovers an exact hand-computable DiD effect on a saturated synthetic design", {
  # Same construction as test-basic_regression.R's DiD check: WorkHoursCont ~ Mother + Post +
  # Mother:Post is fully saturated for a balanced 2x2 design, so Mother:Post must equal exactly
  # cellMean(1,1) - cellMean(1,0) - cellMean(0,1) + cellMean(0,0) = 32 - 30 - 30 + 30 = 2 hours.
  # All rows are Employed == 1 (the function filters on that internally, so this fixture already
  # satisfies it). Controls use a balanced 2-level factor (see test-basic_regression.R for why
  # this preserves exactness) so every level is a 2+-level factor without perturbing the result.
  make_cell <- function(mother, post, hours_vec) {
    n <- length(hours_vec)
    ctrl <- factor(rep(c("A", "B"), length.out = n))
    tibble::tibble(
      Mother = mother, Post = post, Employed = 1L, WorkHoursCont = hours_vec,
      MatzavMishpachti = ctrl, Dat = ctrl, GilNK = ctrl, MachozMegurim = ctrl, TeudaGvoha = ctrl
    )
  }
  synth <- dplyr::bind_rows(
    make_cell(0, 0, rep(30, 20)),
    make_cell(0, 1, rep(30, 20)),
    make_cell(1, 0, rep(30, 20)),
    make_cell(1, 1, rep(32, 20))  # +2 hours for mothers, post-period only
  )
  synth$IDPUF <- seq_len(nrow(synth))

  out <- capture.output(res <- suppressWarnings(run_intensive_margin_reg(synth)))
  did_coef <- coef(res$models$hours)[["Mother:Post"]]
  expect_equal(did_coef, 2, tolerance = 1e-8)
})

# ── `year_fe` (2026-09-22 grade-report response, item M1) ────────────────────────────────────
test_that("year_fe = TRUE replaces Post with survey-year effects and keeps Mother:Post", {
  set.seed(15)
  fx <- make_hours_ddd_panel(delta = -3, n = 1200, n_occ = 10, with_years = TRUE)
  out <- capture.output(res <- suppressWarnings(run_intensive_margin_reg(fx$panel, year_fe = TRUE)))

  coefs <- names(coef(res$models$hours))
  expect_true("Mother:Post" %in% coefs)
  expect_false("Post" %in% coefs)
  expect_true(any(grepl("^ShnatSeker::20(17|18|21|22|23)$", coefs)))
  expect_false("ShnatSeker::2019" %in% coefs)

  out <- capture.output(res_default <- suppressWarnings(run_intensive_margin_reg(fx$panel)))
  expect_true("Post" %in% names(coef(res_default$models$hours)))
})
