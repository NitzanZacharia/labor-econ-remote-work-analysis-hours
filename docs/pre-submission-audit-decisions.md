# Pre-submission audit: decision register

**Status as of 2026-09-19.** The audit ran against HEAD `501f656`; its fixes are pushed as
`d662aa3` (paper) and `7967624` (repo). **No factual error was found in the paper.** This document
records every item still waiting on an author decision, ordered by whether it blocks submission.

## Deferred — circle back before submission

The author asked on 2026-09-19 to park these four and return to them at the end. They are the
complete outstanding list; everything else in this register is either resolved or actioned.

| # | Item | Why it is parked | What closes it |
|---|---|---|---|
| D1 | The Conclusion | Author writes it last | Replace the skeleton block at `paper/paper.tex` with your own prose, and delete the banner |
| D2 | Furlough sentence | Author is checking for a CBS source | Either the citation, or the reworded sentence in the D2 entry below |
| ~~D5~~ | ~~Crosswalk provenance~~ | **CLOSED 2026-09-23** | Derivation reproduced exactly from Dingel & Neiman plus the BLS crosswalk. See below. |
| ~~D15~~ | ~~Null-placebo caveat~~ | **CLOSED 2026-09-19** | Decided: leave it out, keep only the hours placebo. See below. |

### D15. The employment placebo's null is underpowered, not informative — CLOSED

**Decision, 2026-09-19: leave it out of the paper; keep only the hours placebo.** No change to
`paper.tex` was needed — every placebo reference there already scopes to the hours DDD, and the
Empirical Strategy section states that explicitly. The artifacts stay in `outputs/` because the
pipeline produces them, and `results_digest.md` §3.4 now records that their absence from the paper
is a deliberate choice rather than an oversight, which matters because the repository is graded.

Two things also changed the picture after this was first written. The power claim was rescaled
(see the active task above), so the employment margin is underpowered by a factor of roughly two
to three rather than eight to ten. And the paper's own placebo section is unambiguous about which
outcome it uses. Both make leaving it out the cleaner choice rather than a gap.

The original analysis follows, for the record.

Wired in on 2026-09-19 and now exported as `outputs/gender_placebo_{did,ddd}_table.csv`.
Estimates, men with `Mother` read as `Father`: DiD $0.0077$ (SE $0.0054$); DDD $0.0444$
(SE $0.0833$) additive and $0.0661$ (SE $0.0849$) with cell fixed effects. All insignificant.

**The issue.** A placebo returning null is the direction you want. But this placebo sits on the
employment margin, and the paper already establishes (Section 5.2) that the employment DDD is
underpowered rather than precise: its minimum detectable effect is about 26% of the baseline
employment rate, 8–10 times the point estimate. A null on that margin is uninformative for the
same reason the main employment DDD is. Presenting it as corroboration without that caveat would
repeat, in the placebo, exactly the error the paper is careful to avoid in the main result.

**Options.** (a) Leave it out of the paper entirely; it is in the repo for completeness and the
hours placebo already does the falsification work. (b) Report it with the caveat stated plainly,
one sentence, alongside the hours placebo. (c) Report it without the caveat — not recommended.

**Impact.** (a) is the safe default and costs nothing, since the hours placebo is the one that
matters for the primary specification. (b) is more complete and shows you understand what your
own power analysis implies; it costs two sentences. (c) would be a real inconsistency an examiner
could fairly pick up.

## What the audit established

| Check | Result |
|---|---|
| Two full pipeline runs, default and flag-enabled | All 70 committed CSVs reproduce byte for byte |
| Paper values against artifacts | 75 automated comparisons, zero mismatches |
| Numeric literals in the paper body | 356 total; every one traced to the digest, to an artifact, or to a documented derivation |
| Console-only values (MDEs, Imbens–Manski intervals, z-tests, Wald tests) | All reproduce, verified twice: by hand from artifacts and in the run logs |
| Bibliography | 15 keys cited, 15 defined, no orphans; all 8 pre-existing entries verified field by field against Crossref and NBER |
| Test suite | FAIL 0, WARN 0, SKIP 0, PASS 631 |
| Paper compile | 0 errors, 0 undefined references, 0 BibTeX warnings, 25 pages |

## Closed without needing a decision

- **Exposure-cell disclosure.** The 8,884-cell artifact's smallest weighted cell is 30.2 and the
  1st percentile is 179.9; nothing is below 5. No small-cell disclosure risk, so whether the
  repository is public does not matter for it.
- **Orphan artifacts.** 14 files with no generating code moved to `outputs/archive/` with a README
  explaining what produced each and what superseded it. (That whole directory was deleted on
  2026-09-21 — nothing regenerated them and git retains them.)
