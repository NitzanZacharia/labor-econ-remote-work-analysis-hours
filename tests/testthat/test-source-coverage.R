# test-source-coverage.R
# Two lists of source() calls are maintained by hand -- main.R's and helper-setup.R's -- and a
# script that reaches neither is invisible: either untested, or defined and never run. Nothing
# enforced either list until the 2026-09-23 codebase audit checked them by hand; this pins both.

r_files <- function(dir) {
  list.files(file.path(project_root, dir), pattern = "[.]R$", full.names = FALSE)
}

source_calls_in <- function(paths) {
  txt <- paste(unlist(lapply(paths, readLines, warn = FALSE)), collapse = "\n")
  regmatches(txt, gregexpr('source\\(file\\.path\\("(scripts|robustness)", "[A-Za-z0-9_.]+"\\)\\)', txt))[[1]]
}

is_sourced <- function(dir, file, calls) {
  any(grepl(paste0('"', dir, '", "', file, '"'), calls, fixed = TRUE))
}

test_that("helper-setup.R sources every function-bearing file in scripts/ and robustness/", {
  calls <- source_calls_in(file.path(project_root, "tests", "testthat", "helper-setup.R"))
  expect_gt(length(calls), 50)
  for (f in r_files("scripts"))    expect_true(is_sourced("scripts", f, calls),    info = f)
  for (f in r_files("robustness")) expect_true(is_sourced("robustness", f, calls), info = f)
})

test_that("every file in scripts/ is sourced by an entry point or by another script", {
  callers <- c(
    file.path(project_root, c("main.R", "run_mismatch.R")),
    list.files(file.path(project_root, "scripts"),    pattern = "[.]R$", full.names = TRUE),
    list.files(file.path(project_root, "robustness"), pattern = "[.]R$", full.names = TRUE)
  )
  calls <- source_calls_in(callers)
  for (f in r_files("scripts")) expect_true(is_sourced("scripts", f, calls), info = f)
})
