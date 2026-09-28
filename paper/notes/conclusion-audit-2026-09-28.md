# Conclusion audit: `paper/paper.tex` §9 (pre-submission)

**Date:** 2026-09-28. **Scope:** the Conclusion (`paper.tex:1010-1027`, two paragraphs, 186
words), read against the Abstract (178-195), the Introduction (198-259), the Results lead
(601-611), the Discussion (896-953) and the Limitations (956-1007) as committed at `4802830`.
**Rule applied (author's choice):** analysis and proposals only. `paper.tex` was NOT edited and
the paper was not recompiled. The current text was written by the co-author and moved in verbatim
on 2026-09-26; whether and how to replace it is the authors' joint call.

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

## 1. Current text (verbatim, `paper.tex:1013-1027`)

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
| 1 | F | Opens by restating the question ("we ask whether...") rather than answering it. A conclusion's first sentence should be the answer. | 1013 vs. the Introduction's own answer at 233-241 | Open with the answer: no on average, yes where the work can be done from home. |
| 2 | F, I | Reports two of the "three findings" the Introduction (233) and the Results lead (602) promise. The fathers' opposite-signed gradient, which the Discussion calls the check that "rules out a shock common to all workers" (936), is absent. | 233-241, 602-607, 837, 936; nothing at 1013-1018 | Add the fathers' gradient to the findings sentence. |
| 3 | I | No magnitude anywhere. "Small" and "increases with" are the only quantifiers; the reader leaves without 3.22 per unit, 1.71 between quartiles, or "three fifths of their penalty". | 233-236, 914-923 | State at least the quartile contrast and the three-fifths / none pairing. |
| 4 | I | Does not close the loop with the Introduction: flexibility as the last driver of the gender gap (203-207), the Israeli fertility context (215-218), and the contrast with the US extensive-margin result (211-214, 249-252) are all absent. | 203-218, 249-254 | One sentence placing the result against Harrington & Kahn (intensive vs. extensive margin, different country). |
| 5 | I | The Abstract's last sentence ("about *which* mothers benefit ... rather than about mothers as a group", 193-194) is the paper's one-line takeaway and the natural last line of the Conclusion; it does not appear. | 193-194, 949-953 | End on it. |
| 6 | T | Paragraph 2 (1020-1024) is roughly 60% caveats that restate Limitations nearly verbatim: post-period calibration (961-964), weaker external score (964), pre-trend power (960-961), inference by procedure (972-973). The 2026-09-23 grade report deducted 2 points for exactly this: "the post-period calibration caveat, the forty-cluster caveat, and the 2023 caveat each appear three or more times". | 1020-1022 vs. 959-973 | Collapse to one sentence naming the two limitations that condition the reading, with `\ref{sec:limitations}`. |
| 7 | T | "does not establish a universal benefit from remote work" rebuts a claim nobody made. | 1020 | Cut; "conditional" alone carries it. |
| 8 | T, F | "The data also contain no earnings amount" is a data-description sentence, not a conclusion, and sits between the employment margin and the research agenda. | 1024; the fact belongs to §3.1 (header note, 25) | Cut; the agenda's "link hours with earnings" already implies it. |
| 9 | T | Terminology drift: "mother/comparison gap" vs. the paper's "mother/childless gap"; "some already employed mothers" vs. "mothers who already hold *teleworkable* jobs". | 1015 vs. 604; 1018 vs. 950-951 | Use the paper's terms. |
| 10 | I | The employment margin is "too imprecise here to settle the question"; the Results make the sharper point that the employment DDD is *uninformative*, "evidence neither for nor against", and that "the two nulls should not be read as one verdict". | 1022-1024 vs. 891-893 | Keep the sentence, add "either way" or point to `sec:res-extensive`. |
| 11 | I | The Discussion's narrow policy reading (WFH matters for how intensively mothers in teleworkable jobs work, not for whether mothers work; access to those jobs is unequal, so the population-wide gain is smaller than the gradient) is the paper's practical takeaway and never reaches the Conclusion. | 949-953 | One sentence on the policy reading. |
| 12 | F | Two paragraphs with no "so what" beat between summary and caveats; the interpretation is one clause ("consistent with greater scheduling flexibility"). | 1017-1018 | Give the interpretation its own sentences (mechanism signature, contribution). |

### 2.3 Claim ledger (current text)

Every factual claim in the Conclusion, and where the paper supports it.

| # | Claim (line) | Supporting line(s) | Verdict |
|---|---|---|---|
| 1 | Average change among women observed working is small (1014-1015) | 233-234 (DiD 0.23, SE 0.18); 617-619 (MDE ~0.51, "reasonably precise null") | OK |
| 2 | Post-2021 change in the gap increases with calibrated WFH exposure (1015-1016) | 235-236; 602-605 | OK (wording: "mother/comparison" is not the paper's term) |
| 3 | Strongest contrast at the top of the exposure distribution (1016) | 238 ("concentrated in the most teleworkable quartile"); 914-923 | OK |
| 4 | Strongest among mothers with younger children (1016-1017) | 239-240; 822 | OK |
| 5 | Exposure score partly uses post-period WFH information (1020-1021) | 961-963 | OK |
| 6 | Wholly external score yields a weaker result (1021-1022) | 964 ("positive and insignificant") | OK |
| 7 | Pre-trend tests have limited power (1022) | 960-961 | OK |
| 8 | Inference varies with the procedure (1022) | 188-190 (p = 0.003 / 0.032 / 0.056); 972-973 | OK |
| 9 | Employment interaction too imprecise to settle the question (1022-1024) | 880-893 | OK, understated (see §2.2 #10) |
| 10 | No earnings amount in the data (1024) | header note 25 (§3.1 sentence) | OK, misplaced (see §2.2 #8) |

No claim is wrong; nothing needs a fix in place.

### 2.4 Alignment check against the sections the Conclusion must agree with

| Section | What it commits the Conclusion to | Present now? |
|---|---|---|
| Abstract (178-195) | Three inference procedures reported side by side; "which mothers" closing line | Inference: yes (as a caveat). Closing line: no |
| Introduction, "Three findings emerge" (233-241) | (1) precise null; (2) 3.22 / 1.71, concentrated in the top quartile; (3) child-age gradient **and** fathers' opposite gradient | (1) yes, no number; (2) yes, no number; (3) half |
| Introduction, contribution (249-254) | Intensive margin vs. US extensive margin; Israeli-calibrated exposure; forty clusters as evidence | No |
| Results lead (602-607) | Same three findings; employment margin "too imprecisely estimated to support a comparable conclusion" | Employment: yes |
| Discussion (896-953) | Three-fifths / none magnitudes; mechanism "signature rather than proof"; narrow policy reading | None of the three |
| Limitations (956-1007) | Already states every caveat in full | The Conclusion should point here, not repeat it |

## 3. Alternative versions

Rules common to all three: (i) every number already appears in `paper.tex` and is traced by
line below; no number is added, the same discipline as the 2026-09-27 Introduction and Results
passes; (ii) Limitations are pointed to, not re-listed; (iii) the co-author's research-agenda
sentence is kept, lightly edited; (iv) only existing macros, `\citep` keys (`goldin2014`,
`harrington2025`) and `\ref` labels (`sec:limitations`, `sec:res-extensive`) are used, so any
version compiles as a drop-in replacement for lines 1013-1027.

Shared number provenance:

| Literal | `paper.tex` line(s) |
|---|---|
| DiD 0.23 (SE 0.18); "rules out average gains much above half an hour a week" | 233-234; 617-618 |
| 3.22 hours per unit of exposure | 235; 186 (SE 1.02) |
| 1.71 hours between the top and bottom quartile means | 235-236; 187; 661 |
| "recovered roughly three fifths of their penalty" (top quartile) | 920-921 |
| "recovered none of it" (bottom quartile, implied change -0.35) | 922-923 |
| Largest for mothers of children under five; declines with age of youngest child | 239-240; 191-192 |
| Fathers: gradient of the opposite sign | 240-241; 837 |
| Forty occupation clusters; three inference procedures | 241-243; 188-190; 972-973 |
| Pre-treatment external index: positive and insignificant | 964; 245-247 |
| Employment DDD uninformative, "neither for nor against" | 891-893 |
| US: WFH raised mothers' employment and income | 211-214 |
| "signature rather than its proof" | 942 |
| "which mothers ... rather than mothers as a group" | 193-194 |

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
difference-in-differences of $0.23$ hours (SE $0.18$) that rules out average gains much above half
an hour a week. Where the work can be done from home, yes: the post-2021 change in the gap rises
with an occupation's WFH exposure, by $3.22$ hours per unit of exposure, or $1.71$ hours a week
between the most and least teleworkable quartiles of occupations. Mothers in the most teleworkable
jobs recovered roughly three fifths of their pre-period penalty; mothers in the least teleworkable
jobs recovered none of it. And the gradient behaves as a flexibility mechanism should: it is
largest for mothers of children under five, declines with the age of the youngest child, and has
the opposite sign for fathers in the same occupations.

We read this pattern as the signature of a relaxed time constraint \citep{goldin2014} rather than
its proof. Relative to the US evidence, where remote work raised mothers' employment and income
\citep{harrington2025}, the Israeli response appears on the intensive margin, in how much mothers
who already hold teleworkable jobs work rather than in whether mothers hold jobs; the employment
margin is estimated too imprecisely here to say either way (Section~\ref{sec:res-extensive}). Two
limitations condition the reading (Section~\ref{sec:limitations}): the one exposure measure built
entirely from pre-treatment information yields a positive but insignificant estimate, and with
forty occupation clusters the headline's precision is the range across three inference procedures
rather than a single $p$-value.

The policy implication is correspondingly narrow. Remote work matters for which mothers can work
more, not for mothers as a group, and access to teleworkable jobs is itself unequally distributed.
Stronger evidence would link hours with earnings and household time use, measure exposure before
treatment in the Israeli setting, and estimate women's and men's responses together on a design
that separates access to WFH from occupation choice.
```

**Length.** 327 words (current: 186). Three paragraphs.

**Drops vs. current:** the restated question; "universal benefit"; the four-caveat list; the
earnings sentence. **Adds:** the answer as the first sentence; magnitudes (0.23, 3.22, 1.71,
three fifths / none); the fathers' gradient; the mechanism reading with `goldin2014`; the US
comparison with `harrington2025`; the policy reading; the "which mothers" close; two `\ref`s.

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
assumption is not directly testable, and the estimate rests on a calibrated exposure measure and
forty occupation clusters (Section~\ref{sec:limitations}). What would settle the mechanism is
evidence that links hours with earnings and household time use, measures exposure before treatment
in the Israeli setting, and estimates women's and men's responses together on a design that
separates access to remote work from occupation choice.
```

**Length.** 285 words. Two paragraphs.

**Drops vs. current:** the restated question; the four-caveat list; the earnings sentence; the
employment-margin sentence (the Results and Discussion already carry it, and the Abstract's
verdict on it stands). **Adds:** the Introduction's framing as the opening; 1.71 and the
three-fifths / none pairing; the fathers' gradient; the access / unequal-distribution
implication (949-953); one `\ref`.

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

The result is conditional. The one exposure measure built entirely from pre-treatment information
yields a weaker, insignificant estimate, and the headline's precision depends on the inference
procedure (Section~\ref{sec:limitations}). Employment is an important separate margin, but its
exposure interaction is too imprecise here to settle the question either way. Stronger evidence
would link hours with earnings and household time use, measure exposure before treatment in the
Israeli setting, and estimate women's and men's responses together on a design that better
separates access to WFH from occupation choice. The result is about which mothers benefit from
remote work rather than about mothers as a group.
```

**Length.** 203 words. Two paragraphs.

**The six changes, as a diff against 1013-1027:**

1. L1013-1014 "Using Israeli survey data, we ask whether the expansion of remote work coincided
   with a change in the motherhood penalty in usual weekly hours." → "Remote work did not narrow
   the motherhood penalty in hours for employed Israeli women on average, but it did where the
   work can be done from home."
2. L1015 "mother/comparison gap" → "mother/childless gap".
3. L1016-1017 "...among mothers with younger children." → "...among mothers with younger
   children, and fathers in the same occupations show a gradient of the opposite sign."
4. L1018 "some already employed mothers" → "mothers who already hold teleworkable jobs".
5. L1020-1022 "The result is conditional and does not establish a universal benefit from remote
   work. The exposure score partly uses post-period WFH information; the wholly external score
   yields a weaker result, pre-trend tests have limited power, and inference varies with the
   procedure." → "The result is conditional. The one exposure measure built entirely from
   pre-treatment information yields a weaker, insignificant estimate, and the headline's
   precision depends on the inference procedure (Section~\ref{sec:limitations})."
6. L1024 "The data also contain no earnings amount." deleted; "either way" appended to the
   employment sentence; closing sentence "The result is about which mothers benefit from remote
   work rather than about mothers as a group." appended (from the Abstract, 193-194).

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
| "Which mothers" close | No | Yes | Yes, paraphrased | Yes |
| Words | 186 | 327 | 285 | 203 |
| Fidelity to co-author's voice | -- | Low | Low | High |

## 5. Recommendation and how to apply

**Recommendation: Version A.** The Conclusion was excluded from both grade reports at the
authors' request, so the submitted version will be read for the first time; it should carry the
same "three findings" spine as the Introduction and Results and give the reader the numbers the
Abstract promised. A is 141 words longer than the current text, but it replaces repetition with
content, which is the direction the grade report asked for. If the co-author prefers to keep
their draft, **Version C** applies the same fixes at a fifth of the delta. **Version B** is the
choice if the authors want the paper to end on its argument rather than its estimates; the
optional employment-margin insert in §3.B should then be used.

A reasonable hybrid, if wanted: A's first two paragraphs followed by B's second paragraph in
place of A's third.

**To apply (not done here):**

1. Replace `paper/paper.tex` lines 1013-1027 with the chosen block.
2. Add a dated header comment line at the top of `paper.tex`, in the style of the
   2026-09-27 "INTRODUCTION AND ABSTRACT PASS" note (line 46), stating that the Conclusion was
   rewritten and that no number was added.
3. Recompile from `paper/`: `pdflatex`, `bibtex`, `pdflatex`, `pdflatex` (one more `pdflatex`
   if the log warns that labels may have changed). Check the log for undefined references; the
   only new `\ref`s are `sec:limitations` and `sec:res-extensive`, both defined.
4. Update `README.md`'s section summary if it paraphrases the Conclusion (it was audited against
   the paper on 2026-09-28 at `778948e`).

## 6. Not done / open items

- `paper.tex`, `paper.pdf` and `README.md` are unchanged. No recompile was needed.
- **Co-author sign-off.** The current text is the co-author's. Versions A and B replace it;
  Version C edits it. Which is acceptable is a decision between the authors, not one this note
  makes.
- **Seminar rule.** Earlier repo notes recorded a rule that students write the Conclusion
  themselves; that rule is satisfied by any of the three versions only if the authors adopt and
  own the text. If the course constrains how much may be assisted, Version C is the one to
  prefer.
- The Abstract's "which mothers" line is now used in A, B and C; if adopted, the Abstract and
  Conclusion will end on the same sentence. That is conventional, but the authors may prefer to
  vary one of them.
