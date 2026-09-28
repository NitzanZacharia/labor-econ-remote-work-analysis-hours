# main.R

# ── 1. Clear environment and load modules ─────────────────────────────────────
rm(list = ls())
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "comparative_statistics.R"))
source(file.path("scripts", "descriptive_table.R"))
source(file.path("scripts", "basic_regression.R"))
source(file.path("scripts", "basic_reg_compared_data.R"))  # manual robustness call only (README "Setup & running"); not run by the pipeline
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

# Load modules required for the WFH exposure index and DDD mechanism test
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

# Paper figure layer (docs/decisions/paper-figure-layer.md): the shared theme/palette plus the
# three descriptive builders added for the paper's Descriptive Statistics section.
source(file.path("scripts", "paper_theme.R"))
source(file.path("scripts", "hours_descriptive_plots.R"))
source(file.path("scripts", "hours_dose_response.R"))
# Two descriptives the 2026-09-22 editorial audit asked for (items B2 and I1; the audit note is
# in git history): the Israeli realized-WFH share by year, and the reference-week absence share by
# exposure quartile.
source(file.path("scripts", "wfh_share_by_year.R"))
source(file.path("scripts", "absence_by_exposure_quartile.R"))
source(file.path("scripts", "build_mechanism_scatter.R"))
source(file.path("scripts", "build_event_study_plot.R"))

# robustness/ is normally sourced only inside the RUN_AGE_BALANCE_ROBUSTNESS block, but
# pretrend_wald_test.R is a diagnostic rather than a robustness spec: its F-statistics are the
# paper's parallel-trends evidence, so it runs unconditionally -- §7 for the two DiD-level models,
# §8a for the DDD event study, which cannot run any earlier because it needs §8's exposure measure.
source(file.path("robustness", "pretrend_wald_test.R"))

# Grade-report response (docs/decisions/grade-report-response.md): saturated and
# quartile-binned DDD columns, the child-age heterogeneity split, the occupation-level first
# stage, small-cluster inference (wild bootstrap + permutation test), and the generated-table
# layer that writes paper/tables/*.tex.
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
# Grade-report-2 response (docs/decisions/grade-report-2-response.md): calibration tests,
# occupational sorting, leave-one-out influence and pre-period balance.
source(file.path("scripts", "hours_ddd_swap_control.R"))
source(file.path("scripts", "exposure_sorting_check.R"))
source(file.path("scripts", "hours_ddd_cell_exposure.R"))
source(file.path("scripts", "hours_ddd_leave_one_out.R"))
source(file.path("scripts", "build_leave_one_out_plot.R"))
source(file.path("scripts", "build_balance_by_exposure_quartile.R"))

# ── 2. Configure paths ────────────────────────────────────────────────────────
message("Edit folder paths if needed!")
folder_path   <- "G:/My Drive/Uni/econ/csv_data"
rds_file_path <- paste0(folder_path, "/cleaned_df.rds")

# ── 3. Execute data pipeline (with caching) ───────────────────────────────────
# Cache validity is tied to data_processing.R's content, not just to the RDS file's existence --
# otherwise a stale cache built before a data_processing.R change (e.g. a corrected WFH coding
# rule, or a new derived column) keeps getting silently reused with no error. The hash is stored
# in a small sidecar file next to the cache.
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
check_idpuf_panel_structure(cleaned_df)   # reporting-only; returns invisibly, see §9

message("Checking WFH_RefWeek's NA rationale against AvadBeshavua...")
check_wfh_refweek_avadbeshavua(cleaned_df) # reporting-only; returns invisibly

# ── 4. Comparative statistics ─────────────────────────────────────────────────
message("Running comparative statistics...")
comp_stats <- run_comparative_stats(cleaned_df)

message("Building the descriptive (Table 1) summary...")
desc_table <- build_descriptive_table(cleaned_df)

# ── 5. Run regressions ────────────────────────────────────────────────────────
# Primary (intensive-margin/hours) regression runs first, matching the hours pivot
# (docs/decisions/hours-ddd-pivot.md); the secondary (extensive-margin/employment) regressions
# follow.
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

# ── 6. Run descriptive stats ────────────────────────────────────────────────────────
message("Running employment_by_child_age...")
emp_res <- employment_by_child_age(cleaned_df)

# ── 7. Event studies & parallel-trends tests ──────────────────────────────────
# Diagnostics.R's event-study plot draws to whatever device is active rather than opening its own
# (see the comment there) -- wrap the call in an explicit device targeting outputs/ so a real run
# produces a saved plot instead of leaking an auto-numbered Rplots*.pdf into the repo root.
pdf(file.path("outputs", "event_study_pretrend.pdf"))
diagnostics_results <- run_diagnostics(cleaned_df)
dev.off()

# Primary (hours) pretrend/event-study check (docs/decisions/hours-ddd-pivot.md). No device wrapper:
# run_hours_diagnostics() draws nothing, it returns tidy coefficients that build_event_study_plot()
# turns into a ggplot below (docs/decisions/ddd-event-study.md).
hours_diagnostics_results <- run_hours_diagnostics(cleaned_df)

