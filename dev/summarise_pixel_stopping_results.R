# Summarise the fixed-epoch and early-stopping comparison
#
# Run from the package root after dev/compare_pixel_stopping.R:
#   source("dev/summarise_pixel_stopping_results.R")

library(dplyr)
library(tidyr)

results_directory <- file.path("dev", "pixel_stopping_results")

model_results <- read.csv(
  file.path(results_directory, "pixel_stopping_summary.csv")
)
test_predictions <- read.csv(
  file.path(results_directory, "pixel_stopping_test_predictions.csv")
)

# Recalculate accuracy directly from the landscape-level predictions.
calculated_accuracy <- test_predictions |>
  mutate(correct = actual_class == predicted_class) |>
  group_by(use_case, training_seed, method) |>
  summarise(calculated_test_accuracy = mean(correct), .groups = "drop")

accuracy_check <- model_results |>
  select(use_case, training_seed, method, test_accuracy) |>
  left_join(
    calculated_accuracy,
    by = c("use_case", "training_seed", "method")
  ) |>
  mutate(difference = test_accuracy - calculated_test_accuracy)

if (any(abs(accuracy_check$difference) > 1e-12)) {
  stop("Stored test accuracies do not match the prediction-level results.")
}

cat("Stored test accuracies match the prediction-level results.\n\n")

# Put the paired methods beside each other for every use case and seed.
seed_comparison <- model_results |>
  select(
    use_case,
    training_seed,
    method,
    test_accuracy,
    validation_accuracy,
    epochs_trained
  ) |>
  pivot_wider(
    names_from = method,
    values_from = c(test_accuracy, validation_accuracy, epochs_trained)
  ) |>
  mutate(
    test_difference =
      test_accuracy_early_stopping - test_accuracy_fixed_epochs
  )

cat("Results for each training seed:\n")
print(seed_comparison, width = Inf)

# Summarise variation across training seeds without hiding the range.
method_summary <- model_results |>
  group_by(use_case, method) |>
  summarise(
    n_seeds = n(),
    mean_test_accuracy = mean(test_accuracy),
    sd_test_accuracy = sd(test_accuracy),
    minimum_test_accuracy = min(test_accuracy),
    maximum_test_accuracy = max(test_accuracy),
    mean_epochs_trained = mean(epochs_trained),
    .groups = "drop"
  )

cat("\nSummary across training seeds:\n")
print(method_summary, width = Inf)
