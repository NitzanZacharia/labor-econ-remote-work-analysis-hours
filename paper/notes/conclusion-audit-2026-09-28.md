# Conclusion audit: `paper/paper.tex` §9 (pre-submission)

**Date:** 2026-09-28. Re-anchored 2026-10-03 at `6454bd0`. **Scope:** the Conclusion (`paper.tex:1089-1103`, two paragraphs, 186
words), read against the Abstract (162-179), the Introduction (182-244), the Results lead
(589-596), the Discussion (937-1014) and the Limitations (1016-1083). Analysis written at
`4802830`; the drafts in §3 and their line references were brought up to `ca0eb93`, after the
referee-review response of 2026-09-28, later the same day.
**Rule applied (author's choice):** analysis and proposals only. `paper.tex` was NOT edited and
the paper was not recompiled. The current text was written by the co-author and moved in verbatim
on 2026-09-26; whether and how to replace it is the authors' joint call.

**Status at `57d9452` (2026-09-29).** The Conclusion is still the co-author's text, verbatim, now
at `paper.tex:1137-1151`; nothing below has been applied. Since `ca0eb93` the referee-review
response (items 5–22 on 2026-09-29, items 1–4, 6, 10 and 11 the day before) edited the Abstract,
Introduction, Results, Discussion and Limitations, so every line number below has shifted
(current anchors: Abstract 178–198, Introduction 201–270, Results 637, Discussion 988,
Limitations 1063, Conclusion 1134). None of those edits changes a verdict in the claim ledger
(§2.3) or a number in the drafts (§3): the DiD null and its confidence interval, 3.22 / 1.71, the
three-fifths / none pairing, the fathers' gradient, the bootstrap qualification, the teaching
reclassification and the marital checks all still read as quoted. One premise did change: the
Abstract no longer ends on "which mothers benefit ... rather than mothers as a group"; since the
2026-09-28 co-author pass it ends on the intensive-margin implication ("raises intensive-margin
labor supply for mothers in teleworkable occupations specifically, rather than reducing the
motherhood penalty across the board"). §2.2 item 5 and the matching §2.4 row therefore no longer
describe a line the Abstract carries, and the closing sentence of Versions A, B and C now
paraphrases the Discussion's policy reading rather than repeating the Abstract, which also
retires the duplication concern in §6. The recommendation (Version A, C as fallback) stands.

**Status at `6454bd0` (2026-10-03; paper text at `00dadf2`).** The Conclusion is still the
co-author's text, verbatim, now at `paper.tex:1077-1091`. Twenty-seven commits have landed since
`57d9452`: a restructure-and-polish pass over every other section (Introduction, Literature
Review, Data, Descriptive Statistics, Empirical Strategy, Results, Discussion, Limitations, the
appendices; `fd24db3` to `8f859dc`), then the four-phase pre-submission audit (`0148968`,
`211135e`, `a8367f4`, `e546ff4`, `a7c8a09`, `60f682b`, `b969f31`, `00dadf2`), whose Phase 1 found
no numeric error in the paper and whose Phase 4 copyedit excluded the Conclusion. Every line
number in §2 and §3 was re-anchored to `00dadf2` on 2026-10-03 and each cell now also names the
section label, so the next shift can be resolved by label. Re-verification of every quotation
the ledger and the drafts rely on: all present, with three changes. (i) The DiD standard error no
longer appears in prose (the Abstract dropped its SEs on 2026-09-28); Version A's "(SE $0.18$)"
traces to Table 2, column (1), a generated table. (ii) The external index's estimate ($0.672$, SE
$0.884$) moved from prose to Table 3; the prose says "positive and insignificant" and "about a
fifth the size of the headline", which is what the drafts say. (iii) The Abstract's former "which
mothers ... rather than mothers as a group" line is gone from the paper altogether; it now closes
on "mothers in teleworkable occupations specifically, rather than reducing the motherhood penalty
across the board" (197-199). Version C's closing sentence, which quoted the old line, is reworded
to the current one; Versions A and B already paraphrased the Discussion's policy reading. One
wording in Version A was tightened to match the paper: the supporting rows' bootstrap $p$-values
"mostly" lie above 5% (Discussion 946-948), not uniformly. Separately, `harrington2025` now
resolves to the 2026 *National Tax Journal* article (bib key unchanged), so Version A's citation
prints "Harrington and Kahn, 2026". None of this changes a verdict in §2.3 or a number in §3. The
recommendation (Version A, C as fallback) stands.

**Applied 2026-10-03 (committed on `main`).** Version A is now the paper's Conclusion,
at `paper.tex:1084-1116`: the §3.A block pasted as is, with `\noindent` added at the start of its
second and third paragraphs to match the paper's paragraph style (every section indents its first
paragraph and prefixes the rest) and no other change. A dated `CONCLUSION 2026-10-03` line was
added to the header comment block of `paper.tex`; the paper was recompiled (pdflatex, bibtex,
pdflatex, pdflatex): 37 pages, up from 36, no undefined reference or citation, BibTeX clean, the
reference list unchanged (both `\citep` keys were already cited). README's description of the
Conclusion was updated. §5's four steps are therefore done. The co-author's text survives in §1
below and in git history before this change.

