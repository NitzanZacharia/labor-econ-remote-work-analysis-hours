# absence_by_exposure_quartile.R
# Share of employed women who did NOT work in the reference week (AvadBeshavua != 1), by quartile of
# occupation-level WFH exposure, and by quartile x Mother x Post.
#
# Why this exists. The hours outcome is defined on reference-week workers in every year
# (docs/decisions/hours-population-harmonization.md), which drops the ~10% of the employed who were
# absent that week. If absence is itself related to WFH exposure -- teleworkable jobs making it
# easier to work while unwell or while caring for a child, say -- that restriction is not innocuous
# for the triple interaction. The paper's Limitations section used to assert the relation was
# "mild" with no number attached; the 2026-09-22 editorial audit (item I1) removed the claim and
# asked for the four quartile shares so it can be restored with evidence or left out.
#
# Quartiles are those of build_hours_dose_response(): breakpoints from the pre-period distribution
# of the occupation-level measure, applied to all years. main.R passes that function's `breaks` in
# so the quartiles here are identical to Figure 2's; when none are supplied the same rule recomputes
# them on this sample, which (because the join and the pre-period filter are the same) yields the
# same edges. Absence shares are cell means with a standard error clustered by IDPUF, via
# clustered_se(), like every other descriptive in the paper's Section 4.
library(tidyverse)
library(fixest)
source(file.path("scripts", "clustered_se.R"))
source(file.path("robustness", "age_balance_robustness.R"))

build_absence_by_exposure_quartile <- function(cleaned_df, exposure_index, breaks = NULL) {
  if (!"AvadBeshavua" %in% names(cleaned_df)) {
    stop("build_absence_by_exposure_quartile: cleaned_df has no AvadBeshavua column.")
  }

  df <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code,
                                WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    ) %>%
    filter(!is.na(WFH_Exposure), !is.na(AvadBeshavua)) %>%
    mutate(absent = as.integer(AvadBeshavua != 1))

  if (is.null(breaks)) {
    pre_exposure <- df %>% filter(ShnatSeker < 2020) %>% pull(WFH_Exposure)
    breaks <- quantile(pre_exposure, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
    if (any(duplicated(breaks))) {
      stop("build_absence_by_exposure_quartile: duplicate quartile breakpoints -- cut() would ",
           "silently produce fewer than 4 bins.")
    }
  }

  df <- assign_wfh_quartile(df, breaks)

  summarise_cells <- function(grouped) {
    grouped %>%
      group_modify(~ {
        # Share taken directly as the cell mean (identical to the feols intercept); clustered_se()
        # supplies the standard error and degrades to NA on a constant cell instead of erroring.
        fit <- clustered_se(.x, absent ~ 1, "(Intercept)")
        tibble(absent_share = mean(.x$absent), se = fit$se, n = nrow(.x))
      }) %>%
      ungroup()
  }

  by_quartile <- df %>% group_by(WFH_Exposure_Q) %>% summarise_cells() %>% arrange(WFH_Exposure_Q)
  by_cell     <- df %>% group_by(WFH_Exposure_Q, Mother, Post) %>% summarise_cells() %>%
    arrange(WFH_Exposure_Q, Mother, Post)

  invisible(list(
    by_quartile = by_quartile,
    by_cell     = by_cell,
    breaks      = breaks
  ))
}
