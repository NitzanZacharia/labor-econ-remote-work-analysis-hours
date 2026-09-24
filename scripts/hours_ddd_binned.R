# hours_ddd_binned.R
# Quartile-binned version of the primary hours DDD (scripts/hours_ddd_regression.R);
# docs/decisions/grade-report-response.md, item M1.
#
# The pooled DDD reports one slope per unit of exposure. Figure 2 (build_hours_dose_response())
# shows that the raw dose-response is not linear: three quartiles near zero and one well above.
# This specification replaces the continuous score with the quartile it falls in, so the paper can
# report the Q4-vs-Q1 contrast as a coefficient with a standard error instead of reading it off a
# figure with no controls. The bins are the SAME bins as Figure 2 -- main.R passes that figure's
# `breaks` in, and assign_wfh_quartile() is the same cut() step -- so the table and the figure
# describe the same four groups of occupations.
#
#   WorkHoursCont ~ Mother * Post * i(WFH_Exposure_Q, ref = 1) + controls
#
# expands to the full set of two-way terms plus three triple interactions, one per non-reference
# quartile. Coefficients are extracted BY NAME ("Mother:Post:WFH_Exposure_Q::4"), never by etable
# label (which prints "Mother x Post x WFH_Exposure_Q = 4") -- the same rule
# tidy_event_study_coefs() follows for the event studies.
#
# Because the breakpoints come from the row-level pre-period distribution, the bins are
# worker-weighted and hold unequal numbers of OCCUPATIONS. Occupation is the cluster, so a
# quartile coefficient resting on a handful of occupations is less precisely estimated than its
# row count suggests; the per-quartile occupation counts are returned and printed in Table 2 for
# that reason.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "assign_wfh_quartile.R"))

run_hours_ddd_binned <- function(cleaned_df, exposure_index, breaks, controls = DEFAULT_CONTROLS,
                                 ref_quartile = 1, outcome = "WorkHoursCont") {

  if (length(breaks) != 5 || any(duplicated(breaks))) {
    stop("run_hours_ddd_binned: `breaks` must be five strictly increasing quartile edges ",
         "(build_hours_dose_response()$breaks or compute_occupation_exposure_breaks()).")
  }

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    ) %>%
    assign_wfh_quartile(breaks)

  n_matched <- nrow(df_ddd)
  message(sprintf(
    "run_hours_ddd_binned: %d of %d employed rows (%.1f%%) retained an occupation-level WFH_Exposure match.",
    n_matched, n_employed, 100 * n_matched / n_employed
  ))

  # Occupations and estimation rows per quartile. The row count uses the outcome's own
  # non-missing rows so it matches what feols estimates on, not the matched frame.
  quartile_sizes <- df_ddd %>%
    filter(!is.na(.data[[outcome]])) %>%
    group_by(WFH_Exposure_Q) %>%
    summarise(
      n_occupations = n_distinct(MishlachYad_ISCO_08_2),
      n_rows        = n(),
      exposure_low  = min(WFH_Exposure),
      exposure_high = max(WFH_Exposure),
      .groups = "drop"
    ) %>%
    arrange(WFH_Exposure_Q)
  message("run_hours_ddd_binned: occupations and rows per exposure quartile:")
  print(as.data.frame(quartile_sizes))

  formula_bin <- as.formula(paste(
    outcome, sprintf("~ Mother * Post * i(WFH_Exposure_Q, ref = %d) +", ref_quartile),
    paste(controls, collapse = " + ")
  ))

  reg_bin <- feols(formula_bin, data = df_ddd, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(reg_bin, "run_hours_ddd_binned()'s quartile triple interactions")

  triple_pattern <- "^Mother:Post:WFH_Exposure_Q::(\\d)$"
  triple_terms   <- grep(triple_pattern, names(coef(reg_bin)), value = TRUE)
  if (length(triple_terms) == 0) {
    stop("run_hours_ddd_binned: no Mother:Post:WFH_Exposure_Q::<q> coefficients found. Names present: ",
         paste(names(coef(reg_bin)), collapse = ", "))
  }

  df_t <- degrees_freedom(reg_bin, type = "t")
  coefs <- tibble(
    term      = triple_terms,
    quartile  = as.integer(sub(triple_pattern, "\\1", triple_terms)),
    estimate  = unname(coef(reg_bin)[triple_terms]),
    std_error = unname(se(reg_bin)[triple_terms])
  ) %>%
    mutate(
      t_stat  = estimate / std_error,
      p_value = 2 * pt(abs(t_stat), df = df_t, lower.tail = FALSE),
      ci_low  = estimate - qt(0.975, df = df_t) * std_error,
      ci_high = estimate + qt(0.975, df = df_t) * std_error,
      ref_quartile = ref_quartile
    ) %>%
    left_join(quartile_sizes, by = c("quartile" = "WFH_Exposure_Q")) %>%
    arrange(quartile)

  table_bin <- etable(reg_bin, headers = c(paste0(outcome, " (hours DDD, exposure quartiles)")),
                      digits = 4)
  print(table_bin)

  message("=== Hours DDD, quartile bins: Mother x Post x (quartile q vs quartile ", ref_quartile, ") ===")
  print(as.data.frame(coefs %>% select(quartile, estimate, std_error, p_value, ci_low, ci_high,
                                       n_occupations, n_rows)), digits = 4)

  invisible(list(
    table          = table_bin,
    model          = reg_bin,
    coefs          = coefs,
    quartile_sizes = quartile_sizes,
    breaks         = breaks,
    n_employed     = n_employed,
    n_matched      = n_matched,
    n_clusters     = n_distinct(df_ddd$MishlachYad_ISCO_08_2)
  ))
}
