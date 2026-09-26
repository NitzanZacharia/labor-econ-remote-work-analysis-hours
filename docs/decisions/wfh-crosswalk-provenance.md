# Open question: provenance of `data/israeli_cbs_wfh_2digit.csv`

**Status: CLOSED 2026-09-23. The derivation is known and reproduces the file exactly.**
Raised by the pre-submission audit, 2026-09-19, and tracked as D5 in
`docs/decisions/pre-submission-audit-decisions.md`, where it is now struck. The `% VERIFY` comment in
`paper/references.bib` is resolved, the BLS crosswalk is cited in the appendix
(`bls2012crosswalk`), and the two "undocumented" sentences in the paper are gone — see "Where the
answer is recorded" below.

## Answer

The file is the Dingel and Neiman (2020) binary `teleworkable` flag, mapped from the US
occupation classification onto ISCO-08 through the Bureau of Labor Statistics' 2012 crosswalk,
and averaged without weights within each two-digit ISCO-08 sub-major group. Concretely: take the
six-digit SOC prefix of every row of D&N's O*NET-SOC file; join it, many-to-many, to every
(ISCO-08 code, 2010 SOC code) pair in the BLS sheet; within each two-digit group, the score is the
mean of the flag over the joined pairs, `matched_soc_count_2d` is the number of pairs, and
`total_4digit_codes` is the number of distinct ISCO codes the sheet lists for the group (the
sheet's two minor-group codes, 211 and 315, are why groups 21 and 31 exceed the ISCO-08 standard
by one). Groups with no D&N match (armed forces, SOC 55-) get a count of zero and no score;
`is_wfh_binary_2d` is the score at a 0.5 cutoff.

Inputs, both public, pinned by SHA-256:

| Input | Source | SHA-256 |
|---|---|---|
| `occupations_workathome.csv` (968 rows: `onetsoccode,title,teleworkable`) | github.com/jdingel/DingelNeiman-workathome, `occ_onet_scores/output/` | `42ff3ae084478b554526671710b53a16d39f88c3eebb24f56f46372d7243bd40` |
| `ISCO_SOC_Crosswalk.xls`, sheet "ISCO-08 to 2010 SOC", cells A7:E1132 | BLS on behalf of the SOCPC, August 2012 (updated June 2015), bls.gov/soc/soccrosswalks.htm. The author's copy was supplied by the Israeli Central Bureau of Statistics; it is the BLS's own workbook. | `6d376cdc29e7b52e10e420644f46d7be69a1c48be1b3c650c290f21b4db3dd41` |

Run on 2026-09-23: the rebuild equals the committed file on all 43 rows and five columns at
tolerance 1e-12, with a matched-pair total of 1,439. The BLS workbook is the same file Dingel and
Neiman's own country-level code reads (`country_measures/code/country_level_measures.do`); their
country aggregation is employment-weighted, so the unweighted mean here is this project's choice,
already acknowledged in the appendix's remark that the calibrated score mixes two scales.

The proof is executable. The last block of `tests/testthat/test-wfh_crosswalk_integrity.R`
re-runs the derivation from the two source files (checking their hashes first) and asserts
equality with the committed CSV; it skips, rather than fails, when the files are not supplied, so
the suite stays green and dependency-free everywhere else (`readxl` is used only there, through
`skip_if_not_installed()`). To run it:

```powershell
$env:WFH_DN_OCCUPATIONS_CSV = "<path>\occupations_workathome.csv"
$env:WFH_BLS_ISCO_SOC_XLS  = "<path>\ISCO_SOC_Crosswalk.xls"
& 'C:\Program Files\R\R-4.5.1\bin\Rscript.exe' run_tests.R
```

The six blocks before it need no source files and pin the structural signatures of the same
derivation in the committed file (integer score-times-count products, the ISCO-08 unit-group
counts plus the two BLS surpluses, the 0.5 cutoff, and the three scores the paper quotes).

The source files are not committed: D&N's repository is GPLv3, the BLS sheet is an `.xls`, and
both are public at the addresses above.

## Where the answer is recorded

- This document, and the header of `tests/testthat/test-wfh_crosswalk_integrity.R` — done.
- `paper/references.bib` — the `% VERIFY` comment replaced by the provenance, and a
  `bls2012crosswalk` entry added; `paper/appendix.tex` (exposure-construction paragraph) states
  the derivation and cites it; the Limitations sentence in `paper/paper.tex` no longer calls the
  crosswalk undocumented — done 2026-09-23.
- `docs/decisions/pre-submission-audit-decisions.md` — D5 struck, with a closed entry — done 2026-09-23.
- `README.md` (`data/` description) and `paper/notes/results_digest.md` (its own `[VERIFY]`
  marker for this item) — not updated; neither is read by the paper.

---

The original question follows, for the record.

## Why this file matters

It is the root input to the paper's headline result. The chain is short and every link depends on
this file:

```
data/israeli_cbs_wfh_2digit.csv        <- provenance: see "Answer" above
  -> build_exposure_isco2()            scripts/wfh_exposure_cells.R:8
  -> calibrate_isco_exposure()         scripts/wfh_exposure_cells.R:32   (swaps 10 of 40 occupations)
  -> outputs/wfh_exposure_calibrated.csv
  -> run_hours_ddd_regression()        the triple interaction, the paper's central claim (3.407 when
                                       this was written; 3.224 since the 2026-09-21 harmonization)
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

## What was missing (as of 2026-09-19)

The paper cites \citet{dingel2020} for this measure, and that citation's own fields are verified.
The gap was not the citation, it was the derivation.

Dingel and Neiman score **US** occupations under the American **SOC** classification. The CBS data
uses **ISCO**, the international classification, at two digits. Something mapped one onto the
other and aggregated up. The repository held the output of that step and no record of the step
itself. Three things therefore could not be checked by a reader:

1. **Whether the scores are Dingel and Neiman's**, rather than a reconstruction that resembles
   them. — Answered: they are, exactly.
2. **Which SOC-to-ISCO crosswalk was used.** — Answered: the BLS 2012 ISCO-08/SOC-2010 crosswalk.
3. **How many-to-one mappings were resolved.** — Answered: an unweighted mean over all matched
   (ISCO code, O*NET-SOC row) pairs.

## What the audit could and could not establish

Could not: anything about the file's origin. It was not documented in `README.md`, `CLAUDE.md`,
`docs/HLD.md`, `docs/LLD.md`, any decision memo, or the git history of the file itself.

Could: the file is internally consistent and behaves as the pipeline expects. All 40 civilian
two-digit occupations carry a score; the calibration swaps exactly 10; and the three swaps the
paper names (teaching 0.966 to 0.069, clerical support 1.000 to 0.098, ICT 1.000 to 0.360)
reproduce from it exactly.