hours_event_study_plot <- build_event_study_plot(
  hours_diagnostics_results$pretrend_coefs,
  title    = "Hours event study: Mother × Year",
  subtitle = "Weekly work hours, employed women aged 25–59; 95% CIs, individual-clustered SEs",
  y_label  = "Mother × Year (95% CI)",
  se_note  = "standard errors clustered by individual"
)

# Joint Wald tests on the pre-2020 Mother:year coefficients. Unconditional, and deliberately placed
# right beside the event studies whose models they test: parallel trends requires the pre-period
# coefficients to be jointly, not just individually, indistinguishable from zero, and both
# F-statistics are reported in the paper (Results §5.3 and Limitations). Keep them out of any
# feature flag -- a default `Rscript main.R` has to reproduce the paper's identification evidence.
message("Running joint Wald test on pre-2020 Mother:year pre-trend coefficients (employment)...")
pretrend_wald <- run_pretrend_joint_test(diagnostics_results$pretrend_model)

message("Running joint Wald test on pre-2020 Mother:year pre-trend coefficients (hours, primary)...")
pretrend_wald_hours <- run_pretrend_joint_test(hours_diagnostics_results$pretrend_model)

# Results are exported once, at the very end of the script (── 9 ──), so that §8's WFH-exposure
# measures and DDD regressions land in the same outputs/ artifact set as everything above. Do not
# move an export call up here: anything defined after it would silently never reach disk.

# ── 8. WFH-Exposure Measures & DDD Regression ─────────────────────────────────
# Four separate measures, four separate purposes. They are NOT combined into one "best" index fed
# to a single regression -- an earlier version of this section did that (swapping the theoretical
# index for realized-2022-23 values above an arbitrary gap threshold, with no account of sampling
# noise), which both contaminated the DDD's exposure regressor with post-treatment behavior and
# let a 4-observation occupation cell (ISCO 63) swing the ranking. See
# docs/decisions/calibrated-exposure-and-cell-ddd.md for the full argument.
message("Building the WFH-exposure measures...")

# calibrate_isco_exposure()/build_wfh_exposure_index()/build_exposure_cells() must NOT be built from
# cleaned_df alone: it is the exact women-25-59 sample the employment DDD later fits, so an
# occupation score built from it is built from the very people in the regression (see
# wfh_exposure_index.R's header). build_exposure_cells() stratifies by Min, so adding men leaves
# its women cells unchanged; calibrate_isco_exposure()/build_wfh_exposure_index() aggregate by
# occupation only, so adding men's realized WFH is what breaks that mechanical link.
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

# (a) External, exogenous teleworkability (Dingel & Neiman via O*NET/SOC->ISCO crosswalk).
# Pre-period by construction, immune to Israel's own COVID-era WFH behavior -- but a US-task-based
# measure, so it misclassifies occupations where Israeli institutional practice diverges sharply
# (teaching is the clear case: D&N scores it near-ceiling teleworkable, but Israeli schools stayed
# in-person by Ministry of Education policy).
exposure_external <- build_exposure_isco2()

# (b) Statistically-calibrated version of (a): corrects occupations where the realized-vs-D&N gap
# is large AND well-powered enough that it can't be sampling noise (a cluster-robust one-sided
# test against the gap_threshold, not a flat sample-size floor -- see calibrate_isco_exposure()'s
# own documentation in wfh_exposure_cells.R for why). Still draws on 2022-23 realized data, which
# sits inside the post-period, so this is a documented compromise, not a fully pre-treatment
# measure -- report (c)/(d) alongside it so the paper shows whether conclusions depend on it.
exposure_calibrated <- calibrate_isco_exposure(exposure_population_df, exposure_external)
message(sprintf(
  "  calibration swapped %d of %d occupations for realized Israeli values (gap > 0.5, statistically distinguishable from sampling noise at 95%% confidence):",
  sum(exposure_calibrated$swap), nrow(exposure_calibrated)
))
print(exposure_calibrated %>% filter(swap) %>%
        select(ISCO2, n, tele_ext, realized_wfh, gap, se_clustered, margin) %>%
        as.data.frame(), digits = 3)

# Sensitivity check: exposure_calibrated (and exposure_realized/exposure_cells below) is built by
# dropping every disclosure-masked-ISCO row via !is.na(ISCO2) -- masking concentrates in thin
# occupation cells, so this checks whether masked rows' realized WFH looks different from unmasked
# rows' within the same coarse (ISCO1) occupation family, as a proxy for whether that dropped
# subsample is likely to be biasing the exposure index. See isco_masking_diagnostics.R.
message("Checking ISCO disclosure-masking sensitivity (masked vs. unmasked realized WFH)...")
isco_masking_check <- check_isco_masking_sensitivity(cleaned_df)

# (c) Realized Israeli WFH by occupation, anchored per
# docs/decisions/checkpoint6-wfh-anchor-year.md. Post-treatment by construction -- a robustness
# check, not a substitute for (a)/(b). min_n = 200 drops occupations too thin to trust (without a
# floor, a 4-observation cell can dominate the ranking -- see ISCO 63 above).
exposure_realized <- build_wfh_exposure_index(exposure_population_df, ref_year = 2021, min_n = 200)

