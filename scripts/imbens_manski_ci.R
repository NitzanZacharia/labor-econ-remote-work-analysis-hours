# imbens_manski_ci.R
# Imbens and Manski (2004) confidence interval for a partially identified parameter: solve
# Phi(c + delta / max(se)) - Phi(-c) = conf_level and report [theta_L - c se_L, theta_U + c se_U];
# collapses to the two-sided interval when delta = 0.
imbens_manski_ci <- function(theta_L, theta_U, se_L, se_U, conf_level = 0.95) {
  delta <- max(theta_U - theta_L, 0)
  denom <- max(se_L, se_U)
  if (delta == 0 || !is.finite(denom) || denom <= 0) {
    z_ci <- qnorm(1 - (1 - conf_level) / 2)
    return(list(c_alpha = z_ci, lower = theta_L - z_ci * se_L, upper = theta_U + z_ci * se_U))
  }
  target  <- function(c) pnorm(c + delta / denom) - pnorm(-c) - conf_level
  c_alpha <- uniroot(target, interval = c(0, 20), tol = 1e-10)$root
  list(c_alpha = c_alpha, lower = theta_L - c_alpha * se_L, upper = theta_U + c_alpha * se_U)
}
