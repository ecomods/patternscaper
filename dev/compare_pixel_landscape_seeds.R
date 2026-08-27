# Compare training- and test-landscape generation seeds
#
# This diagnostic uses early stopping and separates two sources of variation:
# A. Different training landscapes, with validation data, test data, and the
#    Keras model seed fixed.
# B. Different test landscapes, with one trained reference model fixed.
#
# Run from the package root:
#   source("dev/compare_pixel_landscape_seeds.R")

# Load required libraries -------------------------------------------------

devtools::load_all(quiet = TRUE)
library(dplyr)

if (!identical(keras3::config_backend(), "tensorflow")) {
  cli::cli_abort("A working Keras TensorFlow backend is required.")
}

# Settings ----------------------------------------------------------------

reference_training_landscape_seed <- 42
validation_landscape_seed <- 43
training_landscape_seeds <- c(
  reference_training_landscape_seed,
  4201:4209
)
test_landscape_seeds <- 5201:5210
model_seed <- 4231

n_training <- 100
n_test <- 100
n_validation_per_pattern <- 10
epochs <- 100
patience <- 15

results_directory <- file.path(
  "dev",
  "pixel_landscape_seed_results"
)
dir.create(results_directory, recursive = TRUE, showWarnings = FALSE)

use_cases <- list(
  ecotones = c(
    "sharp",
    "diffuse",
    "clustered",
    "fingers",
    "bands",
    "random"
  ),
  self_organized = c(
    "bare",
    "spots",
    "labyrinth",
    "gaps",
    "dense"
  )
)

# Store results -----------------------------------------------------------

training_seed_results <- list()
training_seed_per_class <- list()
training_seed_predictions <- list()
test_seed_results <- list()
test_seed_per_class <- list()
test_seed_predictions <- list()

training_result_id <- 1
test_result_id <- 1

for (use_case_name in names(use_cases)) {
  patterns <- use_cases[[use_case_name]]

  # Seed 42 reproduces the training and test landscapes from the corresponding
  # use-case script. The test set follows the training set in the same RNG stream.
  set.seed(reference_training_landscape_seed)
  reference_training <- create_landscapes(
    n = n_training,
    patterns = patterns
  )
  fixed_test <- create_landscapes(
    n = n_test,
    patterns = patterns
  )

  # Keep one independent validation set fixed across all training-set fits.
  set.seed(validation_landscape_seed)
  fixed_validation <- create_landscapes(
    n = length(patterns) * n_validation_per_pattern,
    patterns = patterns
  )

  # Experiment A: vary only the generated training landscapes -------------

  for (training_landscape_seed in training_landscape_seeds) {
    message(
      "Training ",
      use_case_name,
      " with training-landscape seed ",
      training_landscape_seed
    )

    if (training_landscape_seed == reference_training_landscape_seed) {
      training_landscapes <- reference_training
    } else {
      set.seed(training_landscape_seed)
      training_landscapes <- create_landscapes(
        n = n_training,
        patterns = patterns
      )
    }

    # Reset the Keras seed so only the generated training landscapes differ.
    set_random_seed(model_seed)
    start_time <- Sys.time()

    model <- train_pixel_model(
      landscapes = training_landscapes,
      validation_landscapes = fixed_validation,
      cv_method = "none",
      epochs = epochs,
      patience = patience,
      verbose = FALSE
    )

    runtime_minutes <- as.numeric(difftime(
      Sys.time(),
      start_time,
      units = "mins"
    ))

    fixed_test_results <- apply_pixel_model(
      landscapes = fixed_test,
      model = model,
      verbose = FALSE
    )

    validation_performance <- model$performance
    test_performance <- fixed_test_results$performance

    training_seed_results[[training_result_id]] <- data.frame(
      use_case = use_case_name,
      training_landscape_seed = training_landscape_seed,
      validation_landscape_seed = validation_landscape_seed,
      model_seed = model_seed,
      requested_epochs = validation_performance$requested_epochs,
      epochs_trained = validation_performance$epochs_trained,
      best_epoch = validation_performance$best_epoch,
      validation_accuracy = validation_performance$accuracy,
      test_accuracy = test_performance$accuracy,
      runtime_minutes = runtime_minutes
    )

    training_seed_per_class[[training_result_id]] <- bind_rows(
      validation_performance$per_class_metrics |>
        mutate(dataset = "validation", .before = 1),
      test_performance$per_class_metrics |>
        mutate(dataset = "test", .before = 1)
    ) |>
      mutate(
        use_case = use_case_name,
        training_landscape_seed = training_landscape_seed,
        model_seed = model_seed,
        .before = 1
      )

    training_seed_predictions[[training_result_id]] <-
      fixed_test_results$predictions |>
      transmute(
        use_case = use_case_name,
        training_landscape_seed = training_landscape_seed,
        model_seed = model_seed,
        landscape_id,
        actual_class,
        predicted_class,
        score
      )

    training_result_id <- training_result_id + 1

    # Experiment B: vary only the generated test landscapes ---------------
    # Run this once using the reference model fitted above.
    if (training_landscape_seed == reference_training_landscape_seed) {
      for (test_landscape_seed in test_landscape_seeds) {
        message(
          "Applying the ",
          use_case_name,
          " reference model to test-landscape seed ",
          test_landscape_seed
        )

        set.seed(test_landscape_seed)
        test_landscapes <- create_landscapes(
          n = n_test,
          patterns = patterns
        )

        seeded_test_results <- apply_pixel_model(
          landscapes = test_landscapes,
          model = model,
          verbose = FALSE
        )
        seeded_test_performance <- seeded_test_results$performance

        test_seed_results[[test_result_id]] <- data.frame(
          use_case = use_case_name,
          training_landscape_seed = reference_training_landscape_seed,
          validation_landscape_seed = validation_landscape_seed,
          model_seed = model_seed,
          test_landscape_seed = test_landscape_seed,
          test_accuracy = seeded_test_performance$accuracy
        )

        test_seed_per_class[[test_result_id]] <-
          seeded_test_performance$per_class_metrics |>
          mutate(
            use_case = use_case_name,
            training_landscape_seed = reference_training_landscape_seed,
            model_seed = model_seed,
            test_landscape_seed = test_landscape_seed,
            .before = 1
          )

        test_seed_predictions[[test_result_id]] <-
          seeded_test_results$predictions |>
          transmute(
            use_case = use_case_name,
            training_landscape_seed = reference_training_landscape_seed,
            model_seed = model_seed,
            test_landscape_seed = test_landscape_seed,
            landscape_id,
            actual_class,
            predicted_class,
            score
          )

        test_result_id <- test_result_id + 1
        rm(test_landscapes, seeded_test_results)
      }
    }

    rm(model, training_landscapes)
    gc(verbose = FALSE)
    keras3::clear_session()
  }
}