# (d) Pre-period (2017-2019) shift-share exposure by demographic cell, built from the calibrated
# occupation-level score (b). Unlike (a)-(c), this is defined for every row of cleaned_df --
# employed and non-employed alike -- so it's the only one of the four that doesn't condition the
# third difference on Employed, the regression's own outcome. This is the exposure measure for the
# secondary (employment) DDD's own regressor, and is separately reused (for its quartile structure
# only, not as a regressor) by the primary (hours) DDD's Lee-bounds selection correction -- see
# hours_ddd_lee_bounds.R's header comment for why two different exposure measures serve two
# different roles.
#
# exposure_cell_vars is DELIBERATELY FINER than cell_fe_vars below, and must stay that way. Making
# the two identical is the old design, whose exposure regressor was collinear enough with its own
# controls/FE that the employment DDD's MDE was ~51% of baseline -- an uninformative null rather
# than evidence of one. The extra three (MatzavMishpachti, Dat, BirthContinent) are all pre-period
# demographic variables observed regardless of employment status, so they do not reintroduce
# occupation-level exposure's employment-conditioning problem.
# Full argument, cell-size tables and the measured MDE reductions:
# docs/decisions/exposure-cell-granularity-fix.md.
exposure_cell_vars <- c("Min", "GilNK", "TeudaGvoha", "MachozMegurim", "MatzavMishpachti", "Dat",
                         "BirthContinent")
exposure_cells <- build_exposure_cells(
  exposure_population_df,
  exposure_calibrated %>% select(ISCO2, tele_ext = wfh_exposure_calibrated),
  cell_vars = exposure_cell_vars
)

# ── 8a. Primary DDD (hours): pure occupation-level exposure (docs/decisions/hours-ddd-pivot.md) ─
# PRIMARY specification; the extensive-margin DDD in 8b below is secondary. Unconditional -- this
# is the project's default analysis, not an opt-in diagnostic.
#
# The one thing to know at this call site: the exposure regressor here is the PURE occupation-level
# measure, which is safe for a hours outcome (WorkHoursCont's conditioning on employment is
# intrinsic to the question) but would NOT be safe for 8b's Employed outcome, where it would
# condition the DDD's outcome on itself. Dropping non-employed rows still introduces a real
# selection-on-a-mediator problem; run_hours_ddd_lee_bounds() below bounds it.
# Why the pivot happened, and the power arithmetic behind it: docs/decisions/hours-ddd-pivot.md.
message("Running primary DDD (hours, pure occupation-level exposure, Employed==1 subsample)...")
hours_exposure_index <- exposure_calibrated %>%
  select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)
hours_ddd <- run_hours_ddd_regression(cleaned_df, hours_exposure_index)

message("Computing minimum detectable effect for the hours DDD's triple interaction...")
baseline_hours <- mean(cleaned_df$WorkHoursCont[cleaned_df$Employed == 1], na.rm = TRUE)
# `df` is the t degrees of freedom the model's own p-values use (G - 1 = 39 occupation clusters),
# so the MDE's multiplier matches the inference rather than assuming a normal reference
# (docs/decisions/grade-report-2-response.md). The employment MDEs in §8d keep the normal multiplier: their
# ~210 cell clusters make the two indistinguishable.
mde_hours <- compute_ddd_mde(hours_ddd$model, baseline_rate = baseline_hours,
                             regressor = hours_ddd$exposure_vector,
                             df = degrees_freedom(hours_ddd$model, type = "t"))

# Parallel-trends check for the PRIMARY estimand. §7's two Wald tests are both DiD-level
# (Mother x year): they ask whether mothers and non-mothers trended together, averaging over WFH
# exposure. The DDD's identifying assumption is the stricter one -- that the mother/non-mother gap
# trended together ACROSS exposure levels -- and an exposure-correlated pre-period divergence that
# nets to zero across occupations passes §7 while violating it. Hence a third pretrend model, on the
# triple interaction itself. Placed here rather than in §7 because it needs hours_exposure_index.
#
# Same exposure measure, same subsample, same occupation-level clustering as hours_ddd above, so the
# test is on the assumption that specific model rests on rather than on a neighbouring one.
message("Running DDD event study (hours, Mother x year x WFH_Exposure)...")
hours_ddd_event_study <- run_hours_ddd_event_study(cleaned_df, hours_exposure_index)

# keep/label are passed explicitly: the default `keep` is anchored to the DiD-level ":Mother$" terms
# and would match none of this model's triple-interaction coefficients. See pretrend_wald_test.R's
# header for why the anchor matters.
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

# Occupation-level robustness variants (external/realized exposure) -- run_hours_ddd_regression()
# already takes a generic exposure_index, so no new function is needed here, just two more call
# sites.
message("Running primary DDD robustness variant (hours, raw external Dingel & Neiman index)...")
hours_ddd_external <- run_hours_ddd_regression(
  cleaned_df,
  exposure_external %>% select(occupation_code = ISCO2, wfh_exposure = tele_ext)
)

