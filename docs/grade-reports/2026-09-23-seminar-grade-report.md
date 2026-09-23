# Seminar Grading Report

## Final Grade: 86 / 100

**Paper:** *Did Remote Work Narrow the Motherhood Penalty? Evidence on the Intensive Margin from
Israeli Labor Force Survey Microdata, 2017–2023* (`paper/paper.tex`, 42 pages).
**Graded:** 2026-09-23, from the LaTeX source, the generated tables in `paper/tables/`, the
figures in `outputs/figures/`, and the R pipeline (`main.R`, `scripts/`, `robustness/`,
`tests/testthat/`).
**Scope note:** the Conclusion (`paper.tex` lines 1425–1485) was excluded from the evaluation as
instructed. Nothing below refers to it, and no points were affected by it.

**Overall verdict.** This is an unusually mature empirical seminar paper. The design is correct
and carefully argued: a DiD with a pre-trend event study, a triple difference with the right
lower-order terms, occupation-level clustering with three small-cluster inference procedures,
a selection correction with Imbens–Manski intervals, saturated and binned functional-form checks,
a permutation falsification test, and heterogeneity that goes in the direction the mechanism
predicts. The pipeline is reproducible, the tables are machine-generated from the fitted models,
and the prose is honest about what the evidence does and does not show. Points are lost for two
identification issues the paper does not fully resolve (the partly post-treatment exposure
measure, and occupational sorting as an unaddressed channel), for a manuscript that is longer and
more repetitive than a seminar paper should be, and for several smaller presentational matters.

---

## Rubric

| Criterion | Weight | Earned |
|---|---:|---:|
| Academic writing quality (abstract through discussion; structure, precision, citations) | 20 | 16 |
| Correct application of econometric methods (DiD/DDD specification, identifying assumptions, inference, selection) | 30 | 25 |
| Regression tables and figures (formatting, completeness, notes, consistency with text) | 15 | 13 |
| Robustness of the empirical strategy (pre-trends, placebos, permutation, heterogeneity, reproducibility) | 20 | 18 |
| Clarity of the economic argument (mechanism, magnitudes, interpretation, limitations) | 15 | 14 |
| **Total** | **100** | **86** |

---

## Point Deductions

### Econometric methods (−5)

**Deducted 3 points: the headline estimate is not robust to the only fully pre-treatment exposure
measure, and the choice of the calibrated index as primary was made after seeing the results.**
The calibrated index swaps ten of forty occupation scores to their realized 2022–23 Israeli WFH
shares, which sit inside the post-period (Section 3.2, lines 380–397). With the fully
pre-treatment Dingel–Neiman index the triple interaction is 0.67 (SE 0.88, p = 0.45); with the
calibrated index it is 3.22 (SE 1.02); with the realized 2021 index it is 5.20 (SE 2.36)
(Table 4). The paper is candid about this (lines 967–998 and the Limitations paragraph at
lines 1362–1371) and offers a sensible defense: all ten swaps are downward, the shares are
computed on men and women pooled, and dropping the ten swapped occupations gives 4.31 (SE 1.19).
That last check is the strongest argument, but it is not a clean test of the *calibration*: it
changes the *sample* as well as the measure, removing nearly half the observations including the
three largest occupations (teaching, business associate professionals, ICT professionals). The
reader is left with a result that appears only when the regressor incorporates post-period
information or when the largest occupations are excluded. *Better approach:* (i) state a
pre-specified rule for choosing among the three indices and apply it, rather than describing the
calibrated one as primary and the others as robustness; (ii) construct the realized shares from
**men only** (fathers and childless men are not in the estimation sample), which removes the
mechanical link between the regressor and the outcomes of the women being modelled while keeping
all forty occupations; (iii) as a within-sample test of the calibration itself, estimate the DDD
on all forty occupations with the external index but add a swapped-occupation indicator
interacted with the full Mother × Post structure, so the sample is held fixed and only the
scoring of the ten occupations changes.

