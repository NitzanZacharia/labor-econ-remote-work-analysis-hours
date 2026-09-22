# Shared setup for the two gender-placebo runners (gender_placebo.R's run_gender_placebo() and
# hours_gender_placebo.R's run_hours_gender_placebo()). Both need the same three things before they
# can fit anything -- a cleaned+validated male subsample, a printed control-category report, and an
# occupation-level calibrated exposure table -- and the two copies of that scaffolding had drifted
# apart in wording while staying identical in behaviour.
#
# Only the setup is shared. The regressions themselves are deliberately NOT merged: they differ in
# outcome (Employed vs. WorkHoursCont), in exposure measure (cell-based vs. pure occupation-level),
# and in clustering (GilNK^TeudaGvoha^MachozMegurim vs. MishlachYad_ISCO_08_2). Those are real
# specification differences, not duplication -- see each runner's own header comment.
library(tidyverse)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))

# Returns list(cleaned_men, exposure_calibrated). exposure_calibrated is NULL when it could not be
# built, which both callers treat as "skip the DDD placebo" rather than an error -- that keeps
# run_gender_placebo()'s original (Checkpoint 5) contract of always returning cleaned_men/result.
#
# `caller` only labels the messages, so a reader of a `Rscript main.R` log can tell which of the two
# placebos is talking.
#
# `build_exposure = FALSE` skips the exposure step entirely, for a caller that already holds an
# exposure table in a different shape (run_hours_gender_placebo() takes occupation_code/wfh_exposure,
# not ISCO2/wfh_exposure_calibrated). Without it, that caller would rebuild -- and reload the
# women's cached RDS -- for a result it then discards.
prepare_placebo_male_inputs <- function(folder_path,
                                        cleaned_men = NULL,
                                        cleaned_women = NULL,
                                        exposure_calibrated = NULL,
                                        exposure_csv_path = file.path("data", "israeli_cbs_wfh_2digit.csv"),
                                        build_exposure = TRUE,
                                        caller = "gender placebo") {
  # cleaned_men is accepted rather than always reloaded: once main.R calls either placebo in the
  # default pipeline it already holds a cleaned male frame (built for the exposure population), and
  # reloading it from the raw CSVs would repeat the single most expensive step in the run for no
  # gain. Passing NULL keeps the standalone behaviour.
  if (is.null(cleaned_men)) {
    message("Loading data for men (sex_filter = 'men')...")
    cleaned_men <- load_and_clean_data(folder_path, sex_filter = "men")

    message("Validating cleaned data (male subsample)...")
    validate_cleaned_df(cleaned_men, sex_filter = "men")
  }

  # Human gate (Checkpoint 5, docs/ROADMAP.md): report category sizes only -- a category that's
  # sparse for women (e.g. single-father counts in MisparHorimYechidim) may be near-empty for men.
  # Whether a sparse category needs collapsing is a modeling decision for the researchers, not
  # something this function decides unilaterally.
  message("=== Regression control category sizes, male subsample (report only) ===")
  for (col in DEFAULT_CONTROLS) {
    message("--- ", col, " ---")
    print(table(cleaned_men[[col]], useNA = "ifany"))
  }

  # exposure_calibrated is an occupation-level attribute, not a sex-specific one -- if the caller
  # already has one (e.g. main.R's own exposure_calibrated), it is passed straight through. Otherwise
  # build it from a women's sample (cached RDS if present, else a fresh load) + the external CSV.
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
