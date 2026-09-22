# Secondary/extensive-margin (Employed) outcome, post-hours-pivot (docs/decisions/hours-ddd-pivot.md).
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))

basic_reg_comp <- function(cleaned_data) {

  controls <- DEFAULT_CONTROLS

  rhs <- paste(
    "Mother + Post + Mother:Post",
    paste(controls, collapse = " + "),
    sep = " + "
  )

  formula_employed <- as.formula(paste("Employed ~", rhs))

  reg_employed <- feols(formula_employed, data = cleaned_data, cluster = ~IDPUF)

  reg_employed_muasak <- feols(formula_employed,
                               data = filter(cleaned_data, !is.na(Muasak)),
                               cluster = ~IDPUF)

  table_basic <- etable(
    reg_employed,
    reg_employed_muasak,
    headers  = c("Full Sample (w/ Imputation)", "Muasak-Observed Only"),
    digits   = 4
  )
  print(table_basic)

  return(invisible(list(
    table  = table_basic,
    models = list(
      employed       = reg_employed,
      employed_muasak = reg_employed_muasak
    )
  )))
}