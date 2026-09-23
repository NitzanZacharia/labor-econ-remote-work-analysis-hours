# test-build_paper_tables.R
# build_paper_tables() assembles every table paper/paper.tex prints. A full synthetic input set
# is built here -- real fits where the function reads coefficients, small fabricated frames where
# it only reads numbers -- so the structural guarantees can be pinned without the raw data:
# every block is a balanced tabular, body rows carry the right number of columns, the headline
# cell is byte-identical to tex_coef_cell()'s, and the exporter round-trips the blocks.

make_paper_table_inputs <- function(seed = 91) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = -3, n = 3000, n_occ = 12, with_years = TRUE, with_child_age = TRUE)
  panel <- fx$panel %>%
    dplyr::mutate(
      Leom = sample(c(1, 1, 1, 2), dplyr::n(), replace = TRUE),
      ShaotAvodaBederechKlalNK = sample(1:12, dplyr::n(), replace = TRUE)
    )
  idx <- fx$exposure_index
  quiet <- function(expr) { capture.output(res <- suppressWarnings(suppressMessages(expr))); res }

  desc_table          <- quiet(build_descriptive_table(panel))
  intensive_results   <- quiet(run_intensive_margin_reg(panel))
  intensive_yearfe    <- quiet(run_intensive_margin_reg(panel, year_fe = TRUE))
  hours_ddd           <- quiet(run_hours_ddd_regression(panel, idx))
  hours_ddd_saturated <- quiet(run_hours_ddd_saturated(panel, idx))
  joined <- panel %>% dplyr::inner_join(
    idx %>% dplyr::select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
    by = "MishlachYad_ISCO_08_2")
  breaks <- compute_occupation_exposure_breaks(joined)
  hours_ddd_binned <- quiet(run_hours_ddd_binned(panel, idx, breaks = breaks))
  mde_hours <- quiet(compute_ddd_mde(hours_ddd$model, baseline_rate = 40, regressor = hours_ddd$exposure_vector))

  hours_lee_bounds <- list(
    table = tibble::tibble(bound = c("lower", "point (untrimmed)", "upper"),
                           coef = c(3.1, 3.2, 3.4), se = c(1.1, 1.05, 1.02),
                           ci_low = c(0.9, 1.2, 1.4), ci_high = c(5.3, 5.3, 5.4)),
    diagnostics = list(quartile_selection_rates = tibble::tibble(
      WFH_Exposure_Q = 1:4, s00 = c(.58, .70, .75, .82), s01 = c(.59, .71, .74, .80),
      s10 = c(.55, .69, .76, .74), s11 = c(.58, .70, .75, .74),
      s11_counterfactual = c(.55, .69, .75, .72), n_mother1_post1 = c(21655L, 28540L, 34293L, 21815L),
      excess_selection = TRUE, trim_prop = c(.0448, .0101, .0080, .0285))),
    imbens_manski_ci = list(c_alpha = 1.84, lower = 1.021, upper = 5.324)
  )

  intensive_jewish <- quiet(run_intensive_margin_reg(dplyr::filter(panel, Leom == 1)))
  intensive_arab   <- quiet(run_intensive_margin_reg(dplyr::filter(panel, Leom == 2)))
  hours_ddd_jewish <- quiet(run_hours_ddd_regression(dplyr::filter(panel, Leom == 1), idx, run_mechanism = FALSE))
  hours_ddd_arab   <- quiet(run_hours_ddd_regression(dplyr::filter(panel, Leom == 2), idx, run_mechanism = FALSE))
  hours_ddd_by_child_age <- quiet(run_hours_ddd_by_child_age(panel, idx))

  emp_panel <- joined %>% dplyr::mutate(Employed = rbinom(dplyr::n(), 1, 0.7))
  m_emp <- fixest::feols(Employed ~ Mother + Post + Mother:Post + MatzavMishpachti + Dat + GilNK +
                           MachozMegurim + TeudaGvoha, data = emp_panel, cluster = ~IDPUF)
  m_edd <- fixest::feols(Employed ~ Mother * Post * WFH_Exposure + MatzavMishpachti + Dat + GilNK +
                           MachozMegurim + TeudaGvoha, data = emp_panel, cluster = ~MishlachYad_ISCO_08_2)
  mde_additive <- quiet(compute_ddd_mde(m_edd, baseline_rate = 0.7, regressor = emp_panel$WFH_Exposure))

  fs_table <- tibble::tibble(
    ISCO2 = idx$occupation_code, label = paste("Occupation", idx$occupation_code),
    external = idx$wfh_exposure, realized_usual_calibration = 0.8 * idx$wfh_exposure,
    swap = c(TRUE, rep(FALSE, nrow(idx) - 1)), calibrated = idx$wfh_exposure,
    realized_refweek = 0.7 * idx$wfh_exposure, n_refweek = 250L
  )

  # 2026-09-23 grade-report-2 inputs, from the new functions on the same panel.
  panel_bal <- panel %>% dplyr::mutate(
    TeudaGvoha = factor(sample(c("Below High School", "Matriculation (Bagrut)",
                                 "Academic Degree (BA/MA/PhD)"), dplyr::n(), replace = TRUE)))
  cells <- panel %>% dplyr::distinct(GilNK, TeudaGvoha, MachozMegurim) %>%
    dplyr::mutate(WFH_Exposure = stats::runif(dplyr::n(), 0.05, 0.4), n_cell = 25)
  hours_ddd_calib_men <- list(result = quiet(run_hours_ddd_regression(panel, idx, run_mechanism = FALSE)),
                              n_swapped = 3L, n_occupations = nrow(idx))
  hours_ddd_swap_control <- quiet(run_hours_ddd_swap_control(panel, idx, swapped_codes = idx$occupation_code[1:3]))
  hours_ddd_cell_exposure <- quiet(run_hours_ddd_cell_exposure(panel, cells))
  exposure_sorting_check  <- quiet(run_exposure_sorting_check(panel, idx, breaks = breaks))
  hours_ddd_leave_one_out <- quiet(run_hours_ddd_leave_one_out(panel, idx, labels_path = NULL))
  balance_by_quartile     <- quiet(build_balance_by_exposure_quartile(panel_bal, idx, breaks = breaks))

  list(
    hours_ddd_calib_men = hours_ddd_calib_men, hours_ddd_swap_control = hours_ddd_swap_control,
    hours_ddd_cell_exposure = hours_ddd_cell_exposure, exposure_sorting_check = exposure_sorting_check,
    hours_ddd_leave_one_out = hours_ddd_leave_one_out, balance_by_quartile = balance_by_quartile,
    desc_table = desc_table, intensive_results = intensive_results, hours_ddd = hours_ddd,
    hours_ddd_saturated = hours_ddd_saturated, hours_ddd_binned = hours_ddd_binned,
    mde_hours = mde_hours, hours_lee_bounds = hours_lee_bounds,
    hours_ddd_external = hours_ddd, hours_ddd_realized = hours_ddd,
    hours_ddd_age_interacted = list(model = hours_ddd$model),
    hours_ddd_reweighted = list(model = hours_ddd$model),
    hours_ddd_unswapped = hours_ddd, hours_ddd_ex2023 = hours_ddd,
    hours_ddd_twoway_model = summary(hours_ddd$model, cluster = ~IDPUF + MishlachYad_ISCO_08_2),
    intensive_yearfe = intensive_yearfe,
    hours_ddd_noimputed = hours_ddd, hours_ddd_fulltime = hours_ddd, hours_ddd_longhours = hours_ddd,
    hours_wild_bootstrap = tibble::tibble(
      label = "headline", param = "Mother:Post:WFH_Exposure",
      estimate = unname(coef(hours_ddd$model)[["Mother:Post:WFH_Exposure"]]), t_stat = -3,
      p_boot = 0, ci_low = -5, ci_high = -1, B = 9999L, n_clusters = 12L,
      weights = "rademacher", null_imposed = TRUE, seed = 1L),
    hours_permutation = list(table = tibble::tibble(p_perm = 0.012, n_perm = 999L)),
    intensive_jewish = intensive_jewish, intensive_arab = intensive_arab,
    hours_ddd_jewish = hours_ddd_jewish, hours_ddd_arab = hours_ddd_arab,
    hours_gender_placebo = list(result = list(models = list(hours = intensive_results$models$hours)),
                                ddd_placebo = list(model = hours_ddd$model)),
    hours_ddd_by_child_age = hours_ddd_by_child_age,
    baseline_results = list(models = list(employed = m_emp)),
    ddd_employment_additive = m_edd, mde_additive = mde_additive, baseline_employment_rate = 0.7,
    wfh_occupation_first_stage = list(table = fs_table)
  )
}

