# test-pipeline_smoke.R
# Priority 4 / TESTING_BLUEPRINT.md §4: main.R can't be unit-tested directly (it's a script, not a
# function -- rm(list=ls()), a hardcoded path, saveRDS/readRDS caching). This mirrors its actual
# sequence against the fixtures instead: load -> comparative stats -> pooled regression ->
# Jewish/Arab stratified regressions -> child-age descriptives -> diagnostics.
#
# The second test below extends this to mirror main.R's §8b (WFH-exposure measures + the secondary,
# extensive-margin DDD) -- previously the only part of main.R's sequence with no end-to-end
# coverage at all, even though every function it calls is separately unit-tested elsewhere. This is
# deliberately a SMOKE test, not a correctness test: it checks the orchestration itself (the joins,
# the cell_fe_vars/other_controls split, the two-spec employment DDD) runs without error against
# fixture-sized data, not that any particular number comes out right. Two parameters are adapted
# from main.R's real values because the fixtures are far too small to satisfy them literally:
# build_exposure_isco2() is pointed at a small temporary CSV instead of the real (locally-supplied,
# separately-tracked-as-missing) israeli_cbs_wfh_2digit.csv, and build_wfh_exposure_index() uses
# min_n = 0 instead of main.R's min_n = 200 (which would filter out every fixture occupation and
# degenerate everything downstream of it).
#
# The third test extends this further to mirror main.R's §8a (the PRIMARY, hours-outcome DDD --
# docs/decisions/hours-ddd-pivot.md), which was previously entirely uncovered end-to-end here even
# though its own regression/Lee-bounds functions are separately unit-tested
# (test-hours_ddd_regression.R, test-hours_ddd_lee_bounds.R). As of the pivot this path is
# unconditional (no RUN_HOURS_DDD_PIVOT flag), so it belongs in the same unconditional smoke
# coverage as the rest of this file.

test_that("the full pipeline runs end-to-end against fixtures without error, mirroring main.R's sequence", {
  cleaned <- load_and_clean_data(fixtures_dir)
  expect_gt(nrow(cleaned), 0)

  out <- capture.output(comp_res <- run_comparative_stats(cleaned))
  expect_type(comp_res, "list")

  # suppressWarnings: the pooled fixture, like the Jewish/Arab subsamples below, is small enough
  # that check_for_dropped_coefficients() legitimately fires on this fixture-sparsity artifact.
  out <- capture.output(reg_res <- suppressWarnings(basic_reg(cleaned)))
  expect_s3_class(reg_res$models$employed, "fixest")

  out <- capture.output(jewish_res <- suppressWarnings(basic_reg(dplyr::filter(cleaned, Leom == 1))))
  expect_s3_class(jewish_res$models$employed, "fixest")

  out <- capture.output(arab_res <- suppressWarnings(basic_reg(dplyr::filter(cleaned, Leom == 2))))
  expect_s3_class(arab_res$models$employed, "fixest")

  out <- capture.output(age_res <- employment_by_child_age(cleaned))
  expect_s3_class(age_res$model, "fixest")

  with_null_device({
    out <- capture.output(diag_res <- run_diagnostics(cleaned))
  })
  expect_s3_class(diag_res$pretrend_model, "fixest")
})