# Save diagnostic results -------------------------------------------------

training_seed_results <- bind_rows(training_seed_results)
training_seed_per_class <- bind_rows(training_seed_per_class)
training_seed_predictions <- bind_rows(training_seed_predictions)
test_seed_results <- bind_rows(test_seed_results)
test_seed_per_class <- bind_rows(test_seed_per_class)
test_seed_predictions <- bind_rows(test_seed_predictions)

expected_training_runs <- length(use_cases) * length(training_landscape_seeds)
expected_test_runs <- length(use_cases) * length(test_landscape_seeds)
if (
  nrow(training_seed_results) != expected_training_runs ||
    nrow(test_seed_results) != expected_test_runs
) {
  stop("The landscape-seed diagnostic did not complete every requested run.")
}

training_accuracy_check <- training_seed_predictions |>
  mutate(correct = actual_class == predicted_class) |>
  group_by(use_case, training_landscape_seed) |>
  summarise(
    n_predictions = n(),
    calculated_accuracy = mean(correct),
    .groups = "drop"
  ) |>
  left_join(
    training_seed_results |>
      select(use_case, training_landscape_seed, test_accuracy),
    by = c("use_case", "training_landscape_seed")
  )

test_accuracy_check <- test_seed_predictions |>
  mutate(correct = actual_class == predicted_class) |>
  group_by(use_case, test_landscape_seed) |>
  summarise(
    n_predictions = n(),
    calculated_accuracy = mean(correct),
    .groups = "drop"
  ) |>
  left_join(
    test_seed_results |>
      select(use_case, test_landscape_seed, test_accuracy),
    by = c("use_case", "test_landscape_seed")
  )

if (
  any(training_accuracy_check$n_predictions != n_test) ||
    any(test_accuracy_check$n_predictions != n_test) ||
    any(abs(
      training_accuracy_check$calculated_accuracy -
        training_accuracy_check$test_accuracy
    ) > 1e-12) ||
    any(abs(
      test_accuracy_check$calculated_accuracy -
        test_accuracy_check$test_accuracy
    ) > 1e-12)
) {
  stop("Stored accuracies do not match the landscape-level predictions.")
}

training_seed_summary <- training_seed_results |>
  group_by(use_case) |>
  summarise(
    n_seeds = n(),
    mean_test_accuracy = mean(test_accuracy),
    sd_test_accuracy = sd(test_accuracy),
    minimum_test_accuracy = min(test_accuracy),
    maximum_test_accuracy = max(test_accuracy),
    mean_epochs_trained = mean(epochs_trained),
    .groups = "drop"
  )

test_seed_summary <- test_seed_results |>
  group_by(use_case) |>
  summarise(
    n_seeds = n(),
    mean_test_accuracy = mean(test_accuracy),
    sd_test_accuracy = sd(test_accuracy),
    minimum_test_accuracy = min(test_accuracy),
    maximum_test_accuracy = max(test_accuracy),
    .groups = "drop"
  )

cat("\nTraining-landscape seed summary:\n")
print(training_seed_summary, width = Inf)
cat("\nTest-landscape seed summary:\n")
print(test_seed_summary, width = Inf)

readr::write_csv(
  training_seed_results,
  file.path(results_directory, "training_landscape_seed_results.csv")
)
readr::write_csv(
  training_seed_summary,
  file.path(results_directory, "training_landscape_seed_summary.csv")
)
readr::write_csv(
  training_seed_per_class,
  file.path(results_directory, "training_landscape_seed_per_class.csv")
)
readr::write_csv(
  training_seed_predictions,
  file.path(results_directory, "training_landscape_seed_predictions.csv")
)
readr::write_csv(
  test_seed_results,
  file.path(results_directory, "test_landscape_seed_results.csv")
)
readr::write_csv(
  test_seed_summary,
  file.path(results_directory, "test_landscape_seed_summary.csv")
)
readr::write_csv(
  test_seed_per_class,
  file.path(results_directory, "test_landscape_seed_per_class.csv")
)
readr::write_csv(
  test_seed_predictions,
  file.path(results_directory, "test_landscape_seed_predictions.csv")
)