expected_tables <- c("tab_descriptives", "tab_hours", "tab_lee_selection", "tab_lee_bounds",
                     "tab_robust", "tab_subgroup", "tab_childage", "tab_extensive",
                     "tab_exposure_scores", "tab_balance_quartile")

count_cols <- function(line) {
  # Columns a body line occupies: 1 + number of & separators + extra columns claimed by
  # \multicolumn{k} cells (k - 1 each).
  n_amp  <- lengths(regmatches(line, gregexpr("&", line)))
  spans  <- regmatches(line, gregexpr("\\\\multicolumn\\{([0-9]+)\\}", line))[[1]]
  extra  <- sum(as.integer(sub("\\\\multicolumn\\{([0-9]+)\\}", "\\1", spans)) - 1)
  1 + n_amp + extra
}

test_that("build_paper_tables returns every table the paper prints as a balanced tabular block", {
  inputs <- make_paper_table_inputs()
  res <- build_paper_tables(inputs)

  expect_setequal(names(res$tables), expected_tables)
  for (nm in expected_tables) {
    block <- res$tables[[nm]]
    expect_match(block[1], "^\\\\begin\\{tabular\\}", info = nm)
    expect_equal(tail(block, 1), "\\end{tabular}", info = nm)
    colspec <- sub("^\\\\begin\\{tabular\\}\\{(.*)\\}$", "\\1", block[1])
    n_col <- nchar(gsub("[^lcrp]", "", gsub("p\\{[^}]*\\}", "p", colspec)))
    body <- block[grepl(" \\\\\\\\$", block)]
    for (line in body) expect_equal(count_cols(line), n_col, info = paste(nm, line))
  }
  expect_true(all(c("autonoteHours", "autonoteSubgroup", "autonoteChildAge", "autonoteExtensive") %in%
                    names(res$notes)))
  expect_equal(nrow(res$subgroup_ztests), 4)
})

