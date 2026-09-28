# Shared setup for the two fathers'-comparison runners: a cleaned and validated male subsample, a
# control-category report, and the calibrated exposure table.
library(tidyverse)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))

# exposure_calibrated is NULL when it could not be built; build_exposure = FALSE skips that step
# for a caller that already holds an exposure table.
prepare_placebo_male_inputs <- function(folder_path,
                                        cleaned_men = NULL,
                                        cleaned_women = NULL,
                                        exposure_calibrated = NULL,
                                        exposure_csv_path = file.path("data", "israeli_cbs_wfh_2digit.csv"),
                                        build_exposure = TRUE,
                                        caller = "gender placebo") {
  # A preloaded cleaned_men avoids reloading the raw CSVs.
  if (is.null(cleaned_men)) {
    message("Loading data for men (sex_filter = 'men')...")
    cleaned_men <- load_and_clean_data(folder_path, sex_filter = "men")

    message("Validating cleaned data (male subsample)...")
    validate_cleaned_df(cleaned_men, sex_filter = "men")
  }

  # Report control-category sizes for the male subsample.
  message("=== Regression control category sizes, male subsample (report only) ===")
  for (col in DEFAULT_CONTROLS) {
    message("--- ", col, " ---")
    print(table(cleaned_men[[col]], useNA = "ifany"))
  }

  # The exposure table is passed through when supplied; otherwise built from women's data and the
  # external CSV.
  if (is.null(exposure_calibrated) && isTRUE(build_exposure)) {
    if (!file.exists(exposure_csv_path)) {
      message(caller, ": no exposure table supplied and '", exposure_csv_path,
              "' not found from the current working directory -- skipping the DDD placebo. Pass ",
              "the exposure table directly (e.g. main.R's own exposure_calibrated) or set ",
              "exposure_csv_path if running from somewhere other than the project root.")
    } else {
      if (is.null(cleaned_women)) {
        women_rds <- file.path(folder_path, "cleaned_df.rds")
        if (file.exists(women_rds)) {
          message("Loading cached women's data (for the occupation-level calibrated exposure score)...")
          cleaned_women <- readRDS(women_rds)
        } else {
          message("No cached women's data found -- loading and cleaning it (sex_filter = 'women')...")
          cleaned_women <- load_and_clean_data(folder_path, sex_filter = "women")
        }
      }
      message("Building occupation-level calibrated WFH exposure (from women's realized 2022-23 WFH)...")
      exposure_external   <- build_exposure_isco2(path = exposure_csv_path)
      exposure_calibrated <- calibrate_isco_exposure(cleaned_women, exposure_external)
    }
  }

  list(cleaned_men = cleaned_men, exposure_calibrated = exposure_calibrated)
}
