# helper-setup.R
# testthat auto-sources every helper-*.R file (with working directory set to tests/testthat/)
# before running any test-*.R file. This locates the project root robustly (regardless of exactly
# where testthat sets the working directory), sources every function-bearing .R file in scripts/
# and robustness/ (never main.R itself — it does rm(list=ls()) and would wipe the test session),
# and exposes shared fixtures/helpers used across test files.

find_project_root <- function(start = getwd()) {
  dir <- normalizePath(start, mustWork = TRUE)
  for (i in 1:8) {
    if (file.exists(file.path(dir, "main.R"))) return(dir)
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  stop("Could not locate project root (main.R not found in any parent of ", start, ")")
}

project_root <- find_project_root()

# The function-bearing files live in scripts/ and each other's internal source() calls (e.g.
# data_processing.R referenced from basic_regression.R) use root-relative paths like
# file.path("scripts", "data_processing.R") -- resolved against the current working directory, not
# against the sourced file's own location. So instead of chdir=TRUE per file (which would cd into
# scripts/ and break those internal file.path("scripts", ...) calls by doubling the prefix), pin the
# working directory to project_root once for the whole block and restore it explicitly afterward.
# (Not on.exit(): at this top-level script scope there's no enclosing function frame to attach a
# reliable exit handler to, so an explicit setwd() back is used instead.)
old_wd <- setwd(project_root)

source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "clustered_se.R"))
source(file.path("scripts", "paper_theme.R"))
source(file.path("scripts", "comparative_statistics.R"))
source(file.path("scripts", "descriptive_table.R"))
source(file.path("scripts", "basic_regression.R"))
source(file.path("scripts", "basic_reg_compared_data.R"))
source(file.path("scripts", "intensive_margin_regression.R"))
source(file.path("scripts", "imbens_manski_ci.R"))
source(file.path("scripts", "lee_trim_proportion.R"))
source(file.path("scripts", "lee_trim_cell.R"))
source(file.path("scripts", "intensive_margin_lee_bounds.R"))
source(file.path("scripts", "placebo_male_frame.R"))
source(file.path("scripts", "gender_placebo.R"))
source(file.path("scripts", "hours_gender_placebo.R"))
source(file.path("scripts", "wfh_exposure_index.R"))
source(file.path("scripts", "wfh_exposure_cells.R"))
source(file.path("scripts", "isco_masking_diagnostics.R"))
source(file.path("scripts", "ddd_collinearity_diagnostics.R"))
source(file.path("scripts", "israeli_market_mismatch.R"))
source(file.path("scripts", "hours_ddd_regression.R"))
source(file.path("scripts", "tidy_event_study_coefs.R"))
source(file.path("scripts", "hours_ddd_event_study.R"))
source(file.path("scripts", "hours_ddd_lee_bounds.R"))
source(file.path("scripts", "wfh_first_stage_check.R"))
source(file.path("scripts", "ddd_mde_diagnostics.R"))
source(file.path("scripts", "hours_subgroup_comparison.R"))
source(file.path("scripts", "hours_descriptive_plots.R"))
source(file.path("scripts", "hours_dose_response.R"))
source(file.path("scripts", "wfh_share_by_year.R"))
source(file.path("scripts", "absence_by_exposure_quartile.R"))
source(file.path("scripts", "build_mechanism_scatter.R"))
source(file.path("scripts", "build_event_study_plot.R"))
source(file.path("scripts", "export_results.R"))
source(file.path("scripts", "export_paper_figures.R"))
source(file.path("scripts", "Diagnostics.R"))
source(file.path("scripts", "hours_diagnostics.R"))
source(file.path("scripts", "employment_by_child_age.R"))
source(file.path("scripts", "validation.R"))
source(file.path("scripts", "occupation_exposure_breaks.R"))
source(file.path("scripts", "assign_wfh_quartile.R"))
source(file.path("scripts", "hours_ddd_saturated.R"))
source(file.path("scripts", "hours_ddd_binned.R"))
source(file.path("scripts", "hours_ddd_by_child_age.R"))
source(file.path("scripts", "wfh_occupation_first_stage.R"))
source(file.path("scripts", "build_permutation_plot.R"))
source(file.path("scripts", "tex_coef_cell.R"))
source(file.path("scripts", "format_tex_table_body.R"))
source(file.path("scripts", "build_paper_tables.R"))
source(file.path("scripts", "export_paper_tables.R"))
# 2026-09-23 grade-report-2 response (docs/decisions/grade-report-2-response.md).
source(file.path("scripts", "hours_ddd_swap_control.R"))
source(file.path("scripts", "exposure_sorting_check.R"))
source(file.path("scripts", "hours_ddd_cell_exposure.R"))
source(file.path("scripts", "hours_ddd_leave_one_out.R"))
source(file.path("scripts", "build_leave_one_out_plot.R"))
source(file.path("scripts", "build_balance_by_exposure_quartile.R"))

