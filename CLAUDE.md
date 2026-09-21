# Project conventions for Claude Code

- This is a set of R scripts (no package layout — no DESCRIPTION/NAMESPACE, no roxygen, no
  installed-package semantics). Dependencies: tidyverse + fixest only. Do not add a new dependency
  without flagging it in your response first.
- The "one function per file" rule below is the intent, not a universal fact. Five files in
  `scripts/` already hold more than one, each for a stated reason: `validation.R` (4 — a family of
  data-quality checks), `wfh_exposure_cells.R` (3 — the exposure-construction chain),
  `gender_placebo.R` and `hours_gender_placebo.R` (2 each — a runner plus the DDD variant it
  calls), and `ddd_collinearity_diagnostics.R` (2 — a diagnostic plus a shared guard used by six
  call sites). Follow the rule for new files; do not split these five to satisfy it.
- `main.R` is the orchestrator and stays at the repo root, alongside `run_tests.R` and
  `run_mismatch.R`. Every other .R file defines one function, lives in `scripts/`, and is
  `source()`d via a root-relative, path-qualified call (`source(file.path("scripts", "foo.R"))`) —
  never a bare filename, since cwd is assumed to be the repo root wherever sourcing happens.
  `robustness/` is the one exception to "one function per file": it holds the multi-function
  robustness-chain scripts (`balance_test.R`, `age_balance_robustness.R`, `pretrend_wald_test.R`),
  sourced the same cwd-relative, path-qualified way
  (`source(file.path("robustness", "foo.R"))`) — never moved into `scripts/`.
- `data/` holds small, versioned external inputs the pipeline needs (currently just the Dingel &
  Neiman teleworkability crosswalk, `data/israeli_cbs_wfh_2digit.csv`) — distinct from the raw CBS
  microdata below, which is never checked into the repo.
- Raw CBS CSVs are gitignored and live outside the repo (real path is set locally in main.R's
  `folder_path`). Never assume they're present in a sandbox; check before running Rscript against them.
- `DEFAULT_CONTROLS <- c("MatzavMishpachti","Dat","GilNK","MachozMegurim","TeudaGvoha")`, defined
  once in `scripts/data_processing.R`, is the single source of truth —
  don't reintroduce a local copy in any new file.
- CBS survey weights (`MishkalSofi`, `MishkalShnati`, etc.) are intentionally NOT applied in any
  outcome regression — see README.md's "Known limitations". This is a deliberate scope decision,
  not a gap. Do not add a CBS survey weight to a `feols()`/`lm()` call in this repo without raising
  it with the user first. Three non-survey `weights =` uses already exist and are expected:
  `build_exposure_cells()` (`wfh_exposure_cells.R`) weights by `MishkalSofi` when aggregating
  occupation exposure up to demographic cells, which is internal to constructing the exposure
  regressor; `run_ddd_reweighted()` and `run_hours_ddd_reweighted()`
  (`robustness/age_balance_robustness.R`) pass `weights = ~rake_weight`, which is what those
  age-rebalancing specs are for; and `run_hours_ddd_regression()` uses inverse-variance weights in
  its second-stage `lm()`. None of these is a representativeness correction.
- Before implementing anything, read: docs/ROADMAP.md (the checkpoint in question),
  docs/LLD.md (schema/contracts), docs/HLD.md (why the gap exists). Don't implement from the
  research doc directly — LLD/HLD already reconcile it against the real codebase. For how to test
  something, the live `tests/testthat/` suite is the source of truth.
- Every change that touches a function used elsewhere (data_processing.R, the controls list)
  needs the full `Rscript run_tests.R` suite green before you consider the task done.
- Whenever `paper/paper.tex` or `paper/references.bib` is modified in a session, recompile before
  finishing the turn, overwriting `paper/paper.pdf`. `latexmk` is not usable on this machine
  (MiKTeX's `latexmk` requires Perl, which isn't installed) — use the manual sequence instead:
  `pdflatex`, `bibtex`, `pdflatex`, `pdflatex`, run from within `paper/`. If the final log warns
  that labels may have changed, run one more `pdflatex` pass. Report any BibTeX warnings or
  undefined-citation/reference warnings from the logs.