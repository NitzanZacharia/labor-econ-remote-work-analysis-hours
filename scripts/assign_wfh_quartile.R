# assign_wfh_quartile.R
# The one cut() every quartile consumer applies to a set of exposure breaks.
library(tidyverse)

assign_wfh_quartile <- function(df, breaks) {
  df %>% mutate(WFH_Exposure_Q = as.integer(cut(WFH_Exposure, breaks = breaks, labels = 1:4,
                                                 include.lowest = TRUE)))
}