# The 3 robustness-chain scripts below live in robustness/, not scripts/ -- each defines several
# related functions (a diagnostic + one or more regression specs sharing it), not the single
# function per file convention scripts/ holds its members to.
source(file.path("robustness", "balance_test.R"))
source(file.path("robustness", "age_balance_robustness.R"))
source(file.path("robustness", "pretrend_wald_test.R"))
source(file.path("robustness", "hours_ddd_inference.R"))

setwd(old_wd)

fixtures_dir <- file.path(project_root, "tests", "testthat", "fixtures")

# Redirects graphics output to a null device for the duration of `expr`, so Diagnostics.R's
# dev.new()/iplot() calls neither pop a window nor litter the repo with stray PDFs when tests run
# headlessly. Base-R only (no withr dependency).
with_null_device <- function(expr) {
  grDevices::pdf(file = nullfile())
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
}

# Extracts the value assigned to `controls` in a source file's text -- either a `c(...)`
# character-vector literal, or (since Checkpoint 3) a bare reference like `DEFAULT_CONTROLS`.
# Relies on the controls assignment containing no nested parentheses in the c(...) case, which
# holds for how it's written in this codebase today.
extract_controls_vector <- function(file_path) {
  txt <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
  m <- regmatches(txt, regexpr("controls\\s*<-\\s*(c\\([^)]*\\)|[A-Za-z_][A-Za-z0-9_.]*)", txt))
  if (length(m) != 1 || !nzchar(m)) {
    stop("Could not find a `controls <- ...` assignment in ", file_path)
  }
  eval(parse(text = m), envir = globalenv())
}

# A synthetic occupation-level hours panel with a known injected DDD effect, shared by
# test-hours_ddd_regression.R, test-hours_gender_placebo.R and test-hours_ddd_event_study.R. The
# first two files previously carried character-identical copies of this that differed only in the
# Min column, so a fix to one silently left the other behind; `min_sex = 1L` produces the
# male-subsample variant the placebo needs.
#
# 10 occupations with distinct, evenly-spaced exposure. Mother/Post are assigned independently per
# row rather than per occupation: the regression needs within-occupation variation in both, and
# occupation-level assignment would make an occupation entirely Mother or entirely non-Mother.
#
# `with_years` adds the ShnatSeker column the event-study specification needs, drawn consistently
# with each row's existing Post value (Post == 0 -> a pre-2020 year, Post == 1 -> a post year), so
# the two columns cannot disagree the way an independently sampled year column would. Trailing, and
# defaulting to FALSE, so the two original callers are untouched -- the same convention `min_sex`
# follows above.
# `with_child_age` (2026-09-22) adds GilYeledTzairMBNK -- 0 for non-mothers, a random 1-5 bin for
# mothers -- for run_hours_ddd_by_child_age(). Trailing and default FALSE, like the others.
make_hours_ddd_panel <- function(delta = -3, n = 400, n_occ = 10, min_sex = NULL,
                                 with_years = FALSE,
                                 pre_years = c(2017, 2018, 2019),
                                 post_years = c(2021, 2022, 2023),
                                 with_child_age = FALSE) {
  occ_codes <- 300 + seq_len(n_occ)
  exposure_index <- tibble::tibble(
    occupation_code = occ_codes,
    wfh_exposure    = seq(0.05, 0.95, length.out = n_occ)
  )

  occ_i <- sample(seq_len(n_occ), n, replace = TRUE)
  panel <- tibble::tibble(
    MishlachYad_ISCO_08_2 = occ_codes[occ_i],
    .wfh                  = exposure_index$wfh_exposure[occ_i],
    MatzavMishpachti = factor(sample(1:5, n, replace = TRUE)),
    Dat              = factor(sample(1:5, n, replace = TRUE)),
    GilNK            = factor(sample(3:7, n, replace = TRUE)),
    MachozMegurim    = factor(sample(1:7, n, replace = TRUE)),
    TeudaGvoha       = factor(sample(c("A", "B", "C"), n, replace = TRUE)),
    Mother   = sample(0:1, n, replace = TRUE),
    Post     = sample(0:1, n, replace = TRUE),
    Employed = 1L
  ) %>%
    dplyr::mutate(
      WorkHoursCont = 40 + delta * Mother * Post * .wfh + stats::rnorm(dplyr::n(), 0, 0.5),
      IDPUF = dplyr::row_number()
    ) %>%
    dplyr::select(-.wfh)

  if (!is.null(min_sex)) panel <- dplyr::mutate(panel, Min = min_sex, .before = 1)

  if (isTRUE(with_years)) {
    panel <- dplyr::mutate(
      panel,
      ShnatSeker = ifelse(
        Post == 1,
        sample(post_years, dplyr::n(), replace = TRUE),
        sample(pre_years,  dplyr::n(), replace = TRUE)
      )
    )
  }

  if (isTRUE(with_child_age)) {
    panel <- dplyr::mutate(
      panel,
      GilYeledTzairMBNK = ifelse(Mother == 1, sample(1:5, dplyr::n(), replace = TRUE), 0)
    )
  }

  list(panel = panel, exposure_index = exposure_index)
}
