# Use minimal landscapes for speed
helper_create_tiny_training_set <- function(n_per_class = 3) {
  set.seed(42)

  create_landscapes(
    n = n_per_class * 3,
    patterns = c("sharp", "diffuse", "random"),
    width = 50,
    height = 50,
    rotation = 0
  )
}

helper_minimal_pixel_architecture <- function(input_shape, n_classes, ...) {
  keras3::keras_model_sequential(input_shape = input_shape) |>
    keras3::layer_flatten() |>
    keras3::layer_dense(units = n_classes, activation = "softmax")
}

test_that("train_pixel_model validates cv_method parameter", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_pixel_model(landscapes, cv_method = "invalid"),
    'cv_method must be one of: "none", "k-fold", or "loo"'
  )

  for (bad in list(NA_character_, TRUE, c("none", "loo"), NULL)) {
    expect_error(
      train_pixel_model(landscapes, cv_method = bad),
      'cv_method must be one of: "none", "k-fold", or "loo"'
    )
  }
})

test_that("train_pixel_model validates cv_folds", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  # 1 leaves the single fold with no training data; 0 and negatives make
  # `1:cv_folds` count downwards and silently run a different number of folds
  expect_error(
    train_pixel_model(landscapes, cv_folds = 1),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_pixel_model(landscapes, cv_folds = -3),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_pixel_model(landscapes, cv_folds = 2.5),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_pixel_model(landscapes, cv_folds = "a"),
    "cv_folds must be a single integer >= 2"
  )
  expect_error(
    train_pixel_model(landscapes, cv_folds = NA_real_),
    "cv_folds must be a single integer >= 2"
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

  expect_error(
    train_pixel_model(landscapes, validation_split = 1),
    "validation_split must be between 0 and 1"
  )

  # Type and length are rejected with the same message as an out-of-range
  # value, rather than a coercion error from the range comparison
  expect_error(
    train_pixel_model(landscapes, epochs = c(10, 20)),
    "epochs must be a positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, epochs = 2.5),
    "epochs must be a positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, batch_size = "16"),
    "batch_size must be a positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, learning_rate = c(0.1, 0.2)),
    "learning_rate must be between 0 and 1"
  )
  expect_error(
    train_pixel_model(landscapes, epochs = NA_real_),
    "epochs must be a positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, batch_size = Inf),
    "batch_size must be a positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, learning_rate = NaN),
    "learning_rate must be between 0 and 1"
  )
  expect_error(
    train_pixel_model(landscapes, validation_split = NA_real_),
    "validation_split must be between 0 and 1"
  )
})

test_that("train_pixel_model validates the validation-data contract", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  validation <- helper_create_tiny_training_set(n_per_class = 1)

  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_split = 0.2,
      validation_landscapes = validation
    ),
    "either validation_landscapes or validation_split"
  )
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "k-fold",
      validation_landscapes = validation
    ),
    "only be used when cv_method"
  )
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_landscapes = list()
    ),
    "non-empty list"
  )
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_landscapes = validation[[1]]
    ),
    "A single landscape object was passed"
  )

  missing_class <- validation[
    vapply(validation, \(x) x$pattern != "sharp", logical(1))
  ]
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_landscapes = missing_class
    ),
    "Missing from validation"
  )

  unknown_class <- validation
  unknown_class[[1]]$pattern <- "other"
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_landscapes = unknown_class
    ),
    "Not present in training"
  )

  wrong_dimensions <- validation
  wrong_dimensions[[1]] <- create_landscape(
    validation[[1]]$pattern,
    width = 40,
    height = 40
  )
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_landscapes = wrong_dimensions
    ),
    "same dimensions as the training landscapes"
  )

  unseen_land_cover <- validation
  unseen_land_cover[[1]] <- landscape(
    matrix(2, nrow = 50, ncol = 50),
    pattern = validation[[1]]$pattern
  )
  expect_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      validation_landscapes = unseen_land_cover
    ),
    "land-cover codes not seen during training"
  )

  singleton_class <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("random", width = 20, height = 20),
    create_landscape("random", width = 20, height = 20)
  )
  expect_error(
    train_pixel_model(
      singleton_class,
      cv_method = "none",
      validation_split = 0.2
    ),
    "each class needs at least two landscapes"
  )
})

