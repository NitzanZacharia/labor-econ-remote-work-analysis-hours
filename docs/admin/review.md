# Referee review: suggested revisions

Branch `review`, taken from `doc-audit` at `cbf90ce`. Written 2026-09-28.

**Scope.** This file covers problems with what the paper claims, computes or reports about its own
design. It does not propose new research questions, new data, survey weights, or a different
identification strategy.

**How the list was checked.** Every number below was recomputed from the CBS microdata, rebuilt
in memory with `load_and_clean_data()`. The rebuild reproduces the headline exactly: 3.224 (SE
1.022), N = 246,326, 40 clusters. A second, independent agent then re-derived each claim with its
own code and tried to refute it. Items it rejected are listed in the last section, with the
reason. Where the two computations differ, both values are given.

**Before any number enters the paper:** none of these computations was saved. Every new row
must be produced by `main.R`, through `scripts/build_paper_tables.R`, because `paper/tables/*.tex`
are generated files. After editing the `.tex` files, recompile the PDF. Line numbers refer to
`paper/paper.tex` unless marked `appendix.tex`.

## Summary

| # | Priority | Item | Kind |
|---|---|---|---|
| 1 | High | Marital status is imbalanced with exposure, but only age is tested | New robustness rows + text |
| 2 | High | The supporting rows use an inference test that over-rejects | New p-value column + text |
| 3 | High | "The calibration does not produce the result" overstates | Sweep + one row + text |
| 4 | High | The commuting arithmetic contradicts its own source | Text |
| 5 | Medium | Pre-trend wording is stronger than the numbers | Text (+ footnote) |
| 6 | Medium | The top hours bin (60+, coded 78.5) moves the estimate | New rows + text |
| 7 | Medium | The measurement-error sentence uses the wrong error model | Text |
| 8 | Medium | The ICT sentence names the wrong occupations | Text |
| 9 | Medium | The rebuttal of reporting bias contradicts a cited paper | Text |
| 10 | Medium | The masking check is summarised but never shown | Text (appendix) |
| 11 | Medium | Absence margin: the check the Limitations section asks for is feasible | New rows |
| 12–22 | Low | Numerical and wording precision | Text |

---

## High priority

### 1. Marital status: the imbalance the paper names but does not test

**Where.** At 746–748 the paper says mothers and childless women differ "in age, education and
marital status in ways that themselves vary with exposure", and that "such a gap is what the
triple interaction is identified off". Only age is then tested (748–751, 980–983). Controls
enter in levels only (339–341). The imbalance itself is stated at 394–397: 85% of mothers are
married against 47% of childless women.

**Problem.** In high-exposure occupations, a large and growing share of the childless comparison
group is never married. Their hours fell after 2021. Part of the "mothers rose relative to
childless women" gradient can therefore come from the comparison group, not from mothers.

**Evidence.**
- Never-married share of childless women: 28.6% in exposure quartile Q1, 45.7% in Q4.
- Raw change in hours after 2021, Q4 minus Q1: married mothers +2.2, married childless women
  +0.7, never-married childless women −0.45.
- Adding marital status × Post × WFH (as a factor): 2.191 (SE 1.273), p = 0.093.
- Married women only: 2.743 (SE 1.512), p = 0.078, 39 clusters.
- The other four controls, each interacted the same way, leave the estimate at 2.97–3.17. Marital
  status is the only one that moves it.
- Two caveats, both from the independent check. Interacting marital status is partly
  over-control: most mothers are married, so the term is partly estimated off mothers themselves
  and absorbs some of the effect. Restricting to married women also swaps a marital confound for
  a life-stage one: married childless women are about one age code (about 5 years) older and
  often have grown children. Adding marital and age × Post × WFH together gives 1.847 (SE 1.049).

**Why this improves the paper.** The paper names this imbalance and then leaves it untested. A
referee reads that as a test the authors chose not to run. Reporting it:
1. Closes the most obvious identification question in the paper.
2. Shows the gradient stays positive (about 1.8–2.7) under every version.
3. Turns a hidden weakness into a stated, bounded one.

