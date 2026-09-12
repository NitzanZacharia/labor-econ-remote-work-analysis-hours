# test-hours_phase2_robustness.R
# Hours-outcome (primary DDD) counterpart to test-phase2_robustness.R, added alongside the hours
# analogs in phase2_robustness.R for the hours pivot (docs/decisions/hours-ddd-pivot.md). Unlike
# the employment fixture, every row here has a defined occupation code (prepare_hours_reweighted_
# ddd_df()'s inner_join to exposure_index already restricts to Employed == 1, occupation-matched
# rows -- there's no NA-occupation/non-employed row to simulate here).

make_hours_phase2_panel <- function() {
  set.seed(124)
  cell_defs <- expand.grid(gilnk = 3:7, moch = 1:2, teuda = c("X", "Y"), KEEP.OUT.ATTRS = FALSE)
  cell_defs$WFH_Exposure_cell <- stats::runif(nrow(cell_defs))
  exposure_cells <- tibble::tibble(
    Min = 2, GilNK = factor(cell_defs$gilnk), TeudaGvoha = cell_defs$teuda,
    MachozMegurim = factor(cell_defs$moch), WFH_Exposure = cell_defs$WFH_Exposure_cell
  )

  occ_codes <- c(23, 21, 26, 31, 51)
  exposure_index <- tibble::tibble(
    occupation_code = occ_codes,
    wfh_exposure    = seq(0.1, 0.9, length.out = length(occ_codes))
  )

  panel <- purrr::pmap_dfr(cell_defs, function(gilnk, moch, teuda, WFH_Exposure_cell) {
    n <- 200
    p_young_mother <- if (WFH_Exposure_cell < 0.5) 0.7 else 0.3
    mother <- stats::rbinom(n, 1, if (gilnk <= 4) p_young_mother else (1 - p_young_mother))
    year   <- sample(c(2018, 2019, 2022, 2023), n, replace = TRUE)
    post   <- as.integer(year >= 2021)
    isco   <- sample(occ_codes, n, replace = TRUE)
    wfh    <- exposure_index$wfh_exposure[match(isco, exposure_index$occupation_code)]
    tibble::tibble(
      Min = 2, GilNK = factor(gilnk), TeudaGvoha = teuda, MachozMegurim = factor(moch),
      MatzavMishpachti = factor(rep(c("A", "B"), length.out = n)),
      Dat = factor(rep(c("A", "B"), length.out = n)),
      Mother = mother, ShnatSeker = year, Post = post,
      Employed = 1L, MishlachYad_ISCO_08_2 = isco, MishkalSofi = stats::runif(n, 0.5, 2),
      WorkHoursCont = 40 - 3 * mother * post * wfh + stats::rnorm(n, 0, 0.5)
    )
  })

  panel <- panel %>% dplyr::mutate(IDPUF = dplyr::row_number())

  list(panel = panel, exposure_cells = exposure_cells, exposure_index = exposure_index)
}

test_that("prepare_hours_reweighted_ddd_df builds EducationSector correctly (1 only for ISCO==23)", {
  d <- make_hours_phase2_panel()
  out <- capture.output(prep <- prepare_hours_reweighted_ddd_df(d$panel, d$exposure_cells, d$exposure_index))

  expect_true(all(prep$ddd_df$EducationSector %in% c(0L, 1L)))
  expect_true(all(prep$ddd_df$EducationSector[prep$ddd_df$MishlachYad_ISCO_08_2 == 23] == 1))
  expect_true(all(prep$ddd_df$EducationSector[prep$ddd_df$MishlachYad_ISCO_08_2 != 23] == 0))
})

test_that("run_hours_ddd_twoway_cluster fits both cluster specs on identical N", {
  d <- make_hours_phase2_panel()
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_twoway_cluster(
    d$panel, d$exposure_cells, d$exposure_index
  )))

  expect_s3_class(res$one_way, "fixest")
  expect_s3_class(res$two_way, "fixest")
  expect_equal(stats::nobs(res$one_way), stats::nobs(res$two_way))
  expect_true(res$n_idpuf > 0 && res$n_occyear > 0)
})

test_that("run_hours_ddd_education_checks excludes exactly the ISCO==23 rows", {
  d <- make_hours_phase2_panel()
  n_isco23 <- sum(d$panel$MishlachYad_ISCO_08_2 == 23)
  expect_gt(n_isco23, 0)

  out <- capture.output(res <- suppressWarnings(run_hours_ddd_education_checks(
    d$panel, d$exposure_cells, d$exposure_index
  )))

  expect_equal(res$n_excluded, n_isco23)
  expect_s3_class(res$exclude_isco23, "fixest")
  expect_s3_class(res$education_dummy, "fixest")
  expect_true("Mother:Post:EducationSector" %in% names(coef(res$education_dummy)))
})

test_that("run_hours_ddd_weights_check's combined weight is exactly rake_weight * MishkalSofi and all four specs fit", {
  d <- make_hours_phase2_panel()
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_weights_check(
    d$panel, d$exposure_cells, d$exposure_index
  )))

  for (grp in list(res$unweighted, res$rake_only, res$design_only, res$combined)) {
    expect_s3_class(grp, "fixest")
  }

  out <- capture.output(prep <- prepare_hours_reweighted_ddd_df(d$panel, d$exposure_cells, d$exposure_index))
  expected_combined <- prep$ddd_df$rake_weight * prep$ddd_df$MishkalSofi
  expect_equal(sort(stats::weights(res$combined)), sort(stats::na.omit(expected_combined)),
               tolerance = 1e-8)
})