test_that("train_pixel_model validates architecture and early-stopping parameters", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_pixel_model(landscapes, dropout_rate = 1),
    "dropout_rate must be a single number between 0 and 1"
  )
  expect_error(
    train_pixel_model(landscapes, dropout_rate = -0.1),
    "dropout_rate must be a single number between 0 and 1"
  )
  expect_error(
    train_pixel_model(landscapes, dense_units = 0),
    "dense_units must be a single positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, dense_units = 12.5),
    "dense_units must be a single positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, patience = -1),
    "patience must be a single positive integer or NULL"
  )
  expect_error(
    train_pixel_model(landscapes, patience = "many"),
    "patience must be a single positive integer or NULL"
  )
  expect_error(
    train_pixel_model(landscapes, dropout_rate = NA_real_),
    "dropout_rate must be a single number between 0 and 1"
  )
  expect_error(
    train_pixel_model(landscapes, dense_units = Inf),
    "dense_units must be a single positive integer"
  )
  expect_error(
    train_pixel_model(landscapes, patience = NA_real_),
    "patience must be a single positive integer or NULL"
  )

  for (bad in list("other", NA_character_, 1, c("multiscale", "other"))) {
    expect_error(
      train_pixel_model(landscapes, architecture = bad),
      'architecture must be "multiscale" or a model-building function'
    )
  }
})

test_that("train_pixel_model validates optimizer", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  for (bad in list("other", NA_character_, 1, c("adam", "sgd"), NULL)) {
    expect_error(
      train_pixel_model(landscapes, optimizer = bad),
      'optimizer must be one of: "adam", "sgd", or "rmsprop"'
    )
  }
})

test_that("train_pixel_model validates loss and callbacks", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  for (bad in list(NA_character_, "", " ", 1, c("loss_a", "loss_b"), NULL)) {
    expect_error(
      train_pixel_model(landscapes, loss = bad),
      "loss must be a single non-empty character string"
    )
  }

  for (bad in list("callback", 1, TRUE, function() NULL)) {
    expect_error(
      train_pixel_model(landscapes, callbacks = bad),
      "callbacks must be a list of Keras callbacks or NULL"
    )
  }
})

test_that("train_pixel_model validates verbose", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  expect_error(
    train_pixel_model(landscapes, verbose = "yes"),
    "verbose must be a single logical value"
  )
  expect_error(
    train_pixel_model(landscapes, verbose = c(TRUE, FALSE)),
    "verbose must be a single logical value"
  )
  expect_error(
    train_pixel_model(landscapes, verbose = NA),
    "verbose must be a single logical value"
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

test_that("train_pixel_model rejects a non-list landscapes argument clearly", {
  # A lone landscape used to have its own fields walked and reported as
  # "Invalid element(s) at index(es): 1, 2, 3, 4"
  single <- create_landscape("random", width = 20, height = 20, name = "one")

  expect_error(
    train_pixel_model(single),
    "A single landscape object was passed"
  )

  # Raw raster data instead of a landscape object
  expect_error(
    train_pixel_model(matrix(c(0, 1), nrow = 20, ncol = 20)),
    "must be a list of landscape objects"
  )
})

test_that("train_pixel_model rejects missing pattern labels", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  landscapes[[1]]$pattern <- NA

  expect_error(
    train_pixel_model(landscapes, cv_method = "none"),
    "All training labels must be classified"
  )
})

test_that("train_pixel_model treats unclassified as an ordinary label", {
  skip_if_no_keras()

  relabel_sharp <- function(landscapes) {
    lapply(landscapes, \(x) {
      if (identical(x$pattern, "sharp")) {
        x$pattern <- "unclassified"
      }
      x
    })
  }

  landscapes <- relabel_sharp(helper_create_tiny_training_set(n_per_class = 2))
  validation <- relabel_sharp(helper_create_tiny_training_set(n_per_class = 1))

  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    validation_landscapes = validation,
    epochs = 1,
    batch_size = 2,
    architecture = helper_minimal_pixel_architecture,
    verbose = FALSE
  )

  expect_contains(model$classes, "unclassified")
  expect_contains(
    model$performance$validation_results$actual_class,
    "unclassified"
  )
})

test_that("train_pixel_model rejects a single pattern class", {
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  for (i in seq_along(landscapes)) {
    landscapes[[i]]$pattern <- "sharp"
  }

  expect_error(
    train_pixel_model(landscapes, cv_method = "none"),
    "at least two pattern classes"
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

test_that("train_pixel_model rejects multi-layer landscapes", {
  # The generators always produce single-layer rasters, but landscape() accepts
  # any SpatRaster, so a multi-layer landscape can reach training.
  single_layer <- create_landscape("random", width = 30, height = 30, name = "r1")
  two_layer_sharp <- landscape(
    c(single_layer$data, single_layer$data),
    pattern = "sharp",
    name = "s1"
  )
  two_layer_random <- landscape(
    c(single_layer$data, single_layer$data),
    pattern = "random",
    name = "r2"
  )

  for (landscapes in list(
    list(single_layer, two_layer_sharp),
    list(two_layer_random, two_layer_sharp)
  )) {
    expect_error(
      train_pixel_model(
        landscapes,
        cv_method = "none",
        epochs = 1,
        verbose = FALSE
      ),
      "requires one categorical raster layer"
    )
  }
})

test_that("train_pixel_model aborts on continuous cell values", {
  # Aborts before any keras call, so no training happens.
  landscapes <- list(
    landscape(matrix(0, nrow = 10, ncol = 10), pattern = "a", name = "l1"),
    landscape(
      matrix(c(0.5, rep(1, 99)), nrow = 10, ncol = 10),
      pattern = "b",
      name = "l2"
    )
  )

  expect_error(
    train_pixel_model(landscapes, cv_method = "none", epochs = 1, verbose = FALSE),
    "continuous cell values"
  )
})

test_that("land-cover rasters use one channel per fitted numeric code", {
  first <- landscape(
    matrix(c(-5, 10, 50, -5, 50, 10), nrow = 2),
    pattern = "a"
  )
  second <- landscape(matrix(10, nrow = 2, ncol = 3), pattern = "b")

  land_cover_values <- fit_land_cover_values(list(first, second))
  encoded <- encode_land_cover_raster(first$data, land_cover_values)
  raw <- terra::as.array(first$data)[, , 1]

  expect_equal(land_cover_values, c(-5, 10, 50))
  expect_equal(dim(encoded), c(2, 3, 3))
  for (i in seq_along(land_cover_values)) {
    expect_equal(encoded[, , i], 1 * (raw == land_cover_values[i]))
  }
  expect_equal(apply(encoded, c(1, 2), sum), matrix(1, nrow = 2, ncol = 3))

  missing_class <- encode_land_cover_raster(second$data, land_cover_values)
  expect_true(all(missing_class[, , 1] == 0))
  expect_true(all(missing_class[, , 3] == 0))
})

test_that("train_pixel_model draws split RNG only when validation is requested", {
  skip_if_no_keras()

  # Stratified validation selection uses R's RNG. That draw must not happen at
  # validation_split = 0, where it would shift existing training results.
  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  run_and_capture_seed <- function(validation_split) {
    set_random_seed(1)
    suppressWarnings(train_pixel_model(
      landscapes,
      cv_method = "none",
      epochs = 1,
      validation_split = validation_split,
      verbose = FALSE
    ))
    get(".Random.seed", envir = .GlobalEnv)
  }

  expect_false(identical(run_and_capture_seed(0.2), run_and_capture_seed(0)))
})

test_that("train_pixel_model aborts on landscapes with NA cells", {
  # The NA guard fires before the CNN is built, so no keras training is needed
  m <- matrix(c(0, 1), nrow = 20, ncol = 20)
  clean <- landscape(m, pattern = "a", name = "clean")
  m[1, 1] <- NA
  masked <- landscape(m, pattern = "b", name = "masked")

  expect_error(
    train_pixel_model(list(clean, masked), cv_method = "none"),
    "NA cells"
  )
})

test_that("train_pixel_model works with cv_method='none'", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  set_random_seed(42)
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
      "land_cover_values",
      "architecture",
      "performance",
      "training_geometry"
    )
  )
  expect_equal(model$classes, c("diffuse", "random", "sharp"))
  expect_equal(model$input_shape, c(50, 50, 2))
  expect_equal(model$land_cover_values, c(0, 1))
  expect_equal(model$architecture, "multiscale")
  expect_equal(model$performance$cv_method, "none")
  expect_false("val_loss" %in% names(model$history$metrics))
  expect_false("validation_results" %in% names(model$performance))

  # Training geometry summary reflects the 50x50 training landscapes
  expect_equal(model$training_geometry$n_row, 50)
  expect_equal(model$training_geometry$n_col, 50)
  expect_equal(model$training_geometry$cell_size_x, 1)
  expect_true(model$training_geometry$homogeneous)
})

