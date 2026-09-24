# hours_ddd_cell_exposure.R
# The hours DDD with a PRE-PERIOD exposure regressor that cannot respond to the treatment
# (docs/decisions/grade-report-2-response.md, Methods 2, occupational sorting). The companion diagnostic is
# exposure_sorting_check.R; this file is the bound.
#
# The headline regressor is the calibrated score of the occupation a woman holds WHEN SURVEYED, so
# a mother who moved into a teleworkable job after 2021 carries a higher exposure in the post-period
# than she did before. The demographic-cell index main.R builds for the employment DDD
# (build_exposure_cells(): the calibrated score averaged over each cell's 2017-2019 occupational
# composition, cells defined by sex, age group, education, district, marital status, religion and
# continent of birth) is fixed at its pre-period value for every woman in a cell, whatever job she
# holds later. Re-estimating the hours DDD on that index therefore gives an estimate that
# post-period occupational sorting cannot produce -- an intention-to-treat on pre-period exposure.
#
# Two things it costs, both stated in the paper. The cell index is a much coarser and much less
# dispersed regressor (SD about 0.07 against 0.20 for the occupation-level score), so the per-unit
# coefficient is on a different scale and only the per-SD figure is comparable; and it measures
# exposure with error relative to the woman's actual occupation, which attenuates toward zero.
# Same formula as run_hours_ddd_regression(); clustered on the coarser demographic cell the
# employment DDD clusters on (main.R §8b), since that is the level the regressor varies at.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))

run_hours_ddd_cell_exposure <- function(cleaned_df, exposure_cells,
                                        cell_cluster_vars = c("GilNK", "TeudaGvoha", "MachozMegurim"),
                                        controls = DEFAULT_CONTROLS, outcome = "WorkHoursCont") {
  if (!outcome %in% names(cleaned_df)) {
    stop("run_hours_ddd_cell_exposure: outcome column '", outcome, "' is not in cleaned_df.")
  }
  exposure_join_vars <- setdiff(names(exposure_cells), c("WFH_Exposure", "n_cell"))
  missing_join <- setdiff(exposure_join_vars, names(cleaned_df))
  if (length(missing_join) > 0) {
    stop("run_hours_ddd_cell_exposure: cleaned_df lacks the cell variable(s): ",
         paste(missing_join, collapse = ", "))
  }
  missing_cl <- setdiff(cell_cluster_vars, names(cleaned_df))
  if (length(missing_cl) > 0) {
    stop("run_hours_ddd_cell_exposure: cleaned_df lacks the cluster variable(s): ",
         paste(missing_cl, collapse = ", "))
  }

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)
  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    left_join(exposure_cells, by = exposure_join_vars) %>%
    filter(!is.na(WFH_Exposure))
  n_matched <- nrow(df_ddd)
  message(sprintf(
    "run_hours_ddd_cell_exposure: %d of %d employed rows (%.1f%%) matched a pre-period exposure cell.",
    n_matched, n_employed, 100 * n_matched / n_employed
  ))

  cluster_formula <- as.formula(paste("~", paste(cell_cluster_vars, collapse = "^")))
  formula_ddd <- as.formula(paste(
    outcome, "~ Mother * Post * WFH_Exposure +", paste(controls, collapse = " + ")
  ))
  model <- feols(formula_ddd, data = df_ddd, cluster = cluster_formula)
  check_for_dropped_coefficients(model, "run_hours_ddd_cell_exposure()'s triple interaction")

  term <- "Mother:Post:WFH_Exposure"
  if (!term %in% names(coef(model))) {
    stop("run_hours_ddd_cell_exposure: the triple interaction was not estimated.")
  }

  # The regressor's dispersion on the rows the model actually used, for the per-SD scaling.
  used <- df_ddd %>% filter(!is.na(.data[[outcome]]))
  reg_sd <- sd(used$WFH_Exposure)
  n_clusters <- used %>% distinct(across(all_of(cell_cluster_vars))) %>% nrow()

  coefs <- tibble(
    term           = term,
    estimate       = unname(coef(model)[[term]]),
    std_error      = unname(se(model)[[term]]),
    p_value        = unname(pvalue(model)[[term]]),
    n              = as.integer(nobs(model)),
    n_clusters     = n_clusters,
    regressor_sd   = reg_sd,
    estimate_per_sd = unname(coef(model)[[term]]) * reg_sd,
    se_per_sd       = unname(se(model)[[term]]) * reg_sd
  )

  table <- etable(model, headers = c(paste0(outcome, " (hours DDD, pre-period cell exposure)")), digits = 4)
  print(table)
  message(sprintf(
    "run_hours_ddd_cell_exposure: %s = %.4f (SE %.4f) per unit; regressor SD %.4f -> %.4f (SE %.4f) per SD; %d clusters.",
    term, coefs$estimate, coefs$std_error, reg_sd, coefs$estimate_per_sd, coefs$se_per_sd, n_clusters
  ))

  invisible(list(
    table      = table,
    model      = model,
    coefs      = coefs,
    n_employed = n_employed,
    n_matched  = n_matched,
    n_clusters = n_clusters,
    regressor_sd = reg_sd,
    cluster_vars = cell_cluster_vars,
    outcome    = outcome
  ))
}
