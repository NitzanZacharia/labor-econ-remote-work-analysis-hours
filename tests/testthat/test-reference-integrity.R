# test-reference-integrity.R
# This repo documents heavily and cross-references by path: comments cite decision memos, memos
# cite scripts, the README cites both. Those paths rot silently -- a 2026-09-21 audit found eight
# live references to docs/archive/AUTONOMOUS_RUN_PLAN.md and TESTING_BLUEPRINT.md, deleted one
# commit earlier, including two clickable dead links in README.md and CLAUDE.md. Nothing failed;
# nothing noticed.
#
# This scans every .R and .md file for repo-relative path references and asserts each one resolves.
# It is not a style check -- a dead path in a comment is a reader following a pointer to nothing.

# Files that no longer exist and are referenced ONLY as history, by memos that state they were
# removed. Each is a deliberate record, not a broken pointer, so each is listed explicitly here
# rather than the check being loosened. Removing an entry should mean the reference itself went.
known_removed <- c(
  "scripts/ddd_regression.R",             # employment-DDD robustness variants, removed 2026-09-12
  "robustness/phase2_robustness.R",       # never wired in; removed 2026-09-12
  "tests/testthat/test-ddd_regression.R", # went with the script above
  "outputs/figures/hours_2x2.pdf"         # figure cut from the paper 2026-09-21
)

test_that("every repo-relative path referenced in a .R or .md file resolves", {
  files <- list.files(
    project_root,
    pattern    = "[.](R|md)$",
    recursive  = TRUE,
    full.names = TRUE
  )
  # Skip anything outside version control's reach: testthat's failure dumps, package libraries,
  # and the RStudio project scratch dir. This file is skipped too -- its header names the dead
  # paths that motivated the check, so scanning it would flag its own example.
  files <- files[!grepl("(_problems|[.]Rproj[.]user|renv|packrat|test-reference-integrity[.]R)", files)]
  expect_gt(length(files), 50)

  pattern <- "(docs|scripts|robustness|outputs|paper|tests|data)/[A-Za-z0-9_/.-]+[.](R|md|csv|tex|bib|pdf)"

  missing <- character(0)
  for (f in files) {
    txt  <- paste(readLines(f, warn = FALSE), collapse = "\n")
    hits <- regmatches(txt, gregexpr(pattern, txt))[[1]]
    if (!length(hits)) next
    hits <- unique(sub("[.,)]+$", "", hits))
    for (h in hits) {
      if (h %in% known_removed) next
      if (!file.exists(file.path(project_root, h))) {
        missing <- c(missing, paste0(h, "  (referenced by ", basename(f), ")"))
      }
    }
  }

  expect_identical(
    sort(unique(missing)), character(0),
    info = paste0("Dead path references:\n  ", paste(sort(unique(missing)), collapse = "\n  "))
  )
})

test_that("the known_removed allowlist has not itself gone stale", {
  # If one of these comes back, the allowlist entry is now wrong and should be dropped.
  for (p in known_removed) {
    expect_false(file.exists(file.path(project_root, p)), info = p)
  }
})
