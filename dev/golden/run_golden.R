# Golden regression harness -- shared run function.
#
# Runs a SMALL, FAST version of both classification workflows (metrics-based and
# pixel-based) and returns the results we want to stay stable across refactors.
# It mirrors the analysis use-case scripts (classify_ecotones_*) but scaled down
# so it runs in seconds and can be run often.
#
# Used by:
#   capture.R -- freeze these results as the reference (run on the baseline)
#   check.R   -- re-run and compare current code against the reference
#
# Run from the PACKAGE ROOT. Uses the LOCAL package source via load_all(), so it
# always tests the code you are currently editing.

run_golden <- function() {
  pkgload::load_all(quiet = TRUE)

  # Small, deterministic settings (2 ecotone + 1 self-organized pattern) --------
  patterns <- c("sharp", "random", "spots")
  n        <- 10
  size     <- 40

  # Create identical train/test landscapes (seed shared by both workflows) ------
  set.seed(42)
  train <- create_landscapes(n = n, patterns = patterns, width = size, height = size)
  test  <- create_landscapes(n = n, patterns = patterns, width = size, height = size)

  # Metrics-based workflow -- deterministic, so compared EXACTLY ----------------
  metrics  <- calculate_metrics(landscapes = train, level = "landscape")
  selected <- evaluate_landscape_metrics(metrics = metrics, metrics_number = 5)

  model <- train_metrics_model(
    metrics          = metrics,
    metrics_selected = selected,
    hidden_layers    = c(6),
    cv_method        = "k-fold",
    cv_folds         = 2,
    verbose          = FALSE
  )
  validation <- apply_metrics_model(
    landscapes         = test,
    nn_model           = model,
    return_performance = TRUE
  )

  # Pixel-based workflow -- keras is reproducible across sessions on the same
  # machine (verified), so its results are compared EXACTLY too -----------------
  set_random_seed(4231)
  model_pix <- train_pixels_model(
    landscapes = train,
    cv_method  = "k-fold",
    cv_folds   = 2,
    epochs     = 3,
    verbose    = FALSE
  )
  validation_pix <- apply_pixels_model(
    landscapes         = test,
    nn_model           = model_pix,
    return_performance = TRUE,
    verbose            = FALSE
  )

  # Collect reference values ----------------------------------------------------
  list(
    # Metrics workflow: exact values
    metrics_table    = metrics,
    metrics_selected = selected,
    train_accuracy   = model$performance$accuracy,
    train_confusion  = model$performance$confusion_matrix,
    test_accuracy    = validation$performance$accuracy,
    test_confusion   = validation$performance$confusion_matrix,
    test_predictions = validation$predictions[, c("predicted_class", "confidence")],

    # Pixel workflow: exact values (keras reproducible on the same machine)
    pix_accuracy    = validation_pix$performance$accuracy,
    pix_confusion   = validation_pix$performance$confusion_matrix,
    pix_predictions = validation_pix$predictions
  )
}