message("Running primary DDD robustness variant (hours, realized Israeli index, 2021 anchor)...")
hours_ddd_realized <- run_hours_ddd_regression(cleaned_df, exposure_realized)

# Three further sensitivity rows for the paper's robustness table
# (2026-09-22 editorial audit, items G6, I5 and F3; note in git history). None needs a new function: run_hours_ddd_regression() is generic over its data frame and its exposure index.
#
# (G6) Unswapped occupations only. calibrate_isco_exposure() swaps 10 of 40 occupations to their
# realized 2022-23 share, which sits inside the post-period; on the 30 it leaves alone the
# calibrated and external scores coincide by construction, so a triple interaction that survives
# here is not manufactured by the post-period calibration. The inner_join inside the function
# drops the swapped occupations' rows, leaving 30 clusters.
message("Running primary DDD robustness variant (hours, unswapped occupations only)...")
hours_ddd_unswapped <- run_hours_ddd_regression(
  cleaned_df,
  exposure_calibrated %>%
    filter(!swap) %>%
    select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)
)

# (I5) Excluding the 2023 survey year, whose fourth quarter includes the start of the October 2023
# war. 2023 carries the largest coefficient in both event studies; this row shows what the estimate
# looks like without it. A whole-year exclusion rather than Q4 only, because the survey-month field
# is dropped at cleaning and retaining it would change the cleaned schema.
message("Running primary DiD and DDD excluding the 2023 survey year...")
intensive_ex2023 <- run_intensive_margin_reg(filter(cleaned_df, ShnatSeker != 2023))
hours_ddd_ex2023 <- run_hours_ddd_regression(filter(cleaned_df, ShnatSeker != 2023),
                                             hours_exposure_index)

# (F3) Two-way clustering, individual and occupation, on the primary fit. A re-summary of the
# existing model rather than a refit: the point estimates are unchanged by construction and only
# the standard errors move.
message("Re-summarising the primary hours DDD with two-way (individual + occupation) clustering...")
hours_ddd_twoway_table <- etable(
  summary(hours_ddd$model, cluster = ~IDPUF + MishlachYad_ISCO_08_2),
  headers = c("Hours DDD, two-way clustered"), digits = 4
)
print(hours_ddd_twoway_table)

# ── Specification and outcome-coding checks (grade-report response, items M1/M3) ─────────────
# The dose-response figure is built HERE rather than in §8e, because its quartile edges are the
# bins the binned DDD below uses: one `breaks` object feeds Figure 2, Table 2's column (4) and the
# absence footnote, so the paper never compares bins that are not the same bins.
message("Building the raw hours dose-response by exposure quartile (Figure 2; also supplies the quartile edges)...")
hours_dose_response   <- build_hours_dose_response(cleaned_df, hours_exposure_index)
hours_exposure_breaks <- hours_dose_response$breaks

# (M1) Fully saturated DDD: occupation x year, occupation x mother and mother x year fixed
# effects absorb every lower-order margin the pooled column forces to be linear in exposure.
message("Running the saturated hours DDD (occupation x year, occupation x mother, mother x year FE)...")
hours_ddd_saturated <- run_hours_ddd_saturated(cleaned_df, hours_exposure_index)

# (M1) Quartile-binned DDD on Figure 2's bins: the Q4-vs-Q1 contrast as a coefficient with an SE.
message("Running the quartile-binned hours DDD on Figure 2's exposure quartiles...")
hours_ddd_binned <- run_hours_ddd_binned(cleaned_df, hours_exposure_index,
                                         breaks = hours_exposure_breaks)

# (M1) The plain DiD with survey-year effects in place of the single Post dummy.
message("Running the hours DiD with survey-year effects in place of Post...")
intensive_yearfe <- run_intensive_margin_reg(cleaned_df, year_fe = TRUE)

# (M3) Sensitivity to the construction of the hours outcome. The bin medians make 35 and 40 exact
# bin cut-offs (bin 6 = 35-39 hours, bin 7 = 40-44), so the two indicators are bin-crossing
# outcomes rather than approximations. Codes 11/12 are the irregular-hours codes imputed from
# period-specific medians in data_processing.R; dropping them removes the imputation entirely.
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
# Baseline shares of the two indicators on the estimation sample, by mother status and period, so
# the paper can state what a percentage-point effect is measured against (exported as
# outputs/hours_outcome_shares.csv).
hours_outcome_shares <- hours_outcome_df %>%
  filter(Employed == 1, !is.na(WorkHoursCont)) %>%
  group_by(Mother, Post) %>%
  summarise(share_fulltime = mean(FullTime), share_longhours = mean(LongHours),
            mean_hours = mean(WorkHoursCont), n = n(), .groups = "drop")
print(as.data.frame(hours_outcome_shares), digits = 4)

