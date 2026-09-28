library(tidyverse)
library(fixest)

# The external (Dingel & Neiman) teleworkability score by two-digit ISCO-08.
build_exposure_isco2 <- function(path = file.path("data", "israeli_cbs_wfh_2digit.csv")) {
  read_csv(path, show_col_types = FALSE) %>%
    transmute(ISCO2 = as.numeric(isco_2digit), tele_ext = wfh_probability_2d) %>%
    filter(!is.na(tele_ext))
}

# Replaces the external score with the realized 2022-23 Israeli WFH share where Israeli practice
# diverges from the US task-based prediction (teaching: 0.966 external, 0.063 realized). The swap
# requires the gap to exceed gap_threshold by more than the realized share's cluster-robust
# sampling uncertainty (one-sided test at conf_level), so a thin occupation cannot swap on a
# handful of observations.
calibrate_isco_exposure <- function(cleaned_df, exposure_isco2, wfh_col = "WFH",
                                    ref_year = c(2022, 2023), gap_threshold = 0.5,
                                    conf_level = 0.95) {

  df <- cleaned_df %>%
    filter(
      ShnatSeker %in% ref_year,
      Employed == 1,
      !is.na(MishlachYad_ISCO_08_2),
      !is.na(.data[[wfh_col]])
    ) %>%
    mutate(ISCO2 = MishlachYad_ISCO_08_2)

  z <- qnorm(conf_level)

  # A cluster-robust SE is undefined with fewer than two IDPUFs or a constant outcome; those
  # occupations keep the external value. Other fixest errors are reported, not swallowed.
  realized <- df %>%
    group_by(ISCO2) %>%
    group_modify(~ {
      n <- nrow(.x)
      p <- mean(.x[[wfh_col]])
      se_clustered <- NA_real_
      se_na_reason <- NA_character_
      if (n_distinct(.x$IDPUF) < 2) {
        se_na_reason <- "fewer than 2 distinct IDPUF"
      } else if (n_distinct(.x[[wfh_col]]) < 2) {
        se_na_reason <- "constant outcome within occupation"
      } else {
        se_clustered <- tryCatch({
          m <- feols(as.formula(paste(wfh_col, "~ 1")), data = .x, cluster = ~IDPUF, notes = FALSE)
          unname(se(m)["(Intercept)"])
        }, error = function(e) {
          se_na_reason <<- paste("unexpected fixest error:", conditionMessage(e))
          NA_real_
        })
      }
      tibble(n = n, realized_wfh = p, se_clustered = se_clustered, se_na_reason = se_na_reason)
    }) %>%
    ungroup()

  undefined <- filter(realized, is.na(se_clustered))
  if (nrow(undefined) > 0) {
    message(sprintf(
      "calibrate_isco_exposure: %d of %d occupations kept at their theoretical value (no cluster-robust SE could be computed):",
      nrow(undefined), nrow(realized)
    ))
    print(as.data.frame(select(undefined, ISCO2, n, se_na_reason)))
  }

  exposure_isco2 %>%
    left_join(realized, by = "ISCO2") %>%
    mutate(
      gap    = abs(realized_wfh - tele_ext),
      margin = gap - z * se_clustered - gap_threshold,
      swap   = !is.na(margin) & margin > 0,
      wfh_exposure_calibrated = if_else(swap, realized_wfh, tele_ext)
    ) %>%
    arrange(desc(gap))
}

# Pre-period (2017-2019) shift-share exposure by demographic cell: the calibrated occupation score
# averaged over each cell's occupational composition.
build_exposure_cells <- function(raw_all, exposure_isco2,
                                 cell_vars = c("Min", "GilNK", "TeudaGvoha", "MachozMegurim")) {
  raw_all %>%
    filter(ShnatSeker %in% 2017:2019, Muasak == 1, !is.na(MishlachYad_ISCO_08_2)) %>%
    mutate(ISCO2 = suppressWarnings(as.numeric(MishlachYad_ISCO_08_2))) %>%
    filter(!is.na(ISCO2)) %>%
    count(across(all_of(cell_vars)), ISCO2, wt = MishkalSofi, name = "w") %>%
    left_join(exposure_isco2 %>% select(ISCO2, tele_ext), by = "ISCO2") %>%
    filter(!is.na(tele_ext)) %>%
    group_by(across(all_of(cell_vars))) %>%
    summarise(
      WFH_Exposure = weighted.mean(tele_ext, w),
      n_cell       = sum(w),
      .groups      = "drop"
    )
}