The cost is that two rows lose conventional significance. A result that holds only when the
reader doesn't know about the imbalance is worth less than a slightly weaker result the reader
can trust. A referee who finds this unreported will discount every other robustness row.

**Suggested change.**
- Add two rows to Table `tab:robust` under the age rows: *married women only* and *marital status
  × Post × WFH*. Both go through `run_hours_ddd_regression()`: the second uses its `controls`
  argument, the first a subsetted `cleaned_df`. Wire them in `main.R` and
  `build_paper_tables.R`.
- In §5.4 (after line 751), add a short paragraph:
  - The estimate falls to about 2.2–2.7 and becomes marginal.
  - Part of the gradient reflects never-married childless women in high-exposure jobs working
    fewer hours after 2021.
  - Neither row is a clean test (over-control; life-stage mix).
- Add one clause to the Limitations age paragraph (980–983).
- Do **not** add the all-five-controls × Post × WFH version (1.414, SE 0.919). It adds about 30
  terms on 40 clusters and cannot be interpreted.

### 2. The supporting robustness rows use an inference test the paper itself distrusts

**Where.**
- Stars legend: 593–594.
- Inference section: 524–537.
- The three p-values for the headline: 669–677.
- The "pattern of evidence" paragraph: 888–892.
- "significant at the 5% level in every refit": 757.
- "still significant at the 5% level": 750.
- Limitations: 955–956.

**Problem.** The paper carefully reports analytic, permutation and wild-bootstrap p-values for
the headline. Every other row in Tables `tab:robust`, `tab:childage` and `tab:subgroup` is starred
from the analytic t(39) test only. In this design that test over-rejects. The Discussion then
builds the case for credibility from those rows.

**Evidence.**
- The paper's own 999 permutation draws, reused: the analytic 5% test rejects in 14.1% of draws
  where exposure carries no information. The 95th percentile of |t| is 2.855, not 2.02.
- Effective number of clusters (Carter–Schnepel–Steigerwald): G* = 6.2–8.6, not 40.
  Occupations 26 and 21 carry about half the weight.
- Rows that pass a |t| > 2.86 screen: the headline, saturated, top-quartile bin, child age 0–4,
  and the women-vs-men z-test (3.46).
- Rows that fail it:
  - child age 5–9, 10–14 and 15–17
  - age-reweighted
  - excluding 2023
  - Arab women
  - the Lee lower bound
- The screen is only a rough guide, because the 2.86 cut-off comes from the headline's own design.

**Why this improves the paper.**
- The paper's own stance is that "how precisely the headline is estimated is the range of the
  three inference procedures, not the analytic p-value" (955–956). Applying that stance to the
  supporting rows makes the paper consistent with itself.
- As it stands, a referee can point out that the credibility argument rests on stars the authors
  consider unreliable.
- The checks also reuse the same 40 clusters, so they are not independent confirmations. Saying
  so pre-empts the objection.

**Suggested change.**
- Add a wild-cluster-bootstrap p-value column to `tab:robust`, `tab:childage` and `tab:subgroup`
  (DDD columns), using the existing `run_hours_ddd_wild_bootstrap()` in
  `robustness/hours_ddd_inference.R`. It needs `fwildclusterboot`, an approved dependency that is
  not installed on this machine, so run it wherever `main.R` normally runs.
- Keep the stars. Don't remove them; add the column.
- Report G* once in §4.3.
- In 888–892, replace "what makes the finding credible is the pattern of evidence" with wording
  that says the checks share the same 40 clusters. Also soften 750 and 757 where the bootstrap
  says so.

### 3. Calibration: "does not produce the result" claims more than the checks show

**Where.**
- The promise at 366–369.
- The conclusion at 738–741: "The calibration does not produce the result".
- Its repetition in Limitations at 945–947.
- "a regressor fixed before treatment" at 948. The cell index averages the *calibrated* score
  (377; `main.R:271–275`), so it is only fixed in occupational composition.

