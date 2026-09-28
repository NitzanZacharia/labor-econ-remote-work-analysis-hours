# hours_ddd_marital_interacted.R
# Marital-balance check on the hours DDD: the married share of mothers exceeds that of childless
# women by more in high-exposure occupations, so part of the gradient could come from the
# comparison group's marital mix. This adds marital status x Post x WFH_Exposure (and the two-way
# terms) alongside the triple interaction, the marital analogue of run_hours_ddd_age_interacted().
# Partly over-control, since most mothers are married; read beside the married-only row.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))

run_hours_ddd_marital_interacted <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS,
                                             outcome = "WorkHoursCont") {
  if (!outcome %in% names(cleaned_df)) {
    stop("run_hours_ddd_marital_interacted: outcome column '", outcome, "' is not in cleaned_df.")
  }
  if (!"MatzavMishpachti" %in% names(cleaned_df)) {
    stop("run_hours_ddd_marital_interacted: cleaned_df has no MatzavMishpachti column.")
  }

  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    ) %>%
    mutate(MatzavMishpachti = as.factor(MatzavMishpachti))

  n_clusters <- n_distinct(df_ddd$MishlachYad_ISCO_08_2)

  model <- feols(
    as.formula(paste(
      outcome, "~ Mother * Post * WFH_Exposure + Post * WFH_Exposure * MatzavMishpachti +",
      paste(controls, collapse = " + ")
    )),
    data = df_ddd, cluster = ~MishlachYad_ISCO_08_2
  )
  check_for_dropped_coefficients(model, "run_hours_ddd_marital_interacted()'s triple interaction")

  print(etable(model, headers = c("Hours DDD, marital-status interacted"), digits = 4))

  invisible(list(model = model, n_clusters = n_clusters, n_matched = nrow(df_ddd)))
}
