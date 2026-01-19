# Generate test fixtures for ecotoneClassifyR tests
#
# This script is NOT run during package testing - it's for manual regeneration
# Run this when:
# - Landscape generation functions change significantly
# - You need to update test data for new package versions
#
# Usage: source("tests/testthat/fixtures/create_fixtures.R")

# Load the current development version of the package
devtools::load_all()

set.seed(123456) # Fixed seed for reproducibility

# 1. Minimal dataset (edge cases and basic validation) -----------------------
minimal_landscapes <- create_training_landscapes(
  n = 6,
  patterns = c("spots", "labyrinth")
)

minimal_metrics_all <- calculate_landscape_metrics(
  minimal_landscapes,
  level = "landscape"
)

# Select top 10 valid metrics (no NAs)
minimal_best_metrics <- evaluate_landscape_metrics(
  minimal_metrics_all,
  method = "coeffvar_all",
  metrics_number = 10,
  verbose = FALSE
)

# Keep only selected metrics
minimal_metrics <- minimal_metrics_all |>
  dplyr::filter(metric %in% minimal_best_metrics)

saveRDS(minimal_landscapes, "tests/testthat/fixtures/minimal_landscapes.rds")
saveRDS(minimal_metrics, "tests/testthat/fixtures/minimal_metrics.rds")

# 2. Small dataset (standard tests) ------------------------------------------
small_landscapes <- create_training_landscapes(
  n = 30,
  patterns = c("spots", "labyrinth", "gaps")
)

small_metrics_landscape_all <- calculate_landscape_metrics(
  small_landscapes,
  level = "landscape"
)

small_metrics_class_all <- calculate_landscape_metrics(
  small_landscapes,
  level = "class"
)

# Select top 15 valid metrics for landscape level
small_best_landscape <- evaluate_landscape_metrics(
  small_metrics_landscape_all,
  method = "coeffvar_all",
  metrics_number = 15,
  verbose = FALSE
)

# Select top 15 valid metrics for class level
small_best_class <- evaluate_landscape_metrics(
  small_metrics_class_all,
  method = "coeffvar_all",
  metrics_number = 15,
  verbose = FALSE
)

small_metrics_landscape <- small_metrics_landscape_all |>
  dplyr::filter(metric %in% small_best_landscape)

small_metrics_class <- small_metrics_class_all |>
  dplyr::filter(metric %in% small_best_class)

saveRDS(small_landscapes, "tests/testthat/fixtures/small_landscapes.rds")
saveRDS(
  small_metrics_landscape,
  "tests/testthat/fixtures/small_metrics_landscape.rds"
)
saveRDS(small_metrics_class, "tests/testthat/fixtures/small_metrics_class.rds")

# 3. Balanced dataset (CV and class imbalance tests) -------------------------
balanced_landscapes <- create_training_landscapes(
  n = 24,
  patterns = c("spots", "labyrinth", "gaps", "sharp")
)

balanced_metrics_all <- calculate_landscape_metrics(
  balanced_landscapes,
  level = "landscape"
)

# Select top 15 valid metrics
balanced_best <- evaluate_landscape_metrics(
  balanced_metrics_all,
  method = "coeffvar_all",
  metrics_number = 15,
  verbose = FALSE
)

balanced_metrics <- balanced_metrics_all |>
  dplyr::filter(metric %in% balanced_best)

saveRDS(balanced_landscapes, "tests/testthat/fixtures/balanced_landscapes.rds")
saveRDS(balanced_metrics, "tests/testthat/fixtures/balanced_metrics.rds")

cli::cli_alert_success("All fixtures created successfully!")
cli::cli_alert_info(
  "Minimal: {length(minimal_best_metrics)} metrics, {length(minimal_landscapes)} landscapes"
)
cli::cli_alert_info(
  "Small: {length(small_best_landscape)} landscape metrics, {length(small_best_class)} class metrics, {length(small_landscapes)} landscapes"
)
cli::cli_alert_info(
  "Balanced: {length(balanced_best)} metrics, {length(balanced_landscapes)} landscapes"
)
