# lee_trim_cell.R
# Trims floor(trim_prop * n) rows from the top (lower bound) or bottom (upper bound) of one cell's
# outcome distribution. Ties are broken by row order; callers must drop missing outcomes first.
library(tidyverse)

lee_trim_cell <- function(cell_df, trim_prop, outcome_col = "WorkHoursCont") {
  n_cell <- nrow(cell_df)
  if (n_cell == 0 || trim_prop <= 0) {
    return(list(lower = cell_df, upper = cell_df, n_cell = n_cell, n_trim = 0L))
  }
  n_trim <- as.integer(floor(trim_prop * n_cell))
  ranked <- arrange(cell_df, .data[[outcome_col]])
  # Indices are injected with !! so n_cell cannot resolve to a column of the same name.
  keep_lower <- seq_len(max(n_cell - n_trim, 0))
  keep_upper <- if (n_trim < n_cell) (n_trim + 1):n_cell else integer(0)
  list(lower  = slice(ranked, !!keep_lower),
       upper  = slice(ranked, !!keep_upper),
       n_cell = n_cell, n_trim = n_trim)
}