- **The broken mismatch runner.** `run_mismatch.R` read a path that does not exist and could not
  run on any machine; repaired and verified.

---

## Tier 1 — blocks submission

### D1. The Conclusion is still the red draft block

**Still open as of 2026-09-21.** The block is the Conclusion skeleton in `paper/paper.tex`, marked
by the `SKELETON -- NOT SUBMITTABLE TEXT` comment and the two red
`[SKELETON ONLY --- REPLACE WITH YOUR OWN TEXT BEFORE SUBMISSION]` /
`[END SKELETON --- DELETE THIS BLOCK]` markers (grep `SKELETON` to find it; line numbers have moved
twice). The course rule quoted at `paper/archive/old_paper.tex:209-213`
requires this section to be written individually by the student, and the block in the file is
explicitly labelled a model answer for self-comparison. **It still compiles into the PDF today, in
red.** `\usepackage{xcolor}` is carried solely for these markers and can go with them.

**Options.** Write it yourself, which is the only compliant route. If useful, I can produce a
skeleton of the claims the verified results support, for you to write against — that is not the
same as writing it.

**Impact.** Submitting with the block present is an academic-integrity problem rather than a
formatting one. Nothing else in this register outranks it. Removing it also frees
`\usepackage{xcolor}` (commented `% draft-conclusion flag`), which exists only for the red flag.

### D2. The furlough sentence is an uncited data claim

`paper/paper.tex`'s Data section. You chose to keep it and supply a CBS source; the source has not
arrived. The claim is that the employment indicator counts furloughed workers as employed. The
codebook shipped with the extract shows `Muasak` has three codes — employed, unemployed, blank for
not-in-labour-force — and no furlough code; the absence-reason variable the archived draft relied
on is not in the extract at all. Nothing in the repo can support or refute the sentence.

**Options.** (a) Supply the CBS documentation and I cite it. (b) Reword to say the extract carries
no furlough indicator, so the design cannot separate furlough from employment either way — fully
supported, and it keeps the caveat. (c) Cut the Halat passage and keep only the statistical account
of why hours respond and employment does not.

**Impact.** (a) is strongest if the source exists, since the institutional story is the paper's
most interesting non-statistical explanation. (b) is safe and costs one sentence of vividness.
(c) loses the mechanism. Leaving it unchanged is the only bad option: an examiner who checks the
codebook finds an unsupported claim about the paper's own dependent variable.

---

## Tier 2 — likely affects the grade

### D3. The course bibliography rule

`old_paper.tex:226-232` says the assignment has name and ordering rules that "no standard citation
package produces automatically", and that Hebrew-language sources need their own section at the
very start of the bibliography. The paper uses `apalike`, a standard style. Two cited works are
plausibly Hebrew-language originals: the Taub Center paper (`madhala2020`) and the Bank of Israel
discussion paper (`buzaglo2023`).

**Options.** Tell me the actual rule and I check the rendered list against it, hand-formatting if
needed; or confirm `apalike` is acceptable and the item closes.

**Impact.** This is the one place the paper may fail an explicit stated requirement. Cheap to
check, potentially expensive to miss. Hand-formatting 15 entries is about an hour.

### D4. The Kleven suffix order

`paper/paper.tex`'s Literature Review citations of Kleven et al. `apalike` labels the cross-country paper 2019a and the Denmark
paper 2019b by title sort, and the Literature Review cites b before a. I deliberately did not fix
this: the paragraph is built on the Danish study and closes by returning to it, so reordering the
sentences to satisfy the suffix would damage the argument.

**Options.** Accept it; reorder the two sentences anyway; or force the suffix with a `key` field,
which is fiddly but leaves the prose alone.

**Impact.** Purely presentational. A grader reading sequentially meets 2019b before 2019a, which
looks like an error even though it is not.

### D5. Crosswalk provenance, the last VERIFY marker — CLOSED

