# hours_ddd_inference.R
# Small-cluster inference for the primary hours DDD (scripts/hours_ddd_regression.R), added in
# response to the 2026-09-22 grade report (items R1 and M2; docs/decisions/grade-report-response.md).
# Two functions, both about the same forty-cluster problem, so this lives in robustness/ with the
# other multi-function robustness chains rather than in scripts/.
#
# The headline regressor is constant within forty two-digit occupations, so standard errors are
# clustered at that level and the reported p-values lean on a t(39) approximation. Two things
# complement that:
#
#   1. run_hours_ddd_wild_bootstrap(): a wild cluster bootstrap p-value (Rademacher weights, null
#      imposed) via fwildclusterboot::boottest(). Used for the headline triple interaction on the
#      pooled model, and for the DDD event study's two pre-period coefficients individually and
#      as a sum. The JOINT pre-trend test stays the analytic Wald F from pretrend_wald_test.R:
#      fwildclusterboot's mboottest() runs only through Julia (WildBootTests.jl), which is not part
#      of this project's toolchain. boottest() also refuses fixest's `^` fixed-effect syntax, so
#      the saturated column (scripts/hours_ddd_saturated.R) reports analytic SEs only.
#
#   2. run_hours_ddd_permutation_test(): a randomization test of the sharp null that the exposure
#      score is exchangeable across occupations. The forty occupation scores are permuted across
#      the forty occupation codes (the Mother/Post design and every individual's occupation stay
#      fixed), the DDD is refit, and the cluster-robust t of the triple interaction is recorded.
#      The reference distribution is of the STUDENTIZED statistic, not the raw coefficient:
#      reassigning exposure across occupations of very different sizes changes the coefficient's
#      sampling variance draw to draw, so the raw coefficient is not pivotal. This is also the
#      paper's genuine falsification test -- the fathers' comparison is a different population,
#      not an untreated one.
#
# Dependency note. fwildclusterboot (and dqrng, which it draws from) is the one package beyond
# tidyverse + fixest this project uses, flagged in CLAUDE.md and README.md. It is loaded with
# requireNamespace() INSIDE the function, never library() at file top: tests/testthat/helper-setup.R
# sources this file, and a top-level library() would break the whole test session on a machine
# without it. Seeding: set.seed() alone does NOT fix boottest()'s Rademacher draws (verified:
# two runs after set.seed(1) gave different p-values); dqrng::dqset.seed() is what the package
# samples from, so both are set.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))

run_hours_ddd_wild_bootstrap <- function(model, param, clustid = "MishlachYad_ISCO_08_2",
                                         B = 9999, seed = 20260922, R = NULL, r = 0,
                                         type = "rademacher", label = NULL) {
  for (pkg in c("fwildclusterboot", "dqrng")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("run_hours_ddd_wild_bootstrap: package '", pkg, "' is not installed. It is the one ",
           "dependency beyond tidyverse + fixest (see README.md); install it or skip this step.")
    }
  }
  if (!all(param %in% names(coef(model)))) {
    stop("run_hours_ddd_wild_bootstrap: coefficient(s) not in the model: ",
         paste(setdiff(param, names(coef(model))), collapse = ", "))
  }

  dqrng::dqset.seed(seed)
  set.seed(seed)

  args <- list(object = model, param = param, clustid = clustid, B = B, type = type,
               impose_null = TRUE)
  if (!is.null(R)) {
    args$R <- R
    args$r <- r
  }
  # The package prints a one-time note about reproducibility across its own versions; that is not
  # a problem with this call and would otherwise land in every main.R log.
  bt <- suppressWarnings(suppressMessages(do.call(fwildclusterboot::boottest, args)))

  ci <- bt$conf_int
  if (is.null(ci) || length(ci) < 2) ci <- c(NA_real_, NA_real_)

  tbl <- tibble(
    label          = if (is.null(label)) paste(param, collapse = " + ") else label,
    param          = paste(param, collapse = " + "),
    estimate       = unname(bt$point_estimate),
    t_stat         = unname(bt$t_stat),
    p_boot         = unname(bt$p_val),
    ci_low         = unname(ci[1]),
    ci_high        = unname(ci[2]),
    B              = as.integer(B),
    n_clusters     = as.integer(bt$N_G),
    weights        = type,
    null_imposed   = TRUE,
    seed           = as.integer(seed)
  )

  message(sprintf(
    "run_hours_ddd_wild_bootstrap [%s]: estimate = %.4f, t = %.3f, bootstrap p = %.4f (B = %d, %d clusters, %s weights).",
    tbl$label, tbl$estimate, tbl$t_stat, tbl$p_boot, B, tbl$n_clusters, type
  ))

  invisible(list(table = tbl, boottest = bt))
}

