# imbens_manski_ci.R
# Shared helper, extracted from intensive_margin_lee_bounds.R (where it was originally private) so
# hours_ddd_lee_bounds.R can reuse it without duplicating the closed-form solver. Imbens & Manski
# (2004), "Confidence Intervals for Partially Identified Parameters," Econometrica 72(6): a
# confidence interval for the TRUE parameter under partial identification (i.e. when only
# [theta_L, theta_U] is point-identified, not theta itself), not just each endpoint's own sampling
# uncertainty around its own point estimate in isolation.
#
# Solve for c_alpha in
#   Phi(c_alpha + delta / max(se_L, se_U)) - Phi(-c_alpha) = conf_level,   delta = theta_U - theta_L
# and report [theta_L - c_alpha*se_L, theta_U + c_alpha*se_U]. This collapses to the ordinary
# +-1.96*se interval when delta == 0 (no excess selection to trim, so lower/point/upper coincide).
#
# Properties worth knowing when reading the output: c_alpha lies strictly between the one-sided
# z (qnorm(1 - alpha)) and the two-sided z (qnorm(1 - alpha/2)), and DEcreases toward the
# one-sided value as delta / max(se) grows. The correction therefore widens the interval relative
# to using the one-sided z on each endpoint, not relative to the two-sided z.
imbens_manski_ci <- function(theta_L, theta_U, se_L, se_U, conf_level = 0.95) {
  delta <- max(theta_U - theta_L, 0)
  denom <- max(se_L, se_U)
  # delta == 0 has the closed form the comment above promises; return it exactly rather than
  # running the root finder, whose tolerance (~1e-4 by default) is far coarser than qnorm().
  if (delta == 0 || !is.finite(denom) || denom <= 0) {
    z_ci <- qnorm(1 - (1 - conf_level) / 2)
    return(list(c_alpha = z_ci, lower = theta_L - z_ci * se_L, upper = theta_U + z_ci * se_U))
  }
  target  <- function(c) pnorm(c + delta / denom) - pnorm(-c) - conf_level
  c_alpha <- uniroot(target, interval = c(0, 20), tol = 1e-10)$root
  list(c_alpha = c_alpha, lower = theta_L - c_alpha * se_L, upper = theta_U + c_alpha * se_U)
}
