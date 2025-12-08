# Needed packages
library(dplyr)
library(purrr)
library(cli)
library(furrr)
library(future)

devtools::load_all()
source("systematic_test_functions.R")

# Create parameter grid --------------------------------------------------------

param_grid <- expand_grid(
  n_landscapes = c(50, 100, 200, 400),
  epochs = c(20, 50, 100),
  learning_rate = c(0.0001, 0.001, 0.01),
  replicate = 1:5
) |>
  mutate(
    batch_size = case_when(
      n_landscapes <= 100 ~ 8,
      .default = 16
    ),
    dropout_rate = case_when(
      n_landscapes <= 100 ~ 0.4,
      .default = 0.3
    ),
    dense_units = 128,
    optimizer = "adam",
    cv_method = "none"
  )

# Directories ------------------------------------------------------------------
results_dir <- "./"
models_dir <- file.path(results_dir, "models")
figs_dir <- file.path(results_dir, "figs")

dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figs_dir, recursive = TRUE, showWarnings = FALSE)

# Generate datasets ------------------------------------------------------------

patterns <- c("sharp", "diffuse", "fingers", "clustered", "bands", "random")

max_n <- max(param_grid$n_landscapes)
n_validation <- 100

cli::cli_alert_info("Generating {max_n + n_validation} landscapes...")

training_pool <- create_training_landscapes(
  patterns = patterns,
  n = max_n + length(patterns) * 5, # Extra to allow stratified sampling
  width = 100,
  height = 100
)

validation_set <- create_training_landscapes(
  patterns = patterns,
  n = n_validation,
  width = 100,
  height = 100
)

cli::cli_alert_success("Generated all landscapes")

# Training function ------------------------------------------------------------

run_single_experiment <- function(
  params_row,
  training_pool,
  validation_set,
  results_dir
) {
  # Extract parameters
  n_train <- params_row$n_landscapes
  epochs <- params_row$epochs
  learning_rate <- params_row$learning_rate
  batch_size <- params_row$batch_size
  dropout_rate <- params_row$dropout_rate
  dense_units <- params_row$dense_units
  optimizer <- params_row$optimizer
  replicate <- params_row$replicate

  # Create experiment ID
  exp_id <- sprintf(
    "n%d_ep%d_lr%.4f_bs%d_dr%.2f_rep%d",
    n_train,
    epochs,
    learning_rate,
    batch_size,
    dropout_rate,
    replicate
  )

  # Sample training data (stratified by pattern)
  training_patterns <- sapply(training_pool, function(x) x$pattern)

  training_indices <- training_patterns |>
    tibble(pattern = _) |>
    mutate(idx = row_number()) |>
    slice_sample(
      n = ceiling(n_train / length(unique(pattern))),
      .by = pattern
    ) |>
    slice_head(n = n_train) |>
    pull(idx)

  training_landscapes <- training_pool[training_indices]

  # Train model
  start_time <- Sys.time()

  tryCatch(
    {
      model_result <- train_nn_landscapes(
        landscapes = training_landscapes,
        cv_method = "none",
        validation_split = 0.2,
        epochs = epochs,
        batch_size = batch_size,
        learning_rate = learning_rate,
        dropout_rate = dropout_rate,
        dense_units = dense_units,
        optimizer = optimizer,
        patience = 10,
        verbose = 0 # Silent mode for parallel execution
      )

      training_time <- as.numeric(difftime(
        Sys.time(),
        start_time,
        units = "secs"
      ))

      # Validate on independent validation set
      validation_results <- apply_nn_landscapes(
        landscapes = validation_set,
        nn_model = model_result,
        return_performance = TRUE
      )

      # Extract key metrics
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

      # Save individual result immediately (safer for parallel)
      readr::write_rds(
        result,
        file.path(results_dir, paste0(exp_id, ".rds"))
      )

      return(result)
    },
    error = function(e) {
      error_result <- list(
        experiment_id = exp_id,
        parameters = params_row,
        error = e$message,
        timestamp = Sys.time(),
        success = FALSE
      )

      # Save error result
      readr::write_rds(
        error_result,
        file.path(results_dir, paste0(exp_id, "_ERROR.rds"))
      )

      return(error_result)
    }
  )
}

# Setup parallel execution -----------------------------------------------------

# Determine number of workers based on environment
n_workers <- if (Sys.getenv("SLURM_CPUS_PER_TASK") != "") {
  as.numeric(Sys.getenv("SLURM_CPUS_PER_TASK"))
} else {
  parallel::detectCores() - 1 # Leave one core free for local testing
}

cli::cli_alert_info("Setting up parallel execution with {n_workers} workers")

# Setup future plan
plan(multisession, workers = n_workers)

# Run experiments in parallel --------------------------------------------------

cli::cli_alert_info("Running {nrow(param_grid)} experiments in parallel...")

all_results <- future_map(
  1:nrow(param_grid),
  function(i) {
    devtools::load_all()
    run_single_experiment(
      params_row = param_grid[i, ],
      training_pool = training_pool,
      validation_set = validation_set,
      results_dir = results_dir
    )
  },
  .options = furrr_options(
    seed = TRUE, # Ensures reproducible random sampling
    globals = c("training_pool", "validation_set", "results_dir")
  ),
  .progress = TRUE
)

# Close parallel backend
plan(sequential)

cli::cli_alert_success("All experiments complete!")

# Aggregate results ------------------------------------------------------------

# Option 1: Use the returned results
summary_df <- map_dfr(all_results, function(x) {
  # For unsuccessful experiments, fill with NAs
  if (!x$success) {
    return(tibble(
      experiment_id = x$experiment_id,
      n_landscapes = x$parameters$n_landscapes,
      epochs = x$parameters$epochs,
      learning_rate = x$parameters$learning_rate,
      batch_size = x$parameters$batch_size,
      dropout_rate = x$parameters$dropout_rate,
      replicate = x$parameters$replicate,
      validation_accuracy = NA_real_,
      training_time_secs = NA_real_,
      error = x$error
    ))
  }

  tibble(
    experiment_id = x$experiment_id,
    n_landscapes = x$parameters$n_landscapes,
    epochs = x$parameters$epochs,
    learning_rate = x$parameters$learning_rate,
    batch_size = x$parameters$batch_size,
    dropout_rate = x$parameters$dropout_rate,
    replicate = x$parameters$replicate,
    validation_accuracy = x$validation_accuracy,
    training_time_secs = x$training_time_secs,
    error = NA_character_
  )
})

# Save results -----------------------------------------------------------------

readr::write_rds(
  all_results,
  file.path(results_dir, "systematic_test_results.rds")
)

readr::write_csv(
  summary_df,
  file.path(results_dir, "experiment_summary.csv")
)

cli::cli_alert_success("Results saved to {results_dir}")
