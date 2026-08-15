# Compare fixed-epoch and early-stopping pixel models
#
# This is an exploratory diagnostic, not part of the final use-case pipeline.
# Run it from the package root:
#   source("dev/compare_pixel_stopping.R")

# Load required libraries -------------------------------------------------

devtools::load_all(quiet = TRUE)
library(dplyr)

if (!keras_available()) {
  cli::cli_abort("A working Keras TensorFlow backend is required.")
}

# Settings ----------------------------------------------------------------

training_seeds <- 4231:4233
epochs <- 100
patience <- 15
n_validation_per_pattern <- 10

results_directory <- file.path("dev", "pixel_stopping_results")
dir.create(results_directory, recursive = TRUE, showWarnings = FALSE)

# Create ecotone landscapes -----------------------------------------------

ecotone_patterns <- c(
  "sharp",
  "diffuse",
  "clustered",
  "fingers",
  "bands",
  "random"
)

# Seed 42 reproduces the training landscapes from the ecotone use case.
set.seed(42)
ecotone_landscapes_train <- create_landscapes(
  n = 100,
  patterns = ecotone_patterns
)

# Use a different seed for validation so the use-case test set stays untouched.
set.seed(43)
ecotone_landscapes_validation <- create_landscapes(
  n = length(ecotone_patterns) * n_validation_per_pattern,
  patterns = ecotone_patterns
)

# Create self-organized landscapes ----------------------------------------

selforg_patterns <- c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)

# Seed 42 reproduces the training landscapes from the self-organized use case.
set.seed(42)
selforg_landscapes_train <- create_landscapes(
  n = 100,
  patterns = selforg_patterns
)

# Warnings about reducing the number of spots or gaps are expected here.
set.seed(43)
selforg_landscapes_validation <- create_landscapes(
  n = length(selforg_patterns) * n_validation_per_pattern,
  patterns = selforg_patterns
)

# Compare training methods ------------------------------------------------

use_cases <- list(
  ecotones = list(
    training = ecotone_landscapes_train,
    validation = ecotone_landscapes_validation
  ),
  self_organized = list(
    training = selforg_landscapes_train,
    validation = selforg_landscapes_validation
  )
)

methods <- c("fixed_epochs", "early_stopping")
summary_results <- list()
per_class_results <- list()
training_histories <- list()
result_id <- 1

for (use_case_name in names(use_cases)) {
  use_case <- use_cases[[use_case_name]]

  for (training_seed in training_seeds) {
    for (method in methods) {
      message(
        "Training ",
        use_case_name,
        ", seed ",
        training_seed,
        ", ",
        method
      )

      # Reset both R and Keras before each method so the paired models start
      # from the same random state.
      set_random_seed(training_seed)
      start_time <- Sys.time()

      model <- train_pixel_model(
        landscapes = use_case$training,
        validation_landscapes = use_case$validation,
        cv_method = "none",
        epochs = epochs,
        patience = if (method == "early_stopping") patience else NULL,
        verbose = FALSE
      )

      runtime_minutes <- as.numeric(difftime(
        Sys.time(),
        start_time,
        units = "mins"
      ))

      performance <- model$performance
      summary_results[[result_id]] <- data.frame(
        use_case = use_case_name,
        training_seed = training_seed,
        method = method,
        requested_epochs = performance$requested_epochs,
        epochs_trained = performance$epochs_trained,
        stopped_early = performance$stopped_early,
        best_epoch = performance$best_epoch,
        best_validation_loss = performance$best_validation_loss,
        last_epoch_validation_loss = performance$last_epoch_validation_loss,
        model_validation_loss = performance$validation_loss,
        validation_accuracy = performance$accuracy,
        runtime_minutes = runtime_minutes
      )

      per_class_results[[result_id]] <- performance$per_class_metrics |>
        mutate(
          use_case = use_case_name,
          training_seed = training_seed,
          method = method,
          .before = 1
        )

      training_histories[[result_id]] <-
        tibble::as_tibble(model$history$metrics) |>
        mutate(
          use_case = use_case_name,
          training_seed = training_seed,
          method = method,
          epoch = dplyr::row_number(),
          .before = 1
        )

      result_id <- result_id + 1

      rm(model)
      gc(verbose = FALSE)
      keras3::clear_session()
    }
  }
}

# Save diagnostic results -------------------------------------------------

summary_results <- bind_rows(summary_results)
per_class_results <- bind_rows(per_class_results)
training_histories <- bind_rows(training_histories)

print(summary_results)

readr::write_csv(
  summary_results,
  file.path(results_directory, "pixel_stopping_summary.csv")
)
readr::write_csv(
  per_class_results,
  file.path(results_directory, "pixel_stopping_per_class.csv")
)
readr::write_csv(
  training_histories,
  file.path(results_directory, "pixel_stopping_histories.csv")
)