**Problem.** Without reclassification there is no result. The only fully pre-treatment index
(external Dingel–Neiman) gives 0.672 (SE 0.884). The two supporting checks do not rescue the
sentence:
- The unswapped-30 row uses pre-treatment scores, but the choice of *which* 30 uses the 2022–23
  data.
- The men-only row changes whose data calibrate the index, not whether post-period data are used.

**Evidence.**
- Swapping teaching (ISCO 23) alone, keeping every other external score: 1.934 (SE 0.519),
  p < 0.001. Swapping clerks (41) alone: 0.955 (SE 0.934). Reclassifying teaching is what
  creates the result.
- The threshold rule (0.5) has its own sensitivity:

  | Threshold | Estimate (SE) | p | Note |
  |---|---|---|---|
  | 0.30–0.42 | 3.93 (2.82) | 0.17 | |
  | 0.44 | 4.88 | < 0.01 | |
  | 0.45 | 4.24 | < 0.01 | |
  | 0.50 | 3.224 | < 0.01 | headline |
  | 0.55–0.70 | 2.48–3.10 | < 0.01 | |
  | 0.75–0.85 | 2.319 (0.504) | < 0.01 | only 23 and 41 swapped |
  | above that | 0.672 | | nothing swapped (external index) |

**Why this improves the paper.** The honest version of the claim is actually *stronger* ground
to defend. The teaching reclassification rests on an institutional fact the paper already
documents: Israeli schools were fully in person in 2022–23 (appendix 78–81, 354–355). That fact
is independent of anyone's hours. "The result requires reclassifying teaching, and here is the
external evidence that teaching was in person" is a sentence a referee can accept. "The
calibration does not produce the result" is a sentence a referee can refute with the paper's own
0.672. Leaving it invites the reader to distrust the other exposure claims.

**Suggested change.**
- Rewrite 738–741 and 945–947 along those lines.
- Add a *teaching-only swap* row to `tab:robust`.
- Add the threshold sweep to the appendix as a small table or figure, generated in `main.R`
  through `calibrate_isco_exposure(gap_threshold = ...)`.
- At 948, change "a regressor fixed before treatment" to "a regressor that a woman's post-2021
  occupation cannot move".

### 4. The commuting arithmetic contradicts the source it cites

**Where.** 906–909: "the time saved is about 72 minutes per day worked from home
[aksoy2023] ... a mother who returns most of that time to paid work is a mother whose hours rise
by about the amount estimated here."

**Problem.** There are two problems.
1. **The source says the opposite.** Aksoy et al. (2023) find that workers put about **40%** of
   the saved time into their jobs; the rest goes to leisure and caregiving. The paper's own
   literature review says the time is split (275–276). Two remote days × 72 min × 40% ≈ 1 hour,
   not 2.5.
2. **The comparison mixes units.** The 1.4 hours is an average over *all* mothers in
   top-quartile jobs. Only a minority of them work from home: 43% in the reference week in Q4,
   against 17% in Q1. The first-stage slope for mothers is 0.403 (SE 0.072). Per mother who
   actually works from home, the implied increase is roughly 6.5–8 hours a week, much more than
   the ~2.4 hours of commute saved. One caveat: the mother-minus-childless first stage is small
   (0.058, SE 0.070), so this scaling is rough.