# ── Grade-report-2 checks (docs/decisions/grade-report-2-response.md) ─────────────────────────
# Six additions, each one function, all on the primary hours DDD's sample and clustering:
#
#   (a) Men-only calibration. The pooled calibration computes realized 2022-23 WFH shares on men
#       and women together; computing them on MEN ONLY removes every woman in the regression from
#       the construction of her own regressor. Same swap rule, same external index.
#   (b) Fixed-sample calibration test. All forty occupations, external score as regressor, with
#       the ten swapped occupations given their own Mother x Post change -- the calibration's
#       content without the sample change the unswapped-30 row makes.
#   (c) Occupational sorting, diagnosed: a DiD with the exposure score itself as the outcome.
#   (d) Occupational sorting, bounded: the hours DDD on the PRE-PERIOD demographic-cell exposure,
#       which a woman's post-2021 occupation cannot move.
#   (e) Leave-one-occupation-out: forty refits, one occupation dropped each time.
#   (f) Pre-period covariate balance by quartile of the occupation-level score (Appendix Table A2).
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

# (R3) First stage for the occupation-level score the headline is estimated on, plus the 40-row
# appendix table. Men and women pooled, as in the calibration itself.
message("Checking the occupation-level first stage (calibrated score vs realized reference-week WFH)...")
wfh_occupation_first_stage <- build_wfh_occupation_first_stage(
  cleaned_women       = cleaned_df,
  cleaned_men         = cleaned_men_for_exposure,
  exposure_calibrated = exposure_calibrated,
  exposure_external   = exposure_external,
  exposure_realized   = exposure_realized
)

# ── Hours subgroup comparisons (demographic heterogeneity) ────────────────────────────────────
# Two checks on the primary hours DiD/DDD, mirroring the employment outcome's coverage in section 5:
#
# (i) Arab vs. Jewish women (Leom == 2 / Leom == 1): the same hours functions on the two subsamples,
# exactly as basic_reg() is run for basic_reg_jewish/basic_reg_arab. Point estimates only (DiD +
# DDD) -- a heterogeneity check on the primary spec, not a new primary specification, so no
# per-subgroup Lee-bounds/MDE run.
#
# (ii) Male vs. female (gender placebo): the hours DiD/DDD on men, reading "Mother" as "Father",
# to test whether the effect is motherhood-specific rather than a general parenthood/macro pattern
# (hours_gender_placebo.R's header). Reuses cleaned_men_for_exposure and hours_exposure_index from
# above rather than reloading or rebuilding either.
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

# Employment-outcome placebo, the secondary-margin twin of the call above, so both margins carry
# the same falsification check. Reuses cleaned_men_for_exposure rather than reloading it.
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
  # Styled apart from the three women subgroups: men are a different population, not another
  # slice of the study sample, and the placebo's value lies in running the opposite way.
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

# (R2) Heterogeneity by the age of the youngest child: the most direct test of the time-constraint
# mechanism the data allow. Each row is that bin's mothers against ALL childless women; the DiD
# and DDD functions are the primary ones, exactly as the Jewish/Arab rows above.
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

# ── 8b. Secondary DDD (employment): cell-based exposure, defined for the full sample ──────────
# Two specs, reported side by side. SECONDARY since the hours pivot, but still unconditional --
# consistent with basic_reg()/employment_by_child_age(), the pipeline's other employment analyses.
#
# cell_fe_vars (Spec 1's additive controls / Spec 2's fixed effect) is intentionally COARSER than
# exposure_cell_vars above: that gap is what makes WFH_Exposure vary within every FE cell, and so
# what gives Mother:Post:WFH_Exposure any identifying power at all. Spec 1 still carries some
# overlap with cell_fe_vars; check_spec1_collinearity() below reports the live R²/VIF/condition
# number rather than asserting it here.
# Why the two partitions differ: docs/decisions/exposure-cell-granularity-fix.md.
message("Running secondary (employment) DDD (cell-based exposure, calibrated, full sample)...")
ddd_df <- cleaned_df %>%
  left_join(exposure_cells, by = exposure_cell_vars)
message(sprintf(
  "Employment DDD join: %d of %d rows unmatched to an exposure cell (WFH_Exposure NA).",
  sum(is.na(ddd_df$WFH_Exposure)), nrow(ddd_df)
))

cell_fe_vars    <- c("GilNK", "TeudaGvoha", "MachozMegurim")
other_controls  <- setdiff(DEFAULT_CONTROLS, cell_fe_vars)

# Clustered on the cell, never on IDPUF. WFH_Exposure is assigned at cell granularity, not per
# individual, so individual-level clustering cannot see the within-cell error correlation a shared
# exposure value induces -- a classic Moulton problem that understates the SE on exactly the
# coefficient this design exists to estimate. Clustering on the COARSER cell_fe_vars grouping
# (~210 cells) rather than the exposure cell is deliberate and conservative: every cell_fe_vars
# group is a union of exposure cells. ~210 clusters clears the usual >=40-50 rule of thumb but is
# not large; a small-cluster correction would need a new dependency and is deliberately not added.
# Full reasoning: docs/decisions/calibrated-exposure-and-cell-ddd.md.
cell_cluster_formula <- as.formula(paste("~", paste(cell_fe_vars, collapse = "^")))

