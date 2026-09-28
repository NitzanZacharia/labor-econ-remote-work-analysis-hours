# wfh_exposure_index.R
# Realized WFH share by occupation in the anchor year (2021): measured after treatment, so a bound
# rather than the baseline. Build it from a frame wider than the analysis sample.
library(tidyverse)
source(file.path("scripts", "data_processing.R"))

build_wfh_exposure_index <- function(cleaned_df, isco_col = "MishlachYad_ISCO_08_2",
                                     wfh_col = "WFH", ref_year = 2021,
                                     weight_col = NULL, min_n = 0) {

  # Anchor year, employed, known occupation and WFH status.
  df_year <- cleaned_df %>%
    filter(
      ShnatSeker %in% ref_year,
      Employed == 1,
      !is.na(.data[[isco_col]]),
      !is.na(.data[[wfh_col]])
    )

  # Report how many anchor-year rows carry a disclosure-masked occupation code.
  if ("ISCO_masked" %in% names(cleaned_df)) {
    anchor <- filter(cleaned_df, ShnatSeker %in% ref_year, Employed == 1)
    n_masked <- sum(anchor$ISCO_masked, na.rm = TRUE)
    if (n_masked > 0) {
      years_str <- paste(ref_year, collapse = "-")
      message(sprintf(
        "build_wfh_exposure_index: %d of %d employed %s rows (%.1f%%) have a disclosure-masked ISCO code.",
        n_masked, nrow(anchor), years_str, 100 * n_masked / nrow(anchor)
      ))
    }
  }

  idx <- df_year %>%
    group_by(occupation_code = .data[[isco_col]]) %>%
    summarise(
      wfh_exposure = if (is.null(weight_col)) {
        mean(.data[[wfh_col]])
      } else {
        weighted.mean(.data[[wfh_col]], .data[[weight_col]], na.rm = TRUE)
      },
      n            = n(),
      .groups      = "drop"
    ) %>%
    arrange(desc(wfh_exposure))

  # min_n drops occupations too thin to carry a stable share (200 in main.R).
  if (min_n > 0) {
    n_thin <- sum(idx$n < min_n)
    if (n_thin > 0) {
      message(sprintf("build_wfh_exposure_index: dropping %d occupation(s) with n < %d.",
                      n_thin, min_n))
    }
    idx <- filter(idx, n >= min_n)
  }

  idx
}
