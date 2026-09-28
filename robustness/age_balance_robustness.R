# age_balance_robustness.R
# Age-balance robustness chain. GilNK (age group) is imbalanced between mothers and non-mothers
# in the pre-period, and the gap varies by exposure quartile. Two comparison specifications for
# each DDD: Mother:GilNK added to the formula, and pre-period raking weights that equalize each
# Mother group's GilNK distribution within exposure quartile. Quartile edges are computed once on
# the pre-period rows and applied everywhere.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "occupation_exposure_breaks.R"))
source(file.path("scripts", "assign_wfh_quartile.R"))

compute_pre_period_quartile_breaks <- function(cleaned_df, exposure_cells) {
  # Join keys are derived from exposure_cells' own columns.
  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  cleaned_df %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    compute_occupation_exposure_breaks(caller = "compute_pre_period_quartile_breaks")
}

# 1. Age gap by Mother status, per exposure quartile
diagnose_gilnk_by_quartile <- function(cleaned_df, exposure_cells) {
  gilnk_num <- function(x) as.numeric(as.character(x))
  breaks <- compute_pre_period_quartile_breaks(cleaned_df, exposure_cells)

  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  pre_df <- cleaned_df %>%
    filter(ShnatSeker < 2020) %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    filter(!is.na(WFH_Exposure)) %>%
    assign_wfh_quartile(breaks)

  gap <- pre_df %>%
    group_by(WFH_Exposure_Q) %>%
    group_modify(~ {
      tt <- t.test(gilnk_num(GilNK) ~ Mother, data = .x)
      # Sign flipped to Mother 1 minus 0.
      tibble(
        mean_GilNK_Mother0 = unname(tt$estimate[1]),
        mean_GilNK_Mother1 = unname(tt$estimate[2]),
        gap_Mother1_minus_0 = unname(tt$estimate[2] - tt$estimate[1]),
        t_stat = -unname(tt$statistic),
        p_value = tt$p.value,
        n = nrow(.x)
      )
    }) %>%
    ungroup()

  message("=== GilNK (age-group) gap by Mother status, per WFH_Exposure quartile (pre-period) ===")
  print(gap)

  invisible(list(gap_by_quartile = gap, breaks = breaks, pre_df = pre_df))
}

