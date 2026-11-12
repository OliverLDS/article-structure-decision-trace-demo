# Observed Article-Structure Results

Snapshot: 2026-11-12. These are analyses of Zelina's real local decision logs,
not results from the synthetic miniature. Only aggregate outputs are published
here: [trace summary](results/trace_summary_2026-11-12.json) and
[offline model summary](results/offline_evaluation_2026-09-01.json).

## Recorded decisions

The write and revision logs contain 2,681 parseable structure-plan records:
1,103 from new-article writing and 1,578 from article revision. There are 2,586
single-source and 95 multi-source records. Period metadata is absent on 1,749
older or revision records; 925 say `learning` and seven say `evaluating`. No
record in this snapshot says `running`. These totals are log entries, not
independent articles or verified-quality labels.

The most common selected label is `mechanism-first` (1,801 entries). The next
two are `evidence-first` (359) and `comparison-based` (298). The remaining
labels are much less frequent. This imbalance matters for local learning.

## Chronological offline test

The existing Zelina evaluator used records before **2026-09-01** for training
and records on or after that date for testing. It requires a completed article
or revision record and a locally available paper title/abstract. The default
250-term vocabulary was used. The target is the logged ChatGPT structure,
**not** an independently judged best structure.

| Scope | Train | Test | Majority accuracy | M5 multinomial accuracy | Best observed accuracy |
| --- | ---: | ---: | ---: | ---: | ---: |
| Single-source | 383 | 586 | 43.9% | 35.7% | 44.5% (M0 ridge) |
| Multi-source | 78 | 4 | 100% | 100% | 100% (all tested models) |

The single-source M5 multinomial balanced accuracy was 17.7%, versus 16.7%
for the majority baseline. The M0 ridge gain in ordinary accuracy is small and
does not establish a robust improvement. In the multi-source test, **all four**
records have the same label, so 100% accuracy does not distinguish a learned
model from the majority rule. The evaluator emitted 48 warnings during the
combined run; these exploratory estimates need a more carefully controlled
modeling and validation protocol before they support a deployment claim.

The single-source label mix changed markedly across the split: `mechanism-first`
fell from 276/383 (72.1%) in training to 257/586 (43.9%) in testing, while
`evidence-first` rose from 52/383 (13.6%) to 221/586 (37.7%). The 586 test
records represent 575 distinct arXiv groups; no test group appeared in the
pre-cutoff logs. Repeated test groups still mean record-level metrics should
not be read as independent-paper confidence intervals.

## Logged live comparison

Seven `evaluating`-period records contain a local prediction and a ChatGPT
selection. The local prediction matched ChatGPT in **2/7** and differed in
**5/7**. The median recorded local confidence was 0.9999; among the five
mismatches it was 1.0000. This is a small, mixed-mode observation, not a
calibration study. It reinforces that the current score must not be used as a
decision-rights threshold without validation.

## Interpretation

The evidence currently supports the existence of a working trace-to-model
pipeline, **not** a successful transfer of article-structure authority. The
offline M5 feature-set test is not identical to the live classifier's possible
fallback or neighbor-prior blend. Neither test measures final article quality,
human approval, editorial override risk, latency savings, or safe local
decision share. Future revisions should obtain accepted/outcome labels,
predefine train/validation/test periods, calibrate or reject confidence scores,
and report threshold-versus-deferral and error tradeoffs before allocating a
direct decision right to the local model.

## Reproduction

The aggregate JSON files were generated locally with the scripts listed in
[METHOD.md](METHOD.md). Raw decision logs and per-record prediction tables are
not copied into this exhibition repository. The scripts remain available for
inspection and reruns against a local Zelina/LitXR installation.