test_that("train_pixel_model uses explicit validation for early stopping", {
  skip_if_no_keras()

  training <- helper_create_tiny_training_set(n_per_class = 4)
  validation <- helper_create_tiny_training_set(n_per_class = 2)
  constant_architecture <- function(input_shape, n_classes, ...) {
    keras3::keras_model_sequential(input_shape = input_shape) |>
      keras3::layer_flatten() |>
      keras3::layer_dense(
        units = n_classes,
        kernel_initializer = "zeros",
        bias_initializer = "zeros"
      ) |>
      keras3::layer_lambda(f = \(x) x * 0) |>
      keras3::layer_activation(activation = "softmax")
  }

  set_random_seed(42)
  model <- suppressWarnings(train_pixel_model(
    landscapes = training,
    cv_method = "none",
    validation_landscapes = validation,
    architecture = constant_architecture,
    epochs = 6,
    patience = 1,
    verbose = FALSE
  ))

  expect_true("val_loss" %in% names(model$history$metrics))
  expect_lt(length(model$history$metrics$loss), 6)
  expect_equal(model$performance$validation_source, "explicit")
  expect_equal(model$performance$n_training_samples, 12)
  expect_equal(model$performance$n_validation_samples, 6)
  expect_true(model$performance$stopped_early)
  expect_equal(model$performance$best_epoch, 1)
  expect_equal(nrow(model$performance$validation_results), 6)
  expect_setequal(
    model$performance$validation_results$actual_class,
    model$classes
  )
})

test_that("train_pixel_model creates a stratified validation split", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 4)

  set_random_seed(42)
  model <- suppressWarnings(train_pixel_model(
    landscapes = landscapes,
    cv_method = "none",
    validation_split = 0.25,
    epochs = 2,
    patience = NULL,
    verbose = FALSE
  ))

  expect_equal(length(model$history$metrics$loss), 2)
  expect_equal(length(model$history$metrics$val_loss), 2)
  expect_equal(model$performance$validation_source, "split")
  expect_equal(model$performance$n_training_samples, 9)
  expect_equal(model$performance$n_validation_samples, 3)
  expect_false(model$performance$stopped_early)
  expect_equal(
    as.integer(model$performance$class_distribution),
    rep(3L, 3)
  )
  expect_equal(
    as.integer(model$performance$validation_class_distribution),
    rep(1L, 3)
  )
})

