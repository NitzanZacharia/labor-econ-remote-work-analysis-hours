# hours_ddd_saturated.R
# The fully saturated version of the primary hours DDD (scripts/hours_ddd_regression.R), added in
# response to the 2026-09-22 grade report (item M1; docs/decisions/grade-report-response.md).
#
# The pooled DDD enters the occupation-level exposure score as one continuous regressor with its
# two-way interactions, which forces three occupation-level differences -- in hours levels (the
# WFH_Exposure main effect), in the motherhood gap (Mother x WFH_Exposure) and in the post-2021
# change (Post x WFH_Exposure) -- to be LINEAR in exposure. With only forty two-digit occupations,
# the flexible alternative is cheap: absorb every one of those margins with fixed effects and let
# only the triple interaction carry a functional form.
#
#   occupation x survey-year FE   absorbs WFH_Exposure, Post, Post x WFH_Exposure, and any
#                                 occupation-specific year shock (a strict superset of
#                                 occupation + occupation x Post + year)
#   occupation x Mother FE        absorbs Mother, Mother x WFH_Exposure and the occupation-specific
#                                 level of the motherhood gap
#   Mother x survey-year FE       absorbs Mother x Post and the year-by-year path of the
#                                 unconditional motherhood gap
#
# What survives is Mother x Post x WFH_Exposure, identified off how the within-occupation change in
# the motherhood gap covaries with the occupation's exposure score. Mother:Post is NOT in the
# linear part: Mother^ShnatSeker absorbs it exactly (verified on a synthetic panel before this was
# written -- fixest drops it for collinearity if it is included), so the pooled column's
# "effect at zero exposure" has no counterpart here. Anything the pooled column estimates that this
# one does not is by construction, not by omission.
#
# Same join, same sample and same occupation-level clustering as run_hours_ddd_regression(), so the
# two columns of Table 2 differ only in what the lower-order terms are allowed to do.
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
