# Needed packages
library(dplyr)
library(purrr)
library(cli)

devtools::load_all()

# Parse command line arguments -------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
# args <- c("ecotones", "results/keras/test_run", "1")

if (length(args) != 3) {
  cli::cli_abort(
    "Usage: Rscript systematic_test_keras.R <pattern_type> <results_dir> <replicate_id>
  pattern_type: 'selforg' or 'ecotones'
  results_dir: directory for output"
  )
}

pattern_type <- args[1]
results_dir <- args[2]
replicate_id <- as.integer(args[3])

# Set unique seed per replicate
set_random_seed(12345 + replicate_id * 1000)

# Define patterns based on type ------------------------------------------------
if (pattern_type == "selforg") {
  patterns <- c("bare", "spots", "labyrinth", "gaps", "dense")
} else if (pattern_type == "ecotones") {
  patterns <- c("random", "sharp", "diffuse", "fingers", "clustered", "bands")
} else {
  cli::cli_abort(
    "pattern_type must be 'selforg' or 'ecotones', got: {pattern_type}"
  )
}

cli::cli_alert_info("Running experiments for pattern type: {pattern_type}")
cli::cli_alert_info("Results will be saved to: {results_dir}")

# Create parameter grid --------------------------------------------------------

# Minimal test configuration (4 experiments)
# param_grid <- tidyr::expand_grid(
#   n_landscapes = c(12, 24),
#   epochs = c(5),
#   learning_rate = c(0.001)
# ) |>
#   dplyr::mutate(
#     replicate = replicate_id,
#     batch_size = 4,
#     dropout_rate = 0.4,
#     dense_units = 64,
#     optimizer = "adam",
#     cv_method = "none"
#   )

# Full systematic test configuration (180 experiments)
param_grid <- tidyr::expand_grid(
  n_landscapes = c(50, 100, 200, 400, 800),
  epochs = c(20, 50, 100),
  learning_rate = c(0.0001, 0.001, 0.01)
) |>
  dplyr::mutate(
    replicate = replicate_id,
    batch_size = dplyr::case_when(
      n_landscapes <= 100 ~ 8,
      .default = 16
    ),
    dropout_rate = dplyr::case_when(
      n_landscapes <= 100 ~ 0.4,
      .default = 0.3
    ),
    dense_units = 128,
    optimizer = "adam",
    cv_method = "none"
  )

# Directories ------------------------------------------------------------------

dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

# Generate datasets ------------------------------------------------------------
max_n <- max(param_grid$n_landscapes)
n_validation <- 100

cli::cli_alert_info("Generating {max_n + n_validation} landscapes...")

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
  results_dir,
  patterns
) {
  n_train <- params_row$n_landscapes

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

  # Generate only what this experiment needs
  training_landscapes <- create_training_landscapes(
    patterns = patterns,
    n = n_train,
    width = 100,
    height = 100
  )

  # Train model
  start_time <- Sys.time()

  tryCatch(
    {
      model_result <- train_nn_landscapes(
        landscapes = training_landscapes,
        cv_method = "none",
        epochs = epochs,
        batch_size = batch_size,
        learning_rate = learning_rate,
        dropout_rate = dropout_rate,
        dense_units = dense_units,
        optimizer = optimizer,
        verbose = FALSE
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

      # Save individual result
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

# Run experiments--------------------------------------------------

cli::cli_alert_info("Running {nrow(param_grid)} experiments...")

all_results <- map(
  1:nrow(param_grid),
  function(i) {
    cli::cli_alert_info("Running experiment {i} of {nrow(param_grid)}")
    run_single_experiment(
      params_row = param_grid[i, ],
      validation_set = validation_set,
      patterns = patterns,
      results_dir = results_dir
    )
  }
)

cli::cli_alert_success("All experiments complete!")


# Save results -----------------------------------------------------------------

readr::write_rds(
  all_results,
  file.path(
    results_dir,
    paste0(
      "systematic_test_keras_",
      pattern_type,
      "_rep",
      replicate_id,
      "_results.rds"
    )
  )
)

cli::cli_alert_success(
  "Results saved to {results_dir} (replicate {replicate_id})"
)