test_that("train_pixel_model accepts a custom architecture function", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 6)
  build_count <- 0
  custom_architecture <- function(
    input_shape,
    n_classes,
    dropout_rate,
    dense_units
  ) {
    build_count <<- build_count + 1
    expect_equal(input_shape, c(50, 50, 2))
    expect_equal(n_classes, 3)
    expect_equal(dropout_rate, 0.2)
    expect_equal(dense_units, 8)

    keras3::keras_model_sequential(input_shape = input_shape) |>
      keras3::layer_flatten() |>
      keras3::layer_dropout(rate = dropout_rate) |>
      keras3::layer_dense(units = dense_units, activation = "relu") |>
      keras3::layer_dense(units = n_classes, activation = "softmax")
  }

  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "k-fold",
    cv_folds = 2,
    architecture = custom_architecture,
    dropout_rate = 0.2,
    dense_units = 8,
    epochs = 1,
    verbose = FALSE
  )

  # One fresh model for each fold and another for final training.
  expect_equal(build_count, 3)
  expect_equal(model$architecture, "custom")
})

test_that("custom architecture functions must return a Keras model", {
  skip_if_no_keras()

  expect_error(
    create_keras_model(
      architecture = \(...) NULL,
      input_shape = c(10, 10, 1),
      n_classes = 2
    ),
    "must return a Keras model"
  )
})

test_that("train_pixel_model works with cv_method='k-fold'", {
  skip_if_no_keras()

  # 9 per class is the smallest set that keeps cv_folds = 3: validate_cv_params()
  # requires floor(min_class_count / 3) >= cv_folds, and anything less silently
  # downgrades the run to LOO, which satisfies the assertions below without ever
  # exercising the k-fold branch
  landscapes <- helper_create_tiny_training_set(n_per_class = 9)

  set_random_seed(42)
  expect_warning(
    model <- train_pixel_model(
      landscapes,
      cv_method = "k-fold",
      cv_folds = 3,
      epochs = 5,
      batch_size = 4,
      verbose = FALSE
    ),
    NA
  )

  expect_type(model, "list")
  expect_s3_class(model$performance$confusion_matrix, "table")
  expect_type(model$performance$accuracy, "double")
  expect_s3_class(model$performance$per_class_metrics, "tbl_df")

  expect_equal(model$performance$cv_method, "k-fold")
  expect_equal(model$performance$cv_folds, 3)
  expect_equal(model$performance$fold_epochs, rep(5L, 3))

  # Every landscape is held out exactly once across the folds
  validation <- model$performance$validation_results
  expect_equal(nrow(validation), length(landscapes))
  expect_setequal(validation$landscape_id, seq_along(landscapes))

  # find_balanced_cv_folds() stratifies: 9 landscapes per class over 3 folds
  # puts 3 of every class in every fold
  fold_class_counts <- table(validation$fold, validation$actual_class)
  expect_true(all(fold_class_counts == 3))
})

test_that("train_pixel_model works with cv_method='loo'", {
  skip_if_no_keras()

  left <- matrix(0, nrow = 10, ncol = 10)
  left[, 1:5] <- 1
  right <- matrix(0, nrow = 10, ncol = 10)
  right[, 6:10] <- 1
  landscapes <- list(
    landscape(left, pattern = "a"),
    landscape(left[10:1, ], pattern = "a"),
    landscape(right, pattern = "b"),
    landscape(right[10:1, ], pattern = "b")
  )

  build_count <- 0
  minimal_architecture <- function(input_shape, n_classes, ...) {
    build_count <<- build_count + 1
    keras3::keras_model_sequential(input_shape = input_shape) |>
      keras3::layer_flatten() |>
      keras3::layer_dense(units = n_classes, activation = "softmax")
  }

  set_random_seed(42)
  model <- suppressWarnings(train_pixel_model(
    landscapes,
    cv_method = "loo",
    architecture = minimal_architecture,
    epochs = 1,
    batch_size = 2,
    verbose = FALSE
  ))

  validation <- model$performance$validation_results
  expect_equal(model$performance$cv_method, "loo")
  expect_equal(model$performance$cv_folds, 4)
  expect_equal(model$performance$fold_epochs, rep(1L, 4))
  expect_equal(validation$fold, 1:4)
  expect_equal(validation$landscape_id, 1:4)
  # One fresh model per held-out landscape, plus the returned final model.
  expect_equal(build_count, 5)
})

