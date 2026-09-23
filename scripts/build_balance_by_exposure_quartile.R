# build_balance_by_exposure_quartile.R
# Pre-period covariate balance between mothers and childless women, by quartile of the
# OCCUPATION-LEVEL exposure score the hours DDD uses (Figure 2's bins), on the DDD's own
# estimation sample. Added in response to the 2026-09-23 grade report (Robustness deduction 2;
# docs/decisions/grade-report-2-response.md).
#
# What it is for. The triple difference compares the change in the motherhood gap ACROSS exposure
# levels, so what matters is whether mothers and childless women differ from each other in
# different ways at different exposure levels. The paper reported only the age-group gap by
# quartile, in prose; this puts every control the regressions use -- and the population-group
# split -- into one table, each cell the mother-minus-childless difference with an IDPUF-clustered
# standard error from clustered_se() (the same helper Table 1's difference column uses).
#
# It is deliberately NOT robustness/balance_test.R: that function works on the demographic-cell
# index's quartiles (the employment DDD's regressor) and prints chi-square tests of independence.
# The hours DDD is identified off the occupation-level score, so its balance table has to be cut
# on that score's quartiles.
library(tidyverse)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "clustered_se.R"))
source(file.path("robustness", "age_balance_robustness.R"))  # assign_wfh_quartile()

build_balance_by_exposure_quartile <- function(cleaned_df, exposure_index, breaks,
                                               pre_period_before = 2020,
                                               outcome_sample = "WorkHoursCont",
                                               cluster = ~IDPUF) {
  if (length(breaks) != 5 || any(duplicated(breaks))) {
    stop("build_balance_by_exposure_quartile: `breaks` must be five strictly increasing quartile edges.")
  }
  if (!"ShnatSeker" %in% names(cleaned_df)) {
    stop("build_balance_by_exposure_quartile: no ShnatSeker column -- the pre-period cannot be identified.")
  }

  df <- cleaned_df %>%
    filter(ShnatSeker < pre_period_before, Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )
  if (!is.null(outcome_sample) && outcome_sample %in% names(df)) {
    df <- filter(df, !is.na(.data[[outcome_sample]]))
  }
  df <- assign_wfh_quartile(df, breaks)

  # Each entry: a display label, and a function of the frame returning the numeric outcome.
  # Shares are scaled to percentage points so the differences read like Table 1's.
  as_code <- function(x) as.numeric(as.character(x))
  measures <- list(
    list(var = "age_code",  label = "Age-group code (CBS 3--7), mean", unit = "code",
         f = function(d) as_code(d$GilNK)),
    list(var = "married",   label = "Married (\\%)", unit = "pct",
         f = function(d) 100 * as.numeric(as.character(d$MatzavMishpachti) == "1")),
    list(var = "academic",  label = "Academic degree (\\%)", unit = "pct",
         f = function(d) 100 * as.numeric(as.character(d$TeudaGvoha) == "Academic Degree (BA/MA/PhD)")),
    list(var = "below_hs",  label = "Below high school (\\%)", unit = "pct",
         f = function(d) 100 * as.numeric(as.character(d$TeudaGvoha) == "Below High School")),
    list(var = "jewish_head", label = "Jewish household head (\\%)", unit = "pct",
         f = function(d) 100 * as.numeric(as.character(d$Dat) == "1")),
    list(var = "center_tlv", label = "Center or Tel Aviv district (\\%)", unit = "pct",
         f = function(d) 100 * as.numeric(as.character(d$MachozMegurim) %in% c("4", "5")))
  )
  if ("Leom" %in% names(df)) {
    measures <- c(measures, list(
      list(var = "arab", label = "Arab (\\%)", unit = "pct",
           f = function(d) 100 * as.numeric(d$Leom == 2))
    ))
  } else {
    message("build_balance_by_exposure_quartile: no Leom column -- the Arab share is omitted.")
  }
  needed_cols <- c("GilNK", "MatzavMishpachti", "TeudaGvoha", "Dat", "MachozMegurim", "Mother")
  missing_cols <- setdiff(needed_cols, names(df))
  if (length(missing_cols) > 0) {
    stop("build_balance_by_exposure_quartile: missing column(s): ", paste(missing_cols, collapse = ", "))
  }

  quartiles <- sort(unique(df$WFH_Exposure_Q))
  rows <- list()
  for (q in quartiles) {
    d_q <- filter(df, WFH_Exposure_Q == q)
    n_m <- sum(d_q$Mother == 1); n_c <- sum(d_q$Mother == 0)
    for (m in measures) {
      d_q$.y <- m$f(d_q)
      cs <- clustered_se(d_q, .y ~ Mother, "Mother", cluster = cluster)
      rows[[length(rows) + 1]] <- tibble(
        WFH_Exposure_Q = as.integer(q),
        variable       = m$var,
        label          = m$label,
        unit           = m$unit,
        mean_childless = mean(d_q$.y[d_q$Mother == 0], na.rm = TRUE),
        mean_mothers   = mean(d_q$.y[d_q$Mother == 1], na.rm = TRUE),
        difference     = cs$estimate,
        se             = cs$se,
        n_childless    = n_c,
        n_mothers      = n_m,
        n_occupations  = n_distinct(d_q$MishlachYad_ISCO_08_2),
        exposure_low   = min(d_q$WFH_Exposure),
        exposure_high  = max(d_q$WFH_Exposure)
      )
    }
  }
  table <- bind_rows(rows)

  message("=== Pre-period balance (mothers minus childless women) by quartile of occupation-level exposure ===")
  print(as.data.frame(table %>% select(WFH_Exposure_Q, variable, mean_childless, mean_mothers,
                                       difference, se, n_childless, n_mothers)), digits = 3)

  invisible(list(
    table    = table,
    breaks   = breaks,
    n_rows   = nrow(df),
    measures = vapply(measures, function(m) m$var, character(1))
  ))
}
