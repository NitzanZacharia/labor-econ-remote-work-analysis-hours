# build_paper_tables.R
# Assembles every regression and summary table paper/paper.tex prints, as booktabs tabular blocks
# built directly from the fitted models and result frames of a pipeline run. Part of the
# generated-table layer added for the 2026-09-22 grade-report response (item C1;
# docs/decisions/grade-report-response.md).
#
# Before this file existed every table in the paper was a hand-typed tabular block transcribed
# from outputs/*.csv. The numbers matched -- the grade report verified every cell -- but nothing
# enforced it, and one table note had drifted (Table 2 claimed a religion category was dropped
# that was not). Now main.R calls this once, after all models are fit, and export_paper_tables()
# writes one .tex file per block into paper/tables/; paper.tex \input{}s them inside its own,
# still hand-written, table floats (caption, label, notes).
#
# Conventions, all inherited from the paper as it stood:
#   - coefficients via tex_coef_cell(): fixest's 4-significant-digit formatting, stars per the
#     paper's legend, keyed on coefficient NAMES;
#   - the p<0.1 marker is \sym{\cdot}, and every star is a \sym{} macro paper.tex defines;
#   - N with thousands separators; R2 to five significant digits, as etable prints it;
#   - a bootstrap p of exactly zero prints as "<0.0001", the resolution of B = 9,999 draws.
#
# The one input contract: `r` is a named list (see the `need` vector below). Anything absent
# makes the function stop with the missing names, since a table silently built from a NULL model
# would print blanks where the paper expects numbers.
library(tidyverse)
library(fixest)
source(file.path("scripts", "tex_coef_cell.R"))
source(file.path("scripts", "format_tex_table_body.R"))

