# Hours DiD and DDD on the male subsample, with "Mother" read as "Father". The occupation-level
# exposure index is sex-agnostic and reused unchanged.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "intensive_margin_regression.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "placebo_male_frame.R"))

# Fits the hours DDD on an already-cleaned male subsample.
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

  # Clustered on occupation, as run_hours_ddd_regression().
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
  # exposure_index is rebuilt only when absent.
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

  # DDD, male subsample
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