# Mother:GilNK is here because GilNK is imbalanced between Mother==1/0 in the pre-period AND the
# gap's SIZE varies by WFH_Exposure quartile -- an additive GilNK term cannot correct an imbalance
# that itself varies with the regressor of interest. It does NOT change the
# Mother:Post:WFH_Exposure conclusion either way, so it is not rescuing the result; it earns its
# place by surfacing a separate real finding the additive control was masking.
# In Spec 2 GilNK's main effect is absorbed by the cell FE, but Mother:GilNK is not collinear with
# it (the FE groups by GilNK^TeudaGvoha^MachozMegurim, not by Mother within cell), so it still adds
# information. Evidence and the surfaced finding: docs/decisions/age-balance-robustness-chain.md.
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
# Unlike the old design (exposure_cell_vars == cell_fe_vars exactly), WFH_Exposure's bare main
# effect is NOT expected to drop here anymore -- exposure_cell_vars is now finer than cell_fe_vars
# (see the comment above exposure_cells), so WFH_Exposure varies within every cell_fe_vars FE cell
# and is no longer exactly collinear with the FE. Verified against real data
# (docs/decisions/exposure-cell-granularity-fix.md); no expected_drops here means any drop at all
# --including WFH_Exposure's-- now triggers a warning, which is the point.
check_for_dropped_coefficients(ddd_employment_fe, "employment DDD Spec 2 (interacted cell FE)")
employment_ddd_table <- etable(
  ddd_employment_additive, ddd_employment_fe,
  headers = c("Spec 1: additive controls", "Spec 2: interacted cell FE"), digits = 4
)
print(employment_ddd_table)

message("Checking Spec 1's collinearity at runtime (see comment above)...")
check_spec1_collinearity(ddd_df, cell_fe_vars, DEFAULT_CONTROLS)  # prints its own report

# ── 8c. Age-balance robustness chain (docs/decisions/age-balance-robustness-chain.md) ─────────
# ON by default. These are diagnostic/comparison checks layered on top of the employment DDD (8b),
# not a replacement for it -- whether run_ddd_age_interacted()/run_ddd_reweighted() should REPLACE
# 8b is a separate, still-open methodological decision (see the memo), not something this flag
# resolves. The default is TRUE because the paper's robustness table (tab:robust) and its
# age-imbalance sentence both cite artifacts produced here, and a reader following the README must
# be able to reproduce them from `Rscript main.R` alone. The flag is kept, not removed, so the
# chain can still be switched off for a fast run.
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

  # Hours-outcome (primary DDD) analogs -- see age_balance_robustness.R's §4 header comment for why
  # these use the occupation-level exposure_index rather than the cell-based exposure_cells as
  # their actual regressor. hours_exposure_index is the one built in §8a; this block reuses it
  # rather than re-deriving it, so the two cannot drift apart.

  message("Running age-interacted comparison spec for the hours DDD (Mother:GilNK added)...")
  hours_ddd_age_interacted <- run_hours_ddd_age_interacted(cleaned_df, hours_exposure_index)

  message("Running GilNK-reweighted comparison spec for the hours DDD (pre-period raking weights)...")
  hours_ddd_reweighted <- run_hours_ddd_reweighted(cleaned_df, exposure_cells, hours_exposure_index)

}

# ── 8d. Null-vs-power audit (docs/decisions/exposure-cell-granularity-fix.md, B1/B2 section) ──
# ON by default, same framing as 8c: a diagnostic on top of the employment DDD (8b), not a
# replacement. Exists to answer what the null Mother:Post:WFH_Exposure result alone cannot -- is
# this design well-powered enough to detect a plausible effect, or is the null uninformative?
# Two checks: (1) does WFH_Exposure actually predict realized WFH_RefWeek once measurable
# (Post==1), the shift-share design's core relevance assumption; (2) the closed-form minimum
# detectable effect for both employment-DDD specs, so the observed point estimates can be read
# against how small an effect this design could reliably detect at all.
# Default is TRUE because the paper's first-stage figures come from this block.
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

# ── 8f. Small-cluster inference on the primary hours DDD (grade-report items R1 and M2) ───────
# The headline regressor varies across forty occupation clusters. Two complements to the t(39)
# p-values: a wild cluster bootstrap (fwildclusterboot, the one dependency beyond tidyverse +
# fixest -- see README.md) and a permutation test that reassigns the forty exposure scores across
# occupations and refits, which is also the paper's falsification test. The bootstrap takes
# seconds and runs unconditionally. The permutation test refits the DDD N_PERMUTATIONS times
# (~0.8 s each), so it sits behind a flag in the style of §8c/§8d -- ON by default, because the
# paper's permutation p comes from here and a default `Rscript main.R` must reproduce it; set
# N_PERMUTATIONS to 99 for a fast dev run (the exported table records n_perm and the seed, so a
# reduced run cannot be mistaken for the paper's number). The joint pre-trend test stays the
# analytic Wald F above: fwildclusterboot's joint test runs only through Julia, which this
# project does not use (docs/decisions/grade-report-response.md).
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