**Bottom line.** Nothing in the Conclusion is wrong: all ten factual claims trace to a supported
line in the paper (§2.3). The problems are of alignment and emphasis. The section was written
before the Introduction, Abstract and Results were rebuilt on 2026-09-27 around "three findings"
and a "which mothers" reading, and it was never brought into line: it opens by restating the
question instead of answering it, reports two of the three findings (the fathers' gradient is
missing), gives no magnitude at all, never closes the loop with the Introduction's flexibility
framing or the US comparison, and spends most of its second paragraph re-listing Limitations
that sit immediately above it, the exact repetition the 2026-09-23 grade report deducted for.
Three ready-to-paste alternatives follow (§3). **Recommended: Version A** (findings-forward),
with Version C as the fallback if the co-author's draft is to be preserved in structure and
voice. Every number in the drafts already appears in the paper and is traced by line (§3);
no number is added.

---

## 1. Current text (verbatim; `paper.tex:1089-1103` at `4802830`, `1077-1091` at `00dadf2`)

```latex
Using Israeli survey data, we ask whether the expansion of remote work coincided with a change in
the motherhood penalty in usual weekly hours. The average change among women observed working is
small, whereas the post-2021 change in the mother/comparison gap increases with an occupation's
calibrated WFH exposure. The strongest contrast is at the top of the exposure distribution and
among mothers with younger children. Those patterns are consistent with greater scheduling
flexibility helping some already employed mothers supply more paid hours.

The result is conditional and does not establish a universal benefit from remote work. The
exposure score partly uses post-period WFH information; the wholly external score yields a weaker
result, pre-trend tests have limited power, and inference varies with the procedure. Employment is
an important separate margin, but its exposure interaction is too imprecise here to settle the
question. The data also contain no earnings amount. Stronger evidence would link hours with
earnings and household time use, measure exposure before treatment in the Israeli setting, and
estimate women's and men's responses together on a design that better separates access to WFH
from occupation choice.
```

186 words. No numbers, no citations, no cross-references.

## 2. Analysis

### 2.1 Strengths (kept in every alternative)

- **Restraint.** It never overclaims. "Consistent with" and "conditional" match the Discussion's
  own reading of the gradient as "the time-constraint mechanism's signature rather than its
  proof" (942).
- **Brevity.** At 186 words it is the shortest section in a paper the grade report called too
  long, and being number-free it did not go stale through the 2026-09-21 re-verification of
  every hours figure.
- **The research agenda.** The closing sentence (1024-1027) is specific and correct: link hours
  with earnings and time use; measure Israeli exposure pre-treatment; estimate women and men
  jointly on a design that separates WFH access from occupation choice. It is the best sentence
  in the section and survives, lightly edited, in all three drafts.
- **Two of the three findings are there**, in the right order: the average null (1014-1015) and
  the exposure gradient with its top-quartile concentration and child-age pattern (1015-1017).

