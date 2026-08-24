# Compare the built-in pixel architecture with three custom alternatives.
#
# This is an exploratory, potentially long-running script. It uses the same
# training landscapes, test landscapes, and training seeds for every
# architecture. Results are retained in the objects `results` and `summary`;
# the script does not write files.
#
# Run from the package root:
#   source("dev/compare_pixel_architectures.R")

devtools::load_all(quiet = TRUE)

if (!keras_available()) {
  cli::cli_abort("A working Keras TensorFlow backend is required.")
}

# Comparison settings ---------------------------------------------------------

patterns <- c("random", "sharp", "diffuse", "fingers", "clustered", "bands")
n_training <- 300L
n_test <- 300L
landscape_size <- 50L
training_seeds <- c(4231L, 4232L, 4233L)
epochs <- 50L
batch_size <- 16L

# Generate these data once so every architecture sees identical landscapes.
set.seed(42)
training_landscapes <- create_landscapes(
  n = n_training,
  patterns = patterns,
  width = landscape_size,
  height = landscape_size
)
test_landscapes <- create_landscapes(
  n = n_test,
  patterns = patterns,
  width = landscape_size,
  height = landscape_size
)

# Candidate architectures -----------------------------------------------------

# A conventional CNN using only 3 by 3 convolutions.
stacked_3x3_cnn <- function(
  input_shape,
  n_classes,
  dropout_rate,
  dense_units
) {
  keras3::keras_model_sequential(input_shape = input_shape) |>
    keras3::layer_conv_2d(
      filters = 32,
      kernel_size = c(3, 3),
      activation = "relu",
      padding = "same"
    ) |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    keras3::layer_conv_2d(
      filters = 64,
      kernel_size = c(3, 3),
      activation = "relu",
      padding = "same"
    ) |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    keras3::layer_flatten() |>
    keras3::layer_dropout(rate = dropout_rate) |>
    keras3::layer_dense(units = dense_units, activation = "relu") |>
    keras3::layer_dense(units = n_classes, activation = "softmax")
}

# Parallel branches examine each landscape at two spatial scales.
parallel_multiscale_cnn <- function(
  input_shape,
  n_classes,
  dropout_rate,
  dense_units
) {
  inputs <- keras3::keras_input(shape = input_shape)
  fine_features <- inputs |>
    keras3::layer_conv_2d(
      filters = 16,
      kernel_size = c(3, 3),
      activation = "relu",
      padding = "same"
    )
  broad_features <- inputs |>
    keras3::layer_conv_2d(
      filters = 16,
      kernel_size = c(7, 7),
      activation = "relu",
      padding = "same"
    )

  outputs <- keras3::layer_concatenate(
    list(fine_features, broad_features)
  ) |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    keras3::layer_conv_2d(
      filters = 64,
      kernel_size = c(3, 3),
      activation = "relu",
      padding = "same"
    ) |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    keras3::layer_flatten() |>
    keras3::layer_dropout(rate = dropout_rate) |>
    keras3::layer_dense(units = dense_units, activation = "relu") |>
    keras3::layer_dense(units = n_classes, activation = "softmax")

  keras3::keras_model(inputs = inputs, outputs = outputs)
}

# Global average pooling reduces the number of fitted parameters.
compact_cnn <- function(
  input_shape,
  n_classes,
  dropout_rate,
  dense_units
) {
  keras3::keras_model_sequential(input_shape = input_shape) |>
    keras3::layer_conv_2d(
      filters = 32,
      kernel_size = c(3, 3),
      activation = "relu",
      padding = "same"
    ) |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    keras3::layer_conv_2d(
      filters = 64,
      kernel_size = c(3, 3),
      activation = "relu",
      padding = "same"
    ) |>
    keras3::layer_global_average_pooling_2d() |>
    keras3::layer_dropout(rate = dropout_rate) |>
    keras3::layer_dense(units = dense_units, activation = "relu") |>
    keras3::layer_dense(units = n_classes, activation = "softmax")
}

architectures <- list(
  built_in_multiscale = "multiscale",
  stacked_3x3 = stacked_3x3_cnn,
  parallel_multiscale = parallel_multiscale_cnn,
  compact = compact_cnn
)

# Train and evaluate -----------------------------------------------------------

result_rows <- list()
result_index <- 1L

for (training_seed in training_seeds) {
  for (architecture_name in names(architectures)) {
    cli::cli_h2("{architecture_name}, seed {training_seed}")

    # Resetting the seed before every fit makes comparisons reproducible within
    # one software and hardware configuration.
    set_random_seed(training_seed)
    elapsed <- system.time({
      model <- train_pixel_model(
        landscapes = training_landscapes,
        architecture = architectures[[architecture_name]],
        cv_method = "none",
        epochs = epochs,
        batch_size = batch_size,
        patience = NULL,
        verbose = FALSE
      )
    })[["elapsed"]]

    test_result <- apply_pixel_model(
      landscapes = test_landscapes,
      model = model,
      evaluate = "required",
      verbose = FALSE
    )

    result_rows[[result_index]] <- tibble::tibble(
      architecture = architecture_name,
      seed = training_seed,
      test_accuracy = test_result$performance$accuracy,
      parameters = as.numeric(model$model$count_params()),
      elapsed_seconds = unname(elapsed)
    )
    result_index <- result_index + 1L
  }
}

results <- dplyr::bind_rows(result_rows)
summary <- results |>
  dplyr::group_by(architecture) |>
  dplyr::summarise(
    runs = dplyr::n(),
    mean_test_accuracy = mean(test_accuracy),
    sd_test_accuracy = stats::sd(test_accuracy),
    parameters = dplyr::first(parameters),
    mean_elapsed_seconds = mean(elapsed_seconds),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(mean_test_accuracy))

print(results)
print(summary)
