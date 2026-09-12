#hours_gender_placebo
# Hours-outcome (intensive-margin) counterpart to gender_placebo.R's run_gender_placebo() /
# run_gender_ddd_placebo(), added for the hours pivot (docs/decisions/hours-ddd-pivot.md) so the
# project's now-primary dependent variable has the same gender-placebo validation coverage the
# old primary (Employed) DV already had. Reuses run_intensive_margin_reg() as-is: the "Mother"
# column is sex-agnostic in its derivation (1 if any children <17), so for this male subsample it's
# conceptually read as "Father" without any code/column rename -- same convention as
# gender_placebo.R.
#
# The DDD placebo below mirrors hours_ddd_regression.R's run_hours_ddd_regression(), NOT
# gender_placebo.R's run_gender_ddd_placebo(): the primary hours DDD's regressor is the PURE
# occupation-level WFH_Exposure (exposure_index), not the cell-based measure -- so, unlike
# run_gender_ddd_placebo(), this does not need to rebuild a cell-based exposure measure on the male
# subsample at all. Occupation-level exposure is sex-agnostic (an occupation's teleworkability
# doesn't depend on who's asked), so the same exposure_index built from women's data is reused
# unchanged, exactly as run_hours_ddd_regression() itself does.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "intensive_margin_regression.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))

# Pure function: fits the hours DDD placebo on an already-cleaned male subsample (restricted to
# Employed == 1, same as run_hours_ddd_regression()) plus an already-built occupation-level
# exposure index. Split out from run_hours_gender_placebo() so it can be unit-tested directly
# against a purpose-built synthetic panel (see test-hours_gender_placebo.R).
run_hours_gender_ddd_placebo <- function(cleaned_men, exposure_index, controls = DEFAULT_CONTROLS) {
  n_employed <- sum(cleaned_men$Employed == 1, na.rm = TRUE)

  df_ddd <- cleaned_men %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  n_matched <- nrow(df_ddd)
  message(sprintf(
    "run_hours_gender_ddd_placebo: %d of %d employed male rows (%.1f%%) matched an occupation-level WFH_Exposure.",
    n_matched, n_employed, if (n_employed > 0) 100 * n_matched / n_employed else NA
  ))
  if (n_matched == 0) {
    message("run_hours_gender_ddd_placebo: no employed male rows matched an occupation-level ",
            "exposure -- skipping the DDD placebo regression.")
    return(list(n_employed = n_employed, n_matched = 0, model = NULL))
  }

  # Clustered on occupation code, not IDPUF: WFH_Exposure here is occupation-constant, mirroring
  # run_hours_ddd_regression()'s own clustering choice (a Moulton problem otherwise).
  model <- tryCatch({
    formula_ddd <- as.formula(paste(
      "WorkHoursCont ~ Mother * Post * WFH_Exposure +", paste(controls, collapse = " + ")
    ))
    feols(formula_ddd, data = df_ddd, cluster = ~MishlachYad_ISCO_08_2, notes = FALSE)
  }, error = function(e) {
    message("run_hours_gender_ddd_placebo: model fit failed (", conditionMessage(e), ") -- likely ",
            "too few matched/identified observations. Returning NULL.")
    NULL
  })

  if (!is.null(model)) {
    check_for_dropped_coefficients(model, "run_hours_gender_ddd_placebo()'s triple interaction")
    print(etable(model, headers = c("WorkHoursCont (hours DDD placebo, men)"), digits = 4))
  }

  list(n_employed = n_employed, n_matched = n_matched, model = model)
}

run_hours_gender_placebo <- function(folder_path, cleaned_men = NULL, exposure_index = NULL,
                                      exposure_csv_path = file.path("data", "israeli_cbs_wfh_2digit.csv")) {
  if (is.null(cleaned_men)) {
    message("Loading data for men (sex_filter = 'men')...")
    cleaned_men <- load_and_clean_data(folder_path, sex_filter = "men")
    message("Validating cleaned data (male subsample)...")
    validate_cleaned_df(cleaned_men, sex_filter = "men")
  }

  # Human gate (same convention as gender_placebo.R's run_gender_placebo()): report category sizes
  # only -- a category that's sparse for women may be near-empty for men. Whether a sparse category
  # needs collapsing is a modeling decision for the researchers, not something this function decides
  # unilaterally.
  message("=== Regression control category sizes, male subsample (report only) ===")
  for (col in DEFAULT_CONTROLS) {
    message("--- ", col, " ---")
    print(table(cleaned_men[[col]], useNA = "ifany"))
  }

  message("Running run_intensive_margin_reg() on the male subsample ('Mother' column read as ",
          "'has children <17' -- i.e. Father, for this population)...")
  result_hours <- run_intensive_margin_reg(cleaned_men)

  # ── DDD placebo: WorkHoursCont ~ Mother*Post*WFH_Exposure + controls, male subsample ─────────
  # exposure_index is occupation-level and sex-agnostic -- if the caller already has one (e.g.
  # main.R's own exposure_calibrated, reshaped to occupation_code/wfh_exposure), pass it in
  # directly to avoid recomputing it. Otherwise build it here from a women's sample + the external
  # CSV, mirroring gender_placebo.R's own fallback logic.
  if (is.null(exposure_index)) {
    if (!file.exists(exposure_csv_path)) {
      message("run_hours_gender_placebo: no exposure_index supplied and '", exposure_csv_path,
              "' not found from the current working directory -- skipping the DDD placebo. Pass ",
              "exposure_index directly (e.g. main.R's own exposure_calibrated, reshaped) or set ",
              "exposure_csv_path if running from somewhere other than the project root.")
    } else {
      women_rds <- file.path(folder_path, "cleaned_df.rds")
      cleaned_women <- if (file.exists(women_rds)) {
        message("Loading cached women's data (for the occupation-level exposure index)...")
        readRDS(women_rds)
      } else {
        message("No cached women's data found -- loading and cleaning it (sex_filter = 'women')...")
        load_and_clean_data(folder_path, sex_filter = "women")
      }
      message("Building occupation-level calibrated WFH exposure (from women's realized 2022-23 WFH)...")
      exposure_external   <- build_exposure_isco2(path = exposure_csv_path)
      exposure_calibrated <- calibrate_isco_exposure(cleaned_women, exposure_external)
      exposure_index <- exposure_calibrated %>%
        select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)
    }
  }

  ddd_placebo <- NULL
  if (!is.null(exposure_index)) {
    message("Running hours DDD placebo (WorkHoursCont ~ Mother*Post*WFH_Exposure + controls), male subsample...")
    ddd_placebo <- run_hours_gender_ddd_placebo(cleaned_men, exposure_index)
  }

  invisible(list(
    cleaned_men = cleaned_men,
    result      = result_hours,
    ddd_placebo = ddd_placebo
  ))
}
