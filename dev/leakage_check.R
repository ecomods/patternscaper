# Quick A/B check for the CV feature-scaling leakage fix (REVIEW_PROCESS M1).
#
# Isolates the *only* thing the fix changes: how predictors are scaled during
# cross-validation. It runs the SAME folds and the SAME network twice --
#   OLD: scale once on the full dataset, then cross-validate (leaks validation
#        rows into the center/scale applied to them);
#   NEW: scale inside each fold on the training rows only (scale_fold()).
# and reports the resulting CV accuracy for each. Leakage inflates the OLD
# number; the gap is largest for small n / LOO -- the regime the package targets.
#
# Run from the PACKAGE ROOT:  source("dev/leakage_check.R")

pkgload::load_all(quiet = TRUE)

set.seed(1)
patterns <- c("sharp", "diffuse", "clustered", "random")
n <- 6 # small per-class count -> strong leakage regime

landscapes <- create_landscapes(n = n, patterns = patterns, width = 40, height = 40)
metrics <- calculate_metrics(landscapes = landscapes, level = "landscape")

wide <- metrics_to_wide(metrics)
all_pred_cols <- setdiff(names(wide), c("landscape_id", "landscape_name", "pattern"))
# Keep only fully-complete, non-constant metric columns so no class is dropped by
# NA handling (an artefact of this small demo, not of the package).
complete <- all_pred_cols[colSums(is.na(wide[all_pred_cols])) == 0]
non_const <- complete[vapply(wide[complete], \(x) stats::sd(x) > 0, logical(1))]
pred_cols <- head(non_const, 8)

class_names <- sort(unique(wide$pattern))
predictors <- wide[, pred_cols, drop = FALSE]
pattern <- factor(wide$pattern, levels = class_names)

# Leave-one-out folds -- worst case for leakage.
fold_indices <- seq_len(nrow(wide))

fit_predict <- function(train_data, val_data) {
  model <- fit_nn_model(train_data, hidden = 6, threshold = 0.01, stepmax = 1e5)
  raw <- predict(model, newdata = val_data[, pred_cols, drop = FALSE])
  probs <- softmax_rows(raw)
  # neuralnet emits one column per class present in the training fold, in level
  # order -- name by those (a fold may miss a class in this small demo).
  colnames(probs) <- levels(droplevels(train_data$pattern))
  colnames(probs)[max.col(probs, ties.method = "first")]
}

# OLD: full-data scaling once, then CV over the already-scaled data.
scaled_full <- scale(predictors)
old_full <- data.frame(scaled_full, pattern = pattern)

old_correct <- 0L
new_correct <- 0L
for (fold in fold_indices) {
  tr <- fold_indices != fold
  va <- fold_indices == fold

  # OLD path
  old_pred <- fit_predict(old_full[tr, ], old_full[va, , drop = FALSE])
  old_correct <- old_correct + sum(old_pred == as.character(pattern[va]))

  # NEW path: fold-internal scaling
  fs <- scale_fold(predictors[tr, , drop = FALSE], predictors[va, , drop = FALSE])
  new_tr <- data.frame(fs$train, pattern = pattern[tr])
  new_va <- data.frame(fs$val, pattern = pattern[va])
  new_pred <- fit_predict(new_tr, new_va)
  new_correct <- new_correct + sum(new_pred == as.character(pattern[va]))
}

n_total <- length(fold_indices)
cli::cli_h1("CV feature-scaling leakage (LOO, {n} per class x {length(patterns)} classes)")
cli::cli_alert_info("OLD (full-data scaling, leaks): accuracy = {round(old_correct / n_total, 4)}")
cli::cli_alert_info("NEW (fold-internal scaling):     accuracy = {round(new_correct / n_total, 4)}")
cli::cli_alert_info("Optimistic bias removed:         {round((old_correct - new_correct) / n_total, 4)}")
