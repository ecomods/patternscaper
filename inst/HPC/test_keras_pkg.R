# Simplified test using ecotoneClassifyR keras functions

cli::cli_alert_info("Loading ecotoneClassifyR package...")
devtools::load_all()

cli::cli_alert_info("Testing keras3 initialization...")

# Define patterns
patterns <- c("random", "sharp", "diffuse", "fingers", "clustered", "bands")

# Create results directory
results_dir <- "test_results"
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

cli::cli_alert_info("Results will be saved to: {results_dir}")

# Create parameter grid (just 4 small experiments)
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

# Generate training pool and validation set
cli::cli_alert_info("Generating landscape pool...")

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

cli::cli_alert_success(
  "Generated {length(training_pool)} training and {length(validation_set)} validation landscapes"
)

# Run experiments
results <- purrr::map(
  1:nrow(param_grid),
  function(i) {
    cli::cli_alert_info("Running experiment {i} of {nrow(param_grid)}")

    # Clear previous keras session
    keras3::clear_session()

    params <- param_grid[i, ]
    n_train <- params$n_landscapes

    # Create experiment ID
    exp_id <- sprintf(
      "n%d_ep%d_lr%.4f_bs%d_dr%.2f_rep%d",
      n_train,
      params$epochs,
      params$learning_rate,
      params$batch_size,
      params$dropout_rate,
      params$replicate
    )

    # Sample training landscapes
    training_patterns <- sapply(training_pool, function(x) x$pattern)
    n_unique_patterns <- length(unique(training_patterns))
    samples_per_pattern <- ceiling(n_train / n_unique_patterns)

    training_indices <- training_patterns |>
      tibble::tibble(pattern = _) |>
      dplyr::mutate(idx = dplyr::row_number()) |>
      dplyr::slice_sample(n = samples_per_pattern, by = pattern) |>
      dplyr::slice_head(n = n_train) |>
      dplyr::pull(idx)

    training_landscapes <- training_pool[training_indices]

    # Train model
    start_time <- Sys.time()

    tryCatch(
      {
        model <- train_nn_landscapes(
          landscapes = training_landscapes,
          cv_method = "none",
          validation_split = 0.2,
          epochs = params$epochs,
          batch_size = params$batch_size,
          learning_rate = params$learning_rate,
          dropout_rate = params$dropout_rate,
          dense_units = params$dense_units,
          optimizer = params$optimizer,
          patience = 3,
          verbose = 0
        )

        training_time <- as.numeric(difftime(
          Sys.time(),
          start_time,
          units = "secs"
        ))

        # Validate
        validation_results <- apply_nn_landscapes(
          landscapes = validation_set,
          nn_model = model,
          return_performance = TRUE
        )

        cli::cli_alert_success(
          "Experiment {i}: accuracy = {round(validation_results$performance$accuracy, 3)}"
        )

        result <- list(
          experiment_id = exp_id,
          parameters = params,
          training_time_secs = training_time,
          validation_accuracy = validation_results$performance$accuracy,
          timestamp = Sys.time(),
          success = TRUE
        )

        # Save individual result
        readr::write_rds(
          result,
          file.path(results_dir, paste0(exp_id, ".rds"))
        )

        # Clear session after success
        keras3::clear_session()

        result
      },
      error = function(e) {
        cli::cli_alert_danger("Experiment {i} failed: {e$message}")

        # Clear session on error
        keras3::clear_session()

        error_result <- list(
          experiment_id = exp_id,
          parameters = params,
          error = e$message,
          timestamp = Sys.time(),
          success = FALSE
        )

        # Save error result
        readr::write_rds(
          error_result,
          file.path(results_dir, paste0(exp_id, "_ERROR.rds"))
        )

        error_result
      }
    )
  }
)

# Summary
n_success <- sum(sapply(results, function(x) x$success))
cli::cli_alert_success(
  "Completed: {n_success}/{nrow(param_grid)} experiments succeeded"
)

# Aggregate and save summary
summary_df <- purrr::map_dfr(results, function(x) {
  if (!x$success) {
    return(tibble::tibble(
      experiment_id = x$experiment_id,
      n_landscapes = x$parameters$n_landscapes,
      epochs = x$parameters$epochs,
      learning_rate = x$parameters$learning_rate,
      validation_accuracy = NA_real_,
      training_time_secs = NA_real_,
      error = x$error
    ))
  }

  tibble::tibble(
    experiment_id = x$experiment_id,
    n_landscapes = x$parameters$n_landscapes,
    epochs = x$parameters$epochs,
    learning_rate = x$parameters$learning_rate,
    validation_accuracy = x$validation_accuracy,
    training_time_secs = x$training_time_secs,
    error = NA_character_
  )
})

readr::write_csv(
  summary_df,
  file.path(results_dir, "experiment_summary.csv")
)

cli::cli_alert_success("Results saved to {results_dir}")