build_paper_tables <- function(r) {

  need <- c(
    "desc_table", "intensive_results", "hours_ddd", "hours_ddd_saturated", "hours_ddd_binned",
    "mde_hours", "hours_lee_bounds", "hours_ddd_external", "hours_ddd_realized",
    "hours_ddd_age_interacted", "hours_ddd_reweighted", "hours_ddd_unswapped", "hours_ddd_ex2023",
    "hours_ddd_twoway_model", "intensive_yearfe", "hours_ddd_noimputed", "hours_ddd_fulltime",
    "hours_ddd_longhours", "hours_wild_bootstrap",
    "intensive_jewish", "intensive_arab", "hours_ddd_jewish", "hours_ddd_arab",
    "hours_gender_placebo", "hours_ddd_by_child_age", "baseline_results",
    "ddd_employment_additive", "mde_additive", "baseline_employment_rate",
    "wfh_occupation_first_stage",
    # 2026-09-23 grade-report-2 response (docs/decisions/grade-report-2-response.md).
    "hours_ddd_calib_men", "hours_ddd_swap_control", "hours_ddd_cell_exposure",
    "exposure_sorting_check", "hours_ddd_leave_one_out", "balance_by_quartile"
  )
  missing <- setdiff(need, names(r))
  if (length(missing) > 0) {
    stop("build_paper_tables: missing input(s): ", paste(missing, collapse = ", "))
  }

  # ── formatting helpers ────────────────────────────────────────────────────────────────────
  # Fixed decimals throughout (2026-09-23): three for the hours tables, four for the employment
  # table, whose coefficients are on a probability scale. f3 is the standard-error / free-standing
  # coefficient formatter; dec() takes an explicit count.
  dec   <- function(x, d) if (is.na(x)) "" else paste0("$", formatC(x, digits = d, format = "f"), "$")
  f3    <- function(x) dec(x, 3)
  fN    <- function(n) if (is.na(n)) "" else format(as.integer(round(n)), big.mark = "{,}", trim = TRUE)
  fR2   <- function(m) if (is.null(m)) "" else formatC(unname(fixest::r2(m, "r2")), digits = 3, format = "f")
  # Cluster count for a fitted model: the explicit count a result object carries when it has one,
  # otherwise recovered from fixest's t degrees of freedom (G - 1 under one-way clustering; the
  # smaller G - 1 under two-way), which is exactly what the reported p-values use.
  n_cl  <- function(m, explicit = NULL) {
    if (!is.null(explicit) && is.finite(explicit)) return(fN(explicit))
    if (is.null(m)) return("")
    fN(fixest::degrees_freedom(m, type = "t") + 1)
  }
  fp    <- function(p) {
    if (is.na(p)) return("")
    if (p < 0.0001) "$<0.0001$" else paste0("$", formatC(p, digits = 4, format = "f"), "$")
  }
  span  <- function(text, n_col) c(sprintf("\\multicolumn{%d}{l}{%s}", n_col, text), rep(NA, n_col - 1))
  coef_pair_rows <- function(label, models, term, n_col, digits = 3) {
    # Two rows: label + coefficient cells, then blank label + SE cells. `models` is a list with one
    # entry per column (NULL for an empty column); `term` a single name or one per column.
    if (length(term) == 1) term <- rep(term, length(models))
    cells <- mapply(function(m, t) tex_coef_cell(m, t, digits = digits), models, term, SIMPLIFY = FALSE)
    top <- c(label, vapply(cells, `[`, character(1), 1))
    bot <- c("", vapply(cells, `[`, character(1), 2))
    rbind(top, bot)
  }
  coef_of <- function(m, term) if (is.null(m) || !term %in% names(coef(m))) NA_real_ else unname(coef(m)[[term]])
  se_of   <- function(m, term) if (is.null(m) || !term %in% names(coef(m))) NA_real_ else unname(fixest::se(m)[[term]])
  p_of    <- function(m, term) if (is.null(m) || !term %in% names(coef(m))) NA_real_ else unname(fixest::pvalue(m)[[term]])
  n_of    <- function(m) if (is.null(m)) NA_real_ else stats::nobs(m)
  mc3     <- function(text) c(sprintf("\\multicolumn{3}{c}{%s}", text), NA, NA)
  # One sentence per table about coefficients dropped for collinearity, generated from each
  # model's $collin.var (the mechanism that fixes the stale Table 2 note the grade report found).
  # `models` is a named list, the names being how the paper refers to each column or row.
  level_labels <- list(
    Dat              = c(`1` = "Jewish", `2` = "Christian", `3` = "Muslim", `4` = "Druze", `5` = "other"),
    MachozMegurim    = c(`1` = "Jerusalem", `2` = "North", `3` = "Haifa", `4` = "Center",
                         `5` = "Tel Aviv", `6` = "South", `7` = "Judea and Samaria"),
    MatzavMishpachti = c(`1` = "married", `2` = "married, living separately", `3` = "divorced",
                         `4` = "widowed", `5` = "single")
  )
  pretty_var <- function(v) {
    lab <- c(Dat = "religion", MachozMegurim = "district", MatzavMishpachti = "marital status",
             GilNK = "age group", TeudaGvoha = "education")
    for (p in names(lab)) {
      if (startsWith(v, p)) {
        code <- sub(paste0("^", p), "", v)
        lv <- level_labels[[p]]
        code_txt <- if (!is.null(lv) && code %in% names(lv)) unname(lv[code]) else code
        return(sprintf("the %s category `%s'", lab[[p]], code_txt))
      }
    }
    gsub("_", "\\\\_", v)
  }
  dropped_note <- function(models) {
    dropped <- lapply(models, function(m) if (is.null(m)) character(0) else m$collin.var)
    with_drops <- names(models)[lengths(dropped) > 0]
    if (length(with_drops) == 0) {
      return("No coefficient is dropped for collinearity in any column.")
    }
    parts <- vapply(with_drops, function(nm) {
      sprintf("%s drops %s, constant on that sample", nm,
              paste(vapply(dropped[[nm]], pretty_var, character(1)), collapse = " and "))
    }, character(1))
    parts[1] <- paste0(toupper(substr(parts[1], 1, 1)), substr(parts[1], 2, nchar(parts[1])))
    others <- setdiff(names(models), with_drops)
    tail_txt <- if (length(others) == 0) "" else "; no other column drops a coefficient"
    paste0(paste(parts, collapse = "; "), tail_txt, ".")
  }

  # Significance markers from a p-value, or from a difference and its clustered SE (normal
  # reference, for the descriptive balance table). Same legend as tex_coef_cell().
  star_of <- function(p) {
    if (is.na(p)) "" else if (p < 0.001) "\\sym{***}" else if (p < 0.01) "\\sym{**}"
    else if (p < 0.05) "\\sym{*}" else if (p < 0.1) "\\sym{\\cdot}" else ""
  }
  star_of_se <- function(b, s) {
    if (is.na(b) || is.na(s) || s <= 0) return("")
    star_of(2 * stats::pnorm(-abs(b / s)))
  }

  tables <- list()
  notes  <- character(0)

  # ── Table 1: descriptive statistics ───────────────────────────────────────────────────────
  cont <- r$desc_table$continuous
  cat  <- r$desc_table$categorical
  get_c <- function(measure) cont[cont$measure == measure, ]
  diff_cell <- function(row, d) {
    if (is.na(row$difference)) return("")
    if (is.na(row$se_difference)) return(dec(row$difference, d))
    paste0(dec(row$difference, d), " ", paste0("$(", formatC(row$se_difference, digits = d, format = "f"), ")$"))
  }
  obs <- get_c("Observations"); emp <- get_c("Employment rate")
  hm  <- get_c("Usual weekly hours (employed), mean"); hs <- get_c("Usual weekly hours (employed), SD")
  hn  <- get_c("Usual weekly hours (employed), N")
  ag  <- get_c("Age-group code (CBS 3-7), mean"); ar <- get_c("Arab (share)")
  ar_pct <- ar; ar_pct$childless <- 100 * ar$childless; ar_pct$mothers <- 100 * ar$mothers
  ar_pct$difference <- 100 * ar$difference; ar_pct$se_difference <- 100 * ar$se_difference

  desc_rows <- rbind(
    span("\\emph{Panel A: outcomes}", 4),
    c("Observations", fN(obs$childless), fN(obs$mothers), ""),
    c("Employment rate", dec(emp$childless, 4), dec(emp$mothers, 4), diff_cell(emp, 4)),
    c("Usual weekly hours (ref.-week workers), mean", dec(hm$childless, 2), dec(hm$mothers, 2), diff_cell(hm, 2)),
    c("\\quad standard deviation", paste0("[", formatC(hs$childless, digits = 2, format = "f"), "]"),
      paste0("[", formatC(hs$mothers, digits = 2, format = "f"), "]"), ""),
    c("\\quad observations with usual hours", fN(hn$childless), fN(hn$mothers), ""),
    span("\\emph{Panel B: characteristics}", 4),
    c("Age-group code (CBS 3--7), mean", dec(ag$childless, 2), dec(ag$mothers, 2), diff_cell(ag, 2)),
    c("Arab (\\%)", dec(ar_pct$childless, 2), dec(ar_pct$mothers, 2), diff_cell(ar_pct, 2))
  )
  cat_blocks <- list(
    MatzavMishpachti = list(title = "Marital status (\\%)", order = as.character(1:5)),
    Dat              = list(title = "Religion of household head (\\%)", order = as.character(1:5)),
    MachozMegurim    = list(title = "District of residence (\\%)", order = as.character(1:7)),
    TeudaGvoha       = list(title = "Education (\\%)",
                            order = c("Below High School", "High School (no matriculation)",
                                      "Matriculation (Bagrut)", "Post-secondary, non-academic",
                                      "Academic Degree (BA/MA/PhD)", "Other/No Certificate"))
  )
  edu_labels <- c("Below High School" = "Below high school",
                  "High School (no matriculation)" = "High school, no matriculation",
                  "Matriculation (Bagrut)" = "Matriculation (Bagrut)",
                  "Post-secondary, non-academic" = "Post-secondary, non-academic",
                  "Academic Degree (BA/MA/PhD)" = "Academic degree (BA/MA/PhD)",
                  "Other/No Certificate" = "Other / no certificate")
  addlines <- integer(0)
  for (v in names(cat_blocks)) {
    desc_rows <- rbind(desc_rows, c(paste0("\\emph{", cat_blocks[[v]]$title, "}"), "", "", ""))
    addlines <- c(addlines, nrow(desc_rows) - 1)
    sub <- cat[cat$variable == v, ]
    for (lv in cat_blocks[[v]]$order) {
      row <- sub[sub$level == lv, ]
      if (nrow(row) == 0) next
      lab <- if (v == "TeudaGvoha") unname(edu_labels[lv]) else row$level_label
      if (is.na(lab)) lab <- lv
      se_txt <- if ("se_pct_difference" %in% names(row) && !is.na(row$se_pct_difference)) {
        paste0(" $(", formatC(row$se_pct_difference, digits = 2, format = "f"), ")$")
      } else ""
      desc_rows <- rbind(desc_rows, c(
        paste0("\\quad ", lab), dec(row$pct_mother0, 2), dec(row$pct_mother1, 2),
        paste0(dec(row$pct_difference, 2), se_txt)
      ))
    }
  }
  panel_b_start <- which(!is.na(desc_rows[, 1]) & grepl("Panel B", desc_rows[, 1]))
  tables$tab_descriptives <- format_tex_table_body(
    desc_rows, colspec = "lccc",
    header = list(c("", "Childless women", "Mothers", "Difference (SE)")),
    midrule_after = panel_b_start - 1,
    addlinespace_after = addlines
  )

  # ── Table 2: hours DiD and DDD (four columns) ─────────────────────────────────────────────
  m_did <- r$intensive_results$models$hours
  m_ddd <- r$hours_ddd$model
  m_sat <- r$hours_ddd_saturated$model
  m_bin <- r$hours_ddd_binned$model
  cols4 <- list(m_did, m_ddd, m_sat, m_bin)
  q_sizes <- r$hours_ddd_binned$quartile_sizes
  q_occ <- paste(q_sizes$n_occupations[order(q_sizes$WFH_Exposure_Q)], collapse = " / ")
  mde <- r$mde_hours$table

  hours_rows <- rbind(
    coef_pair_rows("Mother $\\times$ Post $\\times$ WFH\\_Exposure", list(NULL, m_ddd, m_sat, NULL), "Mother:Post:WFH_Exposure", 4),
    coef_pair_rows("Mother $\\times$ Post $\\times$ Q2 (vs.\\ Q1)", list(NULL, NULL, NULL, m_bin), "Mother:Post:WFH_Exposure_Q::2", 4),
    coef_pair_rows("Mother $\\times$ Post $\\times$ Q3 (vs.\\ Q1)", list(NULL, NULL, NULL, m_bin), "Mother:Post:WFH_Exposure_Q::3", 4),
    coef_pair_rows("Mother $\\times$ Post $\\times$ Q4 (vs.\\ Q1)", list(NULL, NULL, NULL, m_bin), "Mother:Post:WFH_Exposure_Q::4", 4),
    coef_pair_rows("Mother $\\times$ Post", list(m_did, m_ddd, NULL, m_bin), "Mother:Post", 4),
    coef_pair_rows("Mother $\\times$ WFH\\_Exposure", list(NULL, m_ddd, NULL, NULL), "Mother:WFH_Exposure", 4),
    coef_pair_rows("Post $\\times$ WFH\\_Exposure", list(NULL, m_ddd, NULL, NULL), "Post:WFH_Exposure", 4),
    coef_pair_rows("WFH\\_Exposure", list(NULL, m_ddd, NULL, NULL), "WFH_Exposure", 4),
    coef_pair_rows("Mother", list(m_did, m_ddd, NULL, m_bin), "Mother", 4),
    coef_pair_rows("Post", list(m_did, m_ddd, NULL, m_bin), "Post", 4),
    coef_pair_rows("Constant", list(m_did, m_ddd, NULL, m_bin), "(Intercept)", 4)
  )
  n_coef_rows <- nrow(hours_rows)
  hours_rows <- rbind(
    hours_rows,
    c("MDE for triple interaction ($t_{39}$)", "", dec(mde$mde, 3), "", ""),
    c("SD of exposure, estimation sample", "", dec(mde$regressor_sd, 3), "", ""),
    c("Triple interaction per SD of exposure", "", dec(r$mde_hours$point_estimate * mde$regressor_sd, 3), "", ""),
    c("Occupations in Q1 / Q2 / Q3 / Q4", "", "", "", q_occ),
    # The three FE sets are spelled out in the table note; the cell has to fit a five-column table.
    c("Fixed effects", "None", "None", "Three sets", "None"),
    c("Observations", fN(n_of(m_did)), fN(n_of(m_ddd)), fN(n_of(m_sat)), fN(n_of(m_bin))),
    c("$R^2$", fR2(m_did), fR2(m_ddd), fR2(m_sat), fR2(m_bin)),
    c("Clustering", "individual", "occupation (40)", "occupation (40)", "occupation (40)")
  )
  tables$tab_hours <- format_tex_table_body(
    hours_rows, colspec = "lcccc",
    header = list(c("", "(1) DiD", "(2) DDD", "(3) DDD, saturated", "(4) DDD, quartiles")),
    midrule_after = n_coef_rows
  )
  notes["autonoteHours"] <- dropped_note(list(
    "column (1)" = m_did, "column (2)" = m_ddd, "column (3)" = m_sat, "column (4)" = m_bin
  ))

  # ── Table 3a/3b: Lee bounds ───────────────────────────────────────────────────────────────
  qs <- r$hours_lee_bounds$diagnostics$quartile_selection_rates
  qs <- qs[order(qs$WFH_Exposure_Q), ]
  lee_a <- t(apply(qs, 1, function(x) c(
    as.character(as.integer(x[["WFH_Exposure_Q"]])),
    dec(as.numeric(x[["s00"]]), 4), dec(as.numeric(x[["s01"]]), 4), dec(as.numeric(x[["s10"]]), 4),
    dec(as.numeric(x[["s11"]]), 4), dec(as.numeric(x[["s11_counterfactual"]]), 4),
    fN(as.numeric(x[["n_mother1_post1"]])),
    paste0(formatC(100 * as.numeric(x[["trim_prop"]]), digits = 2, format = "f"), "\\%")
  )))
  tables$tab_lee_selection <- format_tex_table_body(
    lee_a, colspec = "lccccccc",
    header = list(c("Quartile", "$s_{00}$", "$s_{01}$", "$s_{10}$", "$s_{11}$", "$s^*_{11}$",
                    "$n(\\Mother{=}1,\\Post{=}1)$", "Trim"))
  )
  bt <- r$hours_lee_bounds$table
  im <- r$hours_lee_bounds$imbens_manski_ci
  bound_label <- c(lower = "Lower", `point (untrimmed)` = "Point (untrimmed)", upper = "Upper")
  lee_b <- t(apply(bt, 1, function(x) c(
    unname(bound_label[x[["bound"]]]),
    dec(as.numeric(x[["coef"]]), 3), dec(as.numeric(x[["se"]]), 3),
    sprintf("$[%s,\\ %s]$", formatC(as.numeric(x[["ci_low"]]), digits = 3, format = "f"),
            formatC(as.numeric(x[["ci_high"]]), digits = 3, format = "f"))
  )))
  lee_b <- rbind(lee_b, c("Imbens--Manski 95\\% CI for the identified set", "", "",
                          sprintf("$[%s,\\ %s]$", formatC(im$lower, digits = 3, format = "f"),
                                  formatC(im$upper, digits = 3, format = "f"))))
  tables$tab_lee_bounds <- format_tex_table_body(
    lee_b, colspec = "lccc",
    header = list(c("Bound", "Coefficient", "SE", "95\\% CI")),
    midrule_after = nrow(bt)
  )

  # ── Table 4: robustness of the triple interaction ─────────────────────────────────────────
  trip <- "Mother:Post:WFH_Exposure"
  # `stars = FALSE` for the rows whose p-value is NOT the analytic one (bootstrap, permutation):
  # analytic stars beside a bootstrap p would contradict the row's own column.
  # Six cells per row: label, coefficient, SE, p, N, clusters. `clusters` is printed as given when
  # supplied (a count, or "individual"), else recovered from the model's t degrees of freedom.
  spec_row <- function(label, m, term = trip, p_override = NULL, se_override = NULL, stars = TRUE,
                       clusters = NULL, coef_override = NULL, n_override = NULL, digits = 3) {
    c(label,
      if (is.null(coef_override)) tex_coef_cell(m, term, digits = digits, stars = stars)[1] else coef_override,
      if (is.null(se_override)) dec(se_of(m, term), digits) else se_override,
      if (is.null(p_override)) fp(p_of(m, term)) else p_override,
      if (is.null(n_override)) fN(n_of(m)) else n_override,
      if (is.null(clusters)) n_cl(m) else if (is.numeric(clusters)) fN(clusters) else clusters)
  }
  wb  <- r$hours_wild_bootstrap
  wb_head <- wb[wb$label == "headline", ]
  if (nrow(wb_head) == 0) stop("build_paper_tables: hours_wild_bootstrap has no 'headline' row.")
  # The permutation test sits behind RUN_PERMUTATION_TEST in main.R; without it the row is
  # omitted rather than printed blank, so a dev run cannot leave an empty p in the paper.
  pm  <- if (is.null(r$hours_permutation)) NULL else r$hours_permutation$table
  perm_row <- if (is.null(pm)) NULL else
    spec_row(sprintf("\\quad Permutation test (%s reassignments)", fN(pm$n_perm[1])), m_ddd,
             se_override = "", p_override = fp(pm$p_perm[1]), stars = FALSE,
             clusters = r$hours_ddd$n_clusters)
  n_occ_primary <- r$hours_ddd$n_clusters
  # Grade-report-2 rows. Men-only calibration: how many occupations that rule swapped is part of
  # the label, since it is the fact the row exists to report.
  cm <- r$hours_ddd_calib_men
  calib_men_row <- spec_row(
    sprintf("\\quad Calibrated on men only (%d of %d swapped)", as.integer(cm$n_swapped), as.integer(cm$n_occupations)),
    cm$result$model, clusters = cm$result$n_clusters
  )
  sc <- r$hours_ddd_swap_control
  swap_rows <- rbind(
    spec_row("\\quad External index with swapped-occupation terms (40 occ.)", sc$model,
             clusters = sc$n_clusters),
    spec_row("\\quad\\quad $\\Mother \\times \\Post \\times \\mathrm{Swapped}$ (same model)", sc$model,
             term = "Mother:Post:Swapped", clusters = sc$n_clusters)
  )
  loo <- r$hours_ddd_leave_one_out$summary
  loo_row <- c(
    sprintf("\\quad Leave-one-occupation-out (%d refits): range", as.integer(loo$n_refits_valid)),
    sprintf("$[%s,\\ %s]$", formatC(loo$min_estimate, digits = 3, format = "f"),
            formatC(loo$max_estimate, digits = 3, format = "f")),
    "",
    sprintf("$[%s,\\ %s]$", formatC(loo$min_p_value, digits = 4, format = "f"),
            formatC(loo$max_p_value, digits = 4, format = "f")),
    "",
    fN(n_occ_primary - 1)
  )
  ce <- r$hours_ddd_cell_exposure
  ce_coef <- ce$coefs
  cell_row <- spec_row(
    "\\quad Pre-period cell exposure as regressor, per SD", ce$model,
    coef_override = paste0(dec(ce_coef$estimate_per_sd, 3), star_of(ce_coef$p_value)),
    se_override = dec(ce_coef$se_per_sd, 3), clusters = ce$n_clusters
  )
  es <- r$exposure_sorting_check
  es_exp <- es$table[es$table$outcome == "Occupation-level WFH exposure (mean)", ]
  es_top <- es$table[es$table$outcome == "In top exposure quartile (share)", ]
  sort_rows <- rbind(
    spec_row("\\quad Exposure score as outcome: $\\Mother \\times \\Post$", es$models$exposure,
             term = "Mother:Post", clusters = "individual"),
    spec_row("\\quad Top-quartile indicator as outcome: $\\Mother \\times \\Post$", es$models$top_quartile,
             term = "Mother:Post", clusters = "individual")
  )
  robust_rows <- rbind(
    span("\\emph{Exposure measure}", 6),
    spec_row("\\quad Calibrated (primary)", m_ddd, clusters = n_occ_primary),
    spec_row("\\quad External (Dingel--Neiman)", r$hours_ddd_external$model, clusters = r$hours_ddd_external$n_clusters),
    spec_row("\\quad Realized (2021 anchor)", r$hours_ddd_realized$model, clusters = r$hours_ddd_realized$n_clusters),
    calib_men_row,
    swap_rows,
    span("\\emph{Age balance}", 6),
    spec_row("\\quad Age-interacted ($+\\,\\Mother \\times$ age group)", r$hours_ddd_age_interacted$model,
             clusters = r$hours_ddd_age_interacted$n_clusters),
    spec_row("\\quad Reweighted (pre-period age-group raking)", r$hours_ddd_reweighted$model,
             clusters = r$hours_ddd_reweighted$n_clusters),
    span("\\emph{Sample}", 6),
    spec_row("\\quad Unswapped occupations only", r$hours_ddd_unswapped$model, clusters = r$hours_ddd_unswapped$n_clusters),
    spec_row("\\quad Excluding survey year 2023", r$hours_ddd_ex2023$model, clusters = r$hours_ddd_ex2023$n_clusters),
    loo_row,
    span("\\emph{Occupational sorting}", 6),
    cell_row,
    sort_rows,
    span("\\emph{Outcome coding}", 6),
    spec_row("\\quad Irregular-hours codes dropped, not imputed", r$hours_ddd_noimputed$model, clusters = r$hours_ddd_noimputed$n_clusters),
    spec_row("\\quad Full-time indicator ($\\geq 35$ hours)", r$hours_ddd_fulltime$model, clusters = r$hours_ddd_fulltime$n_clusters),
    spec_row("\\quad Long-hours indicator ($\\geq 40$ hours)", r$hours_ddd_longhours$model, clusters = r$hours_ddd_longhours$n_clusters),
    span("\\emph{Inference on the primary estimate}", 6),
    spec_row("\\quad Two-way clustering (individual, occupation)", r$hours_ddd_twoway_model,
             clusters = sprintf("%s $\\times$ ind.", fN(n_occ_primary))),
    spec_row(sprintf("\\quad Wild cluster bootstrap ($B = %s$)", fN(wb_head$B[1])), m_ddd,
             p_override = fp(wb_head$p_boot[1]), stars = FALSE, clusters = n_occ_primary),
    perm_row
  )
  tables$tab_robust <- format_tex_table_body(
    robust_rows, colspec = "lccccc",
    header = list(c("Specification", "Coefficient", "SE", "$p$", "$N$", "Clusters"))
  )

  # ── Table 5: subgroups and the fathers' comparison ────────────────────────────────────────
  did_models <- list(
    "All women (primary)" = m_did,
    "Jewish women"        = r$intensive_jewish$models$hours,
    "Arab women"          = r$intensive_arab$models$hours,
    "Men (fathers vs.\\ childless)" = r$hours_gender_placebo$result$models$hours
  )
  ddd_models <- list(
    "All women (primary)" = m_ddd,
    "Jewish women"        = r$hours_ddd_jewish$model,
    "Arab women"          = r$hours_ddd_arab$model,
    "Men (fathers vs.\\ childless)" = r$hours_gender_placebo$ddd_placebo$model
  )
  sub_rows <- t(mapply(function(lab, md, mt) c(
    lab,
    tex_coef_cell(md, "Mother:Post")[1], f3(se_of(md, "Mother:Post")), fN(n_of(md)),
    tex_coef_cell(mt, trip)[1], f3(se_of(mt, trip)), fN(n_of(mt))
  ), names(did_models), did_models, ddd_models))
  ci_txt <- function(m, term) {
    b <- coef_of(m, term); s <- se_of(m, term)
    if (is.na(b)) return("")
    sprintf("$[%s,\\ %s]$", formatC(b - 1.96 * s, digits = 3, format = "f"),
            formatC(b + 1.96 * s, digits = 3, format = "f"))
  }
  ztest <- function(m1, m2, term) {
    b1 <- coef_of(m1, term); b2 <- coef_of(m2, term); s1 <- se_of(m1, term); s2 <- se_of(m2, term)
    z <- (b1 - b2) / sqrt(s1^2 + s2^2)
    c(z = z, p = 2 * stats::pnorm(-abs(z)))
  }
  z_ja_did <- ztest(did_models[[2]], did_models[[3]], "Mother:Post")
  z_ja_ddd <- ztest(ddd_models[[2]], ddd_models[[3]], trip)
  z_wm_did <- ztest(did_models[[1]], did_models[[4]], "Mother:Post")
  z_wm_ddd <- ztest(ddd_models[[1]], ddd_models[[4]], trip)
  ztxt <- function(z) sprintf("$%s$ (%s)", formatC(z[["z"]], digits = 3, format = "f"),
                              formatC(z[["p"]], digits = 3, format = "f"))
  sub_rows <- rbind(
    sub_rows,
    c("95\\% CI, Jewish", mc3(ci_txt(did_models[[2]], "Mother:Post")), mc3(ci_txt(ddd_models[[2]], trip))),
    c("95\\% CI, Arab", mc3(ci_txt(did_models[[3]], "Mother:Post")), mc3(ci_txt(ddd_models[[3]], trip))),
    c("Jewish vs.\\ Arab, $z$ ($p$)", mc3(ztxt(z_ja_did)), mc3(ztxt(z_ja_ddd))),
    c("Women vs.\\ men, $z$ ($p$)", mc3(ztxt(z_wm_did)), mc3(ztxt(z_wm_ddd)))
  )
  two_panel_header <- list(
    c("", mc3("DiD: $\\Mother \\times \\Post$"), mc3("DDD: $\\Mother \\times \\Post \\times \\WFH$")),
    "\\cmidrule(lr){2-4}\\cmidrule(lr){5-7}",
    c("Subgroup", "Coef.", "SE", "$N$", "Coef.", "SE", "$N$")
  )
  tables$tab_subgroup <- format_tex_table_body(
    sub_rows, colspec = "lcccccc", header = two_panel_header, midrule_after = 4
  )
  subgroup_ztests <- tibble(
    comparison = c("Jewish vs Arab", "Jewish vs Arab", "Women vs men", "Women vs men"),
    term       = c("Mother:Post", trip, "Mother:Post", trip),
    z          = c(z_ja_did[["z"]], z_ja_ddd[["z"]], z_wm_did[["z"]], z_wm_ddd[["z"]]),
    p          = c(z_ja_did[["p"]], z_ja_ddd[["p"]], z_wm_did[["p"]], z_wm_ddd[["p"]])
  )
  notes["autonoteSubgroup"] <- dropped_note(list(
    "the Jewish-women DiD" = did_models[[2]], "the Jewish-women DDD" = ddd_models[[2]],
    "the Arab-women DiD"   = did_models[[3]], "the Arab-women DDD"   = ddd_models[[3]],
    "the men's DiD"        = did_models[[4]], "the men's DDD"        = ddd_models[[4]]
  ))

  # ── Table 6: by age of youngest child ─────────────────────────────────────────────────────
  ca <- r$hours_ddd_by_child_age$table
  ca_models <- r$hours_ddd_by_child_age$models
  ca_rows <- rbind(
    c("All mothers (Table~\\ref{tab:hours})",
      tex_coef_cell(m_did, "Mother:Post")[1], f3(se_of(m_did, "Mother:Post")), fN(n_of(m_did)),
      tex_coef_cell(m_ddd, trip)[1], f3(se_of(m_ddd, trip)), fN(n_of(m_ddd)))
  )
  for (i in seq_len(nrow(ca))) {
    lab <- gsub("-", "--", ca$child_age_bin[i])
    ca_rows <- rbind(ca_rows, c(
      paste0("Youngest child aged ", lab),
      tex_coef_cell(ca_models$did[[ca$child_age_bin[i]]], "Mother:Post")[1],
      f3(ca$did_se[i]), fN(ca$did_n[i]),
      tex_coef_cell(ca_models$ddd[[ca$child_age_bin[i]]], trip)[1],
      f3(ca$ddd_se[i]), fN(ca$ddd_n[i])
    ))
  }
  ca_header <- two_panel_header
  ca_header[[3]][1] <- "Sample of mothers"
  tables$tab_childage <- format_tex_table_body(
    ca_rows, colspec = "lcccccc", header = ca_header, midrule_after = 1
  )
  notes["autonoteChildAge"] <- dropped_note(c(
    setNames(ca_models$did, paste0("the ", gsub("-", "--", names(ca_models$did)), " DiD")),
    setNames(ca_models$ddd, paste0("the ", gsub("-", "--", names(ca_models$ddd)), " DDD"))
  ))

  # ── Table 7: extensive margin ─────────────────────────────────────────────────────────────
  m_emp <- r$baseline_results$models$employed
  m_edd <- r$ddd_employment_additive
  mde_e <- r$mde_additive$table
  # Four fixed decimals here: the outcome is a probability, and the DiD's coefficient (-0.0053)
  # and SE (0.0052) would both print as 0.005 at three.
  ext_rows <- rbind(
    coef_pair_rows("Mother $\\times$ Post $\\times$ WFH\\_Exposure", list(NULL, m_edd), trip, 2, digits = 4),
    coef_pair_rows("Mother $\\times$ Post", list(m_emp, m_edd), "Mother:Post", 2, digits = 4),
    coef_pair_rows("Mother $\\times$ WFH\\_Exposure", list(NULL, m_edd), "Mother:WFH_Exposure", 2, digits = 4),
    coef_pair_rows("Post $\\times$ WFH\\_Exposure", list(NULL, m_edd), "Post:WFH_Exposure", 2, digits = 4),
    coef_pair_rows("WFH\\_Exposure", list(NULL, m_edd), "WFH_Exposure", 2, digits = 4),
    coef_pair_rows("Mother", list(m_emp, NULL), "Mother", 2, digits = 4),
    coef_pair_rows("Post", list(m_emp, NULL), "Post", 2, digits = 4),
    coef_pair_rows("Constant", list(m_emp, NULL), "(Intercept)", 2, digits = 4)
  )
  n_ext_coef <- nrow(ext_rows)
  ext_rows <- rbind(
    ext_rows,
    c("MDE ($\\alpha=0.05$, power $0.80$), per unit", "", dec(mde_e$mde, 4)),
    c("MDE per SD of exposure", "", dec(mde_e$mde_per_sd, 4)),
    c("\\quad as \\% of baseline employment rate", "", paste0(formatC(mde_e$mde_per_sd_pct_of_baseline, digits = 2, format = "f"), "\\%")),
    c("Observations", fN(n_of(m_emp)), fN(n_of(m_edd))),
    c("$R^2$", fR2(m_emp), fR2(m_edd)),
    c("Clustering", "individual", "demographic cell ($\\approx 210$)")
  )
  tables$tab_extensive <- format_tex_table_body(
    ext_rows, colspec = "lcc",
    header = list(c("", "(1) DiD", "(2) DDD, cell-based exposure")),
    midrule_after = c(n_ext_coef, n_ext_coef + 3)
  )
  notes["autonoteExtensive"] <- dropped_note(list("column (1)" = m_emp, "column (2)" = m_edd))

  # ── Appendix Table A1: the forty occupation scores ────────────────────────────────────────
  fs <- r$wfh_occupation_first_stage$table
  fs <- fs[order(fs$ISCO2), ]
  d3 <- function(x) if (is.na(x)) "" else formatC(x, digits = 3, format = "f")
  app_rows <- t(apply(fs, 1, function(x) c(
    as.character(as.integer(x[["ISCO2"]])),
    x[["label"]],
    d3(as.numeric(x[["external"]])),
    d3(as.numeric(x[["realized_usual_calibration"]])),
    if (isTRUE(as.logical(x[["swap"]]))) "yes" else "",
    d3(as.numeric(x[["calibrated"]])),
    d3(as.numeric(x[["realized_refweek"]])),
    fN(as.numeric(x[["n_refweek"]]))
  )))
  # A paragraph column for the titles, so the eight-column table fits the text width at
  # \footnotesize; the note in paper.tex expands the abbreviated headers.
  tables$tab_exposure_scores <- format_tex_table_body(
    app_rows, colspec = "lp{5.2cm}cccccc",
    header = list(c("ISCO", "Occupation (ISCO-08 sub-major group)", "Ext.", "Real.\\ 22--23",
                    "Swap", "Calib.", "Ref.-wk 21--23", "$N$"))
  )

  # ── Appendix Table A2: pre-period balance by exposure quartile ───────────────────────────
  # One column per quartile of the occupation-level score; each variable takes two rows, the
  # mother-minus-childless difference and its IDPUF-clustered SE. Shares are in percentage points,
  # the age code in code units, as build_balance_by_exposure_quartile() labels them.
  bq <- r$balance_by_quartile$table
  q_levels <- sort(unique(bq$WFH_Exposure_Q))
  bal_rows <- NULL
  for (v in unique(bq$variable)) {
    sub <- bq[bq$variable == v, ]
    sub <- sub[order(sub$WFH_Exposure_Q), ]
    lab <- sub$label[1]
    d <- if (sub$unit[1] == "code") 2 else 1
    top <- c(lab, vapply(q_levels, function(q) {
      row <- sub[sub$WFH_Exposure_Q == q, ]
      if (nrow(row) == 0 || is.na(row$difference)) "" else paste0(dec(row$difference, d), star_of_se(row$difference, row$se))
    }, character(1)))
    bot <- c("", vapply(q_levels, function(q) {
      row <- sub[sub$WFH_Exposure_Q == q, ]
      if (nrow(row) == 0 || is.na(row$se)) "" else paste0("$(", formatC(row$se, digits = d, format = "f"), ")$")
    }, character(1)))
    bal_rows <- rbind(bal_rows, top, bot)
  }
  n_bal_coef <- nrow(bal_rows)
  first_var <- bq[bq$variable == unique(bq$variable)[1], ]
  first_var <- first_var[order(first_var$WFH_Exposure_Q), ]
  qcell <- function(col, f) vapply(q_levels, function(q) {
    row <- first_var[first_var$WFH_Exposure_Q == q, ]
    if (nrow(row) == 0) "" else f(row[[col]])
  }, character(1))
  bal_rows <- rbind(
    bal_rows,
    c("Mothers", qcell("n_mothers", fN)),
    c("Childless women", qcell("n_childless", fN)),
    c("Occupations", qcell("n_occupations", fN)),
    c("Exposure range", vapply(q_levels, function(q) {
      row <- first_var[first_var$WFH_Exposure_Q == q, ]
      if (nrow(row) == 0) "" else sprintf("%s--%s", formatC(row$exposure_low, digits = 2, format = "f"),
                                          formatC(row$exposure_high, digits = 2, format = "f"))
    }, character(1)))
  )
  tables$tab_balance_quartile <- format_tex_table_body(
    bal_rows, colspec = paste0("l", strrep("c", length(q_levels))),
    header = list(c("Mothers minus childless women, pre-period", paste0("Q", q_levels))),
    midrule_after = n_bal_coef
  )

  invisible(list(tables = tables, notes = notes, subgroup_ztests = subgroup_ztests))
}
