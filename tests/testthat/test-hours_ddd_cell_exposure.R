# test-hours_ddd_cell_exposure.R
# run_hours_ddd_cell_exposure(): the hours DDD with a pre-period demographic-cell exposure as the
# regressor, joined by the cell variables and clustered on the coarser demographic cell. The
# synthetic exposure_cells frame is built from the panel's own cell combinations, in the shape
# build_exposure_cells() returns (cell vars + WFH_Exposure + n_cell).

make_cell_fixture <- function(seed = 71, n = 3000, n_occ = 10) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = -3, n = n, n_occ = n_occ, min_sex = 2L)
  cells <- fx$panel %>%
    dplyr::distinct(Min, GilNK, TeudaGvoha, MachozMegurim) %>%
    dplyr::mutate(WFH_Exposure = stats::runif(dplyr::n(), 0.05, 0.4), n_cell = 25)
  list(panel = fx$panel, cells = cells)
}

test_that("run_hours_ddd_cell_exposure fits the DDD on the cell index and reports per-SD scaling", {
  d <- make_cell_fixture()
  out <- capture.output(res <- suppressWarnings(run_hours_ddd_cell_exposure(d$panel, d$cells)))

  expect_true(all(c("table", "model", "coefs", "n_matched", "n_clusters", "regressor_sd", "cluster_vars") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_equal(res$coefs$term, "Mother:Post:WFH_Exposure")
  expect_equal(res$n_matched, nrow(d$panel))
  expect_equal(nobs(res$model), nrow(d$panel))
  # Cluster count is the number of distinct (GilNK, TeudaGvoha, MachozMegurim) cells in use.
  expected_clusters <- d$panel %>% dplyr::distinct(GilNK, TeudaGvoha, MachozMegurim) %>% nrow()
  expect_equal(res$n_clusters, expected_clusters)
  expect_equal(res$coefs$n_clusters, expected_clusters)
  # Per-SD figures are the per-unit ones times the regressor's SD on the estimation sample.
  used <- d$panel %>% dplyr::left_join(d$cells, by = c("Min", "GilNK", "TeudaGvoha", "MachozMegurim"))
  expect_equal(res$regressor_sd, sd(used$WFH_Exposure), tolerance = 1e-10)
  expect_equal(res$coefs$estimate_per_sd, res$coefs$estimate * res$regressor_sd, tolerance = 1e-10)
  expect_equal(res$coefs$se_per_sd, res$coefs$std_error * res$regressor_sd, tolerance = 1e-10)
})

test_that("rows with no matched cell are dropped and reported; missing columns error clearly", {
  d <- make_cell_fixture(seed = 72, n = 1200)
  cells_partial <- d$cells[-(1:5), ]
  expect_message(
    out <- capture.output(res <- suppressWarnings(run_hours_ddd_cell_exposure(d$panel, cells_partial))),
    "matched a pre-period exposure cell"
  )
  expect_lt(res$n_matched, nrow(d$panel))
  expect_equal(nobs(res$model), res$n_matched)

  expect_error(run_hours_ddd_cell_exposure(d$panel, d$cells, outcome = "nope"), "outcome")
  expect_error(run_hours_ddd_cell_exposure(dplyr::select(d$panel, -Min), d$cells), "cell variable")
  expect_error(run_hours_ddd_cell_exposure(d$panel, d$cells, cell_cluster_vars = c("GilNK", "Nope")), "cluster variable")
})
