# clustered_se.R
# Cluster-robust estimate + standard error for the descriptive statistics in the paper's §4.
#
# Why this exists. Every figure in §4 originally carried hand-computed standard errors --
# sd/sqrt(n) for a cell mean, sqrt(se_a^2 + se_b^2) for a difference, sqrt(p(1-p)/n) for a rate --
# all of which assume independent observations. The CBS LFS is a rotating panel and the analysis
# sample is nothing like independent: 258,175 hours rows come from 64,602 individuals, 4.0 rows per
# person, and 2.7-2.9 rows per person even within a single survey year, with 96.4% of rows
# belonging to an IDPUF that appears more than once. Measured against feols, the hand-computed SEs
# are understated by roughly 1.6x within year and 1.85x pooled.
#
# That mattered for more than tidiness: §4.3's claim that the three pre-period gaps each lie within
# the others' confidence bounds was FALSE under the unclustered intervals and is TRUE under the
# clustered ones. Widening the intervals repaired the sentence rather than forcing its deletion.
#
# Every quantity this replaces is a saturated difference in means, so the POINT ESTIMATE is
# unchanged by construction -- feols on `y ~ 1` returns the cell mean, on `y ~ Mother` the
# difference in means, and on `y ~ Mother*Post` the exact 2x2 difference-in-differences. Only the
# standard error moves. Any change in a point estimate after adopting this is a bug, and that is
# the integrity check the §4 audit pass verified against.
#
# Note this does NOT make the descriptive figures inferential: they still carry no controls and no
# identifying assumption. It only stops them claiming more precision than the data support.
library(fixest)

clustered_se <- function(data, formula, term, cluster = ~IDPUF) {
  # A degenerate subset degrades to NA rather than erroring. These run once per cell / year /
  # quartile, so one thin cell must not abort a whole figure -- and feols() does not merely return
  # an empty fit on such a subset, it stop()s ("the estimation cannot be done"), which is why the
  # guard has to wrap the call rather than inspect its result. The fixture-sized panels in
  # tests/testthat exercise exactly this path.
  m <- tryCatch(
    suppressMessages(feols(formula, data = data, cluster = cluster)),
    error = function(e) NULL
  )

  n_obs <- if (is.null(m)) sum(stats::complete.cases(data)) else stats::nobs(m)

  if (is.null(m) || !term %in% names(stats::coef(m))) {
    return(list(estimate = NA_real_, se = NA_real_, n = n_obs))
  }

  # A fit can succeed and still yield a non-finite SE (a cluster count of one, say). Report that as
  # NA too rather than plotting an interval of infinite width.
  est <- unname(stats::coef(m)[[term]])
  s   <- unname(fixest::se(m)[[term]])

  list(
    estimate = est,
    se       = if (is.finite(s)) s else NA_real_,
    n        = n_obs
  )
}
