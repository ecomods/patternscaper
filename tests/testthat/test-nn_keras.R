# Use minimal landscapes for speed
helper_create_tiny_training_set <- function(n_per_class = 3) {
  create_landscapes(
    n = n_per_class * 3,
    patterns = c("sharp", "diffuse", "random"),
    width = 50,
    height = 50,
    rotation = 0
  )
}

test_that("train_pixel_model validates cv_method parameter", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_pixel_model(landscapes, cv_method = "invalid"),
    'cv_method must be one of: "none", "k-fold", or "loo"'
  )
})

test_that("train_pixel_model validates numeric parameters", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_pixel_model(landscapes, epochs = 0),
    "epochs must be a positive integer"
  )

  expect_error(
    train_pixel_model(landscapes, batch_size = -1),
    "batch_size must be a positive integer"
  )

  expect_error(
    train_pixel_model(landscapes, learning_rate = 1.5),
    "learning_rate must be between 0 and 1"
  )
})

test_that("train_pixel_model rejects empty or invalid landscapes", {
  expect_error(
    train_pixel_model(list()),
    "landscapes must contain at least one landscape object"
  )

  expect_error(
    train_pixel_model(list("not_a_landscape")),
    "All elements must be landscape objects"
  )
})

test_that("train_pixel_model rejects unclassified landscapes", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  landscapes[[1]]$pattern <- NA

  expect_error(
    train_pixel_model(landscapes, cv_method = "none"),
    "All training labels must be classified"
  )
})

test_that("train_pixel_model aborts on heterogeneous training dimensions", {
  # Aborts before any keras call, so no training happens.
  mixed <- list(
    create_landscape("random", width = 30, height = 30, name = "r1"),
    create_landscape("sharp", width = 40, height = 40, name = "s1")
  )
  expect_error(
    train_pixel_model(mixed, cv_method = "none", epochs = 1, verbose = FALSE),
    "same dimensions"
  )
})

test_that("train_pixel_model handles model_path validation", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      model_path = "/nonexistent/path/model.keras"
    ),
    "Directory for model_path does not exist"
  )
})

test_that("train_pixel_model works with cv_method='none'", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    batch_size = 4,
    verbose = FALSE
  )

  expect_type(model, "list")
  expect_named(
    model,
    c(
      "model",
      "history",
      "classes",
      "input_shape",
      "architecture",
      "performance",
      "training_geometry"
    )
  )
  expect_equal(model$classes, c("diffuse", "random", "sharp"))
  expect_equal(model$input_shape, c(50, 50, 1))
  expect_equal(model$architecture, "multiscale")
  expect_equal(model$performance$cv_method, "none")

  # Training geometry summary reflects the 50x50 training landscapes
  expect_equal(model$training_geometry$n_row, 50)
  expect_equal(model$training_geometry$n_col, 50)
  expect_equal(model$training_geometry$cell_size_x, 1)
  expect_true(model$training_geometry$homogeneous)
})

test_that("train_pixel_model works with cv_method='k-fold'", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 4)

  model <- train_pixel_model(
    landscapes,
    cv_method = "k-fold",
    cv_folds = 3,
    epochs = 2,
    batch_size = 4,
    verbose = FALSE
  )

  expect_type(model, "list")
  expect_s3_class(model$performance$confusion_matrix, "table")
  expect_type(model$performance$accuracy, "double")
  expect_s3_class(model$performance$per_class_metrics, "tbl_df")
})


test_that("train_pixel_model accepts different optimizers", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  expect_no_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      epochs = 1,
      optimizer = "sgd",
      verbose = FALSE
    )
  )
})

test_that("train_pixel_model respects patience parameter", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  # With patience=NULL should run full epochs
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 5,
    patience = NULL,
    verbose = FALSE
  )

  expect_equal(length(model$history$metrics$loss), 5)
})

# apply_pixel_model test -------------------------------------------------

test_that("apply_pixel_model validates model structure", {
  expect_error(
    apply_pixel_model(
      landscapes = list(),
      nn_model = list(wrong = "structure")
    ),
    "must be a trained model from train_pixel_model"
  )
})