test_that("train_pixel_model CV folds always train for all epochs", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 6)
  constant_architecture <- function(input_shape, n_classes, ...) {
    keras3::keras_model_sequential(input_shape = input_shape) |>
      keras3::layer_flatten() |>
      keras3::layer_dense(
        units = n_classes,
        kernel_initializer = "zeros",
        bias_initializer = "zeros"
      ) |>
      keras3::layer_lambda(f = \(x) x * 0) |>
      keras3::layer_activation(activation = "softmax")
  }

  # The constant fold models would stop early if their held-out folds were
  # passed to an early-stopping callback.
  set_random_seed(42)
  model <- suppressWarnings(train_pixel_model(
    landscapes,
    cv_method = "k-fold",
    cv_folds = 2,
    architecture = constant_architecture,
    epochs = 4,
    patience = 1,
    verbose = FALSE
  ))

  expect_equal(model$performance$fold_epochs, rep(4L, 2))
})

test_that("train_pixel_model one-hot encodes three land-cover codes", {
  skip_if_no_keras()

  horizontal <- matrix(rep(c(5, 20, 100, 20), 100), nrow = 20)
  vertical <- t(horizontal)
  landscapes <- list(
    landscape(horizontal, pattern = "a"),
    landscape(horizontal[, 20:1], pattern = "a"),
    landscape(vertical, pattern = "b"),
    landscape(vertical[20:1, ], pattern = "b")
  )

  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 1,
    batch_size = 2,
    dense_units = 8,
    verbose = FALSE
  )

  expect_equal(model$land_cover_values, c(5, 20, 100))
  expect_equal(model$input_shape, c(20, 20, 3))
})


test_that("train_pixel_model accepts different optimizers", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  set_random_seed(42)
  expect_no_error(
    train_pixel_model(
      landscapes,
      cv_method = "none",
      epochs = 1,
      optimizer = "SGD",
      verbose = FALSE
    )
  )
})

test_that("train_pixel_model runs a custom callback", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  completed_epochs <- 0L
  epoch_counter <- keras3::callback_lambda(
    on_epoch_end = function(epoch, logs) {
      completed_epochs <<- completed_epochs + 1L
    }
  )

  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    architecture = helper_minimal_pixel_architecture,
    epochs = 2,
    batch_size = 2,
    callbacks = list(epoch_counter),
    verbose = FALSE
  )

  expect_equal(completed_epochs, 2L)
  expect_equal(length(model$history$metrics$loss), 2)
})

test_that("train_pixel_model supports categorical focal loss", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 2)

  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    architecture = helper_minimal_pixel_architecture,
    epochs = 1,
    batch_size = 2,
    loss = "categorical_focal_crossentropy",
    verbose = FALSE
  )

  expect_length(model$history$metrics$loss, 1)
  expect_true(is.finite(model$history$metrics$loss[[1]]))
})

test_that("train_pixel_model respects patience parameter", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)

  # With patience=NULL should run full epochs
  set_random_seed(42)
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
      model = list(wrong = "structure")
    ),
    "must be a trained model from train_pixel_model"
  )
})

test_that("apply_pixel_model rejects an empty landscape list", {
  stub_model <- helper_pixel_stub_model()

  expect_error(
    apply_pixel_model(list(), stub_model),
    "at least one landscape object"
  )
})

test_that("apply_pixel_model validates verbose", {
  stub_model <- helper_pixel_stub_model()
  application <- landscape(
    matrix(1, nrow = 10, ncol = 10),
    pattern = "a"
  )

  for (bad in list("yes", c(TRUE, FALSE), NA)) {
    expect_error(
      apply_pixel_model(application, stub_model, verbose = bad),
      "verbose must be a single logical value"
    )
  }
})