**Deducted 2 points: occupation is measured contemporaneously and is itself a potential outcome
of the treatment, and the paper never addresses occupational sorting.** The DDD assigns each
woman the exposure of her current occupation. If remote work led mothers to move into, or stay
in, teleworkable occupations after 2021 at different rates than childless women, the
post-period composition of mothers within high-exposure occupations changes for reasons that
have nothing to do with hours choices, and the triple interaction picks that up. The Lee bounds
handle selection into *employment* (Section 4.4), and the saturated specification absorbs
occupation-level shocks, but neither addresses selection *across occupations*. A search of the
manuscript finds no discussion of this channel; the only mentions of sorting (lines 277 and
1403) concern within-firm sorting in the wage-gap literature. *Better approach:* estimate a
DiD with the exposure score itself as the outcome (does mothers' mean exposure rise relative to
childless women's after 2021?). If it does not, say so and cite it as evidence against sorting;
if it does, report the DDD on the pre-period occupational distribution (assign each woman her
demographic cell's pre-period mean exposure, which the paper already constructs for the
employment DDD) as a bound, and discuss the direction of the bias.

*Noted without deduction:* the MDE uses normal critical values (2.8016 × SE) while inference for
the DDD uses t(39); the t-based factor is about 2.9, which would raise the DDD's MDE from 2.86 to
about 2.97 hours and slightly tighten the "detectable, though without much room to spare"
reading (line 838). The Lee construction handles only excess selection in the treated cell,
which the paper acknowledges (lines 1352–1358); a one-line report of what happens in the quartile
where s₁₁ is closest to its counterfactual would make the "little to correct" claim concrete.

### Robustness (−2)

**Deducted 1 point: no influence or leave-one-occupation-out check, even though the identifying
variation rests on a handful of occupations.** Table 2, column (4) shows the response is a step in
the top quartile, which holds six of the forty occupations; two of them (ICT professionals,
N ≈ 14,600, and science and engineering professionals, N ≈ 13,200) are among the largest cells
in the sample. The Arab-women subsection (lines 1155–1163) correctly worries that a few
high-leverage occupations can dominate a small sample, but the same worry is never applied to
the headline. *Better approach:* re-estimate the DDD forty times dropping one occupation each
time and plot the forty triple-interaction estimates with their intervals (a jackknife-style
influence plot); report the range and name any occupation whose removal moves the estimate by
more than one standard error.

**Deducted 1 point: no covariate table by exposure quartile.** The paper states in text that the
mother/childless age gap tracks exposure (−0.97 age-group codes in the lowest quartile,
+0.06 in the highest; lines 1006–1010) and that this "is real and tracks exposure", but the
reader cannot see whether education, marital status, or population group are similarly
unbalanced across quartiles, which is what the DDD's comparison across exposure levels depends
on. *Better approach:* add a compact appendix table with the mother-minus-childless difference
in each control, by exposure quartile, pre-period only, with clustered standard errors. This is
the DDD counterpart of Table 1.

### Tables and figures (−2)

**Deducted 2 points: formatting inconsistencies across the regression tables.**
- Coefficients and standard errors are printed to four *significant* digits rather than a fixed
  number of decimals, so Table 2 mixes 3.224, 0.9495, 0.2280, and 32.35 in the same column, and
  Table 5 prints 1.862 next to 0.9354. Journal and seminar convention is a fixed number of
  decimals per table (three here would suffice). *Better approach:* change the formatter in
  `scripts/tex_coef_cell.R` to fixed decimals; the tables are generated, so this is a one-line
  change.
- R² is printed to five decimals (0.04049), which is spurious precision. Two or three suffice.
- Table 4 reports the cluster count only in its note ("clustered by occupation unless stated");
  the unswapped-occupations row has 30 clusters, not 40, and the reader learns this only from
  the text (line 993). *Better approach:* add a "Clusters" column to Table 4.
- Figure 1's upper panel uses a truncated y-axis (roughly 38–41 hours), which visually magnifies
  movements of under half an hour. The lower panel makes the point correctly; either drop the
  upper panel or note the axis range in the caption.
- The compile log records duplicate hyperref destination warnings (`table.1`, `figure.1`,
  `page.1`), a harmless but untidy artefact of the table-of-contents group; fix with
  `\hypersetup{pageanchor=false}` on the title page or by using `\pagenumbering`.

Otherwise the tables are well done: notes state the sample, controls, clustering, and the MDE;
every number in the prose that I checked against the tables agrees (the DiD, the DDD and its
per-SD and between-quartile scalings, the Lee trim proportions, the two-sample z-statistics, the
Imbens–Manski intervals), and the figures are clean, consistently styled, and carry 95% intervals
with the reference year and the excluded 2020 clearly marked.

### Academic writing (−4)

**Deducted 2 points: length and repetition.** Excluding the Conclusion the manuscript runs to
roughly 12,900 words and 42 pages, well beyond what a seminar paper needs to make this argument.
The three-way disagreement among the analytic, permutation, and bootstrap p-values is stated in
full in the Abstract, the Introduction, Section 5.2, Section 5.4, the Discussion, and the
Limitations. The post-period calibration caveat, the forty-cluster caveat, and the 2023 caveat
each appear three or more times. The prose also leans on meta-commentary that tells the reader how
to read a sentence rather than simply saying it ("One caveat belongs here rather than in a
footnote", "That pattern deserves a direct statement", "worth stating once", "The column's second
row is as informative as its first"). *Better approach:* state each caveat once, in the section
where the evidence appears, and cross-reference it from Limitations in a single clause; cut the
meta-commentary; target 8,000–9,000 words. The Abstract (about 330 words, eleven numbers) should
be halved and carry at most the DiD, the DDD, and one inference statement.

**Deducted 1 point: the literature review is thin on the evidence most directly relevant to the
outcome.** The review covers the child penalty, Goldin's flexibility framework, WFH measurement,
and continuous-treatment DiD well, but it contains no discussion of the direct evidence on
whether remote work changes *hours* (for example the post-pandemic WFH literature summarised in
Barrero, Bloom and Davis's survey work, Emanuel and Harrington on selection into remote work, or
Gibbs, Mengel and Siemroth on hours and output among remote IT professionals), nor any Israeli
evidence on the child penalty itself against which the 1.74-hour intensive-margin penalty could
be benchmarked. *Better approach:* one paragraph on what is known about WFH and hours, with the
sign and magnitude the present estimate should be compared to, and one or two sentences placing
the Israeli hours penalty in the context of existing Israeli estimates.

**Deducted 1 point: internal inconsistencies a careful reader will stumble on.** Section 4.3
(line 644) describes "the hours estimation sample of 258,175 observations", but the DiD in
Table 2 is estimated on 251,857 observations; 258,175 is the descriptive count of Table 1. The
6,318-row difference (presumably rows with a missing control) is never explained. The same
section gives the panel share crossing the pre/post boundary as 1.9% while a source comment gives
1.88% of 80,560 individuals, a different denominator from the 64,602 quoted two sentences
earlier. *Better approach:* add one sentence stating why the regression sample is smaller than
the descriptive sample, and use one denominator for all panel-structure statistics.

### Clarity of the economic argument (−1)

**Deducted 1 point: the "four fifths of the penalty recovered" statement compares the wrong
quantities, and demand-side alternatives to the mechanism are not confronted.** The Discussion
(lines 1289–1295) sets the implied 1.4-hour change for a top-quartile mother against the
*average* penalty of 1.74 hours. But the DDD's own coefficients say the pre-period penalty in a
top-quartile occupation is larger: Mother (−1.45) plus Mother × WFH (−1.30) times mean top-quartile
exposure (0.59) gives about −2.2 hours, so the recovered share is closer to three fifths. The
Discussion also rules out "a general post-pandemic recovery common to all women" as the only
alternative to the time-constraint mechanism, but it does not consider employer-side changes
concentrated in teleworkable sectors that could interact with motherhood without any change in
mothers' constraints (for example a shift in the availability of part-time contracts in
professional and ICT occupations, or the 2021–22 hiring boom in those sectors). The fathers'
negative gradient is read as household reallocation, which is plausible, but an alternative
reading in which remote work changes how hours are *reported* by fathers and mothers differently
is not raised. *Better approach:* redo the arithmetic with the exposure-specific penalty; add a
short paragraph listing the two or three most plausible demand-side alternatives and stating
which of the paper's own checks (the fathers' opposite sign, the child-age gradient, the
saturated specification) bears on each.