**Decision, 2026-09-23: the derivation is established and proven.** `data/israeli_cbs_wfh_2digit.csv`
is Dingel and Neiman's published binary teleworkability indicator, mapped to ISCO-08 through the
BLS 2012 crosswalk between ISCO-08 and the 2010 SOC (the author's copy came from the Israeli CBS;
it is the BLS's own workbook) and averaged without weights over the matched pairs within each
two-digit group. Rebuilding from the two public files reproduces all 43 rows exactly. The
executable proof is the last block of `tests/testthat/test-wfh_crosswalk_integrity.R`, which
skips unless the source files are supplied; the full record, with input hashes, is in
`docs/open-question-wfh-crosswalk-provenance.md`. The VERIFY comment in `paper/references.bib`
is resolved, the BLS crosswalk is cited (`bls2012crosswalk`), and the two "undocumented"
sentences in the paper are gone.

The original entry follows, for the record.

`paper/references.bib:50`. Is `data/israeli_cbs_wfh_2digit.csv` derived from Dingel and Neiman's
published classification, and through which SOC-to-ISCO crosswalk? The paper cites them for it; the
repo documents the derivation nowhere.

**Options.** Tell me the provenance and I record it in the bib comment and the README; or mark the
origin as undocumented, which is honest but weak.

**Impact.** The calibrated exposure index is the paper's key regressor. "Where did this file come
from" is a fair examiner question with no answer in the repo today.

---

## Tier 3 — repo quality, now that the repository is graded

### D6. The parallel-trends test is not reproducible on a default run — ✅ RESOLVED 2026-09-19

**Option (a) was taken.** `run_pretrend_joint_test()` now runs unconditionally in `main.R` §7,
right beside the event studies whose models it tests, and exports
`outputs/pretrend_wald_{hours,employment}.csv`. The original write-up follows for the record.

Both Wald F-statistics in the paper are correct and verified. But `run_pretrend_joint_test()` is
called only inside the `RUN_AGE_BALANCE_ROBUSTNESS` block (`main.R:455,458`), its results are never
referenced again, and it returns an object the export layer discards. A reader running `main.R` as
shipped gets neither statistic.

**Options.** (a) Move the two calls out of the flag block and export the result as a one-row frame:
about 30 minutes plus a rerun. (b) Record in the digest that the figures come from a flag-enabled
run and attach the log.

**Impact.** (a) makes the paper's identification evidence reproducible by the documented command,
which matters more now the repo is graded. (b) is honest but leaves a reader unable to reproduce a
number the Limitations section leans on.

### D7. Two feature flags default to `FALSE` — ✅ RESOLVED 2026-09-19

**Both were flipped to `TRUE`.** `RUN_AGE_BALANCE_ROBUSTNESS` and `RUN_NULL_VS_POWER_AUDIT` now
default on, so one `Rscript main.R` reproduces everything the paper cites; both flags are kept so
the chains can still be switched off for a fast run. Verified: all artifacts regenerate
byte-identically. The original write-up follows for the record.

Nine `age_balance_robustness_*` artifacts and the first-stage table are cited by
the paper but do not regenerate on a default run. All regenerate byte-identically with the flags
on, verified.

**Options.** Leave `FALSE` and document which artifacts need which flag; or flip to `TRUE` so one
command reproduces everything the paper cites.

**Impact.** Flipping makes the default run a complete reproduction at the cost of a longer run.
Leaving them needs a README table so a reader is not stuck.

### D8. Dead code still sourced — ✅ MOSTLY RESOLVED 2026-09-19

**The employment placebo was wired in.** `main.R` now calls `run_gender_placebo()` (which in turn
calls `run_gender_ddd_placebo()`) and exports `gender_placebo_{did,ddd}_table.csv`, closing the
digest's open item 7. `basic_reg_comp()` remains uncalled by the pipeline **by design** — it is a
manual console tool documented in `README.md`, and is unit-tested. The original write-up follows
for the record.

`main.R` sources `basic_reg_compared_data.R` and `gender_placebo.R`; `basic_reg_comp()`,
`run_gender_placebo()` and `run_gender_ddd_placebo()` are never called. The employment-outcome
gender placebo therefore has no exported result, which is the digest's own open item 7.

**Options.** Keep and document as manual-only; wire the employment placebo in so it matches its
hours twin; or delete.

**Impact.** A reader of a graded repo sees three functions nothing runs. Wiring the placebo in
would close the digest's open item, at the cost of one more model in the run.

### D10. Survey-weights robustness check

The unweighted design is a stated scope decision the paper defends. A weighted variant has never
been run.

**Options.** Leave as a stated limitation; or run one as a robustness appendix.

**Impact.** Running it needs sign-off per the project's own convention and could change reported
magnitudes, which this close to submission is a real risk. Recommendation: leave it.

---

## Tier 4 — noted, no action unless you want it

- **D11. Title-page date.** `paper/paper.tex`'s title block uses `\today`, so the printed date is whatever day
  it was last compiled. Fix to the real submission date if that matters.
- **D12. Figure path.** `paper/paper.tex`'s figures include `../outputs/...`, so the paper compiles only
  from inside `paper/`. Copying the PDF into `paper/` would make the folder self-contained.
- **D13. `outputs/israeli_market_mismatch.csv`** was committed in `7967624` because `outputs/` is
  tracked and the repaired runner produces it. Reverse with `git rm --cached` if you prefer.