test_that("apply_pixel_model validates landscapes input", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 2)
  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  expect_error(
    apply_pixel_model(
      landscapes = "not_a_landscape",
      model = model
    ),
    "must be a landscape object or list"
  )

  expect_error(
    apply_pixel_model(
      landscapes = list("not", "landscapes"),
      model = model
    ),
    "All elements must be landscape objects"
  )
})

test_that("apply_pixel_model aborts on landscapes with NA cells", {
  # A stub model is enough here: the NA guard fires before the CNN is touched,
  # so no keras training is needed.
  stub_model <- helper_pixel_stub_model()
  m <- matrix(1, nrow = 10, ncol = 10)
  m[1, 1] <- NA
  masked <- landscape(m, pattern = "a", name = "masked")

  expect_error(
    apply_pixel_model(masked, stub_model),
    "NA cells"
  )
})

test_that("apply_pixel_model aborts on continuous cell values", {
  stub_model <- helper_pixel_stub_model()
  continuous <- landscape(
    matrix(seq(0, 1, length.out = 100), nrow = 10, ncol = 10),
    pattern = "a",
    name = "continuous"
  )

  expect_error(
    apply_pixel_model(continuous, stub_model),
    "continuous cell values"
  )
})

test_that("apply_pixel_model rejects land-cover codes absent during training", {
  stub_model <- helper_pixel_stub_model(
    land_cover_values = c(5, 20, 100)
  )
  application <- landscape(
    matrix(c(5, 20, 200, 5), nrow = 2),
    pattern = "a"
  )

  expect_error(
    apply_pixel_model(application, stub_model),
    "land-cover codes not seen during training"
  )
})

test_that("apply_pixel_model warns on many distinct cell values", {
  # Whole numbers pass the guard, but 100 land-cover categories are implausible.
  # A stub model is sufficient because the warning fires before the CNN is used.
  stub_model <- helper_pixel_stub_model()
  many_valued <- landscape(
    matrix(seq_len(100), nrow = 10, ncol = 10),
    pattern = "a",
    name = "many"
  )

  w <- capture_warnings(try(
    apply_pixel_model(many_valued, stub_model),
    silent = TRUE
  ))
  expect_true(any(grepl("distinct cell values", w)))
})

test_that("apply_pixel_model accepts whole numbers stored as doubles", {
  # binarize_images() in the analysis repo builds 0/1 with ifelse(), which
  # returns doubles. The guard tests values, not the raster's storage type.
  stub_model <- helper_pixel_stub_model()
  binary_double <- landscape(
    matrix(rep(c(0, 1), 50), nrow = 10, ncol = 10),
    pattern = "a",
    name = "binary"
  )

  err <- tryCatch(
    apply_pixel_model(binary_double, stub_model),
    error = function(e) conditionMessage(e)
  )
  expect_false(grepl("continuous cell values", err))
})

test_that("apply_pixel_model rejects multi-layer landscapes", {
  # A stub model is enough here: the layer guard fires before the CNN is
  # touched, so no keras training is needed.
  stub_model <- helper_pixel_stub_model()
  first_layer <- terra::rast(matrix(1, nrow = 10, ncol = 10))
  multi_layer <- landscape(
    c(first_layer, first_layer),
    pattern = "a",
    name = "multi"
  )

  expect_error(
    apply_pixel_model(multi_layer, stub_model),
    "requires one categorical raster layer"
  )
})

test_that("apply_pixel_model warns on aspect-ratio distortion", {
  # Stub model + try(): the aspect warning fires before the CNN is used, and the
  # subsequent predict() on the stub errors, which try() swallows.
  stub_model <- helper_pixel_stub_model(height = 20, width = 20)
  wide <- landscape(
    matrix(1, nrow = 20, ncol = 40),
    pattern = "a",
    name = "wide"
  )

  w <- capture_warnings(try(apply_pixel_model(wide, stub_model), silent = TRUE))
  expect_true(any(grepl("distorted", w)))
})