**Why this improves the paper.** As written, the sentence is checkable against the paper's own
citation and fails. Correctly stated, the magnitude says that commuting time alone cannot
account for the effect. That points to the channel the paper's framework actually proposes:
being able to split hours around care (Goldin; the paper's 258–261). The fix removes a factual
error and aligns the magnitude discussion with the paper's own mechanism.

**Suggested change.** Replace 906–909 with a statement that the per-WFH-mother response exceeds
the commuting time freed, and that this is consistent with flexibility in *when* hours are
worked, not just time saved on travel. Cite the 40% figure correctly, and keep it hedged.

---

## Medium priority

### 5. Pre-trend wording

**Where.**
- "a reasonably precise null": 218 and 602.
- "the groups were not diverging before treatment": 430 and appendix 51–53.

**Problem.** The raw pre-period gap widens monotonically: −1.37, −1.48, −1.67 hours in
2017–2019. The event-study coefficients relative to 2019 are 0.352 and 0.201. The widening is
not significant, but "not diverging" describes three points that all move one way.

**Evidence.**
- Linear pre-period trend in the DiD: −0.175 hours/year (SE 0.129).
- Extrapolated, the trend-adjusted DiD would be 0.939 (SE 0.546).
- This rests on a trend fitted to three points, so it is a sensitivity, not an estimate.

**Why this improves the paper.** A reader who looks at the appendix numbers sees the monotone
pattern immediately. Describing it accurately costs nothing: the paper states that "nothing that
follows rests on this average" (606–607). It also removes a claim ("precise null") that the
trend makes fragile.

**Suggested change.**
- At 430 and appendix 51–53, write "the gap widened slightly, by 0.3 hours over two years,
  within sampling error".
- At 218 and 602, drop "reasonably precise" or add "absent a pre-trend".
- Optionally, footnote the trend-adjusted DiD. Keep it out of the main text.

### 6. The top hours bin

**Where.** Appendix 11–12 assigns 78.5 hours to the open 60+ bin. Paper 770–771: "The effect is
a shift of mothers in teleworkable jobs across the full-time boundary."

**Problem.** 78.5 is the centre of a 60–97 range, but the true mean of that bin is unknown. Part
of the gradient sits at the top of the distribution, not at the full-time boundary.

**Evidence.**
- Top bin recoded to 70: 2.932. To 65: 2.761. To 60: 2.589.
- A linear probability model for being in the 60+ bin gives a triple interaction of 0.034
  (SE 0.009).
- Childless women in Q4 jobs fell from 3.3% to 2.2% in the top bin. Q4 mothers rose from 1.75%
  to 2.24%.

**Why this improves the paper.** The value 78.5 is a coding choice. A referee will ask whether
the estimate depends on it; it moves by up to 20%. The estimate stays positive at every recode,
so reporting this strengthens the outcome-coding section. It also corrects a sentence (770–771)
that locates the effect in one place when the data show it in two.

**Suggested change.**
- Add the 60+ LPM row and one recode row (top bin = 60) to *Outcome coding* in `tab:robust`.
- Rewrite 770–771 to say the effect appears both at the full-time boundary and at the top of
  the distribution, where it partly reflects childless women leaving very long hours.

### 7. The measurement-error sentence

**Where.** 951–953: "within-occupation heterogeneity in teleworkability is classical measurement
error in the regressor and attenuates the triple interaction toward zero".

**Problem.** Giving every woman her occupation's mean score is *Berkson* error (true value =
assigned value + noise). Berkson error does not bias a linear slope. Attenuation comes only from
error in the occupation score itself. If mothers sort into more (or less) teleworkable jobs
*within* an occupation, the bias has unknown sign.

**Evidence.** Simulation with a true slope of 3.00: Berkson-type assignment gives 3.14; classical
error of the same size gives 1.79.

**Why this improves the paper.** The sentence invokes the wrong error model to imply the
estimate is conservative. Any econometrics-trained referee will catch it. The correct statement
is shorter and does not overclaim.

**Suggested change.** Replace it with: assigning the occupation mean does not by itself bias the
slope; error in the occupation score attenuates it; within-occupation sorting of mothers could
bias it in either direction.

### 8. The ICT sentence

**Where.** 892–894: "The gradient is identified off a concrete contrast: ICT professionals
stayed high on every exposure measure, while teaching and clerical support ... moved sharply
down."

**Problem.** ICT is in the top quartile on every measure. That part is true. But ICT does not
carry the gradient; it works slightly against it.

**Evidence.**
- ICT's own triple-interaction response is +0.76 (SE 0.65).
- Dropping ICT *raises* the estimate to 3.29.
- Split into per-occupation contributions, 26 (legal, social and cultural professionals) adds
  +2.14 of the 3.224, 21 (science and engineering professionals) adds +1.69, and ICT (25) adds
  −0.58.
