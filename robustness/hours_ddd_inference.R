# hours_ddd_inference.R
# Small-cluster inference for the hours DDD, whose regressor varies across forty occupations.
# run_hours_ddd_wild_bootstrap(): wild cluster bootstrap p-values (Rademacher, null imposed) via
# fwildclusterboot::boottest(), for the headline and the event study's pre-period terms; the joint
# pre-trend test stays the analytic Wald F. run_hours_ddd_permutation_test(): the forty exposure
# scores are reassigned across occupations, the DDD refit and the cluster-robust t recorded; the
# studentized statistic is used because the raw coefficient is not pivotal across reassignments.
# fwildclusterboot is loaded inside the function; dqrng::dqset.seed() is what fixes its draws.
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
  # The package's one-time reproducibility note is suppressed.
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

  # Permute the score vector and index it onto rows.
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
  # Phipson and Smyth (2010): count the observed statistic among the draws.
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
