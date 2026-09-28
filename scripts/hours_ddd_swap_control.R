# hours_ddd_swap_control.R
# Fixed-sample test of the calibration: the external score as regressor on all forty occupations,
# with the ten swapped occupations given their own Mother x Post structure. The unswapped-30 row
# changes the sample as well as the measure; this keeps the sample and lets Mother:Post:Swapped
# absorb the swapped group's own post-2021 change in the motherhood gap.
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
