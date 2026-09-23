# Editorial audit plan: `paper/paper.tex` (intensive-margin revision)

## Context

The draft (37 pages, ~12,900 words of body text including tables) was written across a pivot: the
project began as an extensive-margin (employment) study and became an hours study. The results and
the abstract already reflect the pivot; the *architecture* does not. Employment material still
occupies its original real estate (two Results subsections, two tables, a Descriptives subsection,
an extensive-margin hypothesis, and a power post-mortem), the Results section still "moves from the
extensive to the intensive margin," and several passages narrate the draft's own revision history
("we previously read this pattern...", "an earlier version of this analysis..."). The audit below
lists, section by section, what to cut, what to tighten, and where the econometric exposition needs
sharpening. Every number cited here is from the current draft; nothing was recomputed.

Verified facts that shape the plan:

- Body length ~12,900 words, 37 pages, 6 tables (incl. summary stats), 4 figures. Tables 6 and 7
  duplicate Figures 3 and 4 coefficient for coefficient.
- The Conclusion is a red skeleton block that the course requires the student to write alone
  (`docs/pre-submission-audit-decisions.md`, D1). This audit gives it a structure, not prose.
- Still-open register items that the audit interacts with: D2 (furlough sentence; now lives only
  in Discussion lines 1340–1348 and dies with the cut recommended there), D3 (course bibliography
  rule), D4 (Kleven a/b order), D5 (crosswalk provenance), D11 (`\today` on the title page).
- The cleaning step drops a survey-month field (`ChodeshSeker`) and a field that looks like a
  computed wage (`SacharMechushavmechushav`). Neither is used. Both matter below.
- Usual hours are bin medians: 4, 11, 18, 25.5, 32, 37, 42, 47, 54.5, 78.5. Mid-distribution bins
  are ~5 hours wide, so the 3.2-hour headline is smaller than one bin.

---

## A. Cross-cutting directives (apply before section work)

### A1. Re-architect around the primary margin

- **Reorder Results.** Current order: 5.1 employment DiD, 5.2 employment DDD, 5.3 hours, 5.4
  subgroups/placebo. New order: 5.1 hours pre-trends and DiD; 5.2 hours DDD (headline); 5.3
  DDD pre-trends and selection bounds; 5.4 robustness; 5.5 subgroups and placebo; 5.6 "The
  extensive margin, briefly" (one paragraph, one compact table). Update the roadmap sentence in the
  Introduction ("moving from the extensive to the intensive margin") accordingly.
- **Demote employment everywhere it is co-equal.** Abstract (3 of ~9 sentences), Introduction
  findings paragraph, Hypotheses (H2), Empirical Strategy (Spec 1 / Spec 2 description), and the
  Discussion's "Why hours and not employment?" all treat the two margins symmetrically. After
  revision, employment should appear as: one abstract clause, one intro sentence, one strategy
  sentence, one results paragraph + table, one discussion paragraph.

### A2. Purge draft-history narration

A paper reports what it finds, not what it used to think. Delete or rewrite as plain statements:

- `paper.tex:525–530` (Descriptives 4.3): "It is worth being explicit that this was not always so
  ... an artifact of the spurious zeros ..." Cut; the Data section already documents the coding
  issue.
- `paper.tex:824–827` (Results 5.2): "An earlier version of the design ... had an MDE of 51% ...
  successive refinements halved it." Cut with the rest of 5.2 (see D below).
- `paper.tex:1340–1348` (Discussion): "We previously read this pattern ... We no longer think the
  data bear that reading." Cut the paragraph; keep only the last sentence's policy reading, merged
  into the preceding paragraph. This also closes register item D2 (furlough) by deletion.
- `paper.tex:1370–1379` (Limitations): "an earlier version of this analysis read the result as a
  significant pre-trend violation ... a reader comparing these figures against an earlier draft is
  entitled to know why they differ." Rewrite as one sentence: the 2017 coding convention, left
  uncorrected, would manufacture a spurious pre-trend; the harmonized sample removes it.

### A3. Say each thing once

Repeated across 3+ locations; pick one canonical home and cross-reference elsewhere:

| Claim | Currently in | Canonical home |
|---|---|---|
| 2020 excluded / no 2020 extract | Intro, Data 3.1, Data 3.2, Data 3.3, Limitations | Data 3.1 (two sentences) |
| 2017 zero-hours convention and the reference-week restriction | Data 3.1, Desc 4.3, Limitations | Data 3.1 |
| "Precise null vs uninformative null" | Abstract, Intro, 5.1, 5.2, 5.3, Discussion, Conclusion skeleton | Results 5.6 (new) once |
| `Mother × Post` in the DDD is the effect at zero exposure | Abstract, Intro, 5.3, Table 4 note, Discussion, Conclusion skeleton | Results 5.2 + Table 4 note |
| Cell-based and occupation-level indices are not comparable | Data 3.3, Fig 2 notes, Strategy | Data 3.3 |
| Rotating panel, ~4 obs/person, SE understated by 1.8–2× | Desc intro, Limitations "Inference" | Empirical Strategy (new "Inference" sub-para); Desc intro reduced to one clause |
| MDE formula and 2.8016 constant | Strategy, 5.3 | Strategy |
| WFH went from ~5% to 25–30% of workdays | Intro, Data 3.2 | Intro, **with a citation** (see B2) |

### A4. Retire the "MDE ÷ point estimate" statistic

`paper.tex:185, 792–794, 853, 1040, 1325, 1473, 1483` and the Abstract. MDE divided by a noisy,
near-zero point estimate is not a power measure (a true zero yields an infinite ratio). It is also
what makes the abstract say "eight to ten times" while 5.2 also says "two to three times" against
the Harrington benchmark. Replace throughout with the two statements that are meaningful: MDE per
SD of exposure as a share of the baseline (1.85%) and MDE relative to the closest published effect
(2–3× Harrington). For the hours DDD replace "88.8% of the point estimate" with the t-statistic
(3.15) and the MDE in hours per SD of exposure. Drop the "MDE / |point estimate|" row from
Table 3.

### A5. Scale the headline coefficient

The occupation-level calibrated index has a maximum of about 0.75 and most of its mass below 0.30
(`paper.tex:571–574`), yet every statement of the result is "per unit of exposure, where exposure
runs from zero to one." The paper reports the SD and IQR of the *cell-based* index (0.0706,
0.0766) but never of the occupation-level regressor the headline uses. Add to Table 4 and to the
first statement of the result: SD and IQR of calibrated exposure on the estimation sample; the
implied effect per SD; and the implied top-quartile-minus-bottom-quartile difference
(3.22 × [mean exposure Q4 − mean exposure Q1]), placed next to the raw top-quartile DiD of 1.55
hours from Figure 2. That last comparison is also the paper's only check of the linear-in-exposure
functional form and should be described as such. Source: quartile means are computable from the
existing `hours_dose_response.R` output; SD/IQR from the DDD sample in `hours_ddd_regression.R`.

---

## B. Abstract and Introduction

### Abstract (`paper.tex:101–123`)