### 2.2 Weaknesses and the improvement each implies

Axis codes: **T** = academic tone, **I** = impact, **F** = summary flow.

| # | Axis | Observation | Evidence (`paper.tex` line) | Fix |
|---|---|---|---|---|
| 1 | F | Opens by restating the question ("we ask whether...") rather than answering it. A conclusion's first sentence should be the answer. | Conclusion 1077 vs. the Introduction's own answer at 233-241 | Open with the answer: no on average, yes where the work can be done from home. |
| 2 | F, I | Reports two of the "three findings" the Introduction (233) and the Results lead (608) promise. The fathers' opposite-signed gradient, which the Discussion calls the check that "rules out a shock common to all workers" (971-972), is absent. | Introduction 233-241; Results lead 608-613; `sec:res-childage` 873-874; Discussion 982-983; nothing at 1077-1082 | Add the fathers' gradient to the findings sentence. |
| 3 | I | No magnitude anywhere. "Small" and "increases with" are the only quantifiers; the reader leaves without 3.22 per unit, 1.71 between quartiles, or "three fifths of their penalty". | Introduction 234-237; Discussion 955-964 | State at least the quartile contrast and the three-fifths / none pairing. |
| 4 | I | Does not close the loop with the Introduction: flexibility as the last driver of the gender gap (207-210), the Israeli fertility context (221-223), and the contrast with the US extensive-margin result (216-220) are all absent. | Introduction 207-210 and 216-223 | One sentence placing the result against Harrington & Kahn (intensive vs. extensive margin, different country). |
| 5 | I | The Abstract's last sentence (now: remote work raises intensive-margin labor supply for mothers in teleworkable occupations specifically, rather than reducing the penalty across the board, 197-199; until 2026-09-28 it was "about *which* mothers benefit ... rather than about mothers as a group") is the paper's one-line takeaway and the natural last line of the Conclusion; it does not appear. | Abstract 197-199; Discussion 996-1001 | End on it. |
| 6 | T | Paragraph 2 (1084-1088) is roughly 60% caveats that restate Limitations nearly verbatim: post-period calibration (1009-1010), weaker external score (1011), pre-trend power (1008-1009), inference by procedure (1013-1015). The 2026-09-23 grade report deducted 2 points for exactly this: "the post-period calibration caveat, the forty-cluster caveat, and the 2023 caveat each appear three or more times". | Conclusion 1084-1086 vs. Limitations 1007-1018 | Collapse to one sentence naming the two limitations that condition the reading, with `\ref{sec:limitations}`. |
| 7 | T | "does not establish a universal benefit from remote work" rebuts a claim nobody made. | 1084 | Cut; "conditional" alone carries it. |
| 8 | T, F | "The data also contain no earnings amount" is a data-description sentence, not a conclusion, and sits between the employment margin and the research agenda. | 1088; the fact belongs to the Data section (`sec:data` 352: "the extract records how a wage is paid but not its amount") | Cut; the agenda's "link hours with earnings" already implies it. |
| 9 | T | Terminology drift: "mother/comparison gap" vs. the paper's "mother/childless gap"; "some already employed mothers" vs. "mothers who already hold *teleworkable* jobs". | 1079 vs. Results lead 610; 1082 vs. Discussion 998 | Use the paper's terms. |
| 10 | I | The employment margin is "too imprecise here to settle the question"; the Results make the sharper point that the employment DDD is *uninformative*, "evidence neither for nor against", and that "the two nulls should not be read as one verdict". | 1086-1088 vs. `sec:res-extensive` 931-933 | Keep the sentence, add "either way" or point to `sec:res-extensive`. |
| 11 | I | The Discussion's narrow policy reading (WFH matters for how intensively mothers in teleworkable jobs work, not for whether mothers work; access to those jobs is unequal, so the population-wide gain is smaller than the gradient) is the paper's practical takeaway and never reaches the Conclusion. | Discussion 996-1001 | One sentence on the policy reading. |
| 12 | F | Two paragraphs with no "so what" beat between summary and caveats; the interpretation is one clause ("consistent with greater scheduling flexibility"). | 1081-1082 | Give the interpretation its own sentences (mechanism signature, contribution). |

