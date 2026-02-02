# Purpose: Explore the systematic keras results to see what is strange
# Plots are done with keras_systematic_plots.R

source(here::here("inst/analyses/functions/plot_systematic_tests.R"))
source(here::here("inst/analyses/functions/plot_theme.R"))

result_path <- "inst/analyses/data/systematic_test_results_keras_selforg.rds"

all_results <- read_rds(result_path)

df_raw <- map_dfr(all_results, combine_validation_results)
summary(df_raw)

df_raw |>
  filter(n_landscapes == 800)

all_results[[length(all_results)]]


# Replicate systematic test setup ----------------------------------------------
set.seed(12345)

# Generate same way as systematic test
training_pool_sys <- create_training_landscapes(
  patterns = c("bare", "spots", "labyrinth", "gaps", "dense"),
  n = 800 + 5 * 5, # max_n + length(patterns) * 5
  width = 100,
  height = 100,
  add_rotation = TRUE
)

validation_set_sys <- create_training_landscapes(
  patterns = c("bare", "spots", "labyrinth", "gaps", "dense"),
  n = 100,
  width = 100,
  height = 100
)

# Sample training data EXACTLY like systematic test
training_patterns_sys <- sapply(training_pool_sys, function(x) x$pattern)
n_train_sys <- 800
n_unique_patterns_sys <- length(unique(training_patterns_sys))
samples_per_pattern_sys <- ceiling(n_train_sys / n_unique_patterns_sys)

training_indices_sys <- training_patterns_sys |>
  tibble::tibble(pattern = _) |>
  dplyr::mutate(idx = dplyr::row_number()) |>
  dplyr::slice_sample(n = samples_per_pattern_sys, by = pattern) |>
  dplyr::slice_head(n = n_train_sys) |>
  dplyr::pull(idx)

training_landscapes_sys <- training_pool_sys[training_indices_sys]


# After generating landscapes, add this diagnostic
print(table(training_patterns_sys))

actual_training_patterns_sys <- sapply(training_landscapes_sys, function(x) {
  x$pattern
})
cli::cli_alert_info("Actual training set pattern distribution:")
print(table(actual_training_patterns_sys))

validation_patterns_sys <- sapply(validation_set_sys, function(x) x$pattern)
cli::cli_alert_info("Validation set pattern distribution:")
print(table(validation_patterns_sys))

# Train with EXACT same parameters
model_sys <- train_nn_pixels(
  landscapes = training_pool_sys,
  cv_method = "none",
  learning_rate = 0.001,
  epochs = 100
)

# Validate on same independent set
validation_sys <- apply_nn_pixels(
  nn_model = model_sys,
  landscape = validation_set_sys,
  return_performance = TRUE
)

cli::cli_alert_info(
  "Systematic test setup accuracy: {validation_sys$performance$accuracy}"
)
print(validation_sys$performance$confusion_matrix)

# ...existing code...

# Step 1: Compare training set sizes and composition
cli::cli_h1("Training Data Comparison")

cli::cli_alert_info("Selforg training size: {length(training_landscapes)}")
cli::cli_alert_info(
  "Systematic training size: {length(training_landscapes_sys)}"
)

patterns_selforg <- sapply(training_landscapes, function(x) x$pattern)
patterns_sys <- sapply(training_landscapes_sys, function(x) x$pattern)

cli::cli_h2("Pattern Distribution")
cli::cli_alert_info("Selforg approach:")
print(table(patterns_selforg))
cli::cli_alert_info("Systematic approach:")
print(table(patterns_sys))

# Step 2: Check if landscapes have names/rotations
cli::cli_h2("Landscape Names (first 20)")
cli::cli_alert_info("Selforg approach:")
print(head(sapply(training_landscapes, function(x) x$name), 20))
cli::cli_alert_info("Systematic approach:")
print(head(sapply(training_landscapes_sys, function(x) x$name), 20))

# Step 3: Check actual raster values for first landscape of each pattern
cli::cli_h2("Sample Raster Values Check")

for (pattern in c("bare", "spots", "labyrinth", "gaps", "dense")) {
  # Find first occurrence in each set
  idx_selforg <- which(patterns_selforg == pattern)[1]
  idx_sys <- which(patterns_sys == pattern)[1]

  if (!is.na(idx_selforg) && !is.na(idx_sys)) {
    vals_selforg <- terra::values(training_landscapes[[idx_selforg]]$data)
    vals_sys <- terra::values(training_landscapes_sys[[idx_sys]]$data)

    cli::cli_alert_info("Pattern: {pattern}")
    cli::cli_text(
      "  Selforg - unique values: {paste(unique(vals_selforg), collapse=', ')}"
    )
    cli::cli_text(
      "  Selforg - range: [{min(vals_selforg, na.rm=TRUE)}, {max(vals_selforg, na.rm=TRUE)}]"
    )
    cli::cli_text(
      "  Selforg - mean: {round(mean(vals_selforg, na.rm=TRUE), 3)}"
    )
    cli::cli_text(
      "  Systematic - unique values: {paste(unique(vals_sys), collapse=', ')}"
    )
    cli::cli_text(
      "  Systematic - range: [{min(vals_sys, na.rm=TRUE)}, {max(vals_sys, na.rm=TRUE)}]"
    )
    cli::cli_text("  Systematic - mean: {round(mean(vals_sys, na.rm=TRUE), 3)}")
  }
}

# Step 4: Visual comparison
cli::cli_h2("Visual Inspection")

# Plot first 9 labyrinth landscapes from each set
idx_lab_selforg <- which(patterns_selforg == "labyrinth")[1:9]
idx_lab_sys <- which(patterns_sys == "labyrinth")[1:9]

plot_landscape_list(
  training_landscapes[idx_lab_selforg],
  ncol = 3
)

plot_landscape_list(
  training_landscapes_sys[idx_lab_sys],
  ncol = 3
)

# Step 5: Check the sampling logic
cli::cli_h2("Sampling Logic Check")

cli::cli_alert_info("Training pool size: {length(training_pool_sys)}")
cli::cli_alert_info("Patterns in pool: {table(training_patterns_sys)}")
cli::cli_alert_info("Samples per pattern requested: {samples_per_pattern_sys}")
cli::cli_alert_info(
  "Total requested: {samples_per_pattern_sys * n_unique_patterns_sys}"
)
cli::cli_alert_info("Actual samples taken: {length(training_indices_sys)}")

# Check if slice_head truncated unevenly
pattern_counts_after_sampling <- table(patterns_sys)
if (any(pattern_counts_after_sampling != pattern_counts_after_sampling[1])) {
  cli::cli_alert_warning("Imbalanced sampling detected!")
  print(pattern_counts_after_sampling)
}
