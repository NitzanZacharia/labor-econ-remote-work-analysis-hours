# assign_wfh_quartile.R
# Cuts a frame's WFH_Exposure into the four quartile bins defined by `breaks` (the five edges from
# compute_occupation_exposure_breaks() or compute_pre_period_quartile_breaks()), as an integer
# WFH_Exposure_Q in 1:4. Every quartile consumer -- the dose-response figure, the binned DDD, the
# Lee bounds, the balance and sorting checks and the age-balance chain -- calls this one cut(), so
# the bins cannot drift apart. include.lowest = TRUE keeps the minimum in bin 1; rows with a
# missing WFH_Exposure get NA.
library(tidyverse)

assign_wfh_quartile <- function(df, breaks) {
  df %>% mutate(WFH_Exposure_Q = as.integer(cut(WFH_Exposure, breaks = breaks, labels = 1:4,
                                                 include.lowest = TRUE)))
}
