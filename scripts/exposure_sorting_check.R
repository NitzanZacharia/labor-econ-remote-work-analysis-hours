# exposure_sorting_check.R
# Does the post-2021 change in mothers' OCCUPATIONS, rather than in their hours, drive the hours
# DDD? (docs/decisions/grade-report-2-response.md, Methods 2.)
#
# The hours DDD assigns each woman the exposure score of her current occupation. Occupation is
# observed at the same time as the outcome, so it is itself a potential outcome of the treatment:
# if remote work drew mothers into teleworkable occupations after 2021 at a different rate than
# childless women, the post-period composition of mothers inside high-exposure occupations changes
# for reasons that have nothing to do with hours choices, and the triple interaction picks that
# up. The Lee bounds (hours_ddd_lee_bounds.R) handle selection into EMPLOYMENT and the saturated
# specification absorbs occupation-level shocks; neither speaks to selection ACROSS occupations.
#
# The direct check is a difference-in-differences with the exposure score itself as the outcome,
# on the DDD's own estimation sample: did mothers' mean occupational exposure move relative to
# childless women's after 2021? Three versions are fitted --
#
#   (i)   WFH_Exposure  ~ Mother * Post + controls              the mean-exposure DiD
#   (ii)  TopQuartile   ~ Mother * Post + controls              a linear probability model on being
#                                                              in Figure 2's top exposure quartile
#   (iii) WFH_Exposure  ~ Mother + i(year) + i(year, Mother)    the event-study form of (i), so a
#                                                              gradual reallocation is visible
#
# -- all clustered by individual, since the outcome here varies at the individual level (the
# occupation she holds), not at the occupation level. A null on (i) and (ii) is evidence against
# sorting large enough to matter; a positive estimate says the hours DDD should be read alongside
# the pre-period-exposure bound in hours_ddd_cell_exposure.R.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "tidy_event_study_coefs.R"))
source(file.path("scripts", "assign_wfh_quartile.R"))

run_exposure_sorting_check <- function(cleaned_df, exposure_index, breaks,
                                       controls = DEFAULT_CONTROLS, ref_year = 2019,
                                       outcome_sample = "WorkHoursCont") {
  if (length(breaks) != 5 || any(duplicated(breaks))) {
    stop("run_exposure_sorting_check: `breaks` must be five strictly increasing quartile edges ",
         "(build_hours_dose_response()$breaks).")
  }

  # The DDD's estimation sample: employed, occupation-matched, and with the hours outcome observed
  # (reference-week workers), so the sorting question is asked of exactly the women whose hours
  # the headline is estimated on. `outcome_sample = NULL` widens it to all matched employed women.
  df <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )
  if (!is.null(outcome_sample)) {
    if (!outcome_sample %in% names(df)) {
      stop("run_exposure_sorting_check: '", outcome_sample, "' is not a column; pass outcome_sample = NULL ",
           "to use all matched employed rows.")
    }
    df <- filter(df, !is.na(.data[[outcome_sample]]))
  }
  df <- df %>%
    assign_wfh_quartile(breaks) %>%
    mutate(TopQuartile = as.integer(WFH_Exposure_Q == 4L))

  message(sprintf("run_exposure_sorting_check: %d rows, %d occupations, %d in the top quartile's occupations.",
                  nrow(df), n_distinct(df$MishlachYad_ISCO_08_2),
                  n_distinct(df$MishlachYad_ISCO_08_2[df$TopQuartile == 1L])))

  rhs_did <- paste("Mother * Post +", paste(controls, collapse = " + "))
  m_exposure <- feols(as.formula(paste("WFH_Exposure ~", rhs_did)), data = df, cluster = ~IDPUF)
  m_top      <- feols(as.formula(paste("TopQuartile ~",  rhs_did)), data = df, cluster = ~IDPUF)

  # Pre-period levels, so the DiD can be read against where each group started.
  pre <- df %>%
    filter(Post == 0) %>%
    group_by(Mother) %>%
    summarise(mean_exposure = mean(WFH_Exposure), share_top = mean(TopQuartile),
              sd_exposure = sd(WFH_Exposure), n = n(), .groups = "drop")
  pre_of <- function(m, col) { v <- pre[[col]][pre$Mother == m]; if (length(v) == 0) NA_real_ else v }

  extract <- function(m, outcome_name, pre_col) {
    tibble(
      outcome         = outcome_name,
      estimate        = unname(coef(m)[["Mother:Post"]]),
      std_error       = unname(se(m)[["Mother:Post"]]),
      p_value         = unname(pvalue(m)[["Mother:Post"]]),
      n               = as.integer(nobs(m)),
      pre_mean_mothers   = pre_of(1, pre_col),
      pre_mean_childless = pre_of(0, pre_col),
      pre_sd_exposure    = sd(df$WFH_Exposure[df$Post == 0])
    )
  }
  table <- bind_rows(
    extract(m_exposure, "Occupation-level WFH exposure (mean)", "mean_exposure"),
    extract(m_top,      "In top exposure quartile (share)",     "share_top")
  ) %>%
    mutate(estimate_per_pre_sd = if_else(outcome == "Occupation-level WFH exposure (mean)",
                                         estimate / pre_sd_exposure, NA_real_))

  # Event-study form: needs the survey-year column. Skipped, with a message, on a frame without it
  # (the synthetic fixtures without with_years = TRUE), never silently.
  es_coefs <- NULL
  m_es     <- NULL
  if ("ShnatSeker" %in% names(df)) {
    m_es <- feols(
      as.formula(paste(
        sprintf("WFH_Exposure ~ Mother + i(ShnatSeker, ref = %d) + i(ShnatSeker, Mother, ref = %d) +",
                ref_year, ref_year),
        paste(controls, collapse = " + ")
      )),
      data = df, cluster = ~IDPUF
    )
    es_coefs <- tidy_event_study_coefs(m_es, term_suffix = "Mother", ref_year = ref_year)
  } else {
    message("run_exposure_sorting_check: no ShnatSeker column -- the event-study version is skipped.")
  }

  message("=== Sorting check: DiD on occupational exposure itself (Mother x Post, clustered by IDPUF) ===")
  print(as.data.frame(table), digits = 4)
  if (!is.null(es_coefs)) {
    message("=== Sorting check, event-study form (Mother x year on exposure, ref ", ref_year, ") ===")
    print(as.data.frame(es_coefs %>% select(year, estimate, std_error, p_value)), digits = 4)
  }

  invisible(list(
    table       = table,
    pre_levels  = pre,
    event_study = es_coefs,
    models      = list(exposure = m_exposure, top_quartile = m_top, event_study = m_es),
    ref_year    = ref_year
  ))
}
