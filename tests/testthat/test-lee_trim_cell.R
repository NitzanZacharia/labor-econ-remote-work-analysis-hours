# test-lee_trim_cell.R
# Hand-computable checks on the two Lee-bounds helpers both Lee-bounds files share. The end-to-end
# behaviour of the bounds themselves is pinned in test-intensive_margin_lee_bounds.R and
# test-hours_ddd_lee_bounds.R; this file pins the arithmetic and the slicing edges in isolation.

test_that("lee_trim_proportion follows the parallel-trends-in-selection arithmetic", {
  tp <- lee_trim_proportion(s00 = 0.5, s01 = 0.5, s10 = 0.5, s11 = 0.7)
  expect_equal(tp$s11_counterfactual, 0.5)
  expect_true(tp$excess_selection)
  expect_equal(tp$trim_prop, 2 / 7)

  # Counterfactual 0.6 above the actual 0.55: nothing to trim.
  tp0 <- lee_trim_proportion(s00 = 0.5, s01 = 0.6, s10 = 0.5, s11 = 0.55)
  expect_false(tp0$excess_selection)
  expect_equal(tp0$trim_prop, 0)

  # Exactly on the counterfactual is not excess either.
  expect_equal(lee_trim_proportion(0.5, 0.5, 0.5, 0.5)$trim_prop, 0)
})

test_that("lee_trim_cell drops the top rows for the lower bound and the bottom rows for the upper", {
  cell <- tibble::tibble(id = 1:10, WorkHoursCont = c(40, 10, 30, 20, 50, 60, 5, 45, 35, 25))
  out  <- lee_trim_cell(cell, trim_prop = 0.25)  # floor(2.5) = 2 rows
  expect_equal(out$n_cell, 10L)
  expect_equal(out$n_trim, 2L)
  expect_equal(nrow(out$lower), 8)
  expect_equal(nrow(out$upper), 8)
  expect_setequal(out$lower$WorkHoursCont, c(5, 10, 20, 25, 30, 35, 40, 45))  # 50, 60 gone
  expect_setequal(out$upper$WorkHoursCont, c(20, 25, 30, 35, 40, 45, 50, 60)) # 5, 10 gone
  expect_true(all(c("id", "WorkHoursCont") %in% names(out$lower)))
})

test_that("lee_trim_cell handles the no-trim, full-trim and empty-cell edges", {
  cell <- tibble::tibble(WorkHoursCont = c(3, 1, 2))

  none <- lee_trim_cell(cell, trim_prop = 0)
  expect_equal(none$n_trim, 0L)
  expect_identical(none$lower, cell)
  expect_identical(none$upper, cell)

  # A trim proportion too small to remove a whole row keeps every row.
  tiny <- lee_trim_cell(cell, trim_prop = 0.1)
  expect_equal(tiny$n_trim, 0L)
  expect_equal(nrow(tiny$lower), 3)

  # 100% trim empties both samples rather than keeping one stray row.
  full <- lee_trim_cell(cell, trim_prop = 1)
  expect_equal(full$n_trim, 3L)
  expect_equal(nrow(full$lower), 0)
  expect_equal(nrow(full$upper), 0)

  empty <- lee_trim_cell(cell[0, ], trim_prop = 0.5)
  expect_equal(empty$n_cell, 0L)
  expect_equal(empty$n_trim, 0L)
})

test_that("lee_trim_cell is not confused by n_cell / n_trim columns in the frame", {
  # hours_ddd_lee_bounds.R's cells carry build_exposure_cells()'s n_cell column; a bare `n_cell`
  # inside slice()'s data mask would resolve to that column and break the index arithmetic.
  cell <- tibble::tibble(WorkHoursCont = c(40, 10, 30, 20, 50, 60, 5, 45, 35, 25),
                         n_cell = 99L, n_trim = 7L)
  out  <- lee_trim_cell(cell, trim_prop = 0.25)
  expect_equal(out$n_cell, 10L)
  expect_equal(out$n_trim, 2L)
  expect_setequal(out$lower$WorkHoursCont, c(5, 10, 20, 25, 30, 35, 40, 45))
  expect_setequal(out$upper$WorkHoursCont, c(20, 25, 30, 35, 40, 45, 50, 60))
  full <- lee_trim_cell(cell, trim_prop = 1)
  expect_equal(nrow(full$lower), 0)
  expect_equal(nrow(full$upper), 0)
})

test_that("lee_trim_cell trims on the named outcome column", {
  cell <- tibble::tibble(WorkHoursCont = c(1, 2, 3, 4), other = c(4, 3, 2, 1))
  out  <- lee_trim_cell(cell, trim_prop = 0.5, outcome_col = "other")
  expect_setequal(out$lower$other, c(1, 2))
  expect_setequal(out$upper$other, c(3, 4))
})