- Dropping 21 gives 2.415, the lowest leave-one-out value.

**Why this improves the paper.** The sentence tells the reader which occupations the result
comes from, and it names the wrong one. Anyone who reads the leave-one-out figure (appendix
`fig:loo`) can see this. Naming the real carriers is also more informative.

**Suggested change.** State that the gradient is carried mainly by ISCO 26 and 21, and that it
relies on teaching and clerks being placed low (item 3). Keep ICT only as an example of an
occupation that is high on every measure.

### 9. The rebuttal of reporting bias contradicts a cited paper

**Where.** 920–924: "the child-age gradient weighs against this, since a reporting difference has
no reason to be twice as large for mothers of infants as for mothers of teenagers." Compare
279–281, which cites [pabilonia2022]: teleworking mothers report more interruptions to their
workday.

**Problem.** The paper's own cited evidence gives a reason for exactly that pattern. Interruptions
from young children make "hours available" and "hours worked" diverge more for mothers of
infants. A reporting gap would therefore plausibly produce the same child-age gradient.

**Why this improves the paper.** An internal contradiction that a reader can spot from the paper
alone damages the Discussion's credibility. The honest version already fits the paper's closing
line ("the mechanism's signature rather than its proof", 924–925).

**Suggested change.** Concede that the child-age gradient does not separate labor supply from
reporting, and cite [pabilonia2022] for why. Keep the other two arguments.

### 10. The masking check is summarised but never shown

**Where.** 953–955: "a proxy check finds no strong evidence of bias from this."

**Problem.** `check_isco_masking_sensitivity()` exists and runs, but the paper never says what it
does or what it found.

**Evidence.**
- The pooled `ISCO_masked` coefficient is 0.045 (SE 0.021): significant at 5%, though tiny in
  explanatory power (within-R² ≈ 0.0001).
- Among professionals (ISCO major group 2), masked workers work from home at 0.29 against 0.16
  for unmasked ones (n = 207 masked).
- The project's own digest calls this "not a clean bill of health" (`results_digest.md`, 864–865).

**Why this improves the paper.** An unverifiable reassurance is weaker than a reported small
number. As written, the claim can't be checked, and the underlying result is slightly less
reassuring than the words suggest.

**Suggested change.** Add two sentences in appendix §B:
- What the check does: masked rows are identified at the one-digit ISCO level.
- What it found: masked professionals work from home more often; the difference is small and the
  rows are few.

Change 954–955 to "finds a small, statistically detectable difference".

### 11. Absence margin: the check the Limitations section asks for can be done

**Where.** Limitations 959–967 say absence is related to exposure and that the bounds "found
little to correct, which is not the same as the concern being absent". The Lee method is set out
at 546–550 and appendix 164–169.

**Problem.** The paper treats the absence margin as out of reach. It is not: 98% of
employed-but-absent women carry an occupation code, so exposure is defined for them.

