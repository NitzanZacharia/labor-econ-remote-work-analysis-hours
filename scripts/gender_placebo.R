# Checkpoint 5 (docs/ROADMAP.md): the Gender Placebo Test from the research doc (Part 2 §3 /
# Part 4 §5) -- replicates the primary DiD model on men (fathers vs. childless men) instead of
# women, to test whether the observed effect is specifically a *motherhood* penalty rather than a
# general *parenthood* or macro shift. Reuses basic_reg() as-is: the "Mother" column (1 if any
# children <17) is sex-agnostic in its derivation, so for this male subsample it's conceptually
# read as "Father" without any code/column rename.
#
# Extended for the DDD placebo (Mother*Post*WFH_Exposure): the two-way basic_reg() placebo above
# tests whether *any* Mother:Post effect exists for men; it says nothing about whether men's
# employment response also happens to track occupational WFH exposure, which is what the primary
# DDD (main.R's ddd_employment_additive / ddd_employment_fe) actually claims. WFH_Exposure itself
# is occupation-level, not sex-specific, so the same calibrated occupation scores
# (exposure_calibrated, built from WOMEN's realized 2022-23 WFH -- see wfh_exposure_cells.R) are
# reused unchanged as the measurement instrument; only
# the cell shift-share weights are rebuilt on men's own pre-period (2017-2019) occupation
# composition, via build_exposure_cells(cleaned_men, ...). This holds "how exposed is this
# occupation" fixed and swaps only the population being tested, which is what a placebo requires.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "basic_regression.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))
source(file.path("scripts", "placebo_male_frame.R"))

# Pure function: fits the DDD placebo (both the additive and interacted-cell-FE specs from
# main.R's ddd_employment_additive / ddd_employment_fe) on an already-cleaned male subsample plus
# an already-built occupation-level calibrated exposure table. Split out from
# run_gender_placebo() so it can be unit-tested directly
# against a purpose-built synthetic panel (see test-gender_placebo.R), independent of the real CSV
# read and of load_and_clean_data()'s file-based fixtures, which are sized for schema/parsing
# tests, not for a fully-saturated triple-interaction formula to be identified.
run_gender_ddd_placebo <- function(cleaned_men, exposure_calibrated, controls = DEFAULT_CONTROLS) {
  cell_fe_vars   <- c("GilNK", "TeudaGvoha", "MachozMegurim")
  other_controls <- setdiff(controls, cell_fe_vars)

  exposure_cells_men <- build_exposure_cells(
    cleaned_men,
    exposure_calibrated %>% select(ISCO2, tele_ext = wfh_exposure_calibrated)
  )

  ddd_df_men <- cleaned_men %>%
    left_join(exposure_cells_men, by = c("Min", "GilNK", "TeudaGvoha", "MachozMegurim"))

  n_total   <- nrow(ddd_df_men)
  n_matched <- sum(!is.na(ddd_df_men$WFH_Exposure))
  message(sprintf(
    "run_gender_ddd_placebo: %d of %d male rows (%.1f%%) matched an exposure cell.",
    n_matched, n_total, if (n_total > 0) 100 * n_matched / n_total else NA
  ))
  if (n_matched == 0) {
    message("run_gender_ddd_placebo: no male rows matched an exposure cell -- skipping the DDD ",
            "placebo regressions.")
    return(NULL)
  }

  # Small/thin subsamples (e.g. a test fixture, or a real but sparsely-matched cell structure) can
  # leave a formula unidentified -- a constant factor level, a singular clustered-vcov matrix, etc.
  # (the same class of failure wfh_exposure_cells.R's calibrate_isco_exposure() already documents
  # for ISCO 63). Caught explicitly and reported per-spec rather than letting one bad spec take
  # down the whole function.
  #
  # Clustered on the same (GilNK, TeudaGvoha, MachozMegurim) cell as main.R's primary DDD, not
  # IDPUF: WFH_Exposure here is cell-constant (from build_exposure_cells()), so individual-level
  # clustering would understate the SE the same way it would in the primary spec -- this placebo
  # is supposed to mirror main.R's spec structure exactly (see header comment above).
  cluster_formula <- as.formula(paste("~", paste(cell_fe_vars, collapse = "^")))
  fit <- function(formula_rhs, fe = NULL) {
    tryCatch({
      f <- if (is.null(fe)) as.formula(paste("Employed ~", formula_rhs))
           else as.formula(paste("Employed ~", formula_rhs, "|", fe))
      feols(f, data = ddd_df_men, cluster = cluster_formula, notes = FALSE)
    }, error = function(e) {
      message("run_gender_ddd_placebo: model fit failed (", conditionMessage(e), ") -- likely too ",
              "few matched/identified observations for this formula. Returning NULL for this spec.")
      NULL
    })
  }

  additive <- fit(paste("Mother * Post * WFH_Exposure +", paste(controls, collapse = " + ")))
  fe       <- fit(paste("Mother * Post * WFH_Exposure +", paste(other_controls, collapse = " + ")),
                   fe = paste(cell_fe_vars, collapse = "^"))

  # The etable is returned as $table, not just printed, so main.R can export it -- mirroring
  # run_hours_gender_ddd_placebo(). Without this the employment placebo ran on every pipeline pass
  # and still left no artifact, which is how results_digest.md §7 item 7 came to record it as
  # having no exported result.
  table_ddd <- NULL
  models_ok <- Filter(Negate(is.null), list(additive = additive, fe = fe))
  if (length(models_ok) > 0) {
    hdrs <- c(additive = "Placebo Spec 1: additive controls",
              fe       = "Placebo Spec 2: interacted cell FE")[names(models_ok)]
    table_ddd <- do.call(etable, c(models_ok, list(headers = unname(hdrs), digits = 4)))
    print(table_ddd)
  } else {
    message("run_gender_ddd_placebo: neither DDD placebo spec could be fit.")
  }

  list(exposure_cells_men = exposure_cells_men,
       models = list(additive = additive, fe = fe),
       table  = table_ddd)
}

run_gender_placebo <- function(folder_path, cleaned_men = NULL, cleaned_women = NULL,
                                exposure_calibrated = NULL,
                                exposure_csv_path = file.path("data", "israeli_cbs_wfh_2digit.csv")) {
  inputs <- prepare_placebo_male_inputs(
    folder_path,
    cleaned_men         = cleaned_men,
    cleaned_women       = cleaned_women,
    exposure_calibrated = exposure_calibrated,
    exposure_csv_path   = exposure_csv_path,
    caller              = "run_gender_placebo"
  )
  cleaned_men         <- inputs$cleaned_men
  exposure_calibrated <- inputs$exposure_calibrated

  message("Running basic_reg() on the male subsample ('Mother' column read as 'has children <17' ",
          "-- i.e. Father, for this population)...")
  result_basic <- basic_reg(cleaned_men)

  # ── DDD placebo: Employed ~ Mother*Post*WFH_Exposure + controls, male subsample ─────────────
  # Skipped rather than errored when no exposure table could be built, so this function's original
  # (Checkpoint 5) contract -- always returns cleaned_men/result -- still holds unconditionally.
  ddd_placebo <- NULL
  if (!is.null(exposure_calibrated)) {
    message("Running DDD placebo (Employed ~ Mother*Post*WFH_Exposure + controls), male subsample...")
    ddd_placebo <- run_gender_ddd_placebo(cleaned_men, exposure_calibrated)
  }

  invisible(list(
    cleaned_men = cleaned_men,
    result      = result_basic,
    ddd_placebo = ddd_placebo
  ))
}
