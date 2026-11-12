# How the Decision Is Learned

## Live workflow

1. A LitXR source digest supplies a paper's context. ChatGPT selects an
   article-level structure from a bounded catalog.
2. Zelina validates and appends the structure-plan JSON to a trace log.
3. A completed-article record gates which traces the local classifier may use.
4. In the `evaluating` period, the classifier trains from historical selected
   labels and paper title/abstract text. Its M5 features combine word
   unigram/bigram TF-IDF, document-shape indicators, and neighboring trace
   labels. A multinomial model produces a ranking, with a similarity-weighted
   fallback or blend when appropriate.
5. Zelina records the local prediction and whether it matches ChatGPT's
   selected label. In the `running` period, a different node retrieves similar
   structure traces for a shortlist; the classifier is not the final decider.

The implementation lives in `zl_agentr/tasks/write_new_blog_article/`:

| Stage | Source file |
| --- | --- |
| Prompt construction | `nodes/generate_article_structure_plan_prompt.R` |
| Response capture and validation | `nodes/obtain_article_structure_plan_json/run_obtain_article_structure_plan_json.sh` |
| Trace recording | `nodes/append_article_structure_plan_json.R` |
| Local model | `nodes/classify_article_structure_local.R` |
| Running-period precedent retrieval | `nodes/retrieve_similar_structure_traces.R` |
| Period routing | `run_workflow_new_blog_article.sh` |

## What the miniature preserves

`run_demo.R` reads only synthetic completed traces, separates training and test
rows chronologically, builds TF-IDF from training text, adds simple shape and
neighbor-label features, trains a local multinomial classifier, and reports
agreement and deferral at an illustrative threshold. It is a teaching-sized
adaptation, not a byte-for-byte copy of Zelina's M5 classifier.

## What remains unproven

Agreement with prior ChatGPT choices is **not** agreement with the best
article structure. The current completed-article gate does not establish that
the structure itself was human-approved or outcome-validated. The miniature
does not estimate calibrated probabilities, quality of final articles, override
risk, cost, or the safe fraction of decisions that could become local. Those
claims require a frozen label catalog, accepted-decision or outcome labels,
chronological holdout evaluation, threshold calibration, and prospective
monitoring of deferrals and overrides.
