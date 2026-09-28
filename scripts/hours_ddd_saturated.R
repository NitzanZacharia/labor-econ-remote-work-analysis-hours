# hours_ddd_saturated.R
# Saturated hours DDD: occupation x year, occupation x mother and mother x year fixed effects
# absorb every lower-order term of the pooled specification, so only the triple interaction
# carries a functional form. Mother:Post is absorbed by Mother^ShnatSeker and has no counterpart
# here. Same join, sample and clustering as run_hours_ddd_regression().
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))

run_hours_ddd_saturated <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS,
                                    outcome = "WorkHoursCont") {

  n_employed <- sum(cleaned_df$Employed == 1, na.rm = TRUE)

  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  n_matched <- nrow(df_ddd)
  message(sprintf(
    "run_hours_ddd_saturated: %d of %d employed rows (%.1f%%) retained an occupation-level WFH_Exposure match.",
    n_matched, n_employed, 100 * n_matched / n_employed
  ))

  fixed_effects <- c("MishlachYad_ISCO_08_2^ShnatSeker", "MishlachYad_ISCO_08_2^Mother",
                     "Mother^ShnatSeker")

  formula_sat <- as.formula(paste(
    outcome, "~ Mother:Post:WFH_Exposure +", paste(controls, collapse = " + "),
    "|", paste(fixed_effects, collapse = " + ")
  ))

  reg_sat <- feols(formula_sat, data = df_ddd, cluster = ~MishlachYad_ISCO_08_2)
  check_for_dropped_coefficients(reg_sat, "run_hours_ddd_saturated()'s triple interaction")

  if (!"Mother:Post:WFH_Exposure" %in% names(coef(reg_sat))) {
    stop("run_hours_ddd_saturated: the triple interaction was not estimated -- it is collinear ",
         "with the fixed effects on this sample.")
  }

  table_sat <- etable(reg_sat, headers = c(paste0(outcome, " (hours DDD, saturated FE)")),
                      digits = 4)
  print(table_sat)

  invisible(list(
    table         = table_sat,
    model         = reg_sat,
    n_employed    = n_employed,
    n_matched     = n_matched,
    n_clusters    = n_distinct(df_ddd$MishlachYad_ISCO_08_2),
    fixed_effects = fixed_effects
  ))
}
