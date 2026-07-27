# Tests for train_metrics_model() and apply_metrics_model()

# Load fixtures once for all tests
fixtures <- load_metrics_fixtures()

# Input validation tests -------------------------------------------------------

test_that("train_metrics_model validates verbose parameter", {
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, verbose = "yes"),
    "verbose must be a single logical value"
  )
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, verbose = c(TRUE, FALSE)),
    "verbose must be a single logical value"
  )
})

test_that("train_metrics_model validates hidden_layers parameter", {
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, hidden_layers = -1),
    "hidden_layers must be positive integer"
  )
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, hidden_layers = 1.5),
    "hidden_layers must be positive integer"
  )
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, hidden_layers = c(5, -1)),
    "hidden_layers must be positive integer"
  )
})

test_that("train_metrics_model validates threshold parameter", {
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, threshold = -0.01),
    "threshold must be a single positive numeric"
  )
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, threshold = c(0.01, 0.02)),
    "threshold must be a single positive numeric"
  )
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, threshold = 0),
    "threshold must be a single positive numeric"
  )
})

test_that("train_metrics_model validates stepmax parameter", {
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, stepmax = -100),
    "stepmax must be a single positive integer"
  )
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, stepmax = 1.5),
    "stepmax must be a single positive integer"
  )
})

test_that("train_metrics_model validates model_path parameter", {
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, model_path = "model.txt"),
    "model_path must end with .rds"
  )
  expect_error(
    train_metrics_model(
      fixtures$minimal_metrics,
      model_path = c("a.rds", "b.rds")
    ),
    "model_path must be a single character string"
  )
})

test_that("train_metrics_model validates cv_method parameter", {
  expect_error(
    train_metrics_model(fixtures$minimal_metrics, cv_method = "invalid"),
    'cv_method must be one of: "none", "k-fold", or "loo"'
  )
})

test_that("train_metrics_model validates metrics data structure", {
  bad_metrics <- fixtures$minimal_metrics |>
    dplyr::select(-pattern)

  expect_error(
    train_metrics_model(bad_metrics),
    "Metrics data is missing required columns"
  )
})

test_that("train_metrics_model validates metrics_selected exists in data", {
  expect_error(
    train_metrics_model(
      fixtures$minimal_metrics,
      metrics_selected = c("nonexistent_metric", "another_fake")
    ),
    "Some selected metrics not found in data"
  )
})

# Core functionality tests -----------------------------------------------------

