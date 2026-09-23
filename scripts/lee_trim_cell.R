# lee_trim_cell.R
# Trims one (Mother == 1, Post == 1) cell for a Lee (2009) bound: floor(trim_prop * n) rows are
# dropped from the top of the outcome distribution for the lower bound and from the bottom for the
# upper bound (monotone selection: the marginal entrants have either the highest or the lowest
# hours in the cell). Shared by intensive_margin_lee_bounds.R (one cell) and
# hours_ddd_lee_bounds.R (one cell per exposure quartile), which then refit on
# bind_rows(other_cells, lower) and bind_rows(other_cells, upper).
#
# seq_len() / integer(0), not "1:(n - k)" / "(k + 1):n": the colon forms produce a reversed
# 2-element sequence rather than zero rows when k == n (a 100% trim), which would keep one stray
# row. Ties in the outcome (common -- WorkHoursCont is a bin-median lookup) are broken by row
# order after arrange(), not randomized; with a small trimmed n that is a minor source of bound
# imprecision. Rows with a missing outcome must be filtered out by the caller first: arrange()
# sorts NA last, so they would be trimmed as if they were the highest values.
library(tidyverse)

lee_trim_cell <- function(cell_df, trim_prop, outcome_col = "WorkHoursCont") {
  n_cell <- nrow(cell_df)
  if (n_cell == 0 || trim_prop <= 0) {
    return(list(lower = cell_df, upper = cell_df, n_cell = n_cell, n_trim = 0L))
  }
  n_trim <- as.integer(floor(trim_prop * n_cell))
  ranked <- arrange(cell_df, .data[[outcome_col]])
  # Row indices are computed outside slice() and injected with !!: inside slice()'s data mask a
  # bare `n_cell` would resolve to the caller's n_cell COLUMN (build_exposure_cells() carries one),
  # not to the scalar above.
  keep_lower <- seq_len(max(n_cell - n_trim, 0))
  keep_upper <- if (n_trim < n_cell) (n_trim + 1):n_cell else integer(0)
  list(lower  = slice(ranked, !!keep_lower),
       upper  = slice(ranked, !!keep_upper),
       n_cell = n_cell, n_trim = n_trim)
}
