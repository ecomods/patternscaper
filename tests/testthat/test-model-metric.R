# Tests for train_metric_model() and apply_metric_model()

# Load fixtures once for all tests
fixtures <- load_metrics_fixtures()

# Input validation tests -------------------------------------------------------

test_that("train_metric_model validates verbose parameter", {
  expect_error(
    train_metric_model(fixtures$minimal_metrics, verbose = "yes"),
    "verbose must be a single logical value"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, verbose = c(TRUE, FALSE)),
    "verbose must be a single logical value"
  )
})

test_that("train_metric_model validates hidden_layers parameter", {
  expect_error(
    train_metric_model(fixtures$minimal_metrics, hidden_layers = -1),
    "hidden_layers must be positive integer"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, hidden_layers = 1.5),
    "hidden_layers must be positive integer"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, hidden_layers = c(5, -1)),
    "hidden_layers must be positive integer"
  )
})

test_that("train_metric_model validates threshold parameter", {
  expect_error(
    train_metric_model(fixtures$minimal_metrics, threshold = -0.01),
    "threshold must be a single positive numeric"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, threshold = c(0.01, 0.02)),
    "threshold must be a single positive numeric"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, threshold = 0),
    "threshold must be a single positive numeric"
  )
})

test_that("train_metric_model validates stepmax parameter", {
  expect_error(
    train_metric_model(fixtures$minimal_metrics, stepmax = -100),
    "stepmax must be a single positive integer"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, stepmax = 1.5),
    "stepmax must be a single positive integer"
  )
})

test_that("train_metric_model validates cv_method parameter", {
  expect_error(
    train_metric_model(fixtures$minimal_metrics, cv_method = "invalid"),
    'cv_method must be one of: "none", "k-fold", or "loo"'
  )
})

test_that("train_metric_model validates cv_folds parameter", {
  expect_error(
    train_metric_model(fixtures$minimal_metrics, cv_folds = 1),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, cv_folds = -3),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, cv_folds = 2.5),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_metric_model(fixtures$minimal_metrics, cv_folds = "a"),
    "cv_folds must be a single integer >= 2"
  )
})

test_that("train_metric_model validates metrics data structure", {
  bad_metrics <- fixtures$minimal_metrics |>
    dplyr::select(-pattern)

  expect_error(
    train_metric_model(bad_metrics),
    "Metrics data is missing required columns"
  )
})

test_that("train_metric_model validates metrics_selected exists in data", {
  expect_error(
    train_metric_model(
      fixtures$minimal_metrics,
      metrics_selected = c("nonexistent_metric", "another_fake")
    ),
    "Some selected metrics not found in data"
  )
})

# Core functionality tests -----------------------------------------------------

test_that("train_metric_model trains model without CV", {
  result <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Check return structure
  expect_type(result, "list")
  expect_named(
    result,
    c(
      "model",
      "features",
      "features_level",
      "scaling",
      "classes",
      "performance",
      "training_geometry"
    )
  )

  # Check model
  expect_s3_class(result$model, "nn")

  # Check features
  expect_type(result$features, "character")
  expect_gt(length(result$features), 0)

  # Check scaling parameters
  expect_type(result$scaling, "list")
  expect_named(result$scaling, c("center", "scale"))
  expect_length(result$scaling$center, length(result$features))
  expect_length(result$scaling$scale, length(result$features))

  # Check classes are alphabetically sorted
  expect_type(result$classes, "character")
  expect_equal(result$classes, sort(result$classes))

  # No performance when cv_method = "none"
  expect_null(result$performance)

  # Fixture predates geometry columns -> training_geometry is NULL, not an error
  expect_null(result$training_geometry)
})

test_that("train_metric_model stores a training_geometry summary", {
  set.seed(1)
  landscapes <- create_landscapes(
    n = 12,
    patterns = c("random", "sharp", "diffuse"),
    width = 40,
    height = 40
  )
  metrics <- calculate_metrics(
    landscapes,
    metrics = c("ai", "lsi", "ed", "contag"),
    level = "landscape"
  )
  model <- suppressWarnings(train_metric_model(
    metrics,
    metrics_selected = c("ai", "lsi", "ed"),
    cv_method = "none",
    stepmax = 1e6,
    verbose = FALSE
  ))

  expect_s3_class(model$training_geometry, "tbl_df")
  expect_equal(model$training_geometry$n_row, 40)
  expect_equal(model$training_geometry$n_col, 40)
  expect_true(model$training_geometry$homogeneous)
})