---

## Strengths (what earned the points)

- **Correct and well-motivated design.** The DDD includes every lower-order interaction, the
  paper states precisely what each absorbs (lines 613–626), and it invokes the single
  parallel-trends assumption of Olden and Møen rather than two. The continuous-treatment caveat
  from Callaway, Goodman-Bacon and Sant'Anna is stated and acted on with saturated and binned
  specifications that agree with the linear one.
- **Serious inference.** Clustering at the level the regressor varies, a t(39) reference, a wild
  cluster bootstrap with the null imposed, and a permutation test on the studentised statistic,
  with all three reported side by side rather than the most favourable one chosen. The code
  (`robustness/hours_ddd_inference.R`) implements these correctly, seeds both random number
  generators, and applies the Phipson–Smyth correction.
- **Pre-trends tested at the right level.** The paper recognises that the DiD event study does
  not license the DDD, estimates the DDD's own event study, and is honest that the pre-period
  intervals are wide enough to contain the estimate itself.
- **Selection into the sample handled rather than assumed away**, including the 2017 coding
  discontinuity in usual hours, which the authors found, diagnosed, and fixed by harmonising the
  hours population across years (documented in `scripts/data_processing.R` and
  `docs/decisions/hours-population-harmonization.md`).
- **Heterogeneity in the predicted direction**, with the child-age gradient and the fathers'
  opposite sign both interpreted with appropriate restraint.
