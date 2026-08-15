test_that("pixel model persistence validates paths and bundle metadata", {
  test_root <- tempfile("pixel-persistence-")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  for (bad in list(NA_character_, "", 1, c("one", "two"))) {
    expect_error(
      load_pixel_model(bad),
      "path.*single non-empty character string"
    )
  }

  stub_model <- helper_pixel_stub_model()
  stub_model$model <- TRUE
  expect_error(
    save_pixel_model(stub_model, file.path(test_root, "model.keras")),
    "bundle directory"
  )
  expect_error(
    save_pixel_model(
      stub_model,
      file.path(test_root, "model"),
      overwrite = NA
    ),
    "overwrite.*single logical"
  )
  expect_error(
    save_pixel_model(list(), file.path(test_root, "model")),
    "trained model from.*train_pixel_model"
  )

  existing_file <- file.path(test_root, "existing-file")
  file.create(existing_file)
  expect_error(
    save_pixel_model(stub_model, existing_file),
    "existing file, not a directory"
  )

  existing_directory <- file.path(test_root, "existing-directory")
  dir.create(existing_directory)
  expect_error(
    save_pixel_model(stub_model, existing_directory),
    "already exists"
  )

  expect_error(
    load_pixel_model(file.path(test_root, "missing")),
    "does not exist"
  )
  expect_error(
    load_pixel_model(existing_file),
    "file, but a model-bundle directory is required"
  )
  expect_error(
    load_pixel_model(existing_directory),
    "incomplete"
  )

  unsupported <- file.path(test_root, "unsupported")
  dir.create(unsupported)
  file.create(file.path(unsupported, "model.keras"))
  saveRDS(
    list(format_version = 99L, metadata = list()),
    file.path(unsupported, "metadata.rds")
  )
  expect_error(
    load_pixel_model(unsupported),
    "Unsupported pixel model bundle format: 99"
  )

  unsupported_version <- file.path(test_root, "unsupported-version")
  dir.create(unsupported_version)
  file.create(file.path(unsupported_version, "model.keras"))
  saveRDS(
    list(format_version = 2L, metadata = list()),
    file.path(unsupported_version, "metadata.rds")
  )
  expect_error(
    load_pixel_model(unsupported_version),
    "Unsupported pixel model bundle format: 2"
  )

  invalid <- file.path(test_root, "invalid")
  dir.create(invalid)
  file.create(file.path(invalid, "model.keras"))
  saveRDS(
    list(format_version = 1L, metadata = list()),
    file.path(invalid, "metadata.rds")
  )
  expect_error(
    load_pixel_model(invalid),
    "invalid model metadata"
  )
})

test_that("pixel model bundle round trip works in the current process", {
  skip_if_not(keras_available(), "Keras TensorFlow backend unavailable")

  left <- matrix(0, nrow = 20, ncol = 20)
  left[, 1:10] <- 1
  right <- matrix(0, nrow = 20, ncol = 20)
  right[, 11:20] <- 1
  training_landscapes <- list(
    landscape(left, pattern = "a", name = "a1"),
    landscape(left[c(2:20, 1), ], pattern = "a", name = "a2"),
    landscape(right, pattern = "b", name = "b1"),
    landscape(right[c(20, 1:19), ], pattern = "b", name = "b2")
  )
  set_random_seed(42)
  nn_model <- train_pixel_model(
    training_landscapes,
    cv_method = "none",
    epochs = 1,
    batch_size = 2,
    dense_units = 8,
    verbose = FALSE
  )
  application <- training_landscapes[[1]]
  before <- apply_pixel_model(
    application,
    nn_model,
    evaluate = "none",
    verbose = FALSE
  )$predictions

  bundle_path <- tempfile("pixel-model-")
  on.exit(unlink(bundle_path, recursive = TRUE), add = TRUE)
  saved_path <- save_pixel_model(nn_model, bundle_path)

  expect_true(dir.exists(saved_path))
  expect_true(file.exists(file.path(saved_path, "model.keras")))
  expect_true(file.exists(file.path(saved_path, "metadata.rds")))

  manifest <- readRDS(file.path(saved_path, "metadata.rds"))
  expect_identical(manifest$format_version, 1L)
  expect_false("model" %in% names(manifest$metadata))
  expect_equal(manifest$metadata$history, nn_model$history)

  reloaded <- load_pixel_model(bundle_path)
  expect_equal(names(reloaded), names(nn_model))
  expect_equal(reloaded$classes, nn_model$classes)
  expect_equal(reloaded$input_shape, nn_model$input_shape)
  expect_equal(reloaded$land_cover_values, nn_model$land_cover_values)
  expect_equal(reloaded$history, nn_model$history)

  after <- apply_pixel_model(
    application,
    reloaded,
    evaluate = "none",
    verbose = FALSE
  )$predictions
  expect_equal(after, before, tolerance = 1e-7)

  expect_error(
    save_pixel_model(nn_model, bundle_path),
    "already exists"
  )
  expect_no_error(
    save_pixel_model(nn_model, bundle_path, overwrite = TRUE)
  )
})

test_that("a fresh R process can load and apply a pixel model bundle", {
  skip_if_not(keras_available(), "Keras TensorFlow backend unavailable")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")

  set_random_seed(42)
  keras_model <- create_keras_model(
    architecture = "multiscale",
    input_shape = c(10, 10, 2),
    n_classes = 2,
    dropout_rate = 0.3,
    dense_units = 8
  )
  nn_model <- list(
    model = keras_model,
    history = NULL,
    classes = c("a", "b"),
    input_shape = c(10, 10, 2),
    land_cover_values = c(0, 1),
    architecture = "multiscale",
    performance = NULL,
    training_geometry = NULL
  )
  cells <- rep(c(0, 1), 50)
  application <- landscape(matrix(cells, nrow = 10), pattern = "a")
  expected <- apply_pixel_model(
    application,
    nn_model,
    evaluate = "none",
    verbose = FALSE
  )$predictions

  bundle_path <- tempfile("pixel-model-")
  on.exit(unlink(bundle_path, recursive = TRUE), add = TRUE)
  save_pixel_model(nn_model, bundle_path)

  package_path <- testthat::test_path("..", "..")
  if (file.exists(file.path(package_path, "DESCRIPTION"))) {
    package_path <- normalizePath(
      package_path,
      winslash = "/",
      mustWork = TRUE
    )
  } else {
    package_path <- NULL
  }
  actual <- callr::r(
    function(package_path, bundle_path, cells) {
      package_env <- if (is.null(package_path)) {
        asNamespace("spatPatClassifyR")
      } else {
        pkgload::load_all(package_path, quiet = TRUE)$env
      }
      application <- package_env$landscape(
        matrix(cells, nrow = 10),
        pattern = "a"
      )
      model <- package_env$load_pixel_model(bundle_path)
      package_env$apply_pixel_model(
        application,
        model,
        evaluate = "none",
        verbose = FALSE
      )$predictions
    },
    args = list(
      package_path = package_path,
      bundle_path = bundle_path,
      cells = cells
    ),
    libpath = .libPaths()
  )

  expect_equal(actual, expected, tolerance = 1e-7)
})