test_that("apply_metric_model warns when application geometry differs from training", {
  set.seed(1)
  train <- create_landscapes(
    n = 12,
    patterns = c("random", "sharp", "diffuse"),
    width = 40,
    height = 40
  )
  train_metrics <- calculate_metrics(
    train,
    metrics = c("ai", "lsi", "ed"),
    level = "landscape"
  )
  model <- suppressWarnings(train_metric_model(
    train_metrics,
    metrics_selected = c("ai", "lsi", "ed"),
    cv_method = "none",
    stepmax = 1e6,
    verbose = FALSE
  ))

  # Apply to 80x80 landscapes: 2x the training extent -> extent warning
  bigger <- create_landscapes(
    n = 4,
    patterns = c("random", "sharp"),
    width = 80,
    height = 80
  )
  w <- capture_warnings(apply_metric_model(bigger, model, verbose = FALSE))
  expect_true(any(grepl("training extent", w)))
})

test_that("train_metric_model warns when training landscapes differ in geometry", {
  set.seed(1)
  mixed <- c(
    create_landscapes(n = 6, patterns = c("random", "sharp"), width = 30, height = 30),
    create_landscapes(n = 6, patterns = c("random", "sharp"), width = 40, height = 40)
  )
  metrics <- calculate_metrics(
    mixed,
    metrics = c("ai", "lsi", "ed"),
    level = "landscape"
  )
  expect_warning(
    train_metric_model(
      metrics,
      metrics_selected = c("ai", "lsi", "ed"),
      cv_method = "none",
      stepmax = 1e6,
      verbose = FALSE
    ),
    "differ in extent or resolution"
  )
})

test_that("train_metric_model trains with k-fold CV", {
  result <- train_metric_model(
    fixtures$small_metrics_landscape,
    cv_method = "k-fold",
    cv_folds = 3,
    verbose = FALSE
  )

  # Should have performance results
  expect_type(result$performance, "list")
  expect_named(
    result$performance,
    c(
      "confusion_matrix",
      "accuracy",
      "per_class_metrics",
      "cv_method",
      "cv_folds",
      "class_counts",
      "validation_results"
    )
  )

  # Accuracy should be between 0 and 1
  expect_gte(result$performance$accuracy, 0)
  expect_lte(result$performance$accuracy, 1)

  # Validation results should have all landscapes
  expect_equal(
    nrow(result$performance$validation_results),
    length(unique(fixtures$small_metrics_landscape$landscape_id))
  )

  # Check validation results structure
  expect_true(all(
    c(
      "landscape_id",
      "fold",
      "actual_class",
      "predicted_class",
      "score"
    ) %in%
      names(result$performance$validation_results)
  ))
})

test_that("train_metric_model trains with LOO CV", {
  result <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "loo",
    verbose = FALSE
  )

  # Should have performance results
  expect_type(result$performance, "list")
  expect_equal(result$performance$cv_method, "loo")

  # Number of folds should equal number of samples
  n_samples <- length(unique(fixtures$minimal_metrics$landscape_id))
  expect_equal(result$performance$cv_folds, n_samples)
})

test_that("train_metric_model runs k-fold CV with a single predictor metric", {
  available_metrics <- unique(fixtures$small_metrics_landscape$metric)

  result <- train_metric_model(
    fixtures$small_metrics_landscape,
    metrics_selected = available_metrics[1],
    cv_method = "k-fold",
    cv_folds = 3,
    verbose = FALSE
  )

  expect_equal(result$features, available_metrics[1])
  expect_gte(result$performance$accuracy, 0)
  expect_lte(result$performance$accuracy, 1)
})

