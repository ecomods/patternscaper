# Test with function wrapper like systematic_test_keras.R

cli::cli_alert_info("Loading ecotoneClassifyR package...")
devtools::load_all()

patterns <- c("random", "sharp", "diffuse", "fingers", "clustered", "bands")
results_dir <- "test_results"
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

# Create parameter grid
param_grid <- tidyr::expand_grid(
  n_landscapes = c(12, 24),
  epochs = c(5),
  learning_rate = c(0.001),
  replicate = 1:2
) |>
  dplyr::mutate(
    batch_size = 4,
    dropout_rate = 0.4,
    dense_units = 64,
    optimizer = "adam"
  )

cli::cli_alert_info("Will run {nrow(param_grid)} experiments")

# Generate landscapes
max_n <- max(param_grid$n_landscapes)
training_pool <- create_training_landscapes(
  patterns = patterns,
  n = max_n + length(patterns) * 2,
  width = 100,
  height = 100
)

validation_set <- create_training_landscapes(
  patterns = patterns,
  n = 12,
  width = 100,
  height = 100
)

# Define experiment function (like systematic script)
run_single_experiment <- function(
  params_row,
  training_pool,
  validation_set,
  results_dir
) {
  keras3::clear_session()

  n_train <- params_row$n_landscapes

  exp_id <- sprintf(
    "n%d_ep%d_lr%.4f_bs%d_dr%.2f_rep%d",
    n_train,
    params_row$epochs,
    params_row$learning_rate,
    params_row$batch_size,
    params_row$dropout_rate,
    params_row$replicate
  )

  # Sample training landscapes
  training_patterns <- sapply(training_pool, function(x) x$pattern)
  n_unique_patterns <- length(unique(training_patterns))
  samples_per_pattern <- ceiling(n_train / n_unique_patterns)

  training_indices <- training_patterns |>
    tibble::tibble(pattern = _) |>
    dplyr::mutate(idx = dplyr::row_number()) |>
    dplyr::slice_sample(n = samples_per_pattern, .by = pattern) |>
    dplyr::slice_head(n = n_train) |>
    dplyr::pull(idx)

  training_landscapes <- training_pool[training_indices]

  start_time <- Sys.time()

  tryCatch(
    {
      model_result <- train_nn_landscapes(
        landscapes = training_landscapes,
        cv_method = "none",
        validation_split = 0.2,
        epochs = params_row$epochs,
        batch_size = params_row$batch_size,
        learning_rate = params_row$learning_rate,
        dropout_rate = params_row$dropout_rate,
        dense_units = params_row$dense_units,
        optimizer = params_row$optimizer,
        patience = 3,
        verbose = 0
      )

      training_time <- as.numeric(difftime(
        Sys.time(),
        start_time,
        units = "secs"
      ))

      validation_results <- apply_nn_landscapes(
        landscapes = validation_set,
        nn_model = model_result,
        return_performance = TRUE
      )

      result <- list(
        experiment_id = exp_id,
        parameters = params_row,
        training_time_secs = training_time,
        training_size = length(training_landscapes),
        validation_accuracy = validation_results$performance$accuracy,
        validation_per_class = validation_results$performance$per_class_metrics,
        confusion_matrix_val = validation_results$performance$confusion_matrix,
        history = model_result$history$metrics,
        timestamp = Sys.time(),
        success = TRUE
      )

      readr::write_rds(result, file.path(results_dir, paste0(exp_id, ".rds")))
      keras3::clear_session()

      result
    },
    error = function(e) {
      keras3::clear_session()

      error_result <- list(
        experiment_id = exp_id,
        parameters = params_row,
        error = e$message,
        timestamp = Sys.time(),
        success = FALSE
      )

      readr::write_rds(
        error_result,
        file.path(results_dir, paste0(exp_id, "_ERROR.rds"))
      )
      error_result
    }
  )
}

# Run experiments using function wrapper
cli::cli_alert_info("Running experiments with function wrapper...")

all_results <- purrr::map(
  1:nrow(param_grid),
  function(i) {
    cli::cli_alert_info("Running experiment {i} of {nrow(param_grid)}")
    run_single_experiment(
      params_row = param_grid[i, ],
      training_pool = training_pool,
      validation_set = validation_set,
      results_dir = results_dir
    )
  }
)

n_success <- sum(sapply(all_results, function(x) x$success))
cli::cli_alert_success(
  "Completed: {n_success}/{nrow(param_grid)} experiments succeeded"
)

summary_df <- purrr::map_dfr(all_results, function(x) {
  if (!x$success) {
    return(tibble::tibble(
      experiment_id = x$experiment_id,
      n_landscapes = x$parameters$n_landscapes,
      validation_accuracy = NA_real_,
      error = x$error
    ))
  }

  tibble::tibble(
    experiment_id = x$experiment_id,
    n_landscapes = x$parameters$n_landscapes,
    validation_accuracy = x$validation_accuracy,
    error = NA_character_
  )
})

readr::write_csv(summary_df, file.path(results_dir, "experiment_summary.csv"))
cli::cli_alert_success("Results saved to {results_dir}")
