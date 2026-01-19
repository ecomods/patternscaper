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

set.seed(42) # Fixed seed for reproducibility

# 1. Minimal dataset (edge cases and basic validation) -----------------------
minimal_landscapes <- create_training_landscapes(
  n = 6,
  patterns = c("spots", "labyrinth")
)

minimal_metrics <- calculate_landscape_metrics(
  minimal_landscapes,
  level = "landscape"
)

saveRDS(minimal_landscapes, "tests/testthat/fixtures/minimal_landscapes.rds")
saveRDS(minimal_metrics, "tests/testthat/fixtures/minimal_metrics.rds")

# 2. Small dataset (standard tests) ------------------------------------------
small_landscapes <- create_training_landscapes(
  n = 30,
  patterns = c("spots", "labyrinth", "gaps")
)

small_metrics_landscape <- calculate_landscape_metrics(
  small_landscapes,
  level = "landscape"
)

small_metrics_class <- calculate_landscape_metrics(
  small_landscapes,
  level = "class"
)

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

balanced_metrics <- calculate_landscape_metrics(
  balanced_landscapes,
  level = "landscape"
)

saveRDS(balanced_landscapes, "tests/testthat/fixtures/balanced_landscapes.rds")
saveRDS(balanced_metrics, "tests/testthat/fixtures/balanced_metrics.rds")
