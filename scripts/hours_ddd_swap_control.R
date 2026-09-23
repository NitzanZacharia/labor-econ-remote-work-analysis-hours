# hours_ddd_swap_control.R
# A fixed-sample test of the exposure calibration, added in response to the 2026-09-23 grade
# report (Methods deduction 1; docs/decisions/grade-report-2-response.md).
#
# The problem it answers. calibrate_isco_exposure() swaps ten of forty occupation scores to their
# realized 2022-23 Israeli WFH shares, which sit inside the post-period. The paper's existing
# defence -- re-estimate on the thirty occupations the calibration left alone -- changes the SAMPLE
# as well as the measure: it drops nearly half the rows, including the three largest occupations.
# A reader cannot tell whether the estimate on the thirty differs from the external-index estimate
# on the forty because the calibration is right or because the largest occupations are gone.
#
# This specification holds the sample at all forty occupations and uses the fully pre-treatment
# external (Dingel & Neiman) score as the regressor, but lets the ten swapped occupations have
# their own level, their own motherhood gap, their own post-period change and their own change in
# the motherhood gap:
#
#   WorkHoursCont ~ Mother * Post * WFH_Exposure + Mother * Post * Swapped + controls
#
# Mother:Post:WFH_Exposure is then the external-score gradient identified off variation in the
# external score WITHIN the swapped and unswapped groups (the Mother:Post:Swapped term absorbs the
# between-group difference in the post-2021 change of the motherhood gap). If the calibration
# merely relabels ten occupations that behave like their external score says, the two triple
# interactions should be small; if those ten occupations are genuinely mis-scored by the external
# index -- teaching and clerical work returned to the workplace whatever their task content --
# Mother:Post:Swapped should be negative (the external index puts them in the treated tail, and
# they did not respond) and the external-score gradient should re-emerge once they are allowed
# their own change. Same join, subsample and occupation-level clustering as
# run_hours_ddd_regression(), so the row is comparable with Table 4's others.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))

run_hours_ddd_swap_control <- function(cleaned_df, external_index, swapped_codes,
                                       controls = DEFAULT_CONTROLS, outcome = "WorkHoursCont") {
  if (!outcome %in% names(cleaned_df)) {
    stop("run_hours_ddd_swap_control: outcome column '", outcome, "' is not in cleaned_df.")
  }
  if (!all(c("occupation_code", "wfh_exposure") %in% names(external_index))) {
    stop("run_hours_ddd_swap_control: external_index needs `occupation_code` and `wfh_exposure` columns.")
  }
  swapped_codes <- as.numeric(swapped_codes)
  if (length(swapped_codes) == 0) {
    stop("run_hours_ddd_swap_control: swapped_codes is empty -- with no swapped occupations the ",
         "Swapped indicator is constant and the specification collapses to the external-index DDD.")
  }

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      external_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    ) %>%
    mutate(Swapped = as.integer(MishlachYad_ISCO_08_2 %in% swapped_codes))

  n_matched   <- nrow(df_ddd)
  n_clusters  <- n_distinct(df_ddd$MishlachYad_ISCO_08_2)
  n_swapped   <- n_distinct(df_ddd$MishlachYad_ISCO_08_2[df_ddd$Swapped == 1])
  share_swapped_rows <- mean(df_ddd$Swapped)
  message(sprintf(
    paste0("run_hours_ddd_swap_control: %d of %d employed rows matched (%d occupations); %d swapped ",
           "occupations carry %.1f%% of the rows."),
    n_matched, n_employed, n_clusters, n_swapped, 100 * share_swapped_rows
  ))
  if (n_swapped == 0 || n_swapped == n_clusters) {
    stop("run_hours_ddd_swap_control: the Swapped indicator is constant on the matched sample ",
         "(", n_swapped, " of ", n_clusters, " occupations swapped).")
  }

  formula_swap <- as.formula(paste(
    outcome, "~ Mother * Post * WFH_Exposure + Mother * Post * Swapped +",
    paste(controls, collapse = " + ")
  ))
  model <- feols(formula_swap, data = df_ddd, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(model, "run_hours_ddd_swap_control()'s triple interactions")

  terms <- c("Mother:Post:WFH_Exposure", "Mother:Post:Swapped")
  missing_terms <- setdiff(terms, names(coef(model)))
  if (length(missing_terms) > 0) {
    stop("run_hours_ddd_swap_control: not estimated: ", paste(missing_terms, collapse = ", "))
  }
  coefs <- tibble(
    term      = terms,
    estimate  = unname(coef(model)[terms]),
    std_error = unname(se(model)[terms]),
    p_value   = unname(pvalue(model)[terms]),
    n         = as.integer(nobs(model)),
    n_clusters = n_clusters,
    n_swapped_occupations = n_swapped
  )

  table <- etable(model, headers = c(paste0(outcome, " (external index + swapped-occupation terms)")),
                  digits = 4)
  print(table)
  message("=== External-score gradient with the swapped occupations' own Mother x Post change absorbed ===")
  print(as.data.frame(coefs), digits = 4)

  invisible(list(
    table      = table,
    model      = model,
    coefs      = coefs,
    n_employed = n_employed,
    n_matched  = n_matched,
    n_clusters = n_clusters,
    n_swapped_occupations = n_swapped,
    share_swapped_rows    = share_swapped_rows,
    outcome    = outcome
  ))
}