**Evidence.** The two independent implementations agree in direction and roughly in size, but
differ in levels.
- Lee bounds on the absence margin, trimmed within occupation-exposure quartiles: lower bound
  2.32 (my implementation, p = 0.034) and 2.34 (the verifier's). Upper bound 4.22 and 3.96,
  respectively.
- Including absent women at their usual hours, 2018–2023 only, because 2017 recorded their hours
  as zero: the estimate falls by about 0.29 (3.19 → 2.91 in one implementation, 3.38 → 3.09 in
  the other).

**Why this improves the paper.** It turns an admitted gap into evidence, and the evidence is
favourable: the lower bound stays positive and significant. These rows complement the existing
bounds, which must use the cell index because the employment margin has no occupation. They do
not replace them.

**Suggested change.**
- Add both rows to the *Selection* block of `tab:robust`.
- Update the last sentence of 964–967.
- The pipeline version is the one to report. The two implementations here differ in details.

---

## Low priority: numerical and wording precision

Each of these is a small fix. Leaving them in gives a careful reader a reason to doubt the
larger claims.

**12. The abstract omits the weakest exposure result** (162–179). It lists what the gradient
survives, but not that the one fully pre-treatment index gives 0.672 (SE 0.884). The
Introduction reports it (229–231). The abstract is what most readers read, so leaving it out
there looks selective. *Add one clause.*

**13. The Introduction's magnitude comparison conflicts with the Discussion's** (219–221 vs
900–904). The Introduction sets the 1.71-hour between-quartile contrast against the 1.74-hour
*average* penalty, which implies near-full recovery. The Discussion says explicitly that the
comparison must be with the penalty in the same jobs (−2.2 hours), and finds three fifths
recovered. *Use the Discussion's comparison in the Introduction.*

**14. "Two thirds"** (735–736). The swapped-occupation gradient is 0.726 of the headline. *Write
"nearly three quarters".*

**15. "A factor of two to three"** (869–872). 1.43 pp per SD of the cell index against 0.78 pp per
10% rise in WFH are different units. Taken at face value the ratio is 1.8, and no conversion is
shown. *Show the conversion or write "roughly twice".*

**16. Occupation counts: 16 vs 15** (`tab_hours.tex` shows Q1 = 16; `tab_balance_quartile.tex`
shows Q1 = 15). The extra one is ISCO 63: 4 observations, all post-period. *Add a note through
`build_paper_tables.R`, or drop occupations with no pre-period rows from the count.*

**17. Top-quartile range** (440): "0.30 to 0.75". 0.30 is the breakpoint; the lowest Q4
occupation scores 0.36 (`tab_balance_quartile`). *Write "0.36 to 0.75", or say "above 0.30".*

**18. "A selection correction that barely moves the bounds"** (891–892). The correction
*produces* the bounds. What barely moves is the estimate. *Write "a selection correction whose
bounds (3.13, 3.44) stay close to the headline".*

**19. The fathers' DiD is in the table but not in the text.** `tab:subgroup` shows fathers'
average hours falling relative to childless men, −0.400\* (SE 0.188), and a women-vs-men DiD
difference of z = 2.41 (p = 0.016). §5.5 (820–829) discusses only the fathers' gradient. This is
a significant result the text ignores, and it bears on the reallocation reading at 826–829.
*Add one sentence.*

**20. Table A1 note: "all ages in the extract"** (appendix 116–117). The calibration population
is men and women aged 25–59: both `cleaned_df` and `cleaned_men` are filtered to age codes 3–7
before `exposure_population_df` is built in `main.R`. *Replace with "aged 25–59".*

**21. "Under 17"** (323, 412, 976–977). The household child count used runs through age 17: the
youngest-child groups end at 15–17 (807, `tab:childage`). *Write "aged 17 or younger" or "under
18".*

**22. "The MDE rules out gains above half an hour"** (600–601). An MDE is a power statement; it
does not rule anything out. The 95% confidence interval, [−0.13, 0.58], does. *Say that instead.*

---

## Checked and not included

| Raised earlier | Why it is not in the list |
|---|---|
| "First estimate of the Israeli penalty in hours" (238) | Already hedged ("to our knowledge") and consistent with 300–302. |
| Stray `\noindent` (330, 351, 432, 501, 561, 573, 896, 913, 927) | Cosmetic only. |
| Remove significance stars | Replaced by item 2 (add a bootstrap column). |
| All five controls × Post × WFH | Over-parameterised on 40 clusters (item 1). |
| Child-age gradient as an age artifact | It survives age × Post × WFH: 3.76 / 3.22 / 2.57 / 1.80. |
| Haredi composition | Excluding them gives 2.96. Not a threat. |
| Scale-mixing in the calibrated index | Already disclosed (953, appendix 98–100, 146–148). |
| Two-way clustering row | No problem found. |
| "Fixed ex ante" selection rule (357) | Can't be verified from the repo either way. |
| Household vs own children | The paper says "in the household". The own-child definition gives 3.02; dropping mothers with no own child gives 3.21. |
| Trend-adjusted DDD (4.40, SE 4.01) | Uninformative. The paper already says the DDD pre-test lacks power (665–667). |
