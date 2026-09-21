# Open question: provenance of `data/israeli_cbs_wfh_2digit.csv`

**Status: OPEN. Raised by the pre-submission audit, 2026-09-19. Needs an author answer.**
Tracked as D5 in `docs/pre-submission-audit-decisions.md`; the corresponding `% VERIFY` comment
sits at `paper/references.bib:52` and is the last unresolved one there.

## Why this file matters

It is the root input to the paper's headline result. The chain is short and every link depends on
this file:

```
data/israeli_cbs_wfh_2digit.csv        <- provenance unknown (this document)
  -> build_exposure_isco2()            scripts/wfh_exposure_cells.R:8
  -> calibrate_isco_exposure()         scripts/wfh_exposure_cells.R:32   (swaps 10 of 40 occupations)
  -> outputs/wfh_exposure_calibrated.csv
  -> run_hours_ddd_regression()        the 3.407 triple interaction, the paper's central claim
```

The file supplies `wfh_probability_2d`, the theoretical teleworkability score per two-digit
occupation. The calibration step corrects it where Israeli practice diverged, but every
uncorrected occupation keeps this file's value verbatim, and the corrected ones are chosen by
comparing against it.

## What the file contains

Columns: `isco_2digit`, `wfh_probability_2d`, `matched_soc_count_2d`, `total_4digit_codes`,
`is_wfh_binary_2d`. The `matched_soc_count_2d` and `total_4digit_codes` columns are themselves
evidence that a mapping step happened: they record how many SOC codes matched and how many
four-digit codes fed each two-digit row.

## What is actually missing

The paper cites \citet{dingel2020} for this measure, and that citation's own fields are verified.
The gap is not the citation, it is the derivation.

Dingel and Neiman score **US** occupations under the American **SOC** classification. The CBS data
uses **ISCO**, the international classification, at two digits. Something mapped one onto the
other and aggregated up. The repository holds the output of that step and no record of the step
itself. Three things therefore cannot be checked by a reader:

1. **Whether the scores are Dingel and Neiman's**, rather than a reconstruction that resembles
   them.
2. **Which SOC-to-ISCO crosswalk was used.** Several exist and they do not agree everywhere.
3. **How many-to-one mappings were resolved.** Several SOC codes collapse into one two-digit ISCO
   code; a simple mean, an employment-weighted mean and a modal assignment give different answers.

## What you need to verify

Trace where the file came from. Any of these closes the question:

- It came from a replication package, supplementary file, or published crosswalk. Name the source
  and, if there is one, the DOI or URL.
- You or your co-author built it. Say so, name the crosswalk used, and state the aggregation rule
  for many-to-one mappings.
- It came from a course dataset or supervisor. Name that.

If the derivation genuinely cannot be reconstructed, say that plainly in the paper's data section
instead. An examiner can accept a documented limitation; an undocumented key input is harder to
defend.

## Where the answer should be recorded once known

- `paper/references.bib:52` — replace the `% VERIFY` comment with the provenance.
- `README.md` — the `data/` description, so a reader of the repo finds it.
- `paper/paper.tex` Section 3.3 — one clause in the sentence introducing the external index, if
  the provenance is something a reader of the paper alone would want.

## What the audit could and could not establish

Could not: anything about the file's origin. It is not documented in `README.md`, `CLAUDE.md`,
`docs/HLD.md`, `docs/LLD.md`, any decision memo, or the git history of the file itself.

Could: the file is internally consistent and behaves as the pipeline expects. 39 of 40 two-digit
occupations carry a score; the calibration swaps exactly 10; and the three swaps the paper names
(teaching 0.966 to 0.069, clerical support 1.000 to 0.098, ICT 1.000 to 0.360) reproduce from it
exactly. Nothing suggests the file is *wrong* — only that its origin is unrecorded.
