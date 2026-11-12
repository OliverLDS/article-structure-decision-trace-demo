# Article-Structure Decision Traces

This is an exhibit for the article-structure decision point in
Zelina's blog workflow. It accompanies the ongoing manuscript *Decision-Trace
Distillation for Reducing LLM Decision Rights in Agentic AI Systems*. The
manuscript and experiment may change; this snapshot documents the current
implementation boundary, not a final empirical result.

During **learning**, ChatGPT chooses a structure from a bounded option set and
Zelina records the decision with the paper context. During **evaluating**, a
local classifier learns from completed historical traces and predicts a label
for comparison with ChatGPT's new decision. During **running**, the current
workflow retrieves similar prior traces to give ChatGPT a shortlist. The local
classifier does **not** currently make all production structure decisions.

Read the [real-log results](RESULTS.md) before the miniature. The observed
offline M5-style model has **not** outperformed the simple majority baseline in the
single-source holdout; no production decision-rights transfer is established.

## Run the miniature

Requires R and the recommended `nnet` package; no API key or network access is
needed.

```sh
Rscript run_demo.R
Rscript test_demo.R
```

The synthetic CSV is intentionally small and includes an ambiguous held-out
label. Its results demonstrate data flow and evaluation mechanics, **not**
real-world accuracy, calibration, cost savings, or safe transfer of decision
authority. See [METHOD.md](METHOD.md) for the mapping
to the live Zelina nodes and the missing evidence needed for stronger claims.

## Boundaries

- No real paper digests, per-record decision logs, account details, browser
  automation, or unpublished manuscript text are included. The real-log
  analysis is published only as aggregate results.
- A completed workflow's ChatGPT choice is a training label in the current
  implementation. It is not necessarily human-approved or outcome-validated.
- Reported model probabilities are ranking signals, not calibrated confidence.
- The threshold in the miniature illustrates deferral; it is not a deployment
  policy.

Development remains in `zl_agentr`. This repository is a one-way, curated
export, not a second implementation to edit independently.
