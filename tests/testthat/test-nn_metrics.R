# Tests for train_nn_metrics() and apply_nn_metrics()

# Load fixtures once for all tests
fixtures <- load_metrics_fixtures()

# Input validation tests -------------------------------------------------------

test_that("train_nn_metrics validates verbose parameter", {
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, verbose = "yes"),
    "verbose must be a single logical value"
  )
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, verbose = c(TRUE, FALSE)),
    "verbose must be a single logical value"
  )
})

test_that("train_nn_metrics validates hidden_layers parameter", {
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, hidden_layers = -1),
    "hidden_layers must be positive integer"
  )
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, hidden_layers = 1.5),
    "hidden_layers must be positive integer"
  )
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, hidden_layers = c(5, -1)),
    "hidden_layers must be positive integer"
  )
})

test_that("train_nn_metrics validates threshold parameter", {
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, threshold = -0.01),
    "threshold must be a single positive numeric"
  )
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, threshold = c(0.01, 0.02)),
    "threshold must be a single positive numeric"
  )
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, threshold = 0),
    "threshold must be a single positive numeric"
  )
})

test_that("train_nn_metrics validates stepmax parameter", {
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, stepmax = -100),
    "stepmax must be a single positive integer"
  )
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, stepmax = 1.5),
    "stepmax must be a single positive integer"
  )
})

test_that("train_nn_metrics validates model_path parameter", {
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, model_path = "model.txt"),
    "model_path must end with .rds"
  )
  expect_error(
    train_nn_metrics(
      fixtures$minimal_metrics,
      model_path = c("a.rds", "b.rds")
    ),
    "model_path must be a single character string"
  )
})

test_that("train_nn_metrics validates cv_method parameter", {
  expect_error(
    train_nn_metrics(fixtures$minimal_metrics, cv_method = "invalid"),
    'cv_method must be one of: "none", "k-fold", or "loo"'
  )
})

test_that("train_nn_metrics validates metrics data structure", {
  bad_metrics <- fixtures$minimal_metrics |>
    dplyr::select(-pattern)

  expect_error(
    train_nn_metrics(bad_metrics),
    "Metrics data is missing required columns"
  )
})

test_that("train_nn_metrics validates metrics_selected exists in data", {
  expect_error(
    train_nn_metrics(
      fixtures$minimal_metrics,
      metrics_selected = c("nonexistent_metric", "another_fake")
    ),
    "Some selected metrics not found in data"
  )
})

# Core functionality tests -----------------------------------------------------

test_that("train_nn_metrics trains model without CV", {
  result <- train_nn_metrics(
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
      "performance"
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
})

test_that("train_nn_metrics trains with k-fold CV", {
  result <- train_nn_metrics(
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
      "confidence"
    ) %in%
      names(result$performance$validation_results)
  ))
})

test_that("train_nn_metrics trains with LOO CV", {
  result <- train_nn_metrics(
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

test_that("train_nn_metrics respects metrics_selected parameter", {
  # Get first 5 unique metrics
  available_metrics <- unique(fixtures$small_metrics_landscape$metric)
  selected_metrics <- available_metrics[1:5]

  result <- train_nn_metrics(
    fixtures$small_metrics_landscape,
    metrics_selected = selected_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Features should match selected metrics
  expect_equal(length(result$features), length(selected_metrics))
  expect_true(all(result$features %in% selected_metrics))
})

test_that("train_nn_metrics works with landscape level metrics", {
  result <- train_nn_metrics(
    fixtures$small_metrics_landscape,
    cv_method = "none",
    verbose = FALSE
  )

  expect_equal(result$features_level, "landscape")
})

test_that("train_nn_metrics works with class level metrics", {
  # Filter to single class for consistency
  metrics_class_filtered <- fixtures$small_metrics_class |>
    dplyr::filter(class == 0)

  result <- train_nn_metrics(
    metrics_class_filtered,
    cv_method = "none",
    verbose = FALSE
  )

  expect_equal(result$features_level, "class")
})

test_that("train_nn_metrics handles custom hidden_layers configuration", {
  # Single layer with 10 neurons
  result_single <- train_nn_metrics(
    fixtures$minimal_metrics,
    hidden_layers = 10,
    cv_method = "none",
    verbose = FALSE
  )
  expect_s3_class(result_single$model, "nn")

  # Multiple layers
  result_multi <- train_nn_metrics(
    fixtures$minimal_metrics,
    hidden_layers = c(8, 4),
    cv_method = "none",
    verbose = FALSE
  )
  expect_s3_class(result_multi$model, "nn")
})

test_that("train_nn_metrics saves model when model_path provided", {
  temp_file <- tempfile(fileext = ".rds")

  result <- train_nn_metrics(
    fixtures$minimal_metrics,
    model_path = temp_file,
    cv_method = "none",
    verbose = FALSE
  )

  # File should exist
  expect_true(file.exists(temp_file))

  # Should be able to load it
  loaded_model <- readRDS(temp_file)
  expect_equal(names(loaded_model), names(result))

  # Clean up
  unlink(temp_file)
})

# NA handling tests ------------------------------------------------------------

test_that("train_nn_metrics handles NA values correctly", {
  # Add NA to ALL metrics for first 5 landscapes (make them truly incomplete)
  metrics_with_na <- fixtures$small_metrics_landscape

  # Get landscape IDs to remove (use first 5 out of 30)
  landscapes_to_break <- unique(metrics_with_na$landscape_id)[1:2]

  # Set ALL metrics for these landscapes to NA
  metrics_with_na$value[
    metrics_with_na$landscape_id %in% landscapes_to_break
  ] <- NA

  expect_warning(
    result <- train_nn_metrics(
      metrics_with_na,
      cv_method = "none",
      verbose = FALSE
    ),
    "Removed.*landscape.*with incomplete metrics"
  )

  # Should still return valid model if landscapes remain (25 out of 30)
  expect_s3_class(result$model, "nn")
})

test_that("train_nn_metrics errors when all landscapes have NAs", {
  # Add NA to all metrics
  metrics_all_na <- fixtures$minimal_metrics
  metrics_all_na$value <- NA

  expect_error(
    train_nn_metrics(metrics_all_na, cv_method = "none", verbose = FALSE),
    "No landscapes remaining after removing those with incomplete metrics"
  )
})
