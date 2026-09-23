# Checkpoint 4 (docs/ROADMAP.md): the intensive-margin (weekly work hours) DiD, per the research
# doc's core DiD spec (Part 2 §1 / Part 4 §2), which models both an employment indicator and
# weekly work hours. As of the hours pivot (docs/decisions/hours-ddd-pivot.md), this is the
# project's PRIMARY dependent-variable regression; basic_regression.R's extensive-margin (Employed)
# model is the secondary/comparison regression. Hours are only meaningful conditional on being
# employed, so this is estimated on the Employed == 1 subsample.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))

# `year_fe` (docs/decisions/grade-report-response.md, item M1) replaces the single Post
# main effect with survey-year effects, i(ShnatSeker, ref = ref_year), while keeping Mother:Post as
# the coefficient of interest. The pooled 2x2 is the paper's column (1); the year-effects version
# is a robustness row, since pooling six years into two periods lets year-specific movements in
# hours (visible in Figure 1) load onto the Post intercept. Default FALSE reproduces every existing
# call byte for byte.
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