# ── 8e. Descriptive figure set for the paper ──────────────────────────────────
# Unconditional, like §8a: paper/paper.tex compiles against these figures, so they cannot sit behind
# a flag.
#
# This is the first point in the pipeline where all the inputs exist: hours_diagnostics_results
# (§7), emp_res (§6), hours_exposure_index and hours_ddd (§8a).
message("Building descriptive figures for the paper (hours 2x2, by-year, dose-response)...")

# hours_by_period is passed rather than recomputed so this figure and
# outputs/hours_diagnostics_hours_by_period.csv are physically the same numbers. If
# hours_diagnostics.R's cell-mean computation ever changes, the figure follows it automatically --
# but only for as long as this argument keeps being passed.
hours_descriptives <- build_hours_descriptive_plots(
  cleaned_df,
  hours_by_period = hours_diagnostics_results$hours_by_period
)

# The dose-response figure (hours_dose_response) is built in §8a, where its quartile edges also
# feed the binned DDD; it is binned on the occupation-level calibrated measure -- the same
# regressor the hours DDD uses, NOT the demographic-cell index.

# Israeli realized-WFH share among employed women by year (post-period only: the CBS items begin in
# 2021), for the Introduction's comparison with the US workday shares. Audit item B2.
wfh_share_by_year <- build_wfh_share_by_year(cleaned_df)
print(as.data.frame(wfh_share_by_year))

# Reference-week absence share by exposure quartile, on the same quartile edges as Figure 2, for
# the Limitations paragraph on the narrowed hours estimand. Audit item I1.
absence_by_exposure_quartile <- build_absence_by_exposure_quartile(
  cleaned_df, hours_exposure_index, breaks = hours_dose_response$breaks
)
print(as.data.frame(absence_by_exposure_quartile$by_quartile))

# Repo-level diagnostic only: results_digest.md §1.5 rules the second-stage mechanism regression out
# of the paper, so this figure is not in paper_figures below. Exporting hours_ddd$mechanism_data
# keeps the 37-occupation frame behind the slope on disk (results_digest.md §7 item 1).
hours_mechanism <- build_mechanism_scatter(
  hours_ddd$mechanism_data,
  fit = hours_ddd$models$mechanism
)

# ── 8g. Paper tables (built here, written after the CSV export in §9) ─────────────────────────
# Assembled before results_to_export so the subgroup z-tests it computes reach outputs/ as a CSV
# alongside everything else. The two-way-clustered object is a fixest summary; se()/pvalue() on
# it give the two-way SEs the paper's Table 4 row reports.
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
  # Grade-report-2 inputs (docs/decisions/grade-report-2-response.md).
  hours_ddd_calib_men      = hours_ddd_calib_men,
  hours_ddd_swap_control   = hours_ddd_swap_control,
  hours_ddd_cell_exposure  = hours_ddd_cell_exposure,
  exposure_sorting_check   = exposure_sorting_check,
  hours_ddd_leave_one_out  = hours_ddd_leave_one_out,
  balance_by_quartile      = balance_by_quartile
))