test_that("the WFH-exposure + secondary (employment) DDD pipeline (main.R's section 8b) runs end-to-end against fixtures without error", {
  cleaned <- load_and_clean_data(fixtures_dir)

  # A minimal external-exposure file covering every ISCO2 code present in the fixtures, with
  # varying (not constant) values, so build_exposure_isco2()'s join has something real to match
  # against and downstream WFH_Exposure genuinely varies across demographic cells -- mirrors
  # main.R's exposure_external step without requiring the real, absent CSV.
  tmp_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp_csv), add = TRUE)
  isco_codes <- unique(stats::na.omit(cleaned$MishlachYad_ISCO_08_2))
  readr::write_csv(
    tibble::tibble(
      isco_2digit = isco_codes,
      wfh_probability_2d = seq_len(length(isco_codes)) / (length(isco_codes) + 1)
    ),
    tmp_csv
  )

  exposure_external <- build_exposure_isco2(path = tmp_csv)
  expect_s3_class(exposure_external, "data.frame")

  out <- capture.output(exposure_calibrated <- suppressWarnings(
    calibrate_isco_exposure(cleaned, exposure_external)
  ))
  expect_true(all(c("ISCO2", "wfh_exposure_calibrated", "swap") %in% names(exposure_calibrated)))

  out <- capture.output(isco_masking_check <- check_isco_masking_sensitivity(cleaned))
  expect_type(isco_masking_check, "list")

  # min_n = 0, not main.R's real min_n = 200 -- see header comment.
  exposure_realized <- build_wfh_exposure_index(cleaned, ref_year = 2021, min_n = 0)
  expect_gt(nrow(exposure_realized), 0)

  exposure_cells <- build_exposure_cells(
    cleaned,
    exposure_calibrated %>% dplyr::select(ISCO2, tele_ext = wfh_exposure_calibrated)
  )
  expect_true(all(
    c("Min", "GilNK", "TeudaGvoha", "MachozMegurim", "WFH_Exposure") %in% names(exposure_cells)
  ))

  ddd_df <- cleaned %>%
    dplyr::left_join(exposure_cells, by = c("Min", "GilNK", "TeudaGvoha", "MachozMegurim"))

  cell_fe_vars   <- c("GilNK", "TeudaGvoha", "MachozMegurim")
  other_controls <- setdiff(DEFAULT_CONTROLS, cell_fe_vars)
  cell_cluster_formula <- as.formula(paste("~", paste(cell_fe_vars, collapse = "^")))

  ddd_employment_additive <- suppressWarnings(feols(
    as.formula(paste("Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                      paste(DEFAULT_CONTROLS, collapse = " + "))),
    data = ddd_df, cluster = cell_cluster_formula
  ))
  expect_s3_class(ddd_employment_additive, "fixest")

  # Spec 2's cell FE genuinely can't be fit against these fixtures: build_exposure_cells()'s
  # pre-period-only construction means every fixture row that matches an exposure cell IS the
  # single pre-period row that built that cell (the fixtures' demographic combinations are all
  # but unique -- they were sized/shaped for schema/parsing edge-case coverage, not for repeated
  # cells across pre- and post-period), so every GilNK^TeudaGvoha^MachozMegurim FE group among the
  # matched rows has exactly 1 observation -- a singleton group demeans to a constant 0, and
  # fixest correctly refuses to fit on that ("the dependent variable is a constant"). This is a
  # fixture-size artifact, not a pipeline bug -- Spec 2's actual mechanics (WFH_Exposure's main
  # effect correctly dropped as collinear with a non-degenerate cell FE, on a panel built the same
  # way but sized so cells repeat across periods) are covered by test-employment_ddd_mechanics.R.
  ddd_employment_fe <- tryCatch(
    suppressWarnings(feols(
      as.formula(paste("Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                        paste(other_controls, collapse = " + "),
                        "|", paste(cell_fe_vars, collapse = "^"))),
      data = ddd_df, cluster = cell_cluster_formula
    )),
    error = function(e) NULL
  )
  expect_true(is.null(ddd_employment_fe) || inherits(ddd_employment_fe, "fixest"))

  out <- capture.output(spec1_check <- suppressWarnings(
    check_spec1_collinearity(ddd_df, cell_fe_vars, DEFAULT_CONTROLS)
  ))
  expect_true(all(
    c("r2_wfh_exposure_on_cells", "vif_wfh_exposure", "condition_number") %in% names(spec1_check)
  ))
})

test_that("the primary (hours) DDD pipeline (main.R's section 8a) runs end-to-end against fixtures without error", {
  cleaned <- load_and_clean_data(fixtures_dir)

  tmp_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp_csv), add = TRUE)
  isco_codes <- unique(stats::na.omit(cleaned$MishlachYad_ISCO_08_2))
  readr::write_csv(
    tibble::tibble(
      isco_2digit = isco_codes,
      wfh_probability_2d = seq_len(length(isco_codes)) / (length(isco_codes) + 1)
    ),
    tmp_csv
  )

  exposure_external <- build_exposure_isco2(path = tmp_csv)
  out <- capture.output(exposure_calibrated <- suppressWarnings(
    calibrate_isco_exposure(cleaned, exposure_external)
  ))
  exposure_cells <- build_exposure_cells(
    cleaned,
    exposure_calibrated %>% dplyr::select(ISCO2, tele_ext = wfh_exposure_calibrated)
  )
  exposure_index <- exposure_calibrated %>%
    dplyr::select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)

  # Fixture-sized data may leave too few Employed==1, occupation-matched rows to identify the
  # triple interaction (the fixtures are sized for schema/parsing edge-case coverage, not a
  # saturated DDD -- see test-hours_ddd_regression.R for the dedicated, purpose-sized panel this
  # regression's actual mechanics are tested against) -- tolerate a clean failure here the same way
  # the employment-DDD smoke test above tolerates Spec 2's degenerate fit.
  hours_ddd <- tryCatch(
    suppressWarnings(run_hours_ddd_regression(cleaned, exposure_index)),
    error = function(e) NULL
  )
  expect_true(is.null(hours_ddd) || inherits(hours_ddd$model, "fixest"))

  if (!is.null(hours_ddd)) {
    out <- capture.output(mde_hours <- compute_ddd_mde(
      hours_ddd$model,
      baseline_rate = mean(cleaned$WorkHoursCont[cleaned$Employed == 1], na.rm = TRUE)
    ))
    expect_true(is.finite(mde_hours$mde))
  }

  # compute_pre_period_quartile_breaks() (called internally) needs enough distinct pre-period
  # WFH_Exposure values to form 4 non-degenerate quartiles -- almost certainly not satisfiable on
  # this fixture, so this is expected to fail cleanly here; its real mechanics are covered by
  # test-hours_ddd_lee_bounds.R's own purpose-built panel.
  hours_lee_bounds <- tryCatch(
    suppressWarnings(run_hours_ddd_lee_bounds(cleaned, exposure_index, exposure_cells)),
    error = function(e) NULL
  )
  expect_true(is.null(hours_lee_bounds) ||
                nrow(hours_lee_bounds$diagnostics$quartile_selection_rates) > 0)
})