test_that("train_metric_model respects metrics_selected parameter", {
  # Get first 5 unique metrics
  available_metrics <- unique(fixtures$small_metrics_landscape$metric)
  selected_metrics <- available_metrics[1:5]

  result <- train_metric_model(
    fixtures$small_metrics_landscape,
    metrics_selected = selected_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Features should match selected metrics
  expect_equal(length(result$features), length(selected_metrics))
  expect_true(all(result$features %in% selected_metrics))
})

test_that("train_metric_model works with landscape level metrics", {
  result <- train_metric_model(
    fixtures$small_metrics_landscape,
    cv_method = "none",
    verbose = FALSE
  )

  expect_equal(result$features_level, "landscape")
})

test_that("train_metric_model works with class level metrics", {
  # Filter to single class for consistency
  metrics_class_filtered <- fixtures$small_metrics_class |>
    dplyr::filter(class == 0)

  result <- train_metric_model(
    metrics_class_filtered,
    cv_method = "none",
    verbose = FALSE
  )

  expect_equal(result$features_level, "class")
})

test_that("train_metric_model handles custom hidden_layers configuration", {
  # Single layer with 10 neurons
  result_single <- train_metric_model(
    fixtures$minimal_metrics,
    hidden_layers = 10,
    cv_method = "none",
    verbose = FALSE
  )
  expect_s3_class(result_single$model, "nn")

  # Multiple layers
  result_multi <- train_metric_model(
    fixtures$minimal_metrics,
    hidden_layers = c(8, 4),
    cv_method = "none",
    verbose = FALSE
  )
  expect_s3_class(result_multi$model, "nn")
})

# NA handling tests ------------------------------------------------------------

test_that("train_metric_model handles NA values correctly", {
  # Add NA to ALL metrics for first 5 landscapes (make them truly incomplete)
  metrics_with_na <- fixtures$small_metrics_landscape

  # Get landscape IDs to remove (use first 5 out of 30)
  landscapes_to_break <- unique(metrics_with_na$landscape_id)[1:2]

  # Set ALL metrics for these landscapes to NA
  metrics_with_na$value[
    metrics_with_na$landscape_id %in% landscapes_to_break
  ] <- NA

  expect_warning(
    result <- train_metric_model(
      metrics_with_na,
      cv_method = "none",
      verbose = FALSE
    ),
    "Removed.*landscape.*where every required metric was NA"
  )

  # Should still return valid model if landscapes remain (25 out of 30)
  expect_s3_class(result$model, "nn")
})

test_that("train_metric_model separates unusable from partly incomplete landscapes", {
  metrics <- fixtures$small_metrics_landscape
  landscape_ids <- unique(metrics$landscape_id)
  first_metric <- unique(metrics$metric)[1]

  # One landscape has no usable metric at all
  metrics$value[metrics$landscape_id == landscape_ids[1]] <- NA
  # Another is missing a single metric only
  metrics$value[
    metrics$landscape_id == landscape_ids[2] &
      metrics$metric == first_metric
  ] <- NA

  warnings <- capture_warnings(
    train_metric_model(metrics, cv_method = "none", verbose = FALSE)
  )

  # The two cases are reported separately, since the remedy differs. The
  # no-information landscape always goes; the partly incomplete one costs a
  # metric under the default na_action.
  expect_match(warnings, "where every required metric was NA", all = FALSE)
  expect_match(warnings, "missing for some landscapes", all = FALSE)
})

test_that("train_metric_model validates na_action parameter", {
  expect_error(
    train_metric_model(
      fixtures$small_metrics_landscape,
      cv_method = "none",
      na_action = "drop_everything",
      verbose = FALSE
    ),
    "na_action must be one of"
  )
})

test_that("train_metric_model na_action chooses which side to sacrifice", {
  metrics <- fixtures$small_metrics_landscape
  landscape_ids <- unique(metrics$landscape_id)
  first_metric <- unique(metrics$metric)[1]

  # A single landscape is missing a single metric
  metrics$value[
    metrics$landscape_id == landscape_ids[1] &
      metrics$metric == first_metric
  ] <- NA

  n_landscapes <- length(landscape_ids)
  n_metrics <- length(unique(metrics$metric))

  # Default drops the metric and keeps every landscape
  expect_warning(
    dropped_metric <- train_metric_model(
      metrics,
      cv_method = "none",
      verbose = FALSE
    ),
    "missing for some landscapes"
  )
  expect_false(first_metric %in% dropped_metric$features)
  expect_equal(length(dropped_metric$features), n_metrics - 1)

  # Opting out keeps every metric and drops the landscape instead
  expect_warning(
    dropped_landscape <- train_metric_model(
      metrics,
      cv_method = "none",
      na_action = "drop_landscapes",
      verbose = FALSE
    ),
    "with incomplete metrics"
  )
  expect_true(first_metric %in% dropped_landscape$features)
  expect_equal(length(dropped_landscape$features), n_metrics)

  # Both warnings state the cost of the alternative
  metric_warning <- capture_warnings(
    train_metric_model(metrics, cv_method = "none", verbose = FALSE)
  )
  expect_match(metric_warning, "drop_landscapes", all = FALSE)
})

test_that("train_metric_model aborts when a pattern is lost entirely", {
  metrics <- fixtures$small_metrics_landscape
  first_metric <- unique(metrics$metric)[1]
  lost_pattern <- unique(metrics$pattern)[1]

  # Every landscape of one pattern is missing the same single metric, so
  # dropping landscapes would remove that pattern from the training set
  metrics$value[
    metrics$pattern == lost_pattern & metrics$metric == first_metric
  ] <- NA

  expect_error(
    suppressWarnings(train_metric_model(
      metrics,
      cv_method = "none",
      na_action = "drop_landscapes",
      verbose = FALSE
    )),
    "eliminated 1 pattern entirely"
  )

  # The default resolves the same data without losing the pattern
  expect_warning(
    result <- train_metric_model(metrics, cv_method = "none", verbose = FALSE),
    "missing for some landscapes"
  )
  expect_true(lost_pattern %in% result$classes)
})

test_that("train_metric_model errors when all landscapes have NAs", {
  # Add NA to all metrics
  metrics_all_na <- fixtures$minimal_metrics
  metrics_all_na$value <- NA

  expect_error(
    train_metric_model(metrics_all_na, cv_method = "none", verbose = FALSE),
    "No landscapes remaining after removing those with incomplete metrics"
  )
})

# apply_metric_model tests ---------------------------------------------------

test_that("apply_metric_model can be silenced with verbose = FALSE", {
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )
  minimal_landscapes <- create_fixture_landscapes("minimal")

  expect_error(
    apply_metric_model(minimal_landscapes, model, verbose = "yes"),
    "verbose must be a single logical value"
  )

  expect_silent(
    suppressWarnings(
      apply_metric_model(
        minimal_landscapes,
        model,
        verbose = FALSE
      )
    )
  )

  # The performance summary is still printed by default
  expect_output(
    suppressWarnings(
      apply_metric_model(
        minimal_landscapes,
        model
      )
    )
  )
})

