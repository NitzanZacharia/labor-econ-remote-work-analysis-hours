# descriptive_table.R
# Table 1 for the paper: summary statistics for the analysis sample, split by mother status.
#
# Why this exists as its own script rather than a slice of an existing artifact: nothing in
# outputs/ gives the demographic composition of the analysis sample by Mother.
# comparative_statistics.R's emp_by_mother covers the employment rate only; hours_diagnostics.R's
# hours_by_period is a Mother x Post 2x2 of the outcome; and robustness/balance_test.R's
# cat_distributions -- the one place categorical composition is computed -- is restricted to the
# pre-period and broken out by WFH-exposure quartile, so it cannot serve as a whole-sample Table 1.
#
# Descriptive only: nothing here feeds a regression. Consistent with the rest of the project, all
# figures are UNWEIGHTED (CBS survey weights are deliberately not applied -- see README's "Known
# limitations"), so these describe the analysis sample, not the Israeli population.
library(tidyverse)

# DEFAULT_CONTROLS is the single source of truth for the control set (scripts/data_processing.R);
# sourced here so this file also works when loaded on its own, not just via main.R.
source(file.path("scripts", "data_processing.R"))

build_descriptive_table <- function(cleaned_df) {

  stopifnot(is.data.frame(cleaned_df), "Mother" %in% names(cleaned_df))

  # The categorical controls are the regression's own control set minus GilNK. GilNK is an ordinal
  # age-group code, summarised as a mean in the continuous panel instead of level by level.
  cat_vars <- setdiff(DEFAULT_CONTROLS, "GilNK")

  # data_processing.R casts GilNK to a factor along with the other categorical controls, so a mean
  # needs the ordinal code back. Same idiom as robustness/balance_test.R and
  # robustness/age_balance_robustness.R, which treat GilNK as ordinal numeric for exactly this.
  gilnk_num <- function(x) as.numeric(as.character(x))

  # ── 1. Continuous / share measures, by mother status ───────────────────────
  by_mother <- cleaned_df %>%
    group_by(Mother) %>%
    summarise(
      n_obs      = n(),
      emp_rate   = mean(Employed, na.rm = TRUE),
      hours_mean = mean(WorkHoursCont[Employed == 1], na.rm = TRUE),
      hours_sd   = sd(WorkHoursCont[Employed == 1], na.rm = TRUE),
      mean_gilnk = mean(gilnk_num(GilNK), na.rm = TRUE),
      arab_share = mean(Leom == 2, na.rm = TRUE),
      .groups    = "drop"
    )

  # Pull one cell, tolerating an absent Mother level (a fixture or subsample may hold only one).
  pick <- function(col, m) {
    v <- by_mother[[col]][by_mother$Mother == m]
    if (length(v) == 0) NA_real_ else as.numeric(v)
  }

  measures <- c(
    n_obs      = "Observations",
    emp_rate   = "Employment rate",
    hours_mean = "Usual weekly hours (employed), mean",
    hours_sd   = "Usual weekly hours (employed), SD",
    mean_gilnk = "Age-group code (CBS 3-7), mean",
    arab_share = "Arab (share)"
  )

  continuous <- tibble(
    measure   = unname(measures),
    childless = map_dbl(names(measures), ~ pick(.x, 0)),
    mothers   = map_dbl(names(measures), ~ pick(.x, 1))
  ) %>%
    mutate(
      # A difference in row counts is not a comparison, so it is left blank rather than computed.
      difference = if_else(measure == "Observations", NA_real_, mothers - childless)
    )

  message("=== Descriptive statistics: continuous measures, by mother status ===")
  print(as.data.frame(continuous), digits = 4)

  # ── 2. Categorical composition, by mother status ───────────────────────────
  # Percentages are within-column (each mother group's levels sum to 100), so the two columns are
  # read as two compositions to compare, not as a split of one total.
  categorical <- lapply(cat_vars, function(v) {
    cleaned_df %>%
      select(Mother, level_raw = all_of(v)) %>%
      filter(!is.na(level_raw)) %>%
      mutate(level = as.character(level_raw)) %>%
      count(Mother, level, name = "n") %>%
      group_by(Mother) %>%
      mutate(pct = n / sum(n) * 100) %>%
      ungroup() %>%
      mutate(variable = v)
  }) %>%
    bind_rows() %>%
    pivot_wider(
      id_cols     = c(variable, level),
      names_from  = Mother,
      values_from = c(n, pct),
      names_glue  = "{.value}_mother{Mother}"
    ) %>%
    arrange(variable, level)

  if (all(c("pct_mother1", "pct_mother0") %in% names(categorical))) {
    categorical <- categorical %>%
      mutate(pct_difference = pct_mother1 - pct_mother0)
  }

  message("=== Descriptive statistics: categorical composition, by mother status ===")
  print(as.data.frame(categorical), digits = 4)

  invisible(list(
    continuous  = continuous,
    categorical = categorical
  ))
}
