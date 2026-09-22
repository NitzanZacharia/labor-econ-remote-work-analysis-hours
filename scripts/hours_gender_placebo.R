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
source(file.path("scripts", "placebo_male_frame.R"))

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

  table_ddd <- NULL
  if (!is.null(model)) {
    check_for_dropped_coefficients(model, "run_hours_gender_ddd_placebo()'s triple interaction")
    table_ddd <- etable(model, headers = c("WorkHoursCont (hours DDD placebo, men)"), digits = 4)
    print(table_ddd)
  }

  list(n_employed = n_employed, n_matched = n_matched, model = model, table = table_ddd)
}

run_hours_gender_placebo <- function(folder_path, cleaned_men = NULL, exposure_index = NULL,
                                      exposure_csv_path = file.path("data", "israeli_cbs_wfh_2digit.csv")) {
  # exposure_index is already in the occupation_code/wfh_exposure shape this file's DDD wants, so
  # it is only rebuilt when absent -- the shared helper returns the calibrated table in its native
  # ISCO2/wfh_exposure_calibrated shape, reshaped below.
  inputs <- prepare_placebo_male_inputs(
    folder_path,
    cleaned_men         = cleaned_men,
    exposure_calibrated = NULL,
    exposure_csv_path   = exposure_csv_path,
    build_exposure      = is.null(exposure_index),
    caller              = "run_hours_gender_placebo"
  )
  cleaned_men <- inputs$cleaned_men

  if (is.null(exposure_index) && !is.null(inputs$exposure_calibrated)) {
    exposure_index <- inputs$exposure_calibrated %>%
      select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)
  }

  message("Running run_intensive_margin_reg() on the male subsample ('Mother' column read as ",
          "'has children <17' -- i.e. Father, for this population)...")
  result_hours <- run_intensive_margin_reg(cleaned_men)

  # ── DDD placebo: WorkHoursCont ~ Mother*Post*WFH_Exposure + controls, male subsample ─────────
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