test_that("apply_metric_model validates evaluate parameter", {
  # Train a simple model first
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  expect_error(
    apply_metric_model(minimal_landscapes, model, evaluate = "yes"),
    'evaluate must be one of: "auto", "required", or "none"'
  )

  expect_error(
    apply_metric_model(minimal_landscapes, model, evaluate = c("auto", "none")),
    'evaluate must be one of: "auto", "required", or "none"'
  )

  expect_error(
    apply_metric_model(minimal_landscapes, model, evaluate = TRUE),
    'evaluate must be one of: "auto", "required", or "none"'
  )

  # Accepted case-insensitively, like cv_method
  expect_no_error(
    suppressWarnings(
      apply_metric_model(
        minimal_landscapes,
        model,
        evaluate = "NONE",
        verbose = FALSE
      )
    )
  )
})

test_that("apply_metric_model return shape does not depend on the data", {
  # The whole point of the contract: a caller can tell what came back without
  # inspecting it, whatever the landscapes happen to carry.
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )
  minimal_landscapes <- create_fixture_landscapes("minimal")

  labelled <- minimal_landscapes
  unlabelled <- lapply(minimal_landscapes, \(l) {
    l$pattern <- "unclassified"
    l
  })

  cases <- list(
    labelled_auto = list(unlabelled = FALSE, evaluate = "auto"),
    labelled_none = list(unlabelled = FALSE, evaluate = "none"),
    unlabelled_auto = list(unlabelled = TRUE, evaluate = "auto"),
    unlabelled_none = list(unlabelled = TRUE, evaluate = "none")
  )

  for (case_name in names(cases)) {
    case <- cases[[case_name]]
    result <- suppressWarnings(apply_metric_model(
      if (case$unlabelled) unlabelled else labelled,
      model,
      evaluate = case$evaluate,
      verbose = FALSE
    ))

    expect_type(result, "list")
    expect_named(result, c("predictions", "performance"), info = case_name)
    expect_s3_class(result$predictions, "tbl_df")
    expect_equal(
      nrow(result$predictions),
      length(minimal_landscapes),
      info = case_name
    )

    # Performance is present exactly when there was ground truth to score and
    # the caller did not opt out
    scored_expected <- !case$unlabelled && case$evaluate != "none"
    expect_equal(!is.null(result$performance), scored_expected, info = case_name)
  }
})

test_that("apply_metric_model validates nn_model structure", {
  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  expect_error(
    apply_metric_model(
      minimal_landscapes,
      list(model = "not a model")
    ),
    "'nn_model' must be a trained model from train_metric_model()"
  )

  expect_error(
    apply_metric_model(
      minimal_landscapes,
      "not a list"
    ),
    "'nn_model' must be a trained model from train_metric_model()"
  )
})

