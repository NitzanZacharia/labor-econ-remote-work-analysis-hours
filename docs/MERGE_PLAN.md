# Merge plan: fold the concise draft's improvements into `paper/paper.tex`

Handoff for Claude Code. Read this whole file before touching anything.

## Context

Two drafts of the same seminar paper:

- **Base document:** `paper/paper.tex` (full draft, with appendix, skeleton Conclusion). This is the file you edit.
- **Reference document:** `docs/concise_20_pages.tex` (condensed draft). **Read-only.** You take about a dozen sentences of language from it; you do not merge it wholesale.

Both drafts are built on the same pipeline outputs and every number in them has been cross-checked and agrees. This merge is editorial: it changes prose, not results.

## Hard constraints

1. **Do not change any number.** Every coefficient, SE, p-value, N, share and cluster count stays exactly as it is in `paper/paper.tex`. The only numbers you introduce are ones already present elsewhere in the body of `paper/paper.tex` (listed in each step).
2. **Do not edit generated files:** nothing under `paper/tables/` (written by `main.R` / `scripts/export_paper_tables.R`), nothing under `outputs/`, and not `main.R` itself.
3. **Do not write the Conclusion.** The assignment requires the students to write it themselves. Step 10 only fixes one factual error in the skeleton's notes and adds a comment. Do not delete the skeleton block, do not remove `\usepackage{xcolor}`, do not replace `\today`.
4. **Do not modify `docs/concise_20_pages.tex`.**
5. Edit with the `Edit` tool using exact anchors. The anchors below are quoted without the source file's hard line wraps (the file wraps at ~100 characters), so **re-read the surrounding lines and match the wrapped text as it actually appears**. Every anchor must match exactly once; if it matches zero or several times, stop and report rather than guess.
6. Preserve the file's style: hard-wrapped at ~100 characters, one sentence flows into the next, `$…$` for numbers, `\emph{}` for emphasis, `~\ref{}` for cross-references.
7. Work on a branch: `git checkout -b merge-concise`. Commit after each step with message `merge: step N — <title>`. Run the compile check (Step 12) at the end, not after every step.

## Step 0 — Inventory

- Read `paper/paper.tex` and `docs/concise_20_pages.tex` in full.
- Read `paper/appendix.tex`.
- `ls paper/tables/` and record whether `tab_lee_bounds.tex` and `tab_extensive.tex` exist. `grep -n 'input{tables/' paper/appendix.tex` to see which table files the appendix currently uses and under what labels. You need this for Step 7d.
- `grep -n 'fig:pretrend-ddd' paper/paper.tex paper/appendix.tex` and record whether the label is ever referenced (`\ref`). Needed for Step 11a.
- Do not commit anything for this step.

## Step 1 — Abstract

**1a.** Replace

```
The estimate is significant at the $1\%$, $5\%$ and $10\%$ levels under analytic, permutation and wild-bootstrap inference respectively.
```

with

```
Because exposure varies across only forty occupations we report three inference procedures: the analytic $p$-value is $0.003$, the permutation $p$-value $0.032$ and the wild cluster bootstrap $p$-value $0.056$.
```

(All three values already appear in Section 6.4, *Inference and falsification*.)

**1b.** Replace

```
about $1.8$ hours a week between the most and least teleworkable quartiles of occupations
```

with

```
$1.71$ hours a week between the mean exposures of the most and least teleworkable quartiles of occupations
```

(`1.71` is the regression-implied contrast reported in Section 6.2; `1.8` was an ambiguous rounding that straddled 1.71 and the raw 1.87.)

**1c.** Insert, immediately before the final sentence `The result is about \emph{which} mothers benefit…`:

```
The employment margin is estimated too imprecisely to support a comparable conclusion.
```

## Step 2 — Introduction

**2a.** After the sentence ending

```
tests whether remote work is the \emph{mechanism}, by asking whether the change is larger in jobs that can actually be done from home.
```

append:

```
Its identifying assumption concerns how the motherhood gap \emph{within} occupations would have evolved across exposure levels absent the shift; pre-period event studies probe that assumption rather than verify it.
```

**2b.** In the results paragraph, replace

```
or $1.8$ hours between the top and bottom quartiles of occupations,
```

with

```
or $1.71$ hours between the mean exposures of the top and bottom quartiles of occupations (a quartile-indicator specification puts the top-versus-bottom contrast at $1.84$ hours),
```

(`1.844` is column (4)'s top-quartile coefficient, Section 6.2.)

**2c.** Replace

```
we report three inference procedures that place the estimate at the $1\%$, $5\%$ and $10\%$ levels.
```

with

```
we report three inference procedures, whose $p$-values run from $0.003$ (analytic) through $0.032$ (permutation) to $0.056$ (wild cluster bootstrap).
```

## Step 3 — Literature Review

**3a.** Replace

```
and our hours estimate is its closest analogue.
```

with

```
and our hours estimate is its closest analogue, without treating the two countries or the two outcomes as equivalent.
```

No trimming in this step. Length is handled in Step 11d, only if a page cap turns out to bind.

## Step 4 — Data and exposure

**4a.** After the sentence ending

```
\emph{Post} equals one for survey years 2021 and later.
```

insert:

```
The comparison group therefore includes women whose children are grown and women who become mothers within the window (Section~\ref{sec:limitations}).
```

**4b.** Replace

```
Hours are defined for women who are employed \emph{and} worked in the survey's reference week, in every year, which makes the hours population identical across years
```

with

```
Hours are defined for women who are employed \emph{and} worked in the survey's reference week, in every year, a harmonization made necessary by a different zero-hours recording convention in the 2017 extract (Appendix~\ref{sec:app-data}); it makes the hours population identical across years
```

Before applying 4b, read the 2017 recording-correction passage in `paper/appendix.tex` (search `2017`). If the appendix describes the 2017 issue differently from "a different zero-hours recording convention", adjust the inserted clause to match the appendix's description and note the change in your commit message.

**4c.** In *Constructing WFH exposure*, replace

```
the calibrated measure is a documented compromise rather than a fully pre-treatment index;
```

with

```
the calibrated measure is \emph{partly post-treatment}, a documented compromise rather than a fully pre-treatment index;
```

**4d.** Directly above the line beginning

```
\emph{Calibrated (primary).} The rule that selects the primary measure is fixed before any estimate is read:
```

add a LaTeX comment line (no change to the prose):

```
% TODO(merge): "fixed before any estimate is read" is a verifiable claim; cite the dated decision
% note in docs/decisions/ that recorded the rule, or soften to "fixed ex ante" if none exists.
```

## Step 5 — Descriptive statistics

**5a.** Replace

```
The near-zero average is therefore a weighted average of three nulls and one substantial positive difference, visible without any regression.
```

with

```
The near-zero average is therefore a weighted average of three nulls and one substantial positive difference. The figure is a description rather than an independent causal test: occupational composition and time-varying confounders can differ across quartiles, which is what the regressions of Section~\ref{sec:results} address.
```

**5b.** In the notes minipage of `\label{fig:dose-response}`, after

```
each quartile's exposure range is printed beneath its tick.
```

append:

```
The $1.55$ hours in the top quartile is that quartile's own difference-in-differences; the raw contrast between the top and bottom quartiles is $1.55 - (-0.32) = 1.87$ hours.
```

## Step 6 — Empirical strategy

**6a.** After the sentence ending

```
would have evolved in parallel absent the shift to remote work.
```

(the Olden–Møen sentence in *Triple differences*) insert:

```
Insignificant pre-period coefficients are evidence about that assumption, not a verification of it.
```

**6b.** In *Inference*, after

```
adds a permutation test that relies on no asymptotic approximation at all.
```

insert:

```
The three procedures answer related but different questions, and where they disagree the disagreement is part of the evidence.
```

**6c.** In *Selection into employment: Lee bounds*, after

```
Appendix~\ref{sec:app-lee} gives the construction and its assumptions.
```

append:

```
The bounds address excess selection under monotonicity; they cannot address selection that violates it, nor differences in absence unrelated to excess selection.
```

## Step 7 — Results

**7a.** In Section 6.2 (`\label{sec:res-ddd}`), after

```
the regression implies $1.71$ hours a week against $1.87$ from the raw cell means.
```

insert:

```
These, together with the $1.55$-hour top-quartile difference-in-differences of Figure~\ref{fig:dose-response}, are three different quantities: the regression-implied contrast between the quartile means, the raw contrast between the two quartiles' own differences-in-differences, and the raw change within the top quartile alone. None is an estimate of another, and the text keeps them apart.
```

**7b.** In *Inference and falsification* (Section 6.4), replace

```
The estimate is significant at the $1\%$, $5\%$ and $10\%$ levels under the three procedures, and we report all three rather than choosing among them.
```

with

```
The strength of the statistical conclusion therefore depends on the inference procedure, and we report all three rather than choosing among them.
```

**7c.** In Section 6.6 (fathers' comparison), after

```
We report that as a reading the data are consistent with, not as a result the design identifies.
```

append:

```
Individual mothers and fathers are not linked in the data, and the fathers' coefficient is itself imprecise.
```

**7d. Promote the Lee-bounds table to the main text.** The headline leans on the selection correction, so its table should sit beside the result rather than in the appendix.

1. In `paper/appendix.tex`, locate the `table` float that inputs the Lee-bounds table (from Step 0). Note its label (call it `LEE_LABEL`). Cut the entire float (from `\begin{table}` to `\end{table}`).
2. Paste it into `paper/paper.tex` immediately after the `\paragraph{Selection.}` block in Section 6.3 (`\label{sec:res-ddd-diag}`), i.e. after the sentence ending `excludes zero.` and before `\paragraph{Sorting across occupations.}`. Wrap it in the same `threeparttable` / `\renewcommand{\baselinestretch}{1}\small` pattern the other main-text tables use if it does not already have one.
3. In the `\paragraph{Selection.}` prose, change `(Appendix~\ref{sec:app-lee})` to `(Table~\ref{LEE_LABEL}, Appendix~\ref{sec:app-lee})`.
4. Compare the table's untrimmed DDD row with column (2) of Table 2 (`3.224`, SE `1.022`). If they differ, add to the table's notes: `The untrimmed coefficient in this exercise differs slightly from column~(2) of Table~\ref{tab:hours} because the estimation and trimming samples are not identical.` If they are identical, add nothing.
5. `grep -n 'Table~[0-9]\|Table [0-9]' paper/paper.tex paper/appendix.tex`: the main-text tables renumber after this move, so any hard-coded table number in prose must be converted to a `\ref`. (Comments at the top of the file that say "Table 2", "Table 4" are comments; leave them.)
6. Leave the employment table (`tab:extensive`) in the appendix.

## Step 8 — Discussion

**8a.** After

```
and the raw top-quartile difference-in-differences of Figure~\ref{fig:dose-response} is $1.55$.
```

insert:

```
That $1.4$ is the fitted change \emph{at} top-quartile exposure, distinct from the $1.71$-hour fitted contrast \emph{between} the quartile means.
```

**8b.** Replace

```
not for whether mothers in general hold jobs.
```

with

```
not for whether mothers in general hold jobs; and access to those jobs is itself unequally distributed across mothers, so the population-wide gain is smaller than the gradient alone suggests and cannot be sized without representative weighting.
```

## Step 9 — Limitations

**9a.** In *Identification and exposure*, after

```
not the analytic $p$-value.
```

append:

```
The permutation test itself assumes that the forty exposure scores are exchangeable across occupations under its null.
```

## Step 10 — Conclusion (skeleton fix only)

**10a.** Inside the skeleton `enumerate`, paragraph 2 contains a factual error that contradicts the body and abstract. Replace

```
Fathers show no exposure gradient, and the women/men difference is $z = 3.461$
```

with

```
Fathers show an opposite-signed gradient ($-1.762$, SE $1.015$, $p = 0.09$), and the women/men difference is $z = 3.461$
```

**10b.** Add one line to the skeleton's comment block (after the line about the removed model answer):

```
% The Conclusion in docs/concise_20_pages.tex covers skeleton paragraphs 1, 2, 4 and 5 but omits
% paragraph 3 ("which mothers", and the measurement point). Use it only as a coverage check.
```

**Do nothing else in this section.**

## Step 11 — Cross-cutting

**11a.** If Step 0 found no `\ref{fig:pretrend-ddd}` anywhere, delete the line `\label{fig:pretrend-ddd}` under `\label{fig:pretrend}`. Otherwise leave it.

**11b.** Sweep for leftovers:

- `grep -n '1\.8\$\|\$1\.8 ' paper/paper.tex` → should return nothing (the 1.8 rounding is gone).
- `grep -n '10\\%\$ levels' paper/paper.tex` → should return nothing.
- `grep -n 'visible without any regression' paper/paper.tex` → nothing.

**11c.** Append to the provenance comment block at the top of `paper/paper.tex`, after the `% The only remaining "% TODO(<item>)"` line:

```
% MERGE PASS 2026-09-25 (docs/MERGE_PLAN.md). Language from docs/concise_20_pages.tex folded in:
% p-values reported directly in place of "1%/5%/10% levels"; 1.71 / 1.87 / 1.55 kept as three
% distinct quantities; identifying assumption stated in the Introduction; comparison-group and
% harmonization caveats moved up to Section 3; Lee-bounds table promoted to Section 6.3;
% permutation-exchangeability caveat added to Limitations. No number changed. Conclusion untouched.
```

**11d. Length (conditional).** Look in `docs/` for the assignment specification or the grade report and check whether a page cap applies. If there is none, skip this step. If there is a cap and the compiled PDF exceeds it after Step 12, cut in this order and stop when under the cap:

1. Literature Review: trim the second paragraph by ~20%, keeping every citation and the Gibbs/Pabilonia bracket.
2. Section 6.4 *Exposure measure* and *Outcome coding*: move the detail of the calibration and LPM checks into the notes of `tab:robust`, leaving one interpretive sentence per check in the prose.
3. Section 6.7 (extensive margin): reduce to two sentences plus a pointer to Appendix Table `tab:extensive`.

Do not cut from the Discussion or Limitations.

## Step 12 — Verify

From `paper/`:

```
pdflatex -interaction=nonstopmode paper.tex
bibtex paper
pdflatex -interaction=nonstopmode paper.tex
pdflatex -interaction=nonstopmode paper.tex
```

Then check and report:

- `grep -n 'undefined\|multiply defined\|Citation.*undefined\|same identifier' paper.log` → must be empty (a duplicate-destination warning from hyperref counts).
- `grep -c 'Overfull' paper.log` before and after the merge; report any new overfull box wider than 20pt with its page.
- Page count of `paper.pdf`.
- The Lee-bounds table appears in Section 6.3 with the expected numbers (`3.126`, `3.443`, `[1.021, 5.324]`).
- `git diff main --stat` and a numeric diff: `git diff main -- paper/paper.tex | grep -oE '[-+].*\$[0-9.-]+\$' | sort | uniq -c`. Every number in added lines must be one of: 0.003, 0.032, 0.056, 1.71, 1.84, 1.55, 1.87, -0.32, 1.4, -1.762, 1.015, 0.09, 3.224, 1.022. Report anything else.

## Final report

Reply with: the commit list, the page count, any anchor that did not match and what you did about it, the outcome of 7d step 4 (untrimmed row identical or not), and whether 11d was triggered.
