# lee_trim_proportion.R
# Lee (2009) trim proportion for the (Mother = 1, Post = 1) cell: the excess of the observed
# selection rate s11 over the parallel-trends counterfactual s10 + (s01 - s00).

lee_trim_proportion <- function(s00, s01, s10, s11) {
  s11_counterfactual <- s10 + (s01 - s00)
  excess    <- s11 > s11_counterfactual
  trim_prop <- if (excess) 1 - s11_counterfactual / s11 else 0
  list(s11_counterfactual = s11_counterfactual, excess_selection = excess, trim_prop = trim_prop)
}
