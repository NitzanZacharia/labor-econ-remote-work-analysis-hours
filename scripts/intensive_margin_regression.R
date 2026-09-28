# Primary DiD: usual weekly hours on Mother x Post with the standard controls, on the employed.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))

# year_fe replaces the single Post effect with survey-year effects (a robustness row); Mother:Post
# stays the coefficient of interest.
run_intensive_margin_reg <- function(cleaned_df, controls = DEFAULT_CONTROLS, year_fe = FALSE,
                                     ref_year = 2019) {

  period_term <- if (isTRUE(year_fe)) sprintf("i(ShnatSeker, ref = %d)", ref_year) else "Post"

  rhs <- paste(
    paste("Mother +", period_term, "+ Mother:Post"),
    paste(controls, collapse = " + "),
    sep = " + "
  )

  formula_hours <- as.formula(paste("WorkHoursCont ~", rhs))

  reg_hours <- feols(formula_hours, data = filter(cleaned_df, Employed == 1), cluster = ~IDPUF)

  table_hours <- etable(reg_hours,
                         headers = c(if (isTRUE(year_fe)) "WorkHoursCont (year effects)" else "WorkHoursCont"),
                         digits = 4)
  print(table_hours)
  return(invisible(list(
    table  = table_hours,
    models = list(hours = reg_hours)
  )))
}
