#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)][[1L]])
root <- dirname(normalizePath(script))
source(file.path(root, "run_demo.R"))
fixture <- file.path(root, "data", "synthetic_traces.csv")
result <- run_demo(fixture)
stopifnot(result$train_count == 18L, result$test_count == 6L,
          result$train_through < result$test_from,
          nrow(result$predictions) == 6L,
          is.finite(result$agreement), result$agreement >= 0, result$agreement <= 1,
          is.finite(result$local_share), result$local_share >= 0, result$local_share <= 1,
          all(result$predictions$action %in% c("local_example", "defer")))
cat("Demo assertions passed.\n")