test_that("apply_metric_model validates landscapes parameter", {
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  expect_error(
    apply_metric_model(
      "not a landscape",
      model
    ),
    "'landscapes' must be a landscape object or list of landscapes"
  )

  expect_error(
    apply_metric_model(
      data.frame(x = 1),
      model
    ),
    "All elements must be landscape objects"
  )
})

test_that("apply_metric_model works with single landscape", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply to single landscape
  result <- apply_metric_model(
    minimal_landscapes[[1]],
    model,
    evaluate = "none"
  )$predictions

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_true(all(
    c("landscape_id", "predicted_class", "score") %in% names(result)
  ))

  # Check predictions
  expect_true(result$predicted_class %in% model$classes)
  expect_gte(result$score, 0)
  expect_lte(result$score, 1)

  # Should have probability columns for each class
  expect_true(all(model$classes %in% names(result)))
})

test_that("apply_metric_model works with list of landscapes", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply to list of landscapes
  result <- apply_metric_model(
    minimal_landscapes,
    model,
    evaluate = "none"
  )$predictions

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), length(minimal_landscapes))

  # All predictions should be valid classes
  expect_true(all(result$predicted_class %in% model$classes))
})

test_that("apply_metric_model reports the class that has the highest score", {
  # predicted_class is taken from the RAW network outputs so that the reporting
  # transform can never move a class boundary, which is what keeps accuracy
  # independent of how scores are presented. That leaves a gap: a future
  # transform that is not order-preserving would make the reported class
  # disagree with the reported scores without anything failing. This test closes
  # it -- the two must always agree.
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )
  minimal_landscapes <- create_fixture_landscapes("minimal")

  result <- apply_metric_model(
    minimal_landscapes,
    model,
    evaluate = "none"
  )$predictions

  scores <- as.matrix(result[, model$classes])
  highest_scoring <- model$classes[max.col(scores, ties.method = "first")]

  expect_equal(result$predicted_class, highest_scoring)
  expect_equal(result$score, apply(scores, 1, max))
  expect_equal(rowSums(scores), rep(1, nrow(scores)), tolerance = 1e-10)
})

test_that("apply_metric_model scores automatically when classes are known", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply with performance evaluation
  result <- apply_metric_model(minimal_landscapes, model)

  # Should return a list with predictions and performance
  expect_type(result, "list")
  expect_named(result, c("predictions", "performance"))

  # Check predictions
  expect_s3_class(result$predictions, "tbl_df")
  expect_true("actual_class" %in% names(result$predictions))

  # Check performance
  expect_type(result$performance, "list")
  expect_true(all(
    c("confusion_matrix", "accuracy", "per_class_metrics") %in%
      names(result$performance)
  ))

  # Accuracy should be valid
  expect_gte(result$performance$accuracy, 0)
  expect_lte(result$performance$accuracy, 1)
})

test_that("apply_metric_model returns NULL performance when classes unknown", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Remove pattern from landscapes to simulate unknown classes
  for (i in seq_along(minimal_landscapes)) {
    minimal_landscapes[[i]]$pattern <- "unclassified"
  }

  # The return shape does not depend on whether anything could be scored
  result <- apply_metric_model(minimal_landscapes, model)

  expect_type(result, "list")
  expect_named(result, c("predictions", "performance"))
  expect_s3_class(result$predictions, "tbl_df")
  expect_null(result$performance)

  # "required" turns the same situation into an error
  expect_error(
    apply_metric_model(minimal_landscapes, model, evaluate = "required"),
    "no landscape has a known true class"
  )
})

