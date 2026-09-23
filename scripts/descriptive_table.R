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
# Cluster-robust standard errors for the difference column (grade-report item T2). Each difference
# is the Mother coefficient of `y ~ Mother` clustered by IDPUF, so the point estimate is the plain
# cell difference -- the integrity rule clustered_se.R's header states for every descriptive.
source(file.path("scripts", "clustered_se.R"))

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
      hours_n    = sum(Employed == 1 & !is.na(WorkHoursCont)),
      mean_gilnk = mean(gilnk_num(GilNK), na.rm = TRUE),
      arab_share = mean(Leom == 2, na.rm = TRUE),
      .groups    = "drop"
    )

  # Standard error of each mothers-minus-childless difference, clustered by individual. The
  # frame carries the numeric versions of the two factor-coded measures so feols sees a number.
  se_frame <- cleaned_df %>%
    mutate(gilnk_num_col = gilnk_num(GilNK), arab_col = as.integer(Leom == 2))
  se_of <- function(data, formula) clustered_se(data, formula, "Mother")$se
  diff_se <- c(
    n_obs      = NA_real_,
    emp_rate   = se_of(se_frame, Employed ~ Mother),
    hours_mean = se_of(filter(se_frame, Employed == 1), WorkHoursCont ~ Mother),
    hours_sd   = NA_real_,
    hours_n    = NA_real_,
    mean_gilnk = se_of(se_frame, gilnk_num_col ~ Mother),
    arab_share = se_of(se_frame, arab_col ~ Mother)
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
    hours_n    = "Usual weekly hours (employed), N",
    mean_gilnk = "Age-group code (CBS 3-7), mean",
    arab_share = "Arab (share)"
  )

  continuous <- tibble(
    measure   = unname(measures),
    childless = map_dbl(names(measures), ~ pick(.x, 0)),
    mothers   = map_dbl(names(measures), ~ pick(.x, 1))
  ) %>%
    mutate(
      # A difference in row counts is not a comparison, so it is left blank rather than computed;
      # the same holds for the hours N row.
      difference = if_else(measure %in% c("Observations", "Usual weekly hours (employed), N"),
                           NA_real_, mothers - childless),
      se_difference = unname(diff_se[names(measures)])
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

    # Clustered SE of each level's share difference, in percentage points: the Mother coefficient
    # of an indicator regression, times 100. One small feols per level.
    categorical <- categorical %>%
      mutate(se_pct_difference = map2_dbl(variable, level, function(v, l) {
        ind_df <- cleaned_df %>%
          select(Mother, IDPUF, level_raw = all_of(v)) %>%
          filter(!is.na(level_raw)) %>%
          mutate(ind_col = as.integer(as.character(level_raw) == l))
        100 * clustered_se(ind_df, ind_col ~ Mother, "Mother")$se
      }))
  }

  # Level labels for the three controls the extract carries only as numeric CBS codes. Source:
  # H20231031Codebook.xlsx, shipped alongside the raw CBS CSVs (sheet "H20231031Codebook":
  # column F = variable, C = code, B = Hebrew label). The same parse reproduces
  # data_processing.R's TeudaGvoha grouping code for code, which is what validates the alignment.
  # English rendering confirmed by the authors, 2026-09-17. Dat is the religion of the household
  # head -- religion, not religiosity. TeudaGvoha is already labelled by data_processing.R, so
  # its level is its label; anything unmapped falls back to the raw code rather than NA.
  code_labels <- list(
    MatzavMishpachti = c(`1` = "Married", `2` = "Married, living separately", `3` = "Divorced",
                         `4` = "Widowed", `5` = "Single, never married"),
    Dat              = c(`1` = "Jewish", `2` = "Christian", `3` = "Muslim", `4` = "Druze",
                         `5` = "Other"),
    MachozMegurim    = c(`1` = "Jerusalem", `2` = "North", `3` = "Haifa", `4` = "Center",
                         `5` = "Tel Aviv", `6` = "South", `7` = "Judea and Samaria")
  )
  label_for <- function(v, l) {
    lk <- code_labels[[v]]
    if (is.null(lk)) return(l)
    out <- unname(lk[l])
    if (is.na(out)) l else out
  }
  categorical <- categorical %>%
    mutate(level_label = map2_chr(variable, level, label_for)) %>%
    relocate(level_label, .after = level)

  message("=== Descriptive statistics: categorical composition, by mother status ===")
  print(as.data.frame(categorical), digits = 4)

  invisible(list(
    continuous  = continuous,
    categorical = categorical
  ))
}