test_that("apply_pixel_model does not warn when aspect ratio matches", {
  # Larger but same aspect (40x40 -> 20x20 is isotropic): no distortion warning.
  stub_model <- helper_pixel_stub_model(height = 20, width = 20)
  square <- landscape(
    matrix(1, nrow = 40, ncol = 40),
    pattern = "a",
    name = "sq"
  )

  w <- capture_warnings(try(
    apply_pixel_model(square, stub_model),
    silent = TRUE
  ))
  expect_false(any(grepl("distorted", w)))
})

test_that("apply_pixel_model returns predictions for single landscape", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # Single landscape
  result <- apply_pixel_model(
    landscapes = landscapes[[1]],
    model = model,
    evaluate = "none"
  )$predictions

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_named(
    result,
    c(
      "landscape_id",
      "landscape_name",
      "actual_class",
      "predicted_class",
      "score",
      "diffuse",
      "random",
      "sharp"
    )
  )
})

test_that("apply_pixel_model returns predictions for multiple landscapes", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  result <- apply_pixel_model(
    landscapes = landscapes[1:5],
    model = model,
    evaluate = "none"
  )$predictions

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  expect_true(all(result$score >= 0 & result$score <= 1))
})

test_that("apply_pixel_model returns performance when requested", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  result <- suppressWarnings(
    apply_pixel_model(
      landscapes = landscapes,
      model = model,
      verbose = FALSE
    )
  )

  expect_type(result, "list")
  expect_named(result, c("predictions", "performance"))
  expect_s3_class(result$predictions, "tbl_df")
  expect_true("actual_class" %in% names(result$predictions))
  expect_s3_class(result$performance$confusion_matrix, "table")
})

test_that("apply_pixel_model handles mixed valid/NA classes", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
  model <- train_pixel_model(
    landscapes,
    cv_method = "none",
    epochs = 2,
    verbose = FALSE
  )

  # Set some to NA
  test_landscapes <- landscapes[1:6]
  test_landscapes[[2]]$pattern <- NA
  test_landscapes[[4]]$pattern <- NA

  result <- suppressWarnings(
    apply_pixel_model(
      landscapes = test_landscapes,
      model = model,
      verbose = FALSE
    )
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
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
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

  # No ground truth to score against is the ordinary inference case, so "auto"
  # simply returns predictions without complaining
  expect_warning(
    result <- apply_pixel_model(
      landscapes = test_landscapes,
      model = model,
      verbose = FALSE
    ),
    NA
  )

  expect_type(result, "list")
  expect_null(result$performance)
  expect_equal(nrow(result$predictions), 3)

  # "required" is how a caller says the labels were meant to be there
  expect_error(
    apply_pixel_model(
      landscapes = test_landscapes,
      model = model,
      evaluate = "required",
      verbose = FALSE
    ),
    "no landscape has a known true class"
  )
})

test_that("apply_pixel_model warns about unknown classes", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
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
      model = model,
      verbose = FALSE
    ),
    "classes not seen during training"
  )

  # Predictions come back for every landscape, but nothing is scored: evaluating
  # only the recognized ones would drop guaranteed errors from the denominator
  expect_type(result, "list")
  expect_equal(nrow(result$predictions), 3)
  expect_null(result$performance)

  expect_error(
    apply_pixel_model(
      landscapes = test_landscapes,
      model = model,
      evaluate = "required",
      verbose = FALSE
    ),
    "true class the model never saw"
  )

  # Nothing is scored under "none", so the warning never fires
  expect_warning(
    apply_pixel_model(
      landscapes = test_landscapes,
      model = model,
      evaluate = "none",
      verbose = FALSE
    ),
    NA
  )
})

test_that("apply_pixel_model handles resizing correctly", {
  skip_if_no_keras()

  landscapes <- helper_create_tiny_training_set(n_per_class = 3)
  set_random_seed(42)
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
    model = model,
    evaluate = "none",
    verbose = FALSE
  )$predictions

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
})
