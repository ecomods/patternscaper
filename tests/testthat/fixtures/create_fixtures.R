# Generate test fixtures for patternscaper tests
#
# This script is NOT run during package testing - it's for manual regeneration
# Run this when:
# - Landscape generation functions change significantly
# - You need to update test data for new package versions
#
# Usage: source("tests/testthat/fixtures/create_fixtures.R")
#
# Note: Generated .rds files are committed to version control for reproducible
# testing. We save ONLY metrics, not landscape objects (terra SpatRaster
# objects cannot be serialized with saveRDS).

# Load the current development version of the package
devtools::load_all()

set.seed(123456) # Fixed seed for reproducibility

# 1. Minimal dataset (edge cases and basic validation) -----------------------
minimal_landscapes <- create_landscapes(
  n = 6,
  patterns = c("spots", "labyrinth")
)

minimal_metrics_all <- calculate_metrics(
  minimal_landscapes,
  level = "landscape"
)

# Select top 10 valid metrics (no NAs)
minimal_best_metrics <- evaluate_metrics(
  minimal_metrics_all,
  metrics_number = 10,
  verbose = FALSE
)

# Keep only selected metrics
minimal_metrics <- minimal_metrics_all |>
  dplyr::filter(metric %in% minimal_best_metrics$selected)

# Save metrics (not landscapes - terra objects can't be serialized)
saveRDS(minimal_metrics, "tests/testthat/fixtures/minimal_metrics.rds")

# Store landscape creation parameters for reproducible regeneration
minimal_landscape_params <- list(
  seed = 42,
  n = 6,
  patterns = c("spots", "labyrinth")
)
saveRDS(
  minimal_landscape_params,
  "tests/testthat/fixtures/minimal_landscape_params.rds"
)


# 2. Small dataset (standard tests) -----------------------------------------

small_landscapes <- create_landscapes(
  n = 30,
  patterns = c("spots", "labyrinth", "gaps")
)

small_metrics_landscape_all <- calculate_metrics(
  small_landscapes,
  level = "landscape"
)

small_metrics_class_all <- calculate_metrics(
  small_landscapes,
  level = "class"
)

# Select top 15 valid metrics for landscape level
small_best_landscape <- evaluate_metrics(
  small_metrics_landscape_all,
  metrics_number = 15,
  verbose = FALSE
)

# Select top 15 valid metrics for class level
small_best_class <- evaluate_metrics(
  small_metrics_class_all,
  metrics_number = 15,
  verbose = FALSE
)

small_metrics_landscape <- small_metrics_landscape_all |>
  dplyr::filter(metric %in% small_best_landscape$selected)

small_metrics_class <- small_metrics_class_all |>
  dplyr::filter(metric %in% small_best_class$selected)

saveRDS(
  small_metrics_landscape,
  "tests/testthat/fixtures/small_metrics_landscape.rds"
)
saveRDS(small_metrics_class, "tests/testthat/fixtures/small_metrics_class.rds")

small_landscape_params <- list(
  seed = 42,
  n = 30,
  patterns = c("spots", "labyrinth", "gaps")
)
saveRDS(
  small_landscape_params,
  "tests/testthat/fixtures/small_landscape_params.rds"
)


# 3. Balanced dataset (CV and class imbalance tests) ---------------------------

balanced_landscapes <- create_landscapes(
  n = 24,
  patterns = c("spots", "labyrinth", "gaps", "sharp")
)

balanced_metrics_all <- calculate_metrics(
  balanced_landscapes,
  level = "landscape"
)

# Select top 15 valid metrics
balanced_best <- evaluate_metrics(
  balanced_metrics_all,
  metrics_number = 15,
  verbose = FALSE
)

balanced_metrics <- balanced_metrics_all |>
  dplyr::filter(metric %in% balanced_best$selected)

saveRDS(balanced_metrics, "tests/testthat/fixtures/balanced_metrics.rds")

balanced_landscape_params <- list(
  seed = 42,
  n = 24,
  patterns = c("spots", "labyrinth", "gaps", "sharp")
)
saveRDS(
  balanced_landscape_params,
  "tests/testthat/fixtures/balanced_landscape_params.rds"
)

cli::cli_alert_success("All fixtures created successfully!")
cli::cli_alert_info("Minimal: {length(minimal_best_metrics)} metrics")
cli::cli_alert_info(
  "Small: {length(small_best_landscape)} landscape metrics, {length(small_best_class)} class metrics"
)
cli::cli_alert_info("Balanced: {length(balanced_best)} metrics")
cli::cli_alert_warning(
  "Landscape objects NOT saved (terra SpatRaster cannot be serialized)"
)