test_that("the headline cell in Table 2 is tex_coef_cell()'s cell for the pooled DDD", {
  inputs <- make_paper_table_inputs()
  res <- build_paper_tables(inputs)
  cell <- tex_coef_cell(inputs$hours_ddd$model, "Mother:Post:WFH_Exposure")
  triple_line <- res$tables$tab_hours[grepl("^Mother \\$\\\\times\\$ Post \\$\\\\times\\$ WFH", res$tables$tab_hours)][1]
  expect_true(grepl(cell[1], triple_line, fixed = TRUE))
  # Column (3) is the saturated model's, column (1) and (4) blank for this row.
  sat_cell <- tex_coef_cell(inputs$hours_ddd_saturated$model, "Mother:Post:WFH_Exposure")
  expect_true(grepl(sat_cell[1], triple_line, fixed = TRUE))
})

test_that("a bootstrap p of zero prints as <0.0001 and the permutation row is omitted without a permutation run", {
  inputs <- make_paper_table_inputs()
  res <- build_paper_tables(inputs)
  expect_true(any(grepl("Wild cluster bootstrap", res$tables$tab_robust) &
                    grepl("<0.0001", res$tables$tab_robust)))
  expect_true(any(grepl("Permutation", res$tables$tab_robust)))

  inputs$hours_permutation <- NULL
  res2 <- build_paper_tables(inputs)
  expect_false(any(grepl("Permutation", res2$tables$tab_robust)))
})

test_that("Table 4 carries a Clusters column and the grade-report-2 rows; hours cells have three decimals", {
  inputs <- make_paper_table_inputs()
  res <- build_paper_tables(inputs)
  rob <- res$tables$tab_robust
  expect_match(rob[1], "\\{lccccc\\}")
  expect_true(any(grepl("Clusters", rob)))
  for (needle in c("Calibrated on men only", "swapped-occupation terms", "Swapped\\}\\$ \\(same model\\)",
                   "Leave-one-occupation-out", "Occupational sorting", "Pre-period cell exposure",
                   "Exposure score as outcome", "Top-quartile indicator")) {
    expect_true(any(grepl(needle, rob)), info = needle)
  }
  # The unswapped row's cluster count is the model's own, the primary row's is the full count.
  primary <- rob[grepl("Calibrated \\(primary\\)", rob)]
  expect_true(grepl(paste0("& ", inputs$hours_ddd$n_clusters, " \\\\\\\\$"), primary))
  # Three fixed decimals on the hours coefficients: no four-decimal coefficient cell survives in
  # Table 2 (p-values and R2 are formatted separately and are not coefficient cells).
  coef_lines <- res$tables$tab_hours[grepl("^(Mother|Post|WFH|Constant)", res$tables$tab_hours)]
  expect_false(any(grepl("\\$-?[0-9]+\\.[0-9]{4}\\$", coef_lines)))
  expect_true(all(grepl("\\$-?[0-9]+\\.[0-9]{3}\\$", coef_lines)))
  # The employment table keeps four.
  ext_lines <- res$tables$tab_extensive[grepl("^Mother \\$\\\\times\\$ Post &", res$tables$tab_extensive)]
  expect_true(any(grepl("\\$-?[0-9]+\\.[0-9]{4}\\$", ext_lines)))
  # Balance table: one column per quartile plus the label, the count rows at the bottom.
  bal <- res$tables$tab_balance_quartile
  expect_match(bal[1], "\\{lcccc\\}")
  expect_true(any(grepl("^Mothers &", bal)))
  expect_true(any(grepl("Exposure range", bal)))
  expect_true(any(grepl("Academic degree", bal)))
})

test_that("a missing input is named in the error", {
  inputs <- make_paper_table_inputs()
  inputs$mde_hours <- NULL
  expect_error(build_paper_tables(inputs), "mde_hours")
})

test_that("the blocks round-trip through export_paper_tables", {
  inputs <- make_paper_table_inputs()
  res <- build_paper_tables(inputs)
  out_dir <- file.path(tempdir(), paste0("paper-tables-", as.integer(Sys.time())))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
  written <- export_paper_tables(res, output_dir = out_dir)
  expect_setequal(basename(written), c(paste0(expected_tables, ".tex"), "auto_notes.tex"))
  expect_equal(readLines(file.path(out_dir, "tab_hours.tex")), res$tables$tab_hours)
})
