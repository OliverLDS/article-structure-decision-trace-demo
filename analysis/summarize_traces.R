#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(jsonlite))

scalar <- function(x, default = "") {
  if (is.null(x) || !length(x) || is.na(x[[1L]])) default else as.character(x[[1L]])
}

read_log <- function(path, workflow) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  parsed <- lapply(lines, function(line) tryCatch(fromJSON(line, simplifyVector = FALSE),
                                                  error = function(e) NULL))
  records <- Filter(Negate(is.null), parsed)
  rows <- lapply(records, function(record) {
    group <- scalar(record$arxiv_id_group)
    type <- scalar(record$plan_type, if (grepl(",", group, fixed = TRUE)) "multi_source" else "single_source")
    selected <- record$selected_structure_labels
    label <- if (length(selected)) scalar(unlist(selected, use.names = FALSE)) else ""
    if (!nzchar(label) && length(record$structure_plan)) {
      row <- record$structure_plan[[1L]]
      label <- scalar(row[[if (identical(type, "multi_source")) "selected_structure" else "chosen article-level structure"]])
    }
    data.frame(workflow = workflow, period = scalar(record$decision_period, "unrecorded"),
               plan_type = type, label = label, stringsAsFactors = FALSE)
  })
  list(rows = if (length(rows)) do.call(rbind, rows) else data.frame(),
       parsed = length(records), invalid = length(parsed) - length(records))
}

count_values <- function(values) {
  values <- values[nzchar(values)]
  as.list(sort(table(values), decreasing = TRUE))
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L || any(!file.exists(args[1:3]))) {
  stop("Usage: summarize_traces.R WRITE_LOG REVISE_LOG LIVE_EVALUATION_CSV OUTPUT_JSON", call. = FALSE)
}
write <- read_log(args[[1L]], "write_new_blog_article")
revise <- read_log(args[[2L]], "revise_existing_blog_article")
rows <- rbind(write$rows, revise$rows)
live <- read.csv(args[[3L]], stringsAsFactors = FALSE)
live <- live[nzchar(live$local_llm_match), , drop = FALSE]
confidence <- suppressWarnings(as.numeric(live$local_confidence))
result <- list(
  schema_version = 1L,
  record_count = nrow(rows),
  invalid_jsonl_lines = write$invalid + revise$invalid,
  workflow_counts = count_values(rows$workflow),
  decision_period_counts = count_values(rows$period),
  plan_type_counts = count_values(rows$plan_type),
  selected_label_counts = count_values(rows$label),
  live_evaluation = list(
    record_count = nrow(live),
    matches = sum(live$local_llm_match == "TRUE"),
    mismatches = sum(live$local_llm_match == "FALSE"),
    confidence_median = if (length(confidence)) median(confidence, na.rm = TRUE) else NULL,
    mismatch_confidence_median = if (any(live$local_llm_match == "FALSE")) {
      median(confidence[live$local_llm_match == "FALSE"], na.rm = TRUE)
    } else NULL
  )
)
dir.create(dirname(args[[4L]]), recursive = TRUE, showWarnings = FALSE)
writeLines(toJSON(result, auto_unbox = TRUE, pretty = TRUE, null = "null"), args[[4L]])
cat(sprintf("Wrote aggregate trace summary: %s\n", args[[4L]]))