- Cut to ≤150 words. Employment gets one clause ("employment shows no change on average and the
  employment DDD is too imprecise to be informative").
- Replace "3.22 hours per unit of exposure" with the per-SD or top-versus-bottom-quartile figure
  from A5. A seminar reader cannot interpret "per unit."
- Keep the closing sentence ("about *which* mothers benefit rather than mothers as a group"). It is
  the paper's thesis.
- Delete "(occupation-level for the hours model, demographic-cell-based for the employment model)"
  from the abstract; it belongs in Data.

### Introduction (`paper.tex:126–205`)

- **B1. Paragraph 1.** Keep. Tighten the last sentence: "we also estimate the employment margin
  but, for reasons of statistical power documented in Section 5.6, treat it as secondary."
- **B2. Uncited data claim, paragraph 4 (`166–168`) and again Data 3.2 (`337–338`).** "Working from
  home accounted for roughly 5% of workdays; after the pandemic 25–30%." These are US figures
  (Barrero, Bloom and Davis). Cite `barrero2021`, label them as US, and, since the pipeline
  computes Israeli realized WFH shares by occupation for 2021–23, report the Israeli aggregate
  share alongside. An examiner in an Israeli labor seminar will ask.
- **B3. Paragraph 3 (`154–164`), Israeli policy stakes.** Written for the extensive margin ("induces
  mothers ... to reduce employment or hours"; "a large and growing share of the working-age
  population is ... a parent"). Reframe in one shorter paragraph around hours: high fertility means
  the hours penalty is borne by an unusually large share of the female workforce, so an
  intensive-margin response has first-order aggregate labor-input consequences. Keep the "schools
  stayed in person" sentence; it motivates the calibration.
- **B4. Paragraph 5 (`175–181`).** Delete the inline DiD equation; it is equation (1) in Section 4.
  One sentence pointing forward suffices.
- **B5. Findings paragraph (`183–195`).** Near-verbatim duplicate of the abstract. Reduce to four
  sentences: no average hours effect; the effect is confined to teleworkable occupations; survives
  selection bounds and age reweighting; fathers show no gradient. Drop the "8–10 times" phrase
  (A4) and the forward reference to the adverse DiD placebo, which is a detail.
- **B6. Missing: economic magnitude.** Nowhere in the Introduction is 3.2 hours put against the
  1.7-hour intensive-margin penalty (`931`) or the 39-hour mean week. Add one sentence once A5
  yields the scaled figure.

---

## C. Literature Review (`paper.tex:208–290`)

- **C1. Goldin paragraph (`224–237`) is the theoretical core and is under-specified for hours.**
  The current text says flexibility could raise "employment probability, hours, or both." Goldin's
  actual mechanism is *non-linear returns to hours*: jobs that pay disproportionately for long,
  contiguous, on-site hours penalize workers who cannot supply them. Remote work lowers the cost
  of supplying a given number of hours (no commute, hours can be split around care). That yields a
  direct intensive-margin prediction: mothers in teleworkable jobs supply more hours, with no
  necessary change in participation. Rewrite the paragraph to state this prediction explicitly. It
  is what H1 rests on, and it is what makes the null DiD plus positive DDD a *confirmation* rather
  than a puzzle.
- **C2. "Does remote work narrow the gap in practice?" (`239–253`).** Adams-Prassl et al. and Alon
  et al. are 2020 shock-incidence papers on employment and earnings. Keep Adams-Prassl only for the
  childcare-burden finding (a time-constraint story, intensive-margin relevant); cut Alon to a
  clause or remove. Angelici and Profeta is about household task division and well-being; keep as
  the one experimental datum but shorten.
- **C3. Missing intensive-margin literature.** The review has no paper on hours or on the value
  of flexibility per se. Candidates the author should consider (verify each and add to
  `references.bib`; not currently in the bib):
  - Mas and Pallais (2017, *AER*), "Valuing Alternative Work Arrangements": workers' willingness to
    pay for WFH and flexible scheduling, with women valuing it more.
  - Cortés and Pan (2019, *JOLE*), "When Time Binds": mothers' hours in long-hours occupations and
    the Goldin mechanism, directly on the intensive margin.
  - Aksoy, Barrero, Bloom, Davis, Dolls and Zarate (2023, *AEA P&P*), "Time Savings When Working
    from Home": commute time saved per WFH day, which gives the Discussion a concrete channel
    (see F3).
  - Bloom, Liang, Roberts and Ying (2015, *QJE*), the Ctrip experiment, if the author wants an
    experimental anchor for WFH effects on work supplied.
- **C4. Harrington paragraph (`269–283`).** The strongest link to Harrington is not made: their
  1.3% income gain among *employed* mothers is an intensive-margin result, and hours is one channel
  to it. State that our hours result is the closest analogue to their income finding. Cut the
  "threefold contribution" list, which duplicates Introduction paragraph 1; keep one sentence on
  the selection correction and one on the calibrated exposure.
- **C5. "Measuring who can work from home" (`255–267`).** Fine; trim the Buzaglo sentence to a
  clause. Yaish et al. belongs in C2's household-time-allocation strand rather than here.
- **C6. "Identification" (`285–290`).** Move the Olden and Møen sentence into the Empirical
  Strategy DDD subsection, where it is used. The Literature Review then ends on Harrington.

---

## D. Data and Institutional Context (`paper.tex:293–389`)

- **D1. Merge 3.2 into 3.1.** "Why 2017–2019 versus 2021–2023" is four sentences that repeat the
  Introduction. Fold the two non-duplicative sentences (no 2020 extract; 2020 was improvised
  arrangements) into 3.1 and delete the subsection.
- **D2. Hours construction needs one more paragraph, not less.** `304–307` compresses a
  measurement decision that bears directly on the headline: usual hours are bin medians with
  ~5-hour bins mid-distribution, and irregular-hours codes are imputed. State the bin structure,
  say the estimand is a bin-median approximation, and note that the 3.2-hour effect is smaller
  than one bin width, so the coefficient is best read as a shift in the share of mothers crossing
  bin boundaries (e.g., part-time to full-time) rather than a fine-grained hours change. **Optional
  new analysis** (author's call): a full-time indicator (hours ≥ 35) as an alternative outcome in
  the DDD, which would make the intensive-margin mechanism concrete. Same regressors, same
  clustering; only the outcome changes.
- **D3. Say what the intensive margin here is and is not.** The pivot brief mentions wages. The
  paper measures hours only. State in 3.1: "hours, not earnings, because [the extract's wage
  field is unusable / the LFS carries no earnings for this sample]." The cleaning step drops a
  field named like a computed wage (`SacharMechushavmechushav`); the author should check the
  codebook and either use it as a secondary outcome or state why not. Either way the Conclusion's
  "next steps" should name earnings.
- **D4. The 2017 paragraph (`309–320`).** Keep as the canonical account (A3) but cut from ~12 lines
  to ~7. The sentence "that second restriction is not cosmetic, and it is worth stating plainly
  because it changes the estimand" can go; the paragraph shows it.
- **D5. Exposure construction (`344–389`).** The three-measure structure is right. Fix these:
  - `358–360`: "a one-sided cluster-robust test at the 95% level" clustered on what? State it.
  - `364–367`: the sentence beginning "Because it draws on 2022–23 realized data" is the paper's
    most exposed flank (see E4 and F2). Move the defense there and keep only the disclosure here.
  - `381–389`: the cell-based index paragraph is an employment-margin artifact but cannot be cut,
    because the DDD Lee bounds trim on its quartiles. Reduce to three sentences and say so: "A
    fourth, demographic-cell index (Appendix/Section 5.6) serves two roles: the employment DDD and
    the selection correction's quartile stratification."
- **D6. Pooled means sentence (`324–326`).** Redundant with Table 1. Delete.

---

## E. Descriptive Statistics (`paper.tex:391–635`)

- **E1. Intro and clustering convention (`394–407`).** Keep two sentences: unadjusted, and all
  intervals clustered by individual for the reason given in Section 4. Move the panel-structure
  explanation to Empirical Strategy (A3).
- **E2. 4.1 Summary table.** Keep the table; cut the prose to the two facts that matter for the
  design: the raw hours gap of −1.38 and the age imbalance that tracks exposure. The marital
  status and district commentary can go to the table note or be dropped.
- **E3. 4.2 Raw hours gap.** Keep as is; it is short and does real work.
- **E4. 4.3 Hours year by year.** Keep the figure. Cut the second paragraph (`525–530`, A2). The
  third paragraph's point (post path is non-monotone; the event study, not the raw series, carries
  the timing claim) can be one sentence.
- **E5. 4.4 Exposure and commuting.** Figure 2 is the paper's best exhibit; keep it and its first
  two paragraphs. The commuting passage (`598–609`) uses a different population, is self-described
  as "descriptive evidence ... rather than a test," and does not enter any specification. Cut to
  two sentences or a footnote. If kept, fix the internal tension: mothers commute *more* than
  childless women, which the text acknowledges "is not what a simple story ... would predict" and
  then does not resolve.
- **E6. 4.5 Extensive margin by child age (`611–635`). Cut entirely.** The section twice says of its
  own numbers "not an estimate of anything." It is a pure extensive-margin artifact, contains no
  comparison group, and its only design-relevant sentence ("the extensive margin is where this
  sample has the least room to move") can be one clause in Section 5.6. Saves about a page.

---

## F. Empirical Strategy (`paper.tex:638–729`)

- **F1. Hypotheses.** Replace the H1/H2 pair with a single stated hypothesis for hours, derived
  from the rewritten Goldin paragraph (C1), plus one sentence: "We also test the employment margin
  for completeness (Section 5.6)." The clause "if flexibility relaxes a binding time constraint
  while the participation margin remains the more costly one to adjust" imports the withdrawn
  margin-ordering story; delete it.
- **F2. Write equation (2) in full.** "`(all lower-order terms)`" is not acceptable in the section
  that carries the paper's mathematical precision. Write the seven-term specification and add two
  sentences on what each two-way term absorbs: `Post × WFH` absorbs any post-2021 change in hours
  in teleworkable occupations common to all women (the general WFH recovery), and `Mother × WFH`
  absorbs the pre-existing level of the motherhood penalty across occupations. That is what makes
  the triple interaction a *differential* change and answers the "isn't this just the WFH
  recovery?" objection before it is raised. Move the Olden and Møen identifying-assumption
  sentence here (C6).
- **F3. Inference sub-paragraph (new).** Consolidate here: (i) the rotating-panel structure and why
  individual clustering matters for the DiD; (ii) occupation clustering for the DDD, 40 clusters;
  (iii) **state the degrees-of-freedom convention.** `fixest` by default uses a t(G−1) reference
  distribution with clustered SEs, so the reported p-values already carry a 39-df small-cluster
  adjustment; the paper currently says "no small-cluster correction is applied," which
  understates what was done. Verify the `ssc` setting used in `hours_ddd_regression.R` and state
  it. (iv) **Optional rigor step, author's call:** a wild cluster bootstrap p-value for the headline
  coefficient (Cameron, Gelbach and Miller 2008). This needs a package outside tidyverse+fixest
  (`fwildclusterboot`), which the project's CLAUDE.md requires flagging before adding. An
  alternative with no new dependency is two-way clustering by individual and occupation
  (`cluster = ~IDPUF + MishlachYad_ISCO_08_2`), reported as a sensitivity row in Table 8.
- **F4. Employment DDD description (`680–686`).** Reduce Spec 1 / Spec 2 to one sentence; keep only
  Spec 1 in the paper (the two differ by 0.006 with identical SEs). Move the ~210-cluster detail to
  the table note.
- **F5. Lee bounds (`690–714`).** Dense but correct. Two clarifications needed:
  - The DDD generalization trims within quartiles of the *cell-based* index while the outcome
    equation uses the *occupation-level* index. State the assumption that makes this a valid bound:
    selection into observed hours is assumed to depend on exposure only through the cell-index
    quartile, so trimming each quartile's excess mass bounds the occupation-level coefficient.
    Currently the reader is told "two different exposure measures thus serve two different roles"
    without being told why that is legitimate.
  - The monotonicity assumption is stated only in Limitations. State it here where the bound is
    defined, one clause.
- **F6. Diagnostics and placebo (`716–729`).** Fine. Trim "valid without a covariance correction
  because the samples are disjoint" to appear once (it is also in Table 9's note and in the
  subgroup text).

---

## G. Results (`paper.tex:732–1293`)

Reordered per A1. Item numbers refer to current text.

### G1. Employment (current 5.1–5.2, `738–870`) → new 5.6, one paragraph and one table

- Merge Tables 2 and 3 into a single "Extensive margin" table with two columns: employment DiD
  (pooled) and employment DDD (Spec 1). Drop the Jewish/Arab employment columns (no
  intensive-margin role; the subgroup story is told on hours in 5.5), drop Spec 2, drop the
  "MDE / |point estimate|" row (A4), keep the per-SD MDE row.
- Text: the DiD is a precise null (SE half a percentage point); the DDD's MDE per SD of exposure is
  1.85% of baseline employment and 2–3× the Harrington benchmark, so it is uninformative; the
  reason is structural (a binary outcome and a cell-level regressor with SD 0.07). Then one
  sentence: the `Post × WFH` main effect is negative and significant, a post-2021 employment
  decline in high-exposure cells unrelated to motherhood. Stop there.
- Delete: the two "we tried to close it" paragraphs (`807–829`), including the first-stage
  regression, VIF, R² of exposure on the fixed effects, and the refinement history. If the author
  wants the first-stage result kept as evidence the index works, it is one sentence in Data 3.3.
- Delete footnote on the `Dat` control being unidentified in the Jewish subsample (`747–753`) once
  the stratified employment columns go; keep the clause about the dropped "other" category in the
  Table 4 note if it applies to the hours DDD.

### G2. Hours pre-trends and DiD (current 5.3 first half, `874–1020`)

- **Table 6 duplicates Figure 3.** Keep the figure; move the five coefficients, SEs and the joint
  Wald test into the figure note; delete the table. Same for Table 7 / Figure 4 (G4). Saves two
  floats.
- Pre-trends paragraph: keep. Cut the employment pre-trend test to a clause ("the same test on
  employment also passes; Section 5.6").
- DiD null paragraph (`930–955`): keep the raw-versus-regression comparison and the "unclustered SE
  is half the clustered one" point. Cut the second paragraph's re-statement of "what kind of null
  this is" to one sentence with the 0.51-hour MDE.
- **Table 5 (Lee bounds on the DiD): delete.** The DiD is a null and the bounds widen a null. One
  sentence with the Imbens–Manski interval [−0.810, 1.096] and the 1.9% trim suffices; keep the
  selection rates in the Table 8 (DDD bounds) note where they are already printed.

### G3. Hours DDD headline (current `1022–1042`)

- First paragraph: after "3.2 additional hours per unit of exposure," add the scaled statements
  from A5.
- Second paragraph (effect at zero exposure): keep; it is the paper's sharpest sentence. Tie it
  explicitly to F2: because `Post × WFH` is in the model, the gradient is net of the general WFH
  hours recovery.
- Third paragraph (power): rewrite per A4. "The estimate is 3.15 standard errors from zero; the MDE
  is 2.86 hours per unit, or X hours per SD of exposure."
- Add to the Table 4 note: the `ssc`/df convention (F3), the SD and IQR of the regressor (A5).

### G4. DDD pre-trends (`1044–1119`)

- Keep the argument that the DiD pre-trend test is not the conservative one (`1045–1051`); it is a
  genuinely good point and unusual in a seminar paper. Cut the specification re-description
  (`1052–1055`), which repeats Section 4.
- Keep the 40-cluster caveat paragraph (`1066–1072`); it is the honest reading. Then do not repeat
  it in Limitations at the same length (H1).
- Table 7 → figure note (G2).

### G5. Lee bounds for the DDD (`1121–1168`)

- Text is right; trim the table note (`1157–1166`) by half. The sentence explaining why the
  untrimmed point estimate is 3.2319 rather than 3.224 is necessary; the row-count detail
  ("548 of 12,249; 197 of 19,511 ...") can go.

### G6. Robustness (`1170–1214`)

- Keep the exposure-measure and age-balance rows. Add the two-way-clustering row if F3(iv) is
  taken.
- **The external-index result (0.672, ns) is the examiner's best objection and gets one sentence.**
  The only fully pre-treatment exposure measure yields an insignificant estimate; the two that use
  post-period Israeli data yield significant ones. The Discussion frames this as "the mechanism
  shows up only once exposure is measured as Israeli jobs were actually done," which is one
  reading. The other is that calibrating on post-period realized WFH lets the regressor absorb
  post-period outcomes. The defenses available in the current design are real but never assembled
  in one place: the calibration population includes men; only 10 of 40 occupations are swapped;
  swaps require a gap > 0.5 and a significant test; and the swap direction is mostly *downward*
  (teaching, clerical), which if anything removes occupations from the treated tail. Assemble them
  here, in one paragraph. **Recommended new check, no new dependency:** re-estimate the DDD on the
  30 unswapped occupations, where calibrated and external indices coincide by construction. If the
  triple interaction holds there, the result is not driven by the post-period calibration. This is
  a sample filter on the existing `run_hours_ddd_regression()` call; it needs a pipeline run and a
  new output CSV.
- Cut the incidental age-profile finding (`1186–1189`); it is not part of the argument.
- Reweighted attenuation sentence: keep, it is candid. "Close enough to the design's minimum
  detectable effect" should be restated without the MDE-ratio framing (A4).

### G7. Subgroups and placebo (`1216–1293`)

- Arab/Jewish paragraph (`1227–1242`): halve. The z-test and the occupational-coverage explanation
  each get two sentences. Cut "The Jewish-women estimate is the more credible of the two and anchors
  any subgroup claim we make" (Discussion says it).
- Placebo: the DDD placebo paragraph (`1249–1254`) is the important one; keep. The adverse DiD
  placebo paragraph (`1256–1264`) is candid but long for what it establishes (the female DiD is
  already a null). Reduce to three sentences.
- Table 9: keep; it is compact. Move "\sym{.} denotes 10%" into the global significance line at
  the top of Results, which already defines `\sym{\cdot}`; the two symbols are currently
  inconsistent (`\cdot` in the header, `.` in the table).

---

## H. Discussion (`paper.tex:1296–1353`)

- **H1. Paragraph 1**: keep verbatim. It is the paper.
- **H2. Paragraph 2 (which occupations)**: keep, but this is where the post-period-calibration
  defense (G6) should be cross-referenced, not asserted as "itself informative."
- **H3. Missing: the economic mechanism in quantities.** Add one paragraph. Aksoy et al. (2023, if
  added per C3) put commute time saved at roughly 70 minutes per WFH day; two WFH days a week is
  ~2.3 hours. The top-versus-bottom-quartile implied effect from A5 will be of the same order. That
  back-of-envelope makes the time-constraint mechanism concrete and is the "stronger economic
  justification" the audit brief asks for. Also state the effect relative to the −1.7 hour
  intensive-margin penalty: for mothers in top-quartile occupations it closes a large fraction of
  it; for the rest, none.
- **H4. Paragraph 3 (timing)**: keep, two sentences. Note that the 2023 coefficient is the largest
  on both the DiD and DDD event studies, and see I5 before leaning on it.
- **H5. Paragraph 4 ("Why hours and not employment?")**: cut by two-thirds. Keep: the employment
  DDD is uninformative, not negative; the hours design is better powered because occupation-level
  exposure is available; Kleven identifies hours as a penalty channel; this is where we depart from
  Harrington. Cut the "purely statistical account" sentence, which restates the same point.
- **H6. Paragraph 5 (furlough / "we previously read")**: delete (A2, closes D2). Fold the final
  policy sentence into paragraph 4.
- **H7. Paragraph 6 (subgroups)**: keep, it is already two sentences.

---

## I. Limitations (`paper.tex:1356–1442`)

- **I1. Parallel trends paragraphs (`1359–1386`)**: three paragraphs → one. Drop the repeated
  F-statistics (they are in the figure notes); drop the draft-history sentences (A2); keep the
  estimand-narrowing point and the absentee-share-related-to-exposure caveat. The claim "we find
  the absentee share only mildly related to exposure across quartiles" has no number attached;
  supply the four quartile absentee shares in a footnote or delete the claim.
- **I2. Lee bounds paragraph**: keep, it is short.
- **I3. Survey weights**: keep, it is short.
- **I4. Exposure anchor**: merge with the post-period-calibration point (G6) into one paragraph
  titled "Exposure is partly post-treatment." That is the honest heading.
- **I5. Missing limitation: October 2023.** The 2023 survey year is the largest coefficient in both
  event studies (0.75** on the DiD, 4.02** on the DDD) and the year the Discussion's
  "gradual adjustment" reading rests on. The 2023 LFS covers the quarter in which the war began,
  with mass reserve call-ups (which move *men's* hours, i.e., the placebo), school closures and
  evacuations (which move *mothers'* hours). The paper never mentions it. The cleaning step drops
  the survey-month field (`ChodeshSeker`), so the check is feasible: retain it and re-estimate the
  hours DiD and DDD excluding October–December 2023, or, at minimum, excluding 2023 entirely
  (`ShnatSeker != 2023`, no schema change). Report as a robustness row; write one Limitations
  paragraph either way. Also note that early 2021 included a third lockdown with partial school
  closure, so "post-acute" is softer for 2021 than the text implies.
- **I6. Missing limitation: control-group contamination.** "Childless" is any woman with no child
  under 17 in the household, so it includes women whose children are 17+ and future mothers.
  Harrington's design has the same feature; say so and note that it biases the DiD toward zero if
  anything.
- **I7. Missing limitation: exposure is measured at 2-digit ISCO.** 40 groups is coarse; Buzaglo's
  within-firm sorting point (cited in the Literature Review and then never used) belongs here as
  classical measurement error in the regressor, which attenuates the DDD toward zero.
- **I8. Inference paragraph (`1424–1442`)**: after F3 moves the panel-structure explanation to
  Section 4, what remains here is: 40 clusters, the df convention, the rejected individual-FE
  design (1.9% span the boundary), and the masked-ISCO sentence. Four sentences.

---

## J. Conclusion (`paper.tex:1445–1520`)

The block must be written by the author (course rule; register item D1). Editorial guidance only:

- Target 400–500 words, five paragraphs: (1) question and the move to Israel and to hours;
  (2) the result as a conjunction: no average effect, an effect confined to teleworkable work,
  robust to selection bounds and age reweighting, absent for fathers; (3) what it means: Goldin's
  time constraint, "which mothers" not "mothers"; (4) what the design cannot say: employment
  (uninformative), earnings (not observed), 2023; (5) next steps: earnings, a better-powered
  employment test, a jointly estimated sex-interacted model.
- Use at most three numbers. The skeleton's nine-item numbered list is a checklist, not a
  structure; do not carry its granularity into prose.
- On completion: delete both red markers and the skeleton comment; remove `\usepackage{xcolor}`
  (carried only for the markers); replace `\today` on the title page with the submission date
  (D11).

---

## K. Condensation budget

Current ~12,900 words body / 37 pages. Target ~8,000–8,500 words / 22–25 pages.

| Section | Now (approx.) | Target | Main lever |
|---|---|---|---|
| Abstract | 230 | 150 | employment to one clause |
| Introduction | 1,050 | 650 | cut equation, cut findings duplicate, shorten Israel para |
| Literature | 1,000 | 850 | cut Alon/threefold list; add C1 and C3 content |
| Data | 1,100 | 800 | merge 3.2; shrink cell-index para; add D2 bins |
| Descriptives | 1,900 + Table 1 | 1,000 | cut 4.5, cut commuting, cut draft history |
| Strategy | 900 | 900 | net zero: cut Spec 2/H2, add full eq. (2) and inference para |
| Results | 4,300 + 5 tables | 2,600 + 3 tables | employment to one para/table; drop Tables 5, 6, 7 |
| Discussion | 900 | 700 | cut furlough para, add magnitude para |
| Limitations | 1,100 | 700 | merge PT paras; add I5–I7 |
| Conclusion | skeleton | 450 | author writes |

Floats after revision: Table 1 (summary), Table 2 (hours DiD + DDD), Table 3 (DDD Lee bounds),
Table 4 (robustness), Table 5 (subgroups/placebo), Table 6 (extensive margin, compact);
Figures 1–4 unchanged, with event-study coefficients in the notes of Figures 3 and 4.

---

## L. Open register items this plan touches

| Item | Effect of this plan |
|---|---|
| D1 Conclusion | Structure given in J; author writes |
| D2 Furlough sentence | Closed by deleting Discussion para 5 (H6) |
| D3 Bibliography rule | Unchanged; author must confirm `apalike` is acceptable or hand-format |
| D4 Kleven a/b order | Unchanged; resolve with a `key` field or accept |
| D5 Crosswalk provenance | Unchanged; becomes more visible once G6 assembles the exposure defense |
| D11 `\today` | Fix at J |

---

## M. Execution order and verification

1. **Text-only edits first** (A2, A3, B, C, D1, D4, D6, E, F1, F2, F4, F5, F6, G1, G2 table
   deletions, G7, H, I1–I4, I6–I8, J structure). No pipeline run needed. Recompile after:
   `pdflatex; bibtex; pdflatex; pdflatex` from `paper/`; check the log for undefined references
   (deleted tables leave dangling `\ref`s: `tab:emp-did`, `tab:emp-ddd`, `tab:lee-did`,
   `tab:pretrend`, `tab:pretrend-ddd` are referenced in 14 places) and for BibTeX warnings if C3
   adds entries.
2. **Numbers that need the pipeline** (A5 scaling, F3 df convention check, and the optional checks
   G6 unswapped-occupations, I5 exclude-2023, D2 full-time indicator, F3 two-way clustering).
   Each is a filter or a `cluster=` argument on an existing function; none needs a new dependency
   except the wild bootstrap, which is flagged as optional. Raw CBS data are outside the repo;
   confirm `folder_path` in `main.R` resolves before running. After any pipeline change run
   `Rscript run_tests.R` (must be green) and re-verify every hours number in the paper against
   `outputs/` per the header comment in `paper.tex`.
3. **Final checks**: page count ≤ 25; grep `paper.tex` for `SKELETON`, `xcolor`, `\today`,
   `previously`, `earlier version`, `per unit of exposure` (should survive only where a per-SD
   figure sits beside it), and `8--10` / `eight to ten` (should be gone).