test_that("apply_metric_model warns about unknown classes", {
  # Use balanced fixture which has more classes
  if (length(unique(fixtures$balanced_metrics$pattern)) > 2) {
    # Train on subset of classes
    metrics_subset <- fixtures$balanced_metrics |>
      dplyr::filter(pattern %in% c("spots", "labyrinth"))

    model_subset <- train_metric_model(
      metrics_subset,
      cv_method = "none",
      verbose = FALSE
    )

    # Create balanced landscapes
    balanced_landscapes <- create_fixture_landscapes("balanced")

    # Get landscapes with different class
    other_class <- setdiff(
      unique(fixtures$balanced_metrics$pattern),
      c("spots", "labyrinth")
    )[1]

    landscapes_other <- balanced_landscapes[
      sapply(balanced_landscapes, function(x) x$pattern == other_class)
    ][1]

    # Should warn about unknown class
    expect_warning(
      result <- apply_metric_model(landscapes_other, model_subset),
      "Input landscapes contain classes not seen during training"
    )

    # Predictions are still returned in full, but nothing is scored: evaluating
    # only the recognized landscapes would drop guaranteed errors from the
    # denominator and overstate the accuracy.
    expect_named(result, c("predictions", "performance"))
    expect_s3_class(result$predictions, "tbl_df")
    expect_equal(nrow(result$predictions), length(landscapes_other))
    expect_null(result$performance)

    # "required" turns the same situation into an error
    expect_error(
      apply_metric_model(
        landscapes_other,
        model_subset,
        evaluate = "required"
      ),
      "true class the model never saw"
    )

    # "none" skips scoring entirely, so the warning never fires
    expect_warning(
      apply_metric_model(landscapes_other, model_subset, evaluate = "none"),
      NA
    )
  }
})

test_that("apply_metric_model works with class-level metrics", {
  # Filter to single class
  metrics_class <- fixtures$small_metrics_class |>
    dplyr::filter(class == 0)

  # Train model
  model <- train_metric_model(
    metrics_class,
    cv_method = "none",
    verbose = FALSE
  )

  # Create small landscapes
  small_landscapes <- create_fixture_landscapes("small")

  # Apply model
  result <- apply_metric_model(
    small_landscapes[1:3],
    model,
    evaluate = "none"
  )$predictions

  # Should work with class-level features
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(model$features_level, "class")
})

test_that("apply_metric_model returns unclassifiable landscapes as NA", {
  skip_if_not_installed("landscapemetrics")

  set.seed(7)
  size <- 20
  make_mixed <- function(pattern, i) {
    landscape(
      matrix(rbinom(size^2, 1, if (pattern == "sparse") 0.3 else 0.7), size, size),
      pattern = pattern,
      name = paste0(pattern, "_", i)
    )
  }

  # Train on landscapes that all contain both classes
  train_landscapes <- c(
    lapply(1:6, \(i) make_mixed("sparse", i)),
    lapply(1:6, \(i) make_mixed("dense", i))
  )
  metrics <- calculate_metrics(
    train_landscapes,
    metrics = c("ai", "pland"),
    level = "class"
  )
  model <- train_metric_model(metrics, cv_method = "none", verbose = FALSE)

  # One new landscape is fully vegetated, so class 0 is absent from it
  new_landscapes <- c(
    lapply(1:3, \(i) make_mixed("sparse", paste0("new", i))),
    list(landscape(matrix(1L, size, size), name = "new_full"))
  )

  expect_warning(
    result <- apply_metric_model(new_landscapes, model, evaluate = "none")$predictions,
    "Could not classify 1 landscape"
  )

  # Every input landscape is present, not just the classifiable ones
  expect_equal(nrow(result), 4)
  expect_true("new_full" %in% result$landscape_name)

  unclassified <- result[result$landscape_name == "new_full", ]
  expect_true(is.na(unclassified$predicted_class))
  expect_true(is.na(unclassified$score))
  expect_true(all(is.na(unclassified[, model$classes])))

  # The other landscapes are classified normally
  classified <- result[result$landscape_name != "new_full", ]
  expect_false(any(is.na(classified$predicted_class)))
  expect_false(any(is.na(classified$score)))
})

test_that("apply_metric_model errors when metrics cannot be calculated", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create minimal landscapes
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Create invalid landscape (empty raster)
  invalid_landscape <- minimal_landscapes[[1]]
  invalid_landscape$data <- terra::rast(matrix(NA, 10, 10))

  # Should error when trying to calculate metrics
  expect_error(
    apply_metric_model(
      invalid_landscape,
      model,
      evaluate = "none"
    )
  )
})

test_that("apply_metric_model includes landscape_name when available", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create minimal landscapes
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply model
  result <- apply_metric_model(
    minimal_landscapes,
    model,
    evaluate = "none"
  )$predictions

  # Should include landscape_name if present
  if ("name" %in% names(minimal_landscapes[[1]])) {
    expect_true("landscape_name" %in% names(result))
  }
})

test_that("apply_metric_model maintains landscape order", {
  # Train model
  model <- train_metric_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create minimal landscapes
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply model
  result <- apply_metric_model(
    minimal_landscapes,
    model,
    evaluate = "none"
  )$predictions

  # landscape_id should match input order
  expect_equal(
    result$landscape_id,
    seq_along(minimal_landscapes)
  )
})