# ── 9. Export results ─────────────────────────────────────────────────────────
# check_idpuf_panel_structure()'s result is deliberately NOT included here -- which is also why §3
# calls it without binding its return value. Its idpuf_years/idpuf_periods tables are keyed by
# individual IDPUF, which is closer to raw identifiable microdata than the aggregate tables
# everything else in this list produces -- per this project's disclosure-risk convention
# (CLAUDE.md, Checkpoint 9), only its console-printed summary counts are surfaced, not a
# persisted per-person roster. Do not "fix" the omission by capturing and exporting it.
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
  # The DiD event-study figure (§7), keyed so it lands as hours_event_study_plot.png. Its
  # coefficients already reach outputs/ as hours_diagnostics_pretrend_coefs.csv via the
  # hours_diagnostics entry above, so only the plot is passed here.
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

  # DDD event study (§8a). Both frames are aggregate -- one row per survey year -- so neither runs
  # into the disclosure convention documented above. $coefs is the tidy estimate/SE/p/CI frame and
  # $table is etable()'s formatted full-model view; the model object itself is skipped by
  # export_all_results(), as with every other fixest fit in this list. The plot's own $data is
  # deliberately not passed: it is $coefs plus the pinned reference-year row, so exporting it would
  # put two near-identical frames in outputs/ and leave the reader to guess which one is the result.
  # Naming: these keys become the filenames, so the plot is keyed `plot` under
  # `hours_ddd_event_study` to land as hours_ddd_event_study_plot.png.
  hours_ddd_event_study = list(
    coefs = hours_ddd_event_study$coefs,
    table = hours_ddd_event_study$table,
    plot  = hours_ddd_event_study_plot$plot
  ),

  # Paper descriptive figures (§8e). Every frame here is aggregate, per the disclosure convention
  # above: hours_by_period is 4 cells, hours_by_year is 6 years x 3 series, dose_response's
  # cell_means is 16 cells, and hours_mechanism$data is one coefficient per ISCO-2 occupation (37
  # rows, the un-fittable ones already dropped inside run_hours_ddd_regression()). Nothing row-level.
  hours_descriptives  = hours_descriptives,
  hours_dose_response = hours_dose_response,
  hours_mechanism     = hours_mechanism,
  hours_lee_bounds_table = hours_lee_bounds$table,
  hours_lee_bounds_quartiles = hours_lee_bounds$diagnostics$quartile_selection_rates,
  hours_lee_bounds_n_trimmed = hours_lee_bounds$diagnostics$n_trimmed_by_quartile,
  ddd_hours_external = hours_ddd_external$table,
  ddd_hours_realized = hours_ddd_realized$table,
  # Editorial-audit rows (all aggregate: etable views or a handful of cells).
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
  # Only the two etable tables are taken here. hours_gender_placebo$cleaned_men is the full male
  # microdata frame (one row per surveyed person) and is deliberately NOT exported: it is a
  # data.frame, so export_all_results() would write it straight to outputs/ if the whole object
  # were passed. Same disclosure-risk logic as idpuf_panel_check and the age-balance pre_df.
  hours_gender_placebo_did_table  = hours_gender_placebo$result$table,
  hours_gender_placebo_ddd_table  = hours_gender_placebo$ddd_placebo$table,
  # Same cherry-pick, same reason: gender_placebo$cleaned_men is full male microdata.
  gender_placebo_did_table        = gender_placebo$result$table,
  gender_placebo_ddd_table        = gender_placebo$ddd_placebo$table,
  hours_did_subgroup_comparison   = hours_did_subgroup_comparison,
  hours_ddd_subgroup_comparison   = hours_ddd_subgroup_comparison,
  ddd_employment = employment_ddd_table,
  # Grade-report response rows (docs/decisions/grade-report-response.md). All aggregate.
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
  # Grade-report-2 rows (docs/decisions/grade-report-2-response.md). All aggregate: etable views, one-row coefficient frames, a 40-row occupation table, and the
  # per-quartile balance frame. hours_ddd_calib_men$index is the 40-row calibrated index.
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
  # The Imbens-Manski intervals (results_digest.md §7 item 2).
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
  # Only the aggregate pieces of each result -- balance_check$pre_df / age_balance_diag$pre_df are
  # row-level (one row per surveyed person) and deliberately excluded, same disclosure-risk logic
  # as idpuf_panel_check above.
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

# Paper figures, again and deliberately. export_all_results() has already written every plot above
# as an 8x5in 150dpi PNG for browsing; this second pass rewrites only the figures paper/paper.tex
# and paper/appendix.tex \includegraphics, as vector PDFs at the size they are printed at
# (~0.8\textwidth). Text sized for a 5in-wide PDF looks small in the 8in PNG -- expected; the PNG
# is not what compiles.
#
# Keys here are filenames: the .tex hard-codes ../outputs/figures/<key>.pdf, so renaming one
# breaks the LaTeX build, and adding one that the paper does not include leaves an orphan PDF in
# the repo. Every plot the paper has cut (the hours 2x2 panel, the two employment-by-child-age
# panels, the mobility series, the child-age forest plot, the mechanism scatter) is still on disk
# as a PNG; the reasons for each cut are in docs/decisions/paper-figure-layer.md and
# docs/ROADMAP.md's Checkpoint 15 (the 2026-09-23 structural cut).
message("Exporting paper figures (vector PDF) to outputs/figures/...")
paper_figures <- list(
  hours_by_year         = list(plot = hours_descriptives$plots$by_year,    width = 5.0, height = 5.0),
  # The two event studies sit a page apart and are read against each other, so they share a size;
  # both match hours_dose_response so no paper figure is scaled down further than its neighbours.
  hours_event_study     = list(plot = hours_event_study_plot$plot,         width = 5.0, height = 3.4),
  hours_ddd_event_study = list(plot = hours_ddd_event_study_plot$plot,     width = 5.0, height = 3.4),
  hours_dose_response   = list(plot = hours_dose_response$plot,            width = 5.0, height = 3.4),
  wfh_first_stage_occupation   = list(plot = wfh_occupation_first_stage$plot,   width = 5.0, height = 3.8)
)
# Forty labelled rows need the height; the width matches the rest so the text renders at the same size.
if (!is.null(hours_ddd_leave_one_out_plot)) {
  paper_figures$hours_ddd_leave_one_out <- list(plot = hours_ddd_leave_one_out_plot$plot, width = 5.0, height = 6.2)
}
if (RUN_PERMUTATION_TEST && !is.null(hours_permutation_plot)) {
  paper_figures$hours_permutation <- list(plot = hours_permutation_plot$plot, width = 5.0, height = 3.2)
}
export_paper_figures(paper_figures)

# Paper tables, generated from the fitted models (docs/decisions/grade-report-response.md, item
# C1). paper/paper.tex \input{}s these blocks inside its hand-written table floats, so every
# number in every table comes from this run; the keys are the filenames the .tex hard-codes.
message("Exporting paper tables (LaTeX tabular blocks) to paper/tables/...")
export_paper_tables(paper_tables)