test_that("train_metrics_model trains model without CV", {
  result <- train_metrics_model(
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

test_that("train_metrics_model trains with k-fold CV", {
  result <- train_metrics_model(
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

test_that("train_metrics_model trains with LOO CV", {
  result <- train_metrics_model(
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

test_that("train_metrics_model respects metrics_selected parameter", {
  # Get first 5 unique metrics
  available_metrics <- unique(fixtures$small_metrics_landscape$metric)
  selected_metrics <- available_metrics[1:5]

  result <- train_metrics_model(
    fixtures$small_metrics_landscape,
    metrics_selected = selected_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Features should match selected metrics
  expect_equal(length(result$features), length(selected_metrics))
  expect_true(all(result$features %in% selected_metrics))
})

test_that("train_metrics_model works with landscape level metrics", {
  result <- train_metrics_model(
    fixtures$small_metrics_landscape,
    cv_method = "none",
    verbose = FALSE
  )

  expect_equal(result$features_level, "landscape")
})

test_that("train_metrics_model works with class level metrics", {
  # Filter to single class for consistency
  metrics_class_filtered <- fixtures$small_metrics_class |>
    dplyr::filter(class == 0)

  result <- train_metrics_model(
    metrics_class_filtered,
    cv_method = "none",
    verbose = FALSE
  )

  expect_equal(result$features_level, "class")
})

test_that("train_metrics_model handles custom hidden_layers configuration", {
  # Single layer with 10 neurons
  result_single <- train_metrics_model(
    fixtures$minimal_metrics,
    hidden_layers = 10,
    cv_method = "none",
    verbose = FALSE
  )
  expect_s3_class(result_single$model, "nn")

  # Multiple layers
  result_multi <- train_metrics_model(
    fixtures$minimal_metrics,
    hidden_layers = c(8, 4),
    cv_method = "none",
    verbose = FALSE
  )
  expect_s3_class(result_multi$model, "nn")
})

test_that("train_metrics_model saves model when model_path provided", {
  temp_file <- tempfile(fileext = ".rds")

  result <- train_metrics_model(
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

test_that("train_metrics_model handles NA values correctly", {
  # Add NA to ALL metrics for first 5 landscapes (make them truly incomplete)
  metrics_with_na <- fixtures$small_metrics_landscape

  # Get landscape IDs to remove (use first 5 out of 30)
  landscapes_to_break <- unique(metrics_with_na$landscape_id)[1:2]

  # Set ALL metrics for these landscapes to NA
  metrics_with_na$value[
    metrics_with_na$landscape_id %in% landscapes_to_break
  ] <- NA

  expect_warning(
    result <- train_metrics_model(
      metrics_with_na,
      cv_method = "none",
      verbose = FALSE
    ),
    "Removed.*landscape.*with incomplete metrics"
  )

  # Should still return valid model if landscapes remain (25 out of 30)
  expect_s3_class(result$model, "nn")
})

test_that("train_metrics_model errors when all landscapes have NAs", {
  # Add NA to all metrics
  metrics_all_na <- fixtures$minimal_metrics
  metrics_all_na$value <- NA

  expect_error(
    train_metrics_model(metrics_all_na, cv_method = "none", verbose = FALSE),
    "No landscapes remaining after removing those with incomplete metrics"
  )
})

# apply_metrics_model tests ---------------------------------------------------

test_that("apply_metrics_model can be silenced with verbose = FALSE", {
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )
  minimal_landscapes <- create_fixture_landscapes("minimal")

  expect_error(
    apply_metrics_model(minimal_landscapes, model, verbose = "yes"),
    "verbose must be a single logical value"
  )

  expect_silent(
    suppressWarnings(
      apply_metrics_model(
        minimal_landscapes,
        model,
        return_performance = TRUE,
        verbose = FALSE
      )
    )
  )

  # The performance summary is still printed by default
  expect_output(
    suppressWarnings(
      apply_metrics_model(
        minimal_landscapes,
        model,
        return_performance = TRUE
      )
    )
  )
})

test_that("apply_metrics_model validates return_performance parameter", {
  # Train a simple model first
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  expect_error(
    apply_metrics_model(
      minimal_landscapes,
      model,
      return_performance = "yes"
    ),
    "return_performance must be a single logical value"
  )

  expect_error(
    apply_metrics_model(
      minimal_landscapes,
      model,
      return_performance = c(TRUE, FALSE)
    ),
    "return_performance must be a single logical value"
  )
})

test_that("apply_metrics_model validates nn_model structure", {
  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  expect_error(
    apply_metrics_model(
      minimal_landscapes,
      list(model = "not a model")
    ),
    "'nn_model' must be a trained model from train_metrics_model()"
  )

  expect_error(
    apply_metrics_model(
      minimal_landscapes,
      "not a list"
    ),
    "'nn_model' must be a trained model from train_metrics_model()"
  )
})

test_that("apply_metrics_model validates landscapes parameter", {
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  expect_error(
    apply_metrics_model(
      "not a landscape",
      model
    ),
    "'landscapes' must be a landscape object or list of landscapes"
  )

  expect_error(
    apply_metrics_model(
      data.frame(x = 1),
      model
    ),
    "All elements must be landscape objects"
  )
})

test_that("apply_metrics_model works with single landscape", {
  # Train model
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply to single landscape
  result <- apply_metrics_model(
    minimal_landscapes[[1]],
    model,
    return_performance = FALSE
  )

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_true(all(
    c("landscape_id", "predicted_class", "confidence") %in% names(result)
  ))

  # Check predictions
  expect_true(result$predicted_class %in% model$classes)
  expect_gte(result$confidence, 0)
  expect_lte(result$confidence, 1)

  # Should have probability columns for each class
  expect_true(all(model$classes %in% names(result)))
})

test_that("apply_metrics_model works with list of landscapes", {
  # Train model
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply to list of landscapes
  result <- apply_metrics_model(
    minimal_landscapes,
    model,
    return_performance = FALSE
  )

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), length(minimal_landscapes))

  # All predictions should be valid classes
  expect_true(all(result$predicted_class %in% model$classes))
})

test_that("apply_metrics_model returns performance when requested", {
  # Train model
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create landscapes on-demand
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply with performance evaluation
  result <- apply_metrics_model(
    minimal_landscapes,
    model,
    return_performance = TRUE
  )

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

test_that("apply_metrics_model returns only predictions when classes unknown", {
  # Train model
  model <- train_metrics_model(
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

  # Apply with return_performance = TRUE (should still return only predictions)
  result <- apply_metrics_model(
    minimal_landscapes,
    model,
    return_performance = TRUE
  )

  # Should return tibble (not list) since no actual classes available
  expect_s3_class(result, "tbl_df")
})

test_that("apply_metrics_model warns about unknown classes", {
  # Use balanced fixture which has more classes
  if (length(unique(fixtures$balanced_metrics$pattern)) > 2) {
    # Train on subset of classes
    metrics_subset <- fixtures$balanced_metrics |>
      dplyr::filter(pattern %in% c("spots", "labyrinth"))

    model_subset <- train_metrics_model(
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
      result <- apply_metrics_model(
        landscapes_other,
        model_subset,
        return_performance = TRUE
      ),
      "Input landscapes contain classes not seen during training"
    )

    # Should return only predictions (not performance)
    expect_s3_class(result, "tbl_df")
  }
})

test_that("apply_metrics_model works with class-level metrics", {
  # Filter to single class
  metrics_class <- fixtures$small_metrics_class |>
    dplyr::filter(class == 0)

  # Train model
  model <- train_metrics_model(
    metrics_class,
    cv_method = "none",
    verbose = FALSE
  )

  # Create small landscapes
  small_landscapes <- create_fixture_landscapes("small")

  # Apply model
  result <- apply_metrics_model(
    small_landscapes[1:3],
    model,
    return_performance = FALSE
  )

  # Should work with class-level features
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(model$features_level, "class")
})

test_that("apply_metrics_model errors when metrics cannot be calculated", {
  # Train model
  model <- train_metrics_model(
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
    apply_metrics_model(
      invalid_landscape,
      model,
      return_performance = FALSE
    )
  )
})

test_that("apply_metrics_model includes landscape_name when available", {
  # Train model
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create minimal landscapes
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply model
  result <- apply_metrics_model(
    minimal_landscapes,
    model,
    return_performance = FALSE
  )

  # Should include landscape_name if present
  if ("name" %in% names(minimal_landscapes[[1]])) {
    expect_true("landscape_name" %in% names(result))
  }
})

test_that("apply_metrics_model maintains landscape order", {
  # Train model
  model <- train_metrics_model(
    fixtures$minimal_metrics,
    cv_method = "none",
    verbose = FALSE
  )

  # Create minimal landscapes
  minimal_landscapes <- create_fixture_landscapes("minimal")

  # Apply model
  result <- apply_metrics_model(
    minimal_landscapes,
    model,
    return_performance = FALSE
  )

  # landscape_id should match input order
  expect_equal(
    result$landscape_id,
    seq_along(minimal_landscapes)
  )
})