test_that("apply_pixel_model validates landscapes input", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  expect_error(
    apply_pixel_model(
      landscapes = "not_a_landscape",
      nn_model = model
    ),
    "must be a landscape object or list"
  )

  expect_error(
    apply_pixel_model(
      landscapes = list("not", "landscapes"),
      nn_model = model
    ),
    "All elements must be landscape objects"
  )
})

test_that("apply_pixel_model aborts on landscapes with NA cells", {
  # A stub model is enough here: the NA guard fires before the CNN is touched,
  # so no keras training is needed.
  stub_model <- list(
    model = NULL,
    classes = c("a", "b"),
    input_shape = c(10, 10, 1)
  )
  m <- matrix(1, nrow = 10, ncol = 10)
  m[1, 1] <- NA
  masked <- landscape(m, pattern = "a", name = "masked")

  expect_error(
    apply_pixel_model(masked, stub_model),
    "NA cells"
  )
})

test_that("apply_pixel_model returns predictions for single landscape", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # Single landscape
  result <- apply_pixel_model(
    landscapes = landscapes[[1]],
    nn_model = model
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_named(
    result,
    c(
      "landscape_id",
      "landscape_name",
      "actual_class",
      "predicted_class",
      "confidence",
      "diffuse",
      "random",
      "sharp"
    )
  )
})

test_that("apply_pixel_model returns predictions for multiple landscapes", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  result <- apply_pixel_model(
    landscapes = landscapes[1:5],
    nn_model = model
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  expect_true(all(result$confidence >= 0 & result$confidence <= 1))
})

test_that("apply_pixel_model returns performance when requested", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  result <- apply_pixel_model(
    landscapes = landscapes,
    nn_model = model,
    return_performance = TRUE,
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_named(result, c("predictions", "performance"))
  expect_s3_class(result$predictions, "tbl_df")
  expect_true("actual_class" %in% names(result$predictions))
  expect_s3_class(result$performance$confusion_matrix, "table")
})

test_that("apply_pixel_model handles mixed valid/NA classes", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # Set some to NA
  test_landscapes <- landscapes[1:6]
  test_landscapes[[2]]$pattern <- NA
  test_landscapes[[4]]$pattern <- "unclassified"

  result <- apply_pixel_model(
    landscapes = test_landscapes,
    nn_model = model,
    return_performance = TRUE,
    verbose = FALSE
  )

  # Should return list structure with NULL performance or valid performance
  expect_type(result, "list")
  expect_equal(nrow(result$predictions), 6)
  # Performance should only be on 4 valid landscapes
  if (!is.null(result$performance)) {
    expect_true(sum(result$performance$class_counts, na.rm = TRUE) <= 4)
  }
})

test_that("apply_pixel_model returns NULL performance for all invalid classes", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # All to NA classes
  test_landscapes <- landscapes[1:3]
  for (i in 1:3) {
    test_landscapes[[i]]$pattern <- NA
  }

  expect_warning(
    result <- apply_pixel_model(
      landscapes = test_landscapes,
      nn_model = model,
      return_performance = TRUE
    ),
    "No valid actual classes"
  )

  expect_type(result, "list")
  expect_null(result$performance)
  expect_equal(nrow(result$predictions), 3)
})

test_that("apply_pixel_model warns about unknown classes", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # Add unknown class
  test_landscapes <- landscapes[1:3]
  test_landscapes[[2]]$pattern <- "unknown_pattern"

  expect_warning(
    result <- apply_pixel_model(
      landscapes = test_landscapes,
      nn_model = model,
      return_performance = TRUE
    ),
    "classes not seen during training"
  )

  expect_type(result, "list")
  expect_null(result$performance)
})

test_that("apply_pixel_model handles resizing correctly", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # Create smaller landscape
  small_landscape <- create_landscape(
    pattern = "sharp",
    width = 25,
    height = 25
  )

  result <- apply_pixel_model(
    landscapes = small_landscape,
    nn_model = model,
    verbose = FALSE
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
})