run_hours_ddd_permutation_test <- function(cleaned_df, exposure_index, n_perm = 999,
                                           seed = 20260922, controls = DEFAULT_CONTROLS,
                                           coef_name = "Mother:Post:WFH_Exposure",
                                           outcome = "WorkHoursCont", report_every = 100) {
  if (n_perm < 1) stop("run_hours_ddd_permutation_test: n_perm must be at least 1.")

  # Same join as run_hours_ddd_regression(), so the observed statistic is the headline's.
  df_ddd <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )

  formula_ddd <- as.formula(paste(
    outcome, "~ Mother*Post*WFH_Exposure +", paste(controls, collapse = " + ")
  ))
  fit <- function(d) feols(formula_ddd, data = d, cluster = ~MishlachYad_ISCO_08_2, notes = FALSE)

  m_obs <- fit(df_ddd)
  if (!coef_name %in% names(coef(m_obs))) {
    stop("run_hours_ddd_permutation_test: '", coef_name, "' not estimated on the observed data.")
  }
  b_obs <- unname(coef(m_obs)[[coef_name]])
  t_obs <- b_obs / unname(se(m_obs)[[coef_name]])
  n_clusters <- n_distinct(df_ddd$MishlachYad_ISCO_08_2)

  # Permute the occupation-level score vector and index it onto rows, rather than re-joining or
  # mutating a 246k-row frame through dplyr each draw.
  codes <- exposure_index$occupation_code
  vals  <- exposure_index$wfh_exposure
  idx   <- match(df_ddd$MishlachYad_ISCO_08_2, codes)

  set.seed(seed)
  coef_perm <- numeric(n_perm)
  t_perm    <- numeric(n_perm)
  started <- Sys.time()
  for (i in seq_len(n_perm)) {
    df_ddd$WFH_Exposure <- sample(vals)[idx]
    m <- fit(df_ddd)
    if (coef_name %in% names(coef(m))) {
      coef_perm[i] <- unname(coef(m)[[coef_name]])
      t_perm[i]    <- coef_perm[i] / unname(se(m)[[coef_name]])
    } else {
      coef_perm[i] <- NA_real_
      t_perm[i]    <- NA_real_
    }
    if (report_every > 0 && i %% report_every == 0) {
      elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
      message(sprintf("run_hours_ddd_permutation_test: %d / %d draws (%.0f s elapsed).",
                      i, n_perm, elapsed))
    }
  }

  ok <- is.finite(t_perm)
  n_ok <- sum(ok)
  # Phipson & Smyth (2010): count the observed statistic among the draws, so p is never zero and
  # its resolution is honestly 1 / (n_perm + 1).
  p_perm_t    <- (1 + sum(abs(t_perm[ok]) >= abs(t_obs))) / (1 + n_ok)
  p_perm_coef <- (1 + sum(abs(coef_perm[ok]) >= abs(b_obs))) / (1 + n_ok)

  tbl <- tibble(
    coef_name        = coef_name,
    estimate         = b_obs,
    t_stat           = t_obs,
    p_perm           = p_perm_t,
    p_perm_coef      = p_perm_coef,
    n_perm           = as.integer(n_perm),
    n_perm_valid     = as.integer(n_ok),
    seed             = as.integer(seed),
    n_clusters       = as.integer(n_clusters),
    t_perm_q025      = unname(quantile(t_perm[ok], 0.025)),
    t_perm_q975      = unname(quantile(t_perm[ok], 0.975)),
    t_perm_max_abs   = max(abs(t_perm[ok])),
    coef_perm_q025   = unname(quantile(coef_perm[ok], 0.025)),
    coef_perm_q975   = unname(quantile(coef_perm[ok], 0.975)),
    # Monte-Carlo standard error of p at the reported value, so a reader can see the resolution.
    p_perm_mc_se     = sqrt(p_perm_t * (1 - p_perm_t) / n_ok)
  )

  draws <- tibble(draw = seq_len(n_perm), coef = coef_perm, t_stat = t_perm)

  message(sprintf(
    paste0("run_hours_ddd_permutation_test: observed %s = %.4f (t = %.3f); permutation p = %.4f ",
           "on the |t| scale (%.4f on the |coef| scale), %d valid draws of %d, seed %d. ",
           "Largest |t| under the null: %.3f."),
    coef_name, b_obs, t_obs, p_perm_t, p_perm_coef, n_ok, n_perm, seed, tbl$t_perm_max_abs
  ))

  invisible(list(table = tbl, draws = draws, model = m_obs))
}
