#!/usr/bin/env Rscript

script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- args[grepl("^--file=", args)]
  if (!length(file_arg)) return("run_demo.R")
  sub("^--file=", "", file_arg[[1L]])
}

tokens <- function(text) {
  x <- strsplit(tolower(gsub("[^a-z0-9]+", " ", text)), " +")[[1L]]
  x[nchar(x) >= 3L]
}

terms <- function(text) {
  x <- tokens(text)
  c(x, if (length(x) > 1L) paste(head(x, -1L), tail(x, -1L), sep = "_") else character())
}

count_matrix <- function(texts, vocab) {
  out <- matrix(0, nrow = length(texts), ncol = length(vocab),
                dimnames = list(NULL, make.names(vocab, unique = TRUE)))
  for (i in seq_along(texts)) {
    counts <- table(terms(texts[[i]]))
    matched <- intersect(names(counts), vocab)
    out[i, match(matched, vocab)] <- as.numeric(counts[matched])
  }
  out
}

text_features <- function(train, test, vocab_size = 40L) {
  counts <- sort(table(unlist(lapply(train, terms), use.names = FALSE)), decreasing = TRUE)
  vocab <- names(head(counts, vocab_size))
  train_counts <- count_matrix(train, vocab)
  test_counts <- count_matrix(test, vocab)
  idf <- log((length(train) + 1) / (colSums(train_counts > 0) + 1)) + 1
  list(train = sweep(log1p(train_counts), 2L, idf, `*`),
       test = sweep(log1p(test_counts), 2L, idf, `*`))
}

shape_features <- function(texts) {
  out <- t(vapply(texts, function(text) {
    x <- tokens(text)
    c(length = length(x), comparison = as.integer(any(x %in% c("compare", "versus", "alternatives"))),
      evaluation = as.integer(any(x %in% c("benchmark", "evaluation", "audit", "tests"))))
  }, numeric(3)))
  out[, "length"] <- out[, "length"] / 20
  out
}

neighbor_features <- function(train_x, test_x, labels, classes, k = 3L) {
  unit <- function(x) x / pmax(sqrt(rowSums(x * x)), 1e-9)
  train_sim <- unit(train_x) %*% t(unit(train_x))
  diag(train_sim) <- -Inf
  test_sim <- unit(test_x) %*% t(unit(train_x))
  summarize_neighbors <- function(sim) {
    out <- matrix(0, nrow = nrow(sim), ncol = length(classes),
                  dimnames = list(NULL, paste0("neighbor_", make.names(classes))))
    for (i in seq_len(nrow(sim))) {
      chosen <- head(order(sim[i, ], decreasing = TRUE), k)
      weights <- pmax(sim[i, chosen], 0) + 1e-6
      for (j in seq_along(classes)) {
        out[i, j] <- sum(weights[labels[chosen] == classes[[j]]]) / sum(weights)
      }
    }
    out
  }
  list(train = summarize_neighbors(train_sim), test = summarize_neighbors(test_sim))
}

run_demo <- function(data_path, threshold = 0.90) {
  if (!requireNamespace("nnet", quietly = TRUE)) stop("The recommended R package nnet is required.")
  if (!is.finite(threshold) || threshold < 0 || threshold > 1) stop("Threshold must be in [0, 1].")
  rows <- read.csv(data_path, stringsAsFactors = FALSE)
  required <- c("date", "title", "abstract", "llm_structure", "completed")
  if (!all(required %in% names(rows))) stop("Trace fixture is missing required columns.")
  rows <- rows[rows$completed & !is.na(rows$completed), , drop = FALSE]
  rows <- rows[order(rows$date), , drop = FALSE]
  if (nrow(rows) < 12L || length(unique(rows$llm_structure)) < 2L) stop("Too few completed traces.")
  split <- floor(nrow(rows) * 0.75)
  train <- rows[seq_len(split), , drop = FALSE]
  test <- rows[seq.int(split + 1L, nrow(rows)), , drop = FALSE]
  if (max(train$date) >= min(test$date)) stop("Train/test dates overlap.")
  classes <- sort(unique(train$llm_structure))
  train_text <- paste(train$title, train$abstract)
  test_text <- paste(test$title, test$abstract)
  tfidf <- text_features(train_text, test_text)
  neighbors <- neighbor_features(tfidf$train, tfidf$test, train$llm_structure, classes)
  x_train <- cbind(tfidf$train, shape_features(train_text), neighbors$train)
  x_test <- cbind(tfidf$test, shape_features(test_text), neighbors$test)
  features <- make.names(colnames(x_train), unique = TRUE)
  colnames(x_train) <- features
  colnames(x_test) <- features
  set.seed(20260717)
  fit <- nnet::multinom(factor(train$llm_structure, levels = classes) ~ .,
                       data = data.frame(x_train, check.names = FALSE),
                       trace = FALSE, decay = 0.1, maxit = 300, MaxNWts = 5000)
  probabilities <- predict(fit, newdata = data.frame(x_test, check.names = FALSE), type = "probs")
  if (is.null(dim(probabilities))) probabilities <- matrix(probabilities, nrow = 1L)
  predicted <- classes[max.col(probabilities)]
  score <- apply(probabilities, 1L, max)
  local_action <- score >= threshold
  list(train_count = nrow(train), test_count = nrow(test),
       train_through = max(train$date), test_from = min(test$date),
       agreement = mean(predicted == test$llm_structure),
       local_share = mean(local_action), deferral_rate = mean(!local_action),
       acted_agreement = if (any(local_action)) mean(predicted[local_action] == test$llm_structure[local_action]) else NA_real_,
       predictions = data.frame(title = test$title, llm_structure = test$llm_structure,
                                local_prediction = predicted, score = round(score, 3),
                                action = ifelse(local_action, "local_example", "defer")))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  data_path <- if (length(args)) args[[1L]] else file.path(dirname(script_path()), "data", "synthetic_traces.csv")
  result <- run_demo(data_path)
  cat(sprintf("Train: %d through %s | Test: %d from %s\n", result$train_count,
              result$train_through, result$test_count, result$test_from))
  cat(sprintf("Agreement with logged ChatGPT label: %.3f | Local share: %.3f | Deferral: %.3f\n",
              result$agreement, result$local_share, result$deferral_rate))
  cat(sprintf("Agreement on locally acted examples: %s\n",
              if (is.na(result$acted_agreement)) "none acted" else sprintf("%.3f", result$acted_agreement)))
  print(result$predictions, row.names = FALSE)
  cat("Synthetic demonstration only. Scores are not calibrated decision confidence.\n")
}