### 2.3 Claim ledger (current text)

Every factual claim in the Conclusion, and where the paper supports it.

| # | Claim (line) | Supporting line(s) | Verdict |
|---|---|---|---|
| 1 | Average change among women observed working is small (1078-1079) | Abstract 188 (DiD $0.23$, "did not change on average"); Table 2 col (1): $0.2280$ ($0.1809$); `sec:res-did` 625-627 (95% CI $[-0.13, 0.58]$; MDE $0.51$) | OK |
| 2 | Post-2021 change in the gap increases with calibrated WFH exposure (1079-1080) | Introduction 235-236; `sec:res-ddd` 666-669 | OK (wording: "mother/comparison" is not the paper's term) |
| 3 | Strongest contrast at the top of the exposure distribution (1080) | Results lead 611-612 ("concentrated in the most teleworkable quartile"); Discussion 955-964 | OK |
| 4 | Strongest among mothers with younger children (1080-1081) | Introduction 239-240; `sec:res-childage` 859-862 | OK |
| 5 | Exposure score partly uses post-period WFH information (1084-1085) | Limitations 1009-1010 | OK |
| 6 | Wholly external score yields a weaker result (1085-1086) | Limitations 1011 ("positive and insignificant"); `sec:res-ddd-diag` 748-750; the estimate itself, $0.672$ ($0.884$), is Table 3's external-index row | OK |
| 7 | Pre-trend tests have limited power (1086) | Limitations 1008-1009; `sec:res-ddd` 688-690 | OK |
| 8 | Inference varies with the procedure (1086) | `sec:res-ddd` 692-697 (p = 0.003 / 0.032 / 0.056); Limitations 1013-1015 | OK |
| 9 | Employment interaction too imprecise to settle the question (1086-1088) | `sec:res-extensive` 921-933 | OK, understated (see §2.2 #10) |
| 10 | No earnings amount in the data (1088) | `sec:data` 352 ("records how a wage is paid but not its amount") | OK, misplaced (see §2.2 #8) |

No claim is wrong; nothing needs a fix in place.

### 2.4 Alignment check against the sections the Conclusion must agree with

| Section | What it commits the Conclusion to | Present now? |
|---|---|---|
| Abstract (180-200) | Three inference procedures reported side by side; closing line on the intensive-margin takeaway (197-199; the "which mothers" line it replaced on 2026-09-28) | Inference: yes (as a caveat). Closing line: no |
| Introduction, "Three findings emerge" (233-250) | (1) precise null; (2) 3.22 / 1.71, concentrated in the top quartile; (3) child-age gradient **and** fathers' opposite gradient | (1) yes, no number; (2) yes, no number; (3) half |
| Introduction, contribution (216-223) | Intensive margin vs. US extensive margin; Israeli-calibrated exposure; first Israeli estimate in hours | No |
| Results lead (608-613) | Same three findings; employment margin "too imprecisely estimated to support a comparable conclusion" | Employment: yes |
| Discussion (936-1001) | Three-fifths / none magnitudes; mechanism "signature rather than proof"; narrow policy reading | None of the three |
| Limitations (1004-1071) | Already states every caveat in full | The Conclusion should point here, not repeat it |

## 3. Alternative versions

Rules common to all three: (i) every number already appears in `paper.tex` and is traced by
line below; no number is added, the same discipline as the 2026-09-27 Introduction and Results
passes; (ii) Limitations are pointed to, not re-listed; (iii) the co-author's research-agenda
sentence is kept, lightly edited; (iv) only existing macros, `\citep` keys (`goldin2014`,
`harrington2025`) and `\ref` labels (`sec:limitations`, `sec:res-extensive`) are used, so any
version compiles as a drop-in replacement for lines 1089-1103.

Shared number provenance (section label and line at `00dadf2`; first anchored at `ca0eb93`):

| Literal | `paper.tex` location |
|---|---|
| DiD 0.23, "did not change on average"; 95% CI "excludes average gains above about half an hour a week" | Abstract 188; `sec:res-did` 625-627 |
| SE 0.18 on the DiD | Table 2 col (1), $0.2280$ ($0.1809$); no longer in prose since the Abstract dropped its SEs (2026-09-28) |
| 3.22 hours per unit of exposure (SE 1.02) | Abstract 189; `sec:res-ddd` 666 |
| 1.71 hours between the top and bottom quartile means | Abstract 190; `sec:res-ddd` 669, 679; Discussion 959 |
| "recovered roughly three fifths of it" (top quartile) | Discussion 962; Introduction 236 |
| "recovered none of it" (bottom quartile) | Discussion 963-964 |
| "behaves as a flexibility mechanism should"; largest for mothers of children under five; declines with age of youngest child | Introduction 238-240; Abstract 196 |
| Fathers: gradient of the opposite sign | Introduction 241; Abstract 196; `sec:res-childage` 873-874 |
| Forty occupation clusters; three inference procedures | Abstract 190-192; Introduction 243-245; `sec:res-ddd` 692-697; Limitations 1013-1016 |
| Supporting checks share the forty clusters; bootstrap $p$ "mostly" above 5%, headline 0.056 | Discussion 946-948; `sec:res-ddd` 696; Limitations 1016-1018 |
| Result requires reclassifying teaching; Israeli schools in person; US task content scores it teleworkable | Abstract 193-195; Introduction 246-249; `sec:res-ddd-diag` 762-764; Limitations 1010 |
| Pre-treatment external index: positive and insignificant | Limitations 1011; `sec:res-ddd-diag` 748-750 (the estimate, $0.672$ / $0.884$, is Table 3's external-index row) |
| Marital checks: gradient positive but only marginally significant | Limitations 1060-1064 |
| Employment DDD uninformative, "neither for nor against" | `sec:res-extensive` 931-933; Discussion 992-993 |
| US: WFH reduced the penalty on employment and income | Introduction 216-217; Discussion 996 |
| "signature rather than its proof" | Discussion 990 |
| Policy reading: mothers who "already hold *teleworkable* jobs"; access "unequally distributed" | Discussion 996-1001 |
| Abstract's close: intensive-margin labor supply "for mothers in teleworkable occupations specifically, rather than reducing the motherhood penalty across the board" (replaced "which mothers ... rather than mothers as a group" on 2026-09-28) | Abstract 197-199 |

### 3.A Version A: findings-forward (recommended)

**Strategy.** Mirror the "three findings" architecture the Introduction and Results already use,
so the paper ends the way it began. Paragraph 1 answers the question in its first sentence and
states the three findings in the Results' order with the headline magnitudes, the three-fifths /
none pairing being the number a reader remembers. Paragraph 2 interprets: the mechanism's
signature, the contribution relative to the US evidence, and one sentence on the two
limitations that condition the reading, with a pointer. Paragraph 3 is the policy reading, the
Abstract's closing line, and the research agenda. Highest information density of the three;
best for a reader who goes straight to the end.

```latex
Did remote work narrow the motherhood penalty in hours? On average, no: among employed Israeli
women, the mother/childless gap in usual weekly hours did not change after 2021, a
difference-in-differences of $0.23$ hours (SE $0.18$) whose 95\% confidence interval excludes
average gains above about half an hour a week. Where the work can be done from home, yes: the
post-2021 change in the gap rises with an occupation's WFH exposure, by $3.22$ hours per unit of
exposure, or $1.71$ hours a week between the most and least teleworkable quartiles of
occupations. Mothers in the most teleworkable jobs recovered roughly three fifths of their
pre-period penalty; mothers in the least teleworkable jobs recovered none of it. And the gradient
behaves as a flexibility mechanism should: it is largest for mothers of children under five,
declines with the age of the youngest child, and has the opposite sign for fathers in the same
occupations.

We read this pattern as the signature of a relaxed time constraint \citep{goldin2014} rather than
its proof: the supporting checks are estimated on the same forty occupation clusters as the
headline, and where a wild cluster bootstrap $p$-value is available it mostly lies above the 5\%
level, the headline's own at $0.056$. Relative to the US evidence, where remote work raised mothers'
employment and income \citep{harrington2025}, the Israeli response appears on the intensive
margin, in how much mothers who already hold teleworkable jobs work rather than in whether mothers
hold jobs; the employment margin is estimated too imprecisely here to say either way
(Section~\ref{sec:res-extensive}). Three limitations condition the reading
(Section~\ref{sec:limitations}). The result requires reclassifying teaching, which US task
content scores as teleworkable and Israeli schools kept in person, and the one exposure measure
built entirely from pre-treatment information yields a positive but insignificant estimate.
Mothers and childless women differ in marital status in a way that tracks exposure, and the two
marital checks leave the gradient positive but only marginally significant. And with forty
occupation clusters the headline's precision is the range across three inference procedures
rather than a single $p$-value.

The policy implication is correspondingly narrow. Remote work matters for which mothers can work
more, not for mothers as a group, and access to teleworkable jobs is itself unequally distributed.
Stronger evidence would link hours with earnings and household time use, measure exposure before
treatment in the Israeli setting, and estimate women's and men's responses together on a design
that separates access to WFH from occupation choice.
```

**Length.** About 400 words (current: 186). Three paragraphs. If length matters more, drop the
sentence beginning "Mothers and childless women differ" and write "Two limitations"; the marital
point then stays only in Limitations.

**Drops vs. current:** the restated question; "universal benefit"; the four-caveat list; the
earnings sentence. **Adds:** the answer as the first sentence; magnitudes (0.23, 3.22, 1.71,
three fifths / none); the fathers' gradient; the mechanism reading with `goldin2014` and the
bootstrap qualification; the US comparison with `harrington2025`; the three named limitations
(teaching reclassification, marital imbalance, small-cluster inference); the policy reading; the
"which mothers" close; two `\ref`s.

### 3.B Version B: question-to-implication (close the Introduction's loop)

**Strategy.** Argue rather than list. Open on the Introduction's hook (flexibility is a good
mothers pay for; remote work lowered its price), report the answer as a contrast (teleworkable
jobs vs. not; mothers vs. fathers), and draw the implication the Discussion reaches: the finding
is about *access* to teleworkable jobs, which is unequal, so the gain for mothers as a group is
smaller than the gradient. Only two numbers, so the paragraph reads as prose rather than a
results digest. Lowest repetition risk; strongest rhetorical arc; least informative for a reader
who wants the estimates.

```latex
Flexibility is a good that mothers pay for, and the post-pandemic shift to remote work lowered its
price for anyone whose job can be done from home. This paper asked whether employed Israeli mothers
used that price fall to supply more paid hours. The answer depends on where they work. Among
employed women as a whole the hours penalty did not move. Within occupations that can be done from
home it narrowed, and the narrowing grows with how teleworkable the occupation is, by about $1.71$
hours a week between the most and least teleworkable quartiles. Mothers in the most teleworkable
jobs recovered roughly three fifths of their penalty, mothers in the least teleworkable jobs
recovered none of it, and fathers in the same occupations show a gradient of the opposite sign, so
the response is specific to mothers rather than a feature of teleworkable work.

The finding is therefore about access rather than about remote work as such. Where the constraint
that flexibility relaxes is binding, for mothers of young children most of all, and where the job
allows it, the intensive-margin penalty shrinks; where the job does not allow it, nothing changes.
Because teleworkable jobs are unequally distributed across mothers, the gain for mothers as a group
is smaller than the gradient alone suggests, and this paper cannot size it. The identifying
assumption is not directly testable, and the estimate rests on reclassifying teaching within the
exposure measure, on a comparison group whose marital composition shifts with exposure, and on
forty occupation clusters (Section~\ref{sec:limitations}). What would settle the mechanism is
evidence that links hours with earnings and household time use, measures exposure before treatment
in the Israeli setting, and estimates women's and men's responses together on a design that
separates access to remote work from occupation choice.
```

**Length.** About 300 words. Two paragraphs.

**Drops vs. current:** the restated question; the four-caveat list; the earnings sentence; the
employment-margin sentence (the Results and Discussion already carry it, and the Abstract's
verdict on it stands). **Adds:** the Introduction's framing as the opening; 1.71 and the
three-fifths / none pairing; the fathers' gradient; the access / unequal-distribution
implication (1009-1012); the three named dependencies (teaching, marital composition, forty
clusters); one `\ref`.

**Trade-off to flag.** Dropping the employment margin from the Conclusion is a deliberate choice
here. If the authors want it kept, insert after "nothing changes.": "Whether remote work also
changed whether mothers work is a question this design cannot answer either way
(Section~\ref{sec:res-extensive})."

### 3.C Version C: minimal edit of the co-author's text (fallback)

**Strategy.** Keep the co-author's two paragraphs, sentence order and voice, and make six
surgical changes that fix items 1, 2, 6, 7, 8, 9 and 10 of §2.2 and add the Abstract's closing
line. No numbers introduced. Best if the co-author's draft is to remain recognisably theirs.

```latex
Remote work did not narrow the motherhood penalty in hours for employed Israeli women on average,
but it did where the work can be done from home. The average change among women observed working
is small, whereas the post-2021 change in the mother/childless gap increases with an occupation's
calibrated WFH exposure. The strongest contrast is at the top of the exposure distribution and
among mothers with younger children, and fathers in the same occupations show a gradient of the
opposite sign. Those patterns are consistent with greater scheduling flexibility helping mothers
who already hold teleworkable jobs supply more paid hours.

The result is conditional. It requires reclassifying teaching, which Israeli schools kept in
person, and the one exposure measure built entirely from pre-treatment information yields a
weaker, insignificant estimate; the two marital checks leave the gradient only marginally
significant, and the headline's precision depends on the inference procedure
(Section~\ref{sec:limitations}). Employment is an important separate margin, but its
exposure interaction is too imprecise here to settle the question either way. Stronger evidence
would link hours with earnings and household time use, measure exposure before treatment in the
Israeli setting, and estimate women's and men's responses together on a design that better
separates access to WFH from occupation choice. The evidence is about mothers in teleworkable
occupations specifically, not about the motherhood penalty across the board.
```

**Length.** About 220 words. Two paragraphs.

**The six changes, as a diff against 1089-1103:**

1. L1089-1090 "Using Israeli survey data, we ask whether the expansion of remote work coincided
   with a change in the motherhood penalty in usual weekly hours." → "Remote work did not narrow
   the motherhood penalty in hours for employed Israeli women on average, but it did where the
   work can be done from home."
2. L1091 "mother/comparison gap" → "mother/childless gap".
3. L1092-1093 "...among mothers with younger children." → "...among mothers with younger
   children, and fathers in the same occupations show a gradient of the opposite sign."
4. L1094 "some already employed mothers" → "mothers who already hold teleworkable jobs".
5. L1096-1098 "The result is conditional and does not establish a universal benefit from remote
   work. The exposure score partly uses post-period WFH information; the wholly external score
   yields a weaker result, pre-trend tests have limited power, and inference varies with the
   procedure." → "The result is conditional. It requires reclassifying teaching, which Israeli
   schools kept in person, and the one exposure measure built entirely from pre-treatment
   information yields a weaker, insignificant estimate; the two marital checks leave the
   gradient only marginally significant, and the headline's precision depends on the inference
   procedure (Section~\ref{sec:limitations})."
6. L1100 "The data also contain no earnings amount." deleted; "either way" appended to the
   employment sentence; closing sentence "The evidence is about mothers in teleworkable
   occupations specifically, not about the motherhood penalty across the board." appended
   (paraphrasing the Abstract's close, 197-199).

## 4. Comparison matrix

| Criterion | Current | A | B | C |
|---|---|---|---|---|
| Opens with the answer | No | Yes | Yes (after one framing sentence) | Yes |
| All three findings, incl. fathers | 2 of 3 | 3 | 3 | 3 |
| Magnitudes stated | None | 0.23, 3.22, 1.71, 3/5 | 1.71, 3/5 | None |
| Loop closed with the Introduction | No | US comparison | Flexibility framing | No |
| Mechanism reading with citation | No | Yes | Implicit | No |
| Repeats Limitations | Four caveats | One sentence + `\ref` | One sentence + `\ref` | One sentence + `\ref` |
| Employment margin | Yes | Yes + `\ref` | Dropped (optional insert) | Yes |
| Policy reading (access, unequal) | No | Yes | Yes, developed | No |
| Closes on the Abstract's takeaway (teleworkable occupations specifically, not across the board) | No | Yes, via the Discussion's policy reading | Yes, paraphrased | Yes |
| Words | 186 | ~400 | ~300 | ~220 |
| Fidelity to co-author's voice | -- | Low | Low | High |

## 5. Recommendation and how to apply

**Recommendation: Version A.** The Conclusion was excluded from both grade reports at the
authors' request, so the submitted version will be read for the first time; it should carry the
same "three findings" spine as the Introduction and Results and give the reader the numbers the
Abstract promised. A is about 210 words longer than the current text, but it replaces repetition with
content, which is the direction the grade report asked for. If the co-author prefers to keep
their draft, **Version C** applies the same fixes at a fifth of the delta. **Version B** is the
choice if the authors want the paper to end on its argument rather than its estimates; the
optional employment-margin insert in §3.B should then be used.

A reasonable hybrid, if wanted: A's first two paragraphs followed by B's second paragraph in
place of A's third.

**To apply (done 2026-10-03; kept as the record of what was done):**

1. Replace `paper/paper.tex` lines 1077-1091 at `00dadf2` (the two paragraphs under
   `\section{Conclusion}`; 1089-1103 when this note was written) with the chosen block.
2. Add a dated header comment line at the top of `paper.tex`, in the style of the
   2026-09-27 "INTRODUCTION AND ABSTRACT PASS" note (line 46), stating that the Conclusion was
   rewritten and that no number was added.
3. Recompile from `paper/`: `pdflatex`, `bibtex`, `pdflatex`, `pdflatex` (one more `pdflatex`
   if the log warns that labels may have changed). Check the log for undefined references; the
   only new `\ref`s are `sec:limitations` and `sec:res-extensive`, both defined.
4. Update `README.md`'s section summary if it paraphrases the Conclusion (it does not as of
   `6454bd0`; it names this note twice and paraphrases nothing).

## 6. Not done / open items

- Superseded 2026-10-03: `paper.tex`, `paper.pdf` and `README.md` changed when Version A was
  applied (see the status block at the top).
- **Co-author sign-off.** The current text is the co-author's. Versions A and B replace it;
  Version C edits it. Which is acceptable is a decision between the authors, not one this note
  makes.
- **Seminar rule.** Earlier repo notes recorded a rule that students write the Conclusion
  themselves; that rule is satisfied by any of the three versions only if the authors adopt and
  own the text. If the course constrains how much may be assisted, Version C is the one to
  prefer.
- The Abstract's closing takeaway is paraphrased in A, B and C. Version A's last paragraph still
  reads "which mothers can work more, not for mothers as a group", the Discussion's policy
  reading rather than the Abstract's current "mothers in teleworkable occupations specifically,
  rather than reducing the motherhood penalty across the board"; same thought, different words.
  With A applied, the Abstract and Conclusion end on that one thought, which is conventional; the
  authors may prefer to vary one of them.
- `harrington2025` prints "Harrington and Kahn, 2026" in-text since `00dadf2` (the published
  *National Tax Journal* version); the drafts' `\citep` key is unchanged, so nothing in them
  needs editing for it.
- The referee review this note's header cites (2026-09-28) leaves version control in Phase 3 of
  the 2026-10-03 repository clean-up, along with the design memos; the reference is plain
  history and `README.md` carries the review's summary.

