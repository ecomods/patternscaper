# Use minimal landscapes for speed
helper_create_tiny_training_set <- function(n_per_class = 3) {
  create_training_landscapes(
    n = n_per_class * 3,
    patterns = c("sharp", "diffuse", "random"),
    width = 50,
    height = 50,
    add_rotation = FALSE
  )
}

test_that("train_nn_landscapes validates cv_method parameter", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_nn_landscapes(landscapes, cv_method = "invalid"),
    'cv_method must be one of: "none", "k-fold", or "loo"'
  )
})

test_that("train_nn_landscapes validates numeric parameters", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_nn_landscapes(landscapes, epochs = 0),
    "epochs must be a positive integer"
  )

  expect_error(
    train_nn_landscapes(landscapes, batch_size = -1),
    "batch_size must be a positive integer"
  )

  expect_error(
    train_nn_landscapes(landscapes, learning_rate = 1.5),
    "learning_rate must be between 0 and 1"
  )
})

test_that("train_nn_landscapes rejects empty or invalid landscapes", {
  expect_error(
    train_nn_landscapes(list()),
    "landscapes must contain at least one landscape object"
  )

  expect_error(
    train_nn_landscapes(list("not_a_landscape")),
    "All elements must be landscape objects"
  )
})

test_that("train_nn_landscapes rejects unclassified landscapes", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  landscapes[[1]]$pattern <- NA

  expect_error(
    train_nn_landscapes(landscapes, cv_method = "none"),
    "All training labels must be classified"
  )
})

test_that("train_nn_landscapes handles model_path validation", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_nn_landscapes(
      landscapes,
      cv_method = "none",
      model_path = "/nonexistent/path/model.keras"
    ),
    "Directory for model_path does not exist"
  )
})

test_that("train_nn_landscapes works with cv_method='none'", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  model <- train_nn_landscapes(
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
      "performance"
    )
  )
  expect_equal(model$classes, c("diffuse", "random", "sharp"))
  expect_equal(model$input_shape, c(50, 50, 1))
  expect_equal(model$architecture, "multiscale")
  expect_equal(model$performance$cv_method, "none")
})

test_that("train_nn_landscapes works with cv_method='k-fold'", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 4)

  model <- train_nn_landscapes(
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


test_that("train_nn_landscapes accepts different optimizers", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  expect_no_error(
    train_nn_landscapes(
      landscapes,
      cv_method = "none",
      epochs = 1,
      optimizer = "sgd",
      verbose = FALSE
    )
  )
})

test_that("train_nn_landscapes respects patience parameter", {
  skip_if_not_installed("keras3")

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  # With patience=NULL should run full epochs
  model <- train_nn_landscapes(
    landscapes,
    cv_method = "none",
    epochs = 5,
    patience = NULL,
    verbose = FALSE
  )

  expect_equal(length(model$history$metrics$loss), 5)
})
