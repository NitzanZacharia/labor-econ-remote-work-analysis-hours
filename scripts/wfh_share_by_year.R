# wfh_share_by_year.R
# The realized share of employed women working from home, by survey year -- the Israeli counterpart
# of the US "share of workdays" figures the paper's Introduction cites from Barrero, Bloom and Davis.
# An Israeli reader will ask what the Israeli share was (paper/notes/editorial-audit-2026-09-22.md,
# item B2).
#
# Two measures, both defined in data_processing.R and both NA before 2021 because the CBS asked
# the items from 2021 only: WFH (usual work location) and WFH_RefWeek (worked from home in the
# reference week). The pipeline's exposure indices are built from WFH; the reference-week series is
# the better-behaved one (data_processing.R's WFH block explains why), so both are reported and the
# paper can say which it quotes. Only years with a non-missing value produce a row, so the result is
# post-period only -- there is no pre-period Israeli share to compute, and the function does not
# pretend otherwise.
#
# Shares are cell means with a standard error clustered by IDPUF via clustered_se(), the same
# convention as every other descriptive in the paper's Section 4. Unweighted, like everything else.
library(tidyverse)
library(fixest)
source(file.path("scripts", "clustered_se.R"))

build_wfh_share_by_year <- function(cleaned_df, wfh_cols = c("WFH", "WFH_RefWeek")) {
  wfh_cols <- intersect(wfh_cols, names(cleaned_df))
  if (length(wfh_cols) == 0) {
    stop("build_wfh_share_by_year: none of the requested WFH columns is present in cleaned_df.")
  }

  employed <- cleaned_df %>% filter(Employed == 1)

  bind_rows(lapply(wfh_cols, function(col) {
    employed %>%
      filter(!is.na(.data[[col]])) %>%
      group_by(ShnatSeker) %>%
      group_modify(~ {
        # The share is the cell mean by construction (feols on `y ~ 1` returns exactly that), so it
        # is taken directly; clustered_se() supplies only the standard error, and degrades to NA
        # rather than erroring on a cell whose outcome is constant.
        fit <- clustered_se(.x, as.formula(paste(col, "~ 1")), "(Intercept)")
        tibble(measure = col, share = mean(.x[[col]]), se = fit$se, n = nrow(.x))
      }) %>%
      ungroup()
  })) %>%
    select(measure, ShnatSeker, share, se, n) %>%
    arrange(measure, ShnatSeker)
}
