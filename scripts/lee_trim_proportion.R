# lee_trim_proportion.R
# The Lee (2009) trim proportion for one (Mother, Post) comparison, shared by
# intensive_margin_lee_bounds.R (pooled) and hours_ddd_lee_bounds.R (one call per exposure
# quartile). s_ab is the share of the (Mother == a, Post == b) cell whose outcome is observed.
# Under parallel trends in selection, post-period mothers' counterfactual rate is
# s10 + (s01 - s00); if the actual s11 exceeds it, the excess share 1 - counterfactual / s11 is
# what the caller trims from that cell's outcome distribution (lee_trim_cell()). No excess means
# trim_prop 0, and the bounds collapse to the untrimmed point estimate: the construction handles
# excess selection in the (1, 1) cell only (docs/decisions/intensive-margin-lee-bounds.md).

lee_trim_proportion <- function(s00, s01, s10, s11) {
  s11_counterfactual <- s10 + (s01 - s00)
  excess    <- s11 > s11_counterfactual
  trim_prop <- if (excess) 1 - s11_counterfactual / s11 else 0
  list(s11_counterfactual = s11_counterfactual, excess_selection = excess, trim_prop = trim_prop)
}