# 2. Employment DDD with Mother:GilNK added
run_ddd_age_interacted <- function(cleaned_df, exposure_cells, controls = DEFAULT_CONTROLS) {
  cell_fe_vars   <- c("GilNK", "TeudaGvoha", "MachozMegurim")
  other_controls <- setdiff(controls, cell_fe_vars)
  # Clustered on the cell the regressor varies at.
  cluster_formula <- as.formula(paste("~", paste(cell_fe_vars, collapse = "^")))

  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  ddd_df <- cleaned_df %>%
    left_join(exposure_cells, by = exposure_join_vars)

  additive <- feols(
    as.formula(paste("Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                      paste(controls, collapse = " + "))),
    data = ddd_df, cluster = cluster_formula
  )
  # Mother:GilNK is not absorbed by the cell FE.
  fe <- feols(
    as.formula(paste("Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                      paste(other_controls, collapse = " + "),
                      "|", paste(cell_fe_vars, collapse = "^"))),
    data = ddd_df, cluster = cluster_formula
  )

  print(etable(additive, fe,
               headers = c("Age-interacted Spec 1: additive", "Age-interacted Spec 2: cell FE"),
               digits = 4))

  invisible(list(additive = additive, fe = fe))
}

# 3. Raking weights on GilNK within exposure quartile, from the pre-period
build_gilnk_rake_weights <- function(cleaned_df, exposure_cells) {
  breaks <- compute_pre_period_quartile_breaks(cleaned_df, exposure_cells)

  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  pre_df <- cleaned_df %>%
    filter(ShnatSeker < 2020) %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    filter(!is.na(WFH_Exposure)) %>%
    assign_wfh_quartile(breaks)

  # Target: the pooled (both Mother groups) GilNK distribution within each quartile.
  target <- pre_df %>%
    count(WFH_Exposure_Q, GilNK, name = "n_target") %>%
    group_by(WFH_Exposure_Q) %>%
    mutate(p_target = n_target / sum(n_target)) %>%
    ungroup()

  own <- pre_df %>%
    count(WFH_Exposure_Q, Mother, GilNK, name = "n_own") %>%
    group_by(WFH_Exposure_Q, Mother) %>%
    mutate(p_own = n_own / sum(n_own)) %>%
    ungroup()

  weights_tbl <- own %>%
    left_join(target %>% select(WFH_Exposure_Q, GilNK, p_target), by = c("WFH_Exposure_Q", "GilNK")) %>%
    mutate(rake_weight = p_target / p_own)

  extreme <- filter(weights_tbl, rake_weight > 10 | rake_weight < 0.1)
  if (nrow(extreme) > 0) {
    message(sprintf(
      "build_gilnk_rake_weights: %d of %d (quartile x Mother x GilNK) cells have an extreme raking weight (<0.1 or >10):",
      nrow(extreme), nrow(weights_tbl)
    ))
    print(as.data.frame(select(extreme, WFH_Exposure_Q, Mother, GilNK, n_own, p_own, p_target, rake_weight)))
  }

  list(weights = weights_tbl %>% select(WFH_Exposure_Q, Mother, GilNK, rake_weight), breaks = breaks)
}

# 4. Hours analogs: occupation-level exposure as regressor, clustered on occupation; the cell
# quartiles serve only to assign the raking weights.
run_hours_ddd_age_interacted <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS) {
  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  model <- feols(
    as.formula(paste("WorkHoursCont ~ Mother * Post * WFH_Exposure + Mother:GilNK +",
                      paste(controls, collapse = " + "))),
    data = df_ddd, cluster = ~MishlachYad_ISCO_08_2
  )

  print(etable(model, headers = c("Hours DDD, age-interacted"), digits = 4))

  invisible(list(model = model, n_clusters = n_distinct(df_ddd$MishlachYad_ISCO_08_2)))
}

run_hours_ddd_reweighted <- function(cleaned_df, exposure_cells, exposure_index,
                                      controls = DEFAULT_CONTROLS, rake = NULL) {
  if (is.null(rake)) rake <- build_gilnk_rake_weights(cleaned_df, exposure_cells)

  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))

  # Cell exposure assigns the weight; occupation exposure is the regressor.
  ddd_df <- cleaned_df %>%
    filter(Employed == 1) %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    filter(!is.na(WFH_Exposure)) %>%
    assign_wfh_quartile(rake$breaks) %>%
    rename(WFH_Exposure_Cell = WFH_Exposure) %>%
    left_join(rake$weights, by = c("WFH_Exposure_Q", "Mother", "GilNK")) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  n_total   <- nrow(ddd_df)
  n_missing <- sum(is.na(ddd_df$rake_weight))
  if (n_missing > 0) {
    message(sprintf(
      paste0("run_hours_ddd_reweighted: %d of %d rows (%.1f%%) have no pre-period-derived weight ",
             "for their (quartile, Mother, GilNK) cell -- dropped by feols's listwise deletion."),
      n_missing, n_total, 100 * n_missing / n_total
    ))
  }

  model <- feols(
    as.formula(paste("WorkHoursCont ~ Mother * Post * WFH_Exposure +", paste(controls, collapse = " + "))),
    data = ddd_df, weights = ~rake_weight, cluster = ~MishlachYad_ISCO_08_2
  )

  print(etable(model, headers = c("Hours DDD, reweighted"), digits = 4))

  invisible(list(rake = rake, model = model,
                 n_clusters = n_distinct(ddd_df$MishlachYad_ISCO_08_2[!is.na(ddd_df$rake_weight)])))
}

run_ddd_reweighted <- function(cleaned_df, exposure_cells, controls = DEFAULT_CONTROLS,
                                rake = NULL) {
  if (is.null(rake)) rake <- build_gilnk_rake_weights(cleaned_df, exposure_cells)

  cell_fe_vars   <- c("GilNK", "TeudaGvoha", "MachozMegurim")
  other_controls <- setdiff(controls, cell_fe_vars)
  cluster_formula <- as.formula(paste("~", paste(cell_fe_vars, collapse = "^")))

  # Weights are keyed on (quartile, Mother, GilNK), so pre-period weights apply to every row.
  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  ddd_df <- cleaned_df %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    filter(!is.na(WFH_Exposure)) %>%
    assign_wfh_quartile(rake$breaks) %>%
    left_join(rake$weights, by = c("WFH_Exposure_Q", "Mother", "GilNK"))

  n_total   <- nrow(ddd_df)
  n_missing <- sum(is.na(ddd_df$rake_weight))
  if (n_missing > 0) {
    message(sprintf(
      paste0("run_ddd_reweighted: %d of %d rows (%.1f%%) have no pre-period-derived weight for ",
             "their (quartile, Mother, GilNK) cell -- dropped by feols's listwise deletion."),
      n_missing, n_total, 100 * n_missing / n_total
    ))
  }

  additive <- feols(
    as.formula(paste("Employed ~ Mother * Post * WFH_Exposure +", paste(controls, collapse = " + "))),
    data = ddd_df, weights = ~rake_weight, cluster = cluster_formula
  )
  fe <- feols(
    as.formula(paste("Employed ~ Mother * Post * WFH_Exposure +", paste(other_controls, collapse = " + "),
                      "|", paste(cell_fe_vars, collapse = "^"))),
    data = ddd_df, weights = ~rake_weight, cluster = cluster_formula
  )

  print(etable(additive, fe,
               headers = c("Reweighted Spec 1: additive", "Reweighted Spec 2: cell FE"),
               digits = 4))

  invisible(list(rake = rake, additive = additive, fe = fe))
}