- **Descriptive evidence before the regressions.** The four cell means, the year-by-year gap,
  and the quartile dose-response figure let the reader see the result before any model is
  imposed, and the paper checks that the regression reproduces the raw arithmetic.
- **Reproducibility.** `main.R` orchestrates the whole pipeline; every table in the paper is
  generated from the fitted models by `scripts/build_paper_tables.R` and `\input{}` by
  `paper.tex`, with collinearity notes generated from each model's dropped-coefficient list. The
  test suite (`tests/testthat/`, 318 test blocks in 56 files) runs on synthetic fixtures without
  the confidential microdata. Specifications in the code match the paper's equations and
  clustering statements at every point I checked (DiD, DDD, saturated, binned, Lee bounds,
  permutation test, cell-based index built from the calibrated score). All 26 bibliography
  entries are cited and every citation resolves; the LaTeX log shows no undefined references.
- **Honesty.** The Limitations section is a model of its kind: the exposure measure's
  post-treatment component, the narrowed estimand, the undocumented crosswalk, the 2023 war
  quarter, and the unweighted estimates are all stated plainly.

---

## Reproducibility check

- Pipeline structure: `main.R` sources 60 single-function scripts and four robustness chains;
  all sourcing is root-relative. The confidential CBS files live outside the repository and were
  not available, so the numbers were not re-derived; they were checked for internal consistency
  across the prose, the generated tables, and the figure annotations.
- Test suite: `Rscript run_tests.R` was executed on 2026-09-23 with R 4.5.1. Result recorded
  below.
- Dependencies are limited to tidyverse, fixest, and `fwildclusterboot` (loaded lazily), as
  documented.

**Test result:** `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1284 ]`, exit status 0. The full suite passes
on this machine without the confidential microdata, which is what a reader without CBS access
needs in order to trust that the pipeline's logic (sample construction, exposure calibration,
DDD specifications, Lee bounds, table generation) behaves as the paper describes.
