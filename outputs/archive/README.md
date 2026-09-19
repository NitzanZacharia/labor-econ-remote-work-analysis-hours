# Archived outputs — do not cite

These 14 files were produced by code that no longer exists in this repository. They were moved
here from `outputs/` on 2026-09-19 during the pre-submission audit, because they sat beside their
live replacements and could be mistaken for current results. They are kept rather than deleted so
the project's history stays legible; git has them either way.

Verified before moving: none of them matches any key in `main.R`'s `results_to_export`, so no
current code path can regenerate them. `paper/notes/results_digest.md` already marked them
"do NOT cite".

| Files | Produced by | Superseded by |
|---|---|---|
| `ddd_primary.csv` | An earlier `main.R` export key `ddd_primary` | `outputs/ddd_employment.csv` |
| `ddd_calibrated_*`, `ddd_external_*`, `ddd_realized_*` (9 files) | `run_ddd_regression()` in the since-deleted `scripts/ddd_regression.R` | `outputs/ddd_hours_table.csv`, `ddd_hours_external.csv`, `ddd_hours_realized.csv` |
| `hours_ddd_pivot_*` (4 files) | The since-removed `RUN_HOURS_DDD_PIVOT` flag | `outputs/ddd_hours_table.csv`, `hours_lee_bounds_*.csv` |

Two traps worth naming explicitly.

**`ddd_primary.csv` disagrees with the live `ddd_employment.csv`.** It predates both the
`Mother:GilNK` interaction and the `BirthContinent` addition to the exposure cells. Anyone
comparing it against the paper will find a mismatch, and the paper is the one that is right.

**The `*_mechanism_data.csv` files are in employment-probability units, not hours.** They came
from the employment-outcome DDD. `docs/hours-intensive-margin-analysis.md` used to cite them as
the source of the hours mechanism regression, which was wrong; that regression's data is not
exported at all, and the digest places it out of scope.
