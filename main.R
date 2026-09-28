# main.R

# 1. Load modules
rm(list = ls())
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "comparative_statistics.R"))
source(file.path("scripts", "descriptive_table.R"))
source(file.path("scripts", "basic_regression.R"))
source(file.path("scripts", "Diagnostics.R"))
source(file.path("scripts", "hours_diagnostics.R"))
source(file.path("scripts", "employment_by_child_age.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "intensive_margin_regression.R"))
source(file.path("scripts", "intensive_margin_lee_bounds.R"))
source(file.path("scripts", "placebo_male_frame.R"))
source(file.path("scripts", "gender_placebo.R"))
source(file.path("scripts", "hours_gender_placebo.R"))
source(file.path("scripts", "export_results.R"))
source(file.path("scripts", "export_paper_figures.R"))
source(file.path("scripts", "wfh_exposure_index.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))
source(file.path("scripts", "isco_masking_diagnostics.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "hours_ddd_regression.R"))
source(file.path("scripts", "tidy_event_study_coefs.R"))
source(file.path("scripts", "hours_ddd_event_study.R"))
source(file.path("scripts", "hours_ddd_lee_bounds.R"))
source(file.path("scripts", "wfh_first_stage_check.R"))
source(file.path("scripts", "ddd_mde_diagnostics.R"))
source(file.path("scripts", "hours_subgroup_comparison.R"))
source(file.path("scripts", "paper_theme.R"))
source(file.path("scripts", "hours_descriptive_plots.R"))
source(file.path("scripts", "hours_dose_response.R"))
source(file.path("scripts", "wfh_share_by_year.R"))
source(file.path("scripts", "absence_by_exposure_quartile.R"))
source(file.path("scripts", "build_mechanism_scatter.R"))
source(file.path("scripts", "build_event_study_plot.R"))
source(file.path("robustness", "pretrend_wald_test.R"))
source(file.path("scripts", "occupation_exposure_breaks.R"))
source(file.path("scripts", "hours_ddd_saturated.R"))
source(file.path("scripts", "hours_ddd_binned.R"))
source(file.path("scripts", "hours_ddd_by_child_age.R"))
source(file.path("scripts", "wfh_occupation_first_stage.R"))
source(file.path("scripts", "build_permutation_plot.R"))
source(file.path("scripts", "tex_coef_cell.R"))
source(file.path("scripts", "format_tex_table_body.R"))
source(file.path("scripts", "build_paper_tables.R"))
source(file.path("scripts", "export_paper_tables.R"))
source(file.path("robustness", "hours_ddd_inference.R"))
source(file.path("scripts", "hours_ddd_swap_control.R"))
source(file.path("scripts", "exposure_sorting_check.R"))
source(file.path("scripts", "hours_ddd_cell_exposure.R"))
source(file.path("scripts", "hours_ddd_leave_one_out.R"))
source(file.path("scripts", "build_leave_one_out_plot.R"))
source(file.path("scripts", "build_balance_by_exposure_quartile.R"))
source(file.path("scripts", "hours_ddd_marital_interacted.R"))
source(file.path("scripts", "calibration_threshold_sweep.R"))

# 2. Paths
message("Edit folder paths if needed!")
folder_path   <- "G:/My Drive/Uni/econ/csv_data"
rds_file_path <- paste0(folder_path, "/cleaned_df.rds")

# 3. Load the cleaned data (cached beside the raw CSVs, keyed to data_processing.R's hash)
cache_meta_path       <- paste0(rds_file_path, ".meta.rds")
data_processing_hash  <- unname(tools::md5sum(file.path("scripts", "data_processing.R")))

cache_is_valid <- file.exists(rds_file_path) && file.exists(cache_meta_path) &&
  identical(readRDS(cache_meta_path)$data_processing_hash, data_processing_hash)

if (cache_is_valid) {
  message("Found saved RDS file (data_processing.R unchanged) — loading pre-cleaned data...")
  cleaned_df <- readRDS(rds_file_path)
} else {
  if (file.exists(rds_file_path)) {
    message("data_processing.R has changed since the cache was built — invalidating cache...")
  }
  message("Checking raw CSV schema for column-order drift...")
  check_schema_drift(folder_path)
  message("Saved RDS not found or stale — loading and cleaning raw data...")
  cleaned_df <- load_and_clean_data(folder_path)
  message("Saving cleaned data for future use...")
  saveRDS(cleaned_df, file = rds_file_path)
  saveRDS(list(data_processing_hash = data_processing_hash), file = cache_meta_path)
}

message("Validating cleaned data...")
validate_cleaned_df(cleaned_df)

message("Checking IDPUF panel structure (cluster-SE unit vs. Mother/Post design)...")
check_idpuf_panel_structure(cleaned_df)

message("Checking WFH_RefWeek's NA rationale against AvadBeshavua...")
check_wfh_refweek_avadbeshavua(cleaned_df)

# 4. Descriptive statistics
message("Running comparative statistics...")
comp_stats <- run_comparative_stats(cleaned_df)

message("Building the descriptive (Table 1) summary...")
desc_table <- build_descriptive_table(cleaned_df)

# 5. DiD regressions
message("Running intensive-margin (work hours) regression...")
intensive_results <- run_intensive_margin_reg(cleaned_df)

message("Running intensive-margin Lee (2009) trimming bounds (selection-on-employment correction)...")
intensive_lee_bounds <- run_intensive_margin_lee_bounds(cleaned_df)

message("Running secondary (employment) regression model...")
baseline_results <- basic_reg(cleaned_df)

message("Running secondary (employment) regression model — Jewish women only...")
baseline_jewish <- basic_reg(filter(cleaned_df, Leom == 1))

message("Running secondary (employment) regression model — Arab women only...")
baseline_arab <- basic_reg(filter(cleaned_df, Leom == 2))

# 6. Employment by age of youngest child
message("Running employment_by_child_age...")
emp_res <- employment_by_child_age(cleaned_df)

# 7. Event studies and joint pre-trend tests
pdf(file.path("outputs", "event_study_pretrend.pdf"))
diagnostics_results <- run_diagnostics(cleaned_df)
dev.off()

hours_diagnostics_results <- run_hours_diagnostics(cleaned_df)

hours_event_study_plot <- build_event_study_plot(
  hours_diagnostics_results$pretrend_coefs,
  title    = "Hours event study: Mother × Year",
  subtitle = "Weekly work hours, employed women aged 25–59; 95% CIs, individual-clustered SEs",
  y_label  = "Mother × Year (95% CI)",
  se_note  = "standard errors clustered by individual"
)

message("Running joint Wald test on pre-2020 Mother:year pre-trend coefficients (employment)...")
pretrend_wald <- run_pretrend_joint_test(diagnostics_results$pretrend_model)

message("Running joint Wald test on pre-2020 Mother:year pre-trend coefficients (hours, primary)...")
pretrend_wald_hours <- run_pretrend_joint_test(hours_diagnostics_results$pretrend_model)

# 8. WFH-exposure measures and DDD regressions
message("Building the WFH-exposure measures...")

message("Loading men's data (sex_filter = 'men') so exposure construction isn't built from the ",
        "exact women-25-59 analysis sample (see wfh_exposure_index.R's header comment)...")
rds_file_path_men   <- paste0(folder_path, "/cleaned_df_men.rds")
cache_meta_path_men <- paste0(rds_file_path_men, ".meta.rds")
cache_is_valid_men <- file.exists(rds_file_path_men) && file.exists(cache_meta_path_men) &&
  identical(readRDS(cache_meta_path_men)$data_processing_hash, data_processing_hash)
if (cache_is_valid_men) {
  message("Found saved RDS file for men (data_processing.R unchanged) — loading pre-cleaned data...")
  cleaned_men_for_exposure <- readRDS(rds_file_path_men)
} else {
  cleaned_men_for_exposure <- load_and_clean_data(folder_path, sex_filter = "men")
  saveRDS(cleaned_men_for_exposure, file = rds_file_path_men)
  saveRDS(list(data_processing_hash = data_processing_hash), file = cache_meta_path_men)
}
exposure_population_df <- bind_rows(cleaned_df, cleaned_men_for_exposure)

# (a) External Dingel & Neiman teleworkability
exposure_external <- build_exposure_isco2()

# (b) Calibrated: (a) swapped to realized 2022-23 shares where the gap is large and significant
exposure_calibrated <- calibrate_isco_exposure(exposure_population_df, exposure_external)
message(sprintf(
  "  calibration swapped %d of %d occupations for realized Israeli values (gap > 0.5, statistically distinguishable from sampling noise at 95%% confidence):",
  sum(exposure_calibrated$swap), nrow(exposure_calibrated)
))
print(exposure_calibrated %>% filter(swap) %>%
        select(ISCO2, n, tele_ext, realized_wfh, gap, se_clustered, margin) %>%
        as.data.frame(), digits = 3)

# ISCO disclosure-masking sensitivity check
message("Checking ISCO disclosure-masking sensitivity (masked vs. unmasked realized WFH)...")
isco_masking_check <- check_isco_masking_sensitivity(cleaned_df)

# (c) Realized Israeli WFH by occupation, 2021 anchor
exposure_realized <- build_wfh_exposure_index(exposure_population_df, ref_year = 2021, min_n = 200)

# (d) Pre-period shift-share exposure by demographic cell (employment DDD regressor; hours Lee-bounds strata)
exposure_cell_vars <- c("Min", "GilNK", "TeudaGvoha", "MachozMegurim", "MatzavMishpachti", "Dat",
                         "BirthContinent")
exposure_cells <- build_exposure_cells(
  exposure_population_df,
  exposure_calibrated %>% select(ISCO2, tele_ext = wfh_exposure_calibrated),
  cell_vars = exposure_cell_vars
)

# 8a. Primary DDD (hours): occupation-level exposure, Employed == 1
message("Running primary DDD (hours, pure occupation-level exposure, Employed==1 subsample)...")
hours_exposure_index <- exposure_calibrated %>%
  select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)
hours_ddd <- run_hours_ddd_regression(cleaned_df, hours_exposure_index)

message("Computing minimum detectable effect for the hours DDD's triple interaction...")
baseline_hours <- mean(cleaned_df$WorkHoursCont[cleaned_df$Employed == 1], na.rm = TRUE)
mde_hours <- compute_ddd_mde(hours_ddd$model, baseline_rate = baseline_hours,
                             regressor = hours_ddd$exposure_vector,
                             df = degrees_freedom(hours_ddd$model, type = "t"))

# DDD event study and its joint pre-trend test
message("Running DDD event study (hours, Mother x year x WFH_Exposure)...")
hours_ddd_event_study <- run_hours_ddd_event_study(cleaned_df, hours_exposure_index)

message("Running joint Wald test on pre-2020 DDD event-study pre-trend coefficients (primary)...")
pretrend_wald_hours_ddd <- run_pretrend_joint_test(
  hours_ddd_event_study$model,
  keep  = sprintf("ShnatSeker::(2017|2018):%s$", hours_ddd_event_study$term_suffix),
  label = "Joint Wald, H0: pre-2020 Mother:year:WFH_Exposure coefficients = 0"
)

hours_ddd_event_study_plot <- build_event_study_plot(
  hours_ddd_event_study$coefs,
  ref_year = hours_ddd_event_study$ref_year,
  title    = "Hours DDD event study: Mother × Year × WFH Exposure",
  subtitle = "Weekly work hours, employed women aged 25–59; 95% CIs, occupation-clustered SEs"
)

message("Running generalized Lee bounds for the hours DDD (stratified by WFH_Exposure quartile)...")
hours_lee_bounds <- run_hours_ddd_lee_bounds(
  cleaned_df,
  exposure_calibrated %>% select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated),
  exposure_cells
)

# Robustness variants: external and realized exposure
message("Running primary DDD robustness variant (hours, raw external Dingel & Neiman index)...")
hours_ddd_external <- run_hours_ddd_regression(
  cleaned_df,
  exposure_external %>% select(occupation_code = ISCO2, wfh_exposure = tele_ext)
)

message("Running primary DDD robustness variant (hours, realized Israeli index, 2021 anchor)...")
hours_ddd_realized <- run_hours_ddd_regression(cleaned_df, exposure_realized)

# Unswapped occupations only
message("Running primary DDD robustness variant (hours, unswapped occupations only)...")
hours_ddd_unswapped <- run_hours_ddd_regression(
  cleaned_df,
  exposure_calibrated %>%
    filter(!swap) %>%
    select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)
)

# Excluding the 2023 survey year
message("Running primary DiD and DDD excluding the 2023 survey year...")
intensive_ex2023 <- run_intensive_margin_reg(filter(cleaned_df, ShnatSeker != 2023))
hours_ddd_ex2023 <- run_hours_ddd_regression(filter(cleaned_df, ShnatSeker != 2023),
                                             hours_exposure_index)

# Two-way clustering (individual + occupation)
message("Re-summarising the primary hours DDD with two-way (individual + occupation) clustering...")
hours_ddd_twoway_table <- etable(
  summary(hours_ddd$model, cluster = ~IDPUF + MishlachYad_ISCO_08_2),
  headers = c("Hours DDD, two-way clustered"), digits = 4
)
print(hours_ddd_twoway_table)

# Specification and outcome-coding checks (the dose-response figure supplies the quartile edges)
message("Building the raw hours dose-response by exposure quartile (Figure 2; also supplies the quartile edges)...")
hours_dose_response   <- build_hours_dose_response(cleaned_df, hours_exposure_index)
hours_exposure_breaks <- hours_dose_response$breaks

# Saturated DDD
message("Running the saturated hours DDD (occupation x year, occupation x mother, mother x year FE)...")
hours_ddd_saturated <- run_hours_ddd_saturated(cleaned_df, hours_exposure_index)

# Quartile-binned DDD
message("Running the quartile-binned hours DDD on Figure 2's exposure quartiles...")
hours_ddd_binned <- run_hours_ddd_binned(cleaned_df, hours_exposure_index,
                                         breaks = hours_exposure_breaks)

# Hours DiD with survey-year effects
message("Running the hours DiD with survey-year effects in place of Post...")
intensive_yearfe <- run_intensive_margin_reg(cleaned_df, year_fe = TRUE)

# Alternative outcome codings: no imputation; full-time (>= 35); long hours (>= 40)
message("Running the hours DDD under alternative outcome codings (no imputation; full-time; long hours)...")
hours_ddd_noimputed <- run_hours_ddd_regression(
  filter(cleaned_df, !(ShaotAvodaBederechKlalNK %in% c(11, 12))),
  hours_exposure_index, run_mechanism = FALSE
)
hours_outcome_df <- cleaned_df %>%
  mutate(
    FullTime  = if_else(is.na(WorkHoursCont), NA_integer_, as.integer(WorkHoursCont >= 35)),
    LongHours = if_else(is.na(WorkHoursCont), NA_integer_, as.integer(WorkHoursCont >= 40))
  )
hours_ddd_fulltime  <- run_hours_ddd_regression(hours_outcome_df, hours_exposure_index, outcome = "FullTime")
hours_ddd_longhours <- run_hours_ddd_regression(hours_outcome_df, hours_exposure_index, outcome = "LongHours")
# Baseline shares of the two indicators
hours_outcome_shares <- hours_outcome_df %>%
  filter(Employed == 1, !is.na(WorkHoursCont)) %>%
  group_by(Mother, Post) %>%
  summarise(share_fulltime = mean(FullTime), share_longhours = mean(LongHours),
            mean_hours = mean(WorkHoursCont), n = n(), .groups = "drop")
print(as.data.frame(hours_outcome_shares), digits = 4)

# Calibration, sorting, influence and balance checks
message("Calibrating the exposure index on men only (grade-report-2, exposure measure)...")
exposure_calibrated_men <- calibrate_isco_exposure(cleaned_men_for_exposure, exposure_external)
message(sprintf(
  "  men-only calibration swapped %d of %d occupations (pooled calibration swapped %d): %s",
  sum(exposure_calibrated_men$swap), nrow(exposure_calibrated_men), sum(exposure_calibrated$swap),
  paste(sort(exposure_calibrated_men$ISCO2[exposure_calibrated_men$swap]), collapse = ", ")
))
hours_ddd_calib_men <- list(
  result = run_hours_ddd_regression(
    cleaned_df,
    exposure_calibrated_men %>% select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated),
    run_mechanism = FALSE
  ),
  n_swapped     = sum(exposure_calibrated_men$swap),
  n_occupations = nrow(exposure_calibrated_men),
  swapped_codes = sort(exposure_calibrated_men$ISCO2[exposure_calibrated_men$swap]),
  index         = exposure_calibrated_men
)

# Teaching alone reclassified: the external index with only ISCO 23 moved to its realized share
message("Running the hours DDD on the external index with teaching (ISCO 23) alone swapped...")
exposure_teaching_only <- exposure_calibrated %>%
  mutate(wfh_exposure = if_else(ISCO2 == 23 & !is.na(realized_wfh), realized_wfh, tele_ext)) %>%
  select(occupation_code = ISCO2, wfh_exposure)
hours_ddd_teaching_swap <- run_hours_ddd_regression(cleaned_df, exposure_teaching_only, run_mechanism = FALSE)

# Calibration gap-threshold sweep (appendix table)
message("Sweeping the calibration gap threshold and refitting the hours DDD at each value...")
calibration_threshold_sweep <- run_calibration_threshold_sweep(
  cleaned_df, exposure_population_df, exposure_external
)

message("Running the fixed-sample calibration test (external index + swapped-occupation terms, all occupations)...")
hours_ddd_swap_control <- run_hours_ddd_swap_control(
  cleaned_df,
  external_index = exposure_external %>% select(occupation_code = ISCO2, wfh_exposure = tele_ext),
  swapped_codes  = exposure_calibrated$ISCO2[exposure_calibrated$swap]
)

message("Checking occupational sorting: DiD on the exposure score itself (grade-report-2)...")
exposure_sorting_check <- run_exposure_sorting_check(cleaned_df, hours_exposure_index,
                                                     breaks = hours_exposure_breaks)

message("Running the hours DDD on the pre-period demographic-cell exposure (sorting bound)...")
hours_ddd_cell_exposure <- run_hours_ddd_cell_exposure(cleaned_df, exposure_cells)

message("Running leave-one-occupation-out refits of the hours DDD (forty fits; about a minute)...")
hours_ddd_leave_one_out <- run_hours_ddd_leave_one_out(cleaned_df, hours_exposure_index)
hours_ddd_leave_one_out_plot <- build_leave_one_out_plot(
  hours_ddd_leave_one_out$table,
  headline_estimate = hours_ddd_leave_one_out$headline$estimate,
  headline_se       = hours_ddd_leave_one_out$headline$se,
  subtitle = "Each point: the triple interaction with the named occupation removed; band = headline +/- 1 SE"
)

message("Building the pre-period balance table by quartile of occupation-level exposure...")
balance_by_quartile <- build_balance_by_exposure_quartile(cleaned_df, hours_exposure_index,
                                                          breaks = hours_exposure_breaks)

# Occupation-level first stage
message("Checking the occupation-level first stage (calibrated score vs realized reference-week WFH)...")
wfh_occupation_first_stage <- build_wfh_occupation_first_stage(
  cleaned_women       = cleaned_df,
  cleaned_men         = cleaned_men_for_exposure,
  exposure_calibrated = exposure_calibrated,
  exposure_external   = exposure_external,
  exposure_realized   = exposure_realized
)

# Subgroup comparisons: Jewish vs Arab women; men with "Mother" read as "Father"
message("Running hours DiD/DDD by ethnicity (Jewish vs. Arab women)...")
intensive_jewish <- run_intensive_margin_reg(filter(cleaned_df, Leom == 1))
check_for_dropped_coefficients(intensive_jewish$models$hours, "hours DiD, Jewish women")
intensive_arab   <- run_intensive_margin_reg(filter(cleaned_df, Leom == 2))
check_for_dropped_coefficients(intensive_arab$models$hours, "hours DiD, Arab women")

hours_ddd_jewish <- run_hours_ddd_regression(filter(cleaned_df, Leom == 1), hours_exposure_index)
check_for_dropped_coefficients(hours_ddd_jewish$model, "hours DDD, Jewish women")
hours_ddd_arab   <- run_hours_ddd_regression(filter(cleaned_df, Leom == 2), hours_exposure_index)
check_for_dropped_coefficients(hours_ddd_arab$model, "hours DDD, Arab women")

message("Running hours gender placebo (men, 'Mother' read as 'Father')...")
hours_gender_placebo <- run_hours_gender_placebo(
  folder_path,
  cleaned_men    = cleaned_men_for_exposure,
  exposure_index = hours_exposure_index
)

message("Running employment gender placebo (men, 'Mother' read as 'Father')...")
gender_placebo <- run_gender_placebo(
  folder_path,
  cleaned_men         = cleaned_men_for_exposure,
  cleaned_women       = cleaned_df,
  exposure_calibrated = exposure_calibrated
)

message("Building hours subgroup comparison plots (DiD and DDD terms, across ethnicity + gender placebo)...")
hours_did_subgroup_comparison <- build_hours_subgroup_comparison(
  models = list(
    "All women (primary)" = intensive_results$models$hours,
    "Jewish women"        = intensive_jewish$models$hours,
    "Arab women"          = intensive_arab$models$hours,
    "Men (placebo)"       = hours_gender_placebo$result$models$hours
  ),
  term     = "Mother:Post",
  title    = "Hours DiD (Mother x Post) by subgroup",
  subtitle = "Weekly hours worked, Employed==1; 95% CI, clustered by IDPUF",
  placebo  = "Men (placebo)"
)
hours_ddd_subgroup_comparison <- build_hours_subgroup_comparison(
  models = list(
    "All women (primary)" = hours_ddd$model,
    "Jewish women"        = hours_ddd_jewish$model,
    "Arab women"          = hours_ddd_arab$model,
    "Men (placebo)"       = hours_gender_placebo$ddd_placebo$model
  ),
  term     = "Mother:Post:WFH_Exposure",
  title    = "Hours DDD (Mother x Post x WFH_Exposure) by subgroup",
  subtitle = "Weekly hours worked, Employed==1; 95% CI, clustered by occupation",
  placebo  = "Men (placebo)"
)

# Heterogeneity by age of the youngest child
message("Running hours DiD/DDD by age of the youngest child...")
hours_ddd_by_child_age <- run_hours_ddd_by_child_age(cleaned_df, hours_exposure_index)
hours_ddd_childage_comparison <- build_hours_subgroup_comparison(
  models = c(
    list("All mothers (primary)" = hours_ddd$model),
    setNames(hours_ddd_by_child_age$models$ddd,
             paste0("Youngest child ", names(hours_ddd_by_child_age$models$ddd)))
  ),
  term     = "Mother:Post:WFH_Exposure",
  title    = "Hours DDD (Mother x Post x WFH_Exposure) by age of youngest child",
  subtitle = "Each bin's mothers vs all childless women; 95% CI, clustered by occupation",
  x_label  = "Mother x Post x WFH_Exposure (95% CI)"
)

# 8b. Secondary DDD (employment): cell-based exposure, full sample, two specifications
message("Running secondary (employment) DDD (cell-based exposure, calibrated, full sample)...")
ddd_df <- cleaned_df %>%
  left_join(exposure_cells, by = exposure_cell_vars)
message(sprintf(
  "Employment DDD join: %d of %d rows unmatched to an exposure cell (WFH_Exposure NA).",
  sum(is.na(ddd_df$WFH_Exposure)), nrow(ddd_df)
))

cell_fe_vars    <- c("GilNK", "TeudaGvoha", "MachozMegurim")
other_controls  <- setdiff(DEFAULT_CONTROLS, cell_fe_vars)

# Clustered on the (GilNK, TeudaGvoha, MachozMegurim) cell
cell_cluster_formula <- as.formula(paste("~", paste(cell_fe_vars, collapse = "^")))

ddd_employment_additive <- feols(
  as.formula(paste("Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                    paste(DEFAULT_CONTROLS, collapse = " + "))),
  data = ddd_df, cluster = cell_cluster_formula
)
ddd_employment_fe <- feols(
  as.formula(paste("Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                    paste(other_controls, collapse = " + "),
                    "|", paste(cell_fe_vars, collapse = "^"))),
  data = ddd_df, cluster = cell_cluster_formula
)
check_for_dropped_coefficients(ddd_employment_additive, "employment DDD Spec 1 (additive controls)")
check_for_dropped_coefficients(ddd_employment_fe, "employment DDD Spec 2 (interacted cell FE)")
employment_ddd_table <- etable(
  ddd_employment_additive, ddd_employment_fe,
  headers = c("Spec 1: additive controls", "Spec 2: interacted cell FE"), digits = 4
)
print(employment_ddd_table)

message("Checking Spec 1's collinearity at runtime (see comment above)...")
check_spec1_collinearity(ddd_df, cell_fe_vars, DEFAULT_CONTROLS)  # prints its own report

# 8c. Age-balance robustness chain
RUN_AGE_BALANCE_ROBUSTNESS <- TRUE
if (RUN_AGE_BALANCE_ROBUSTNESS) {
  source(file.path("robustness", "balance_test.R"))
  source(file.path("robustness", "age_balance_robustness.R"))

  message("Running Phase 1b covariate-balance test (Mother vs. non-Mother, by WFH_Exposure quartile)...")
  balance_check <- run_balance_test(cleaned_df, exposure_cells = exposure_cells)

  message("Diagnosing GilNK (age-group) imbalance by WFH_Exposure quartile...")
  age_balance_diag <- diagnose_gilnk_by_quartile(cleaned_df, exposure_cells)

  message("Running age-interacted comparison spec (Mother:GilNK added to the employment DDD)...")
  ddd_age_interacted <- run_ddd_age_interacted(cleaned_df, exposure_cells)

  message("Running GilNK-reweighted comparison spec (pre-period raking weights)...")
  ddd_reweighted <- run_ddd_reweighted(cleaned_df, exposure_cells)

  # Hours analogs
  message("Running age-interacted comparison spec for the hours DDD (Mother:GilNK added)...")
  hours_ddd_age_interacted <- run_hours_ddd_age_interacted(cleaned_df, hours_exposure_index)

  message("Running GilNK-reweighted comparison spec for the hours DDD (pre-period raking weights)...")
  hours_ddd_reweighted <- run_hours_ddd_reweighted(cleaned_df, exposure_cells, hours_exposure_index)
}

# Marital balance (docs/admin/review.md, item 1): married women only, and marital status
# interacted with Post x WFH_Exposure. Marital status is constant on the married subsample, so it
# leaves the controls there.
message("Running the hours DDD on married women only...")
hours_ddd_married_only <- run_hours_ddd_regression(
  filter(cleaned_df, MatzavMishpachti == 1), hours_exposure_index,
  controls = setdiff(DEFAULT_CONTROLS, "MatzavMishpachti"), run_mechanism = FALSE
)
message("Running the marital-status-interacted hours DDD (marital x Post x WFH_Exposure added)...")
hours_ddd_marital_interacted <- run_hours_ddd_marital_interacted(cleaned_df, hours_exposure_index)

# 8d. Null-vs-power audit (employment DDD)
RUN_NULL_VS_POWER_AUDIT <- TRUE
if (RUN_NULL_VS_POWER_AUDIT) {
  message("Checking WFH_Exposure's first-stage relevance against realized WFH_RefWeek...")
  wfh_first_stage <- check_wfh_first_stage_relevance(ddd_df)

  message("Computing minimum detectable effect for the employment DDD's triple interaction...")
  baseline_employment_rate <- mean(ddd_df$Employed, na.rm = TRUE)
  mde_additive <- compute_ddd_mde(ddd_employment_additive, baseline_rate = baseline_employment_rate,
                                  regressor = ddd_df$WFH_Exposure)
  mde_fe       <- compute_ddd_mde(ddd_employment_fe, baseline_rate = baseline_employment_rate,
                                  regressor = ddd_df$WFH_Exposure)
}

# 8f. Small-cluster inference on the hours DDD: wild cluster bootstrap and permutation test
INFERENCE_SEED   <- 20260922
WILD_BOOTSTRAP_B <- 9999
message("Running wild cluster bootstrap on the headline triple interaction and the DDD pre-trend coefficients...")
pretrend_terms <- sprintf("ShnatSeker::%d:%s", c(2017, 2018), hours_ddd_event_study$term_suffix)
hours_wild_bootstrap <- bind_rows(
  run_hours_ddd_wild_bootstrap(hours_ddd$model, "Mother:Post:WFH_Exposure",
                               B = WILD_BOOTSTRAP_B, seed = INFERENCE_SEED, label = "headline")$table,
  run_hours_ddd_wild_bootstrap(hours_ddd_event_study$model, pretrend_terms[1],
                               B = WILD_BOOTSTRAP_B, seed = INFERENCE_SEED, label = "pretrend_2017")$table,
  run_hours_ddd_wild_bootstrap(hours_ddd_event_study$model, pretrend_terms[2],
                               B = WILD_BOOTSTRAP_B, seed = INFERENCE_SEED, label = "pretrend_2018")$table,
  run_hours_ddd_wild_bootstrap(hours_ddd_event_study$model, pretrend_terms, R = c(1, 1), r = 0,
                               B = WILD_BOOTSTRAP_B, seed = INFERENCE_SEED, label = "pretrend_2017_plus_2018")$table
)
print(as.data.frame(hours_wild_bootstrap %>% select(label, estimate, t_stat, p_boot, ci_low, ci_high, B, n_clusters)), digits = 4)

# Bootstrap p-values for the supporting DDD rows of Tables 4-6 (docs/admin/review.md, item 2):
# every occupation-clustered refit, labelled by its build_paper_tables() input name. A refit the
# bootstrap cannot handle is reported and left blank in the table rather than stopping the run.
message("Running wild cluster bootstrap on the supporting DDD rows...")
boot_specs <- c(
  list(
    list(label = "hours_ddd_external",           model = hours_ddd_external$model),
    list(label = "hours_ddd_realized",           model = hours_ddd_realized$model),
    list(label = "hours_ddd_calib_men",          model = hours_ddd_calib_men$result$model),
    list(label = "hours_ddd_teaching_swap",      model = hours_ddd_teaching_swap$model),
    list(label = "hours_ddd_swap_control",       model = hours_ddd_swap_control$model),
    list(label = "hours_ddd_swap_control",       model = hours_ddd_swap_control$model, param = "Mother:Post:Swapped"),
    list(label = "hours_ddd_age_interacted",     model = hours_ddd_age_interacted$model),
    list(label = "hours_ddd_reweighted",         model = hours_ddd_reweighted$model),
    list(label = "hours_ddd_married_only",       model = hours_ddd_married_only$model),
    list(label = "hours_ddd_marital_interacted", model = hours_ddd_marital_interacted$model),
    list(label = "hours_ddd_unswapped",          model = hours_ddd_unswapped$model),
    list(label = "hours_ddd_ex2023",             model = hours_ddd_ex2023$model),
    list(label = "hours_ddd_noimputed",          model = hours_ddd_noimputed$model),
    list(label = "hours_ddd_fulltime",           model = hours_ddd_fulltime$model),
    list(label = "hours_ddd_longhours",          model = hours_ddd_longhours$model),
    list(label = "hours_ddd_jewish",             model = hours_ddd_jewish$model),
    list(label = "hours_ddd_arab",               model = hours_ddd_arab$model),
    list(label = "hours_gender_placebo_ddd",     model = hours_gender_placebo$ddd_placebo$model)
  ),
  lapply(names(hours_ddd_by_child_age$models$ddd), function(bin) {
    list(label = paste0("hours_ddd_child_age_", bin), model = hours_ddd_by_child_age$models$ddd[[bin]])
  })
)
boot_rows <- lapply(boot_specs, function(s) {
  param <- if (is.null(s$param)) "Mother:Post:WFH_Exposure" else s$param
  tryCatch(
    run_hours_ddd_wild_bootstrap(s$model, param, B = WILD_BOOTSTRAP_B, seed = INFERENCE_SEED,
                                 label = s$label)$table,
    error = function(e) {
      message(sprintf("  wild bootstrap skipped for %s [%s]: %s", s$label, param, conditionMessage(e)))
      NULL
    }
  )
})
hours_wild_bootstrap <- bind_rows(hours_wild_bootstrap, bind_rows(boot_rows))
print(as.data.frame(hours_wild_bootstrap %>% select(label, param, estimate, p_boot, n_clusters)), digits = 4)

RUN_PERMUTATION_TEST <- TRUE
N_PERMUTATIONS       <- 999
if (RUN_PERMUTATION_TEST) {
  message(sprintf("Running the permutation test on the hours DDD (%d draws; several minutes)...", N_PERMUTATIONS))
  hours_permutation <- run_hours_ddd_permutation_test(
    cleaned_df, hours_exposure_index, n_perm = N_PERMUTATIONS, seed = INFERENCE_SEED
  )
  hours_permutation_plot <- build_permutation_plot(
    hours_permutation$draws, t_obs = hours_permutation$table$t_stat,
    p_perm = hours_permutation$table$p_perm,
    title    = "Permutation distribution of the hours DDD triple interaction",
    subtitle = sprintf("%d reassignments of the exposure score across occupations", N_PERMUTATIONS)
  )
}

# 8e. Descriptive figures for the paper
message("Building descriptive figures for the paper (hours 2x2, by-year, dose-response)...")

hours_descriptives <- build_hours_descriptive_plots(
  cleaned_df,
  hours_by_period = hours_diagnostics_results$hours_by_period
)

# Israeli realized-WFH share by year
wfh_share_by_year <- build_wfh_share_by_year(cleaned_df)
print(as.data.frame(wfh_share_by_year))

# Reference-week absence share by exposure quartile
absence_by_exposure_quartile <- build_absence_by_exposure_quartile(
  cleaned_df, hours_exposure_index, breaks = hours_dose_response$breaks
)
print(as.data.frame(absence_by_exposure_quartile$by_quartile))

# Mechanism scatter (repo diagnostic, not in the paper)
hours_mechanism <- build_mechanism_scatter(
  hours_ddd$mechanism_data,
  fit = hours_ddd$models$mechanism
)

# 8g. Paper tables
message("Assembling the paper's tables from the fitted models...")
paper_tables <- build_paper_tables(list(
  desc_table               = desc_table,
  intensive_results        = intensive_results,
  hours_ddd                = hours_ddd,
  hours_ddd_saturated      = hours_ddd_saturated,
  hours_ddd_binned         = hours_ddd_binned,
  mde_hours                = mde_hours,
  hours_lee_bounds         = hours_lee_bounds,
  hours_ddd_external       = hours_ddd_external,
  hours_ddd_realized       = hours_ddd_realized,
  hours_ddd_age_interacted = hours_ddd_age_interacted,
  hours_ddd_reweighted     = hours_ddd_reweighted,
  hours_ddd_unswapped      = hours_ddd_unswapped,
  hours_ddd_ex2023         = hours_ddd_ex2023,
  hours_ddd_twoway_model   = summary(hours_ddd$model, cluster = ~IDPUF + MishlachYad_ISCO_08_2),
  intensive_yearfe         = intensive_yearfe,
  hours_ddd_noimputed      = hours_ddd_noimputed,
  hours_ddd_fulltime       = hours_ddd_fulltime,
  hours_ddd_longhours      = hours_ddd_longhours,
  hours_wild_bootstrap     = hours_wild_bootstrap,
  hours_permutation        = if (RUN_PERMUTATION_TEST) hours_permutation else NULL,
  intensive_jewish         = intensive_jewish,
  intensive_arab           = intensive_arab,
  hours_ddd_jewish         = hours_ddd_jewish,
  hours_ddd_arab           = hours_ddd_arab,
  hours_gender_placebo     = hours_gender_placebo,
  hours_ddd_by_child_age   = hours_ddd_by_child_age,
  baseline_results         = baseline_results,
  ddd_employment_additive  = ddd_employment_additive,
  mde_additive             = mde_additive,
  baseline_employment_rate = baseline_employment_rate,
  wfh_occupation_first_stage = wfh_occupation_first_stage,
  hours_ddd_calib_men      = hours_ddd_calib_men,
  hours_ddd_swap_control   = hours_ddd_swap_control,
  hours_ddd_cell_exposure  = hours_ddd_cell_exposure,
  exposure_sorting_check   = exposure_sorting_check,
  hours_ddd_leave_one_out  = hours_ddd_leave_one_out,
  balance_by_quartile      = balance_by_quartile,
  # 2026-09-28 referee-review response (docs/admin/review.md, items 1-3).
  hours_ddd_married_only       = hours_ddd_married_only,
  hours_ddd_marital_interacted = hours_ddd_marital_interacted,
  hours_ddd_teaching_swap      = hours_ddd_teaching_swap,
  calibration_threshold_sweep  = calibration_threshold_sweep
))

# 9. Export (check_idpuf_panel_structure()'s per-person tables are deliberately not exported)
results_to_export <- list(
  comparative_stats = comp_stats,
  descriptive_table = desc_table,
  intensive_margin = intensive_results,
  intensive_margin_lee_bounds = intensive_lee_bounds,
  basic_reg = baseline_results,
  basic_reg_jewish = baseline_jewish,
  basic_reg_arab = baseline_arab,
  employment_by_child_age = emp_res,
  diagnostics = diagnostics_results,
  hours_diagnostics = hours_diagnostics_results,
  hours_event_study = list(plot = hours_event_study_plot$plot),
  pretrend_wald_employment = pretrend_wald$table,
  pretrend_wald_hours = pretrend_wald_hours$table,
  pretrend_wald_hours_ddd = pretrend_wald_hours_ddd$table,
  isco_masking_sensitivity = isco_masking_check,
  wfh_exposure_external = exposure_external,
  wfh_exposure_calibrated = exposure_calibrated,
  wfh_exposure_realized = exposure_realized,
  wfh_exposure_cells = exposure_cells,
  ddd_hours_table = hours_ddd$table,
  mde_hours = mde_hours$table,
  hours_ddd_event_study = list(
    coefs = hours_ddd_event_study$coefs,
    table = hours_ddd_event_study$table,
    plot  = hours_ddd_event_study_plot$plot
  ),
  hours_descriptives  = hours_descriptives,
  hours_dose_response = hours_dose_response,
  hours_mechanism     = hours_mechanism,
  hours_lee_bounds_table = hours_lee_bounds$table,
  hours_lee_bounds_quartiles = hours_lee_bounds$diagnostics$quartile_selection_rates,
  hours_lee_bounds_n_trimmed = hours_lee_bounds$diagnostics$n_trimmed_by_quartile,
  ddd_hours_external = hours_ddd_external$table,
  ddd_hours_realized = hours_ddd_realized$table,
  ddd_hours_unswapped      = hours_ddd_unswapped$table,
  ddd_hours_ex2023         = hours_ddd_ex2023$table,
  intensive_margin_ex2023  = intensive_ex2023$table,
  ddd_hours_twoway_cluster = hours_ddd_twoway_table,
  wfh_share_by_year        = wfh_share_by_year,
  absence_by_exposure_quartile = list(
    by_quartile = absence_by_exposure_quartile$by_quartile,
    by_cell     = absence_by_exposure_quartile$by_cell
  ),
  intensive_margin_jewish_table   = intensive_jewish$table,
  intensive_margin_arab_table     = intensive_arab$table,
  ddd_hours_jewish_table          = hours_ddd_jewish$table,
  ddd_hours_arab_table            = hours_ddd_arab$table,
  # Only the tables: $cleaned_men is row-level microdata
  hours_gender_placebo_did_table  = hours_gender_placebo$result$table,
  hours_gender_placebo_ddd_table  = hours_gender_placebo$ddd_placebo$table,
  gender_placebo_did_table        = gender_placebo$result$table,
  gender_placebo_ddd_table        = gender_placebo$ddd_placebo$table,
  hours_did_subgroup_comparison   = hours_did_subgroup_comparison,
  hours_ddd_subgroup_comparison   = hours_ddd_subgroup_comparison,
  ddd_employment = employment_ddd_table,
  ddd_hours_saturated      = hours_ddd_saturated$table,
  ddd_hours_binned         = list(table = hours_ddd_binned$table, coefs = hours_ddd_binned$coefs,
                                  quartile_sizes = hours_ddd_binned$quartile_sizes),
  intensive_margin_yearfe  = intensive_yearfe$table,
  ddd_hours_noimputed      = hours_ddd_noimputed$table,
  ddd_hours_fulltime       = hours_ddd_fulltime$table,
  ddd_hours_longhours      = hours_ddd_longhours$table,
  hours_outcome_shares     = hours_outcome_shares,
  hours_wild_bootstrap     = hours_wild_bootstrap,
  hours_ddd_by_child_age   = list(table = hours_ddd_by_child_age$table,
                                  comparison_data = hours_ddd_childage_comparison$data,
                                  comparison_plot = hours_ddd_childage_comparison$plot),
  wfh_occupation_first_stage = list(table = wfh_occupation_first_stage$table,
                                    stats = wfh_occupation_first_stage$stats,
                                    plot  = wfh_occupation_first_stage$plot),
  hours_subgroup_ztests    = paper_tables$subgroup_ztests,
  wfh_exposure_calibrated_men = hours_ddd_calib_men$index,
  ddd_hours_calibrated_men    = hours_ddd_calib_men$result$table,
  ddd_hours_swap_control      = list(table = hours_ddd_swap_control$table, coefs = hours_ddd_swap_control$coefs),
  exposure_sorting_check      = list(table = exposure_sorting_check$table,
                                     pre_levels = exposure_sorting_check$pre_levels,
                                     event_study = exposure_sorting_check$event_study),
  ddd_hours_cell_exposure     = list(table = hours_ddd_cell_exposure$table, coefs = hours_ddd_cell_exposure$coefs),
  hours_ddd_leave_one_out     = list(table = hours_ddd_leave_one_out$table,
                                     summary = hours_ddd_leave_one_out$summary,
                                     plot = if (is.null(hours_ddd_leave_one_out_plot)) NULL else hours_ddd_leave_one_out_plot$plot),
  balance_by_exposure_quartile = balance_by_quartile$table,
  ddd_hours_married_only       = hours_ddd_married_only$table,
  ddd_hours_marital_interacted = etable(hours_ddd_marital_interacted$model,
                                        headers = c("Hours DDD, marital-status interacted"), digits = 4),
  ddd_hours_teaching_swap      = hours_ddd_teaching_swap$table,
  calibration_threshold_sweep  = calibration_threshold_sweep$table,
  hours_lee_bounds_imbens_manski      = as.data.frame(hours_lee_bounds$imbens_manski_ci),
  intensive_margin_lee_bounds_imbens_manski = as.data.frame(intensive_lee_bounds$imbens_manski_ci)
)

if (RUN_PERMUTATION_TEST) {
  results_to_export$hours_permutation <- list(
    table = hours_permutation$table,
    draws = hours_permutation$draws,
    plot  = if (is.null(hours_permutation_plot)) NULL else hours_permutation_plot$plot
  )
}

if (RUN_AGE_BALANCE_ROBUSTNESS) {
  # Aggregate pieces only; the pre_df frames are row-level
  results_to_export$age_balance_robustness <- list(
    balance_test = list(
      gilnk_balance     = balance_check$gilnk_balance,
      gilnk_ttests      = balance_check$gilnk_ttests,
      cat_distributions = balance_check$cat_distributions,
      cat_chisq         = balance_check$cat_chisq
    ),
    age_imbalance_by_quartile = age_balance_diag$gap_by_quartile,
    ddd_age_interacted = etable(
      ddd_age_interacted$additive, ddd_age_interacted$fe,
      headers = c("Age-interacted: additive", "Age-interacted: cell FE"), digits = 4
    ),
    ddd_reweighted = etable(
      ddd_reweighted$additive, ddd_reweighted$fe,
      headers = c("Reweighted: additive", "Reweighted: cell FE"), digits = 4
    ),
    hours_ddd_age_interacted = etable(
      hours_ddd_age_interacted$model,
      headers = c("Hours DDD, age-interacted"), digits = 4
    ),
    hours_ddd_reweighted = etable(
      hours_ddd_reweighted$model,
      headers = c("Hours DDD, reweighted"), digits = 4
    )
  )
}

if (RUN_NULL_VS_POWER_AUDIT) {
  results_to_export$null_vs_power_audit <- list(
    wfh_first_stage_table = wfh_first_stage$table,
    mde_additive           = mde_additive$table,
    mde_fe                 = mde_fe$table
  )
}

message("Exporting results to outputs/...")
export_all_results(results_to_export)

# Paper figures as vector PDFs; keys are the filenames paper.tex hard-codes
message("Exporting paper figures (vector PDF) to outputs/figures/...")
paper_figures <- list(
  hours_by_year         = list(plot = hours_descriptives$plots$by_year,    width = 5.0, height = 5.0),
  hours_event_study     = list(plot = hours_event_study_plot$plot,         width = 5.0, height = 3.4),
  hours_ddd_event_study = list(plot = hours_ddd_event_study_plot$plot,     width = 5.0, height = 3.4),
  hours_dose_response   = list(plot = hours_dose_response$plot,            width = 5.0, height = 3.4),
  wfh_first_stage_occupation   = list(plot = wfh_occupation_first_stage$plot,   width = 5.0, height = 3.8)
)
if (!is.null(hours_ddd_leave_one_out_plot)) {
  paper_figures$hours_ddd_leave_one_out <- list(plot = hours_ddd_leave_one_out_plot$plot, width = 5.0, height = 6.2)
}
if (RUN_PERMUTATION_TEST && !is.null(hours_permutation_plot)) {
  paper_figures$hours_permutation <- list(plot = hours_permutation_plot$plot, width = 5.0, height = 3.2)
}
export_paper_figures(paper_figures)

# Paper tables written to paper/tables/
message("Exporting paper tables (LaTeX tabular blocks) to paper/tables/...")
export_paper_tables(paper_tables)
