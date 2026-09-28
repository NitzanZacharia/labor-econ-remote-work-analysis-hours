# isco_masking_diagnostics.R
# Proxy check on the disclosure-masked occupation rows the exposure index drops: compare realized
# WFH between masked and unmasked rows within the same ISCO1 major group, which a partially masked
# code ("7X") still identifies.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))

check_isco_masking_sensitivity <- function(cleaned_df, wfh_col = "WFH", ref_year = c(2022, 2023)) {

  df <- cleaned_df %>%
    filter(
      ShnatSeker %in% ref_year,
      Employed == 1,
      !is.na(ISCO1),               # fully masked rows carry no signal
      !is.na(.data[[wfh_col]])
    ) %>%
    mutate(mask_label = if_else(ISCO_masked, "masked", "unmasked"))

  # complete() keeps both mask levels for every ISCO1 group so the wide comparison never lacks a column.
  by_group <- df %>%
    group_by(ISCO1, mask_label) %>%
    summarise(mean_wfh = mean(.data[[wfh_col]]), n = n(), .groups = "drop") %>%
    tidyr::complete(ISCO1, mask_label = c("masked", "unmasked"), fill = list(n = 0L))

  comparison_wide <- by_group %>%
    pivot_wider(names_from = mask_label, values_from = c(mean_wfh, n)) %>%
    mutate(gap = mean_wfh_masked - mean_wfh_unmasked) %>%
    arrange(desc(abs(gap)))

  message("check_isco_masking_sensitivity: realized WFH, masked vs. unmasked, by ISCO1 major group:")
  print(as.data.frame(comparison_wide), digits = 3)

  # Within-group test: masking status on WFH with ISCO1 fixed effects. Skipped on fewer than two rows.
  reg <- NULL
  if (nrow(df) < 2) {
    message(sprintf(
      "check_isco_masking_sensitivity: only %d row(s) survived the ref_year/Employed/ISCO1/%s ",
      nrow(df), wfh_col
    ), "filters -- too few to fit the within-group regression. Skipping (model = NULL); the ",
    "descriptive comparison_wide table above still stands.")
  } else {
    reg <- feols(as.formula(paste(wfh_col, "~ ISCO_masked | ISCO1")), data = df, cluster = ~IDPUF)
    print(etable(reg, headers = c("WFH ~ ISCO_masked | ISCO1 (within-group masking gap)"), digits = 4))
  }

  invisible(list(
    by_group        = by_group,
    comparison_wide = comparison_wide,
    model           = reg
  ))
}
