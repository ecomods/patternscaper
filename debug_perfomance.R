# Debug Script: Neural Network Performance Investigation
# Purpose: Systematically test why confidence values are low (~0.4) after softmax

# Setup -------------------------------------------------------------------
devtools::load_all()
library(spatPatClassifyR)
set.seed(123456)
library(tidyverse)

# Step 1: Generate Training Data ------------------------------------------
# Test with different sample sizes to check if data quantity is the issue

# cat("\n=== STEP 1: Generate Training Data ===\n")

# # Small dataset (current approach)
# landscapes_small <- create_landscapes(
#   n = 100,
#   patterns = c("labyrinth", "random", "clustered")
# )

# # Medium dataset
# landscapes_medium <- create_landscapes(
#   n = 300,
#   patterns = c("labyrinth", "random", "clustered")
# )

# # Large dataset
# landscapes_large <- create_landscapes(
#   n = 500,
#   patterns = c("labyrinth", "random", "clustered")
# )

# cat("✓ Created datasets: 100, 300, 500 landscapes\n")

# # Step 2: Calculate Metrics -----------------------------------------------
# cat("\n=== STEP 2: Calculate Landscape Metrics ===\n")

# metrics_small <- calculate_landscape_metrics(
#   landscapes_small,
#   level = "landscape"
# )
# metrics_medium <- calculate_landscape_metrics(
#   landscapes_medium,
#   level = "landscape"
# )
# metrics_large <- calculate_landscape_metrics(
#   landscapes_large,
#   level = "landscape"
# )

# # Write to file
# write_csv(metrics_small, "debug_metrics_small.csv")
# write_csv(metrics_medium, "debug_metrics_medium.csv")
# write_csv(metrics_large, "debug_metrics_large.csv")

# Try with very distinct patterns first
# landscapes_easy <- create_landscapes(
#   n = 100,
#   patterns = c("sharp", "random") # Very different patterns
# )

# metrics_easy <- calculate_landscape_metrics(
#   landscapes_easy,
#   level = "landscape"
# )
# write_csv(metrics_easy, "debug_metrics_easy.csv")

# Read back
metrics_small <- read_csv("debug_metrics_small.csv")
metrics_medium <- read_csv("debug_metrics_medium.csv")
metrics_large <- read_csv("debug_metrics_large.csv")
metrics_easy <- read_csv("debug_metrics_easy.csv")

# Create test landscapes

# Step 3: Feature Selection Analysis --------------------------------------
test_landscapes <- create_landscapes(
  n = 20,
  patterns = c("labyrinth", "random", "clustered")
)
test_landscapes_easy <- create_landscapes(
  n = 20,
  patterns = c("sharp", "random")
)

# Calculate best 10 and best 20 for all metrics combis --------------------
best_10_easy <- evaluate_landscape_metrics(
  metrics = metrics_easy,
  method = "kruskal_effsize",
  metrics_number = 10,
  verbose = FALSE
)

best_20_easy <- evaluate_landscape_metrics(
  metrics = metrics_easy,
  method = "kruskal_effsize",
  metrics_number = 20,
  verbose = FALSE
)

best_10_small <- evaluate_landscape_metrics(
  metrics = metrics_small,
  method = "kruskal_effsize",
  metrics_number = 10,
  verbose = FALSE
)

best_20_small <- evaluate_landscape_metrics(
  metrics = metrics_small,
  method = "kruskal_effsize",
  metrics_number = 20,
  verbose = FALSE
)

best_10_medium <- evaluate_landscape_metrics(
  metrics = metrics_medium,
  method = "kruskal_effsize",
  metrics_number = 10,
  verbose = FALSE
)

best_20_medium <- evaluate_landscape_metrics(
  metrics = metrics_medium,
  method = "kruskal_effsize",
  metrics_number = 20,
  verbose = FALSE
)

best_10_large <- evaluate_landscape_metrics(
  metrics = metrics_large,
  method = "kruskal_effsize",
  metrics_number = 10,
  verbose = FALSE
)

best_20_large <- evaluate_landscape_metrics(
  metrics = metrics_large,
  method = "kruskal_effsize",
  metrics_number = 20,
  verbose = FALSE
)


# Step 5: Train Models with Different Configurations ---------------------

# Model 1: Small data, default architecture
model_1 <- train_nn_metrics(
  metrics = metrics_small,
  metrics_selected = best_10,
  cv_method = "none"
)

# Model 2: Small data, more complex architecture
model_2 <- train_nn_metrics(
  metrics = metrics_small,
  metrics_selected = best_10,
  hidden_layers = c(20, 10),
  cv_method = "none"
)

# Model 3: Small data, more features
model_3 <- train_nn_metrics(
  metrics = metrics_small,
  metrics_selected = best_20,
  cv_method = "none"
)


# Model 4: Medium data
model_4 <- train_nn_metrics(
  metrics = metrics_medium,
  metrics_selected = best_10,
  cv_method = "none"
)


# Model 5: Large data
model_5 <- train_nn_metrics(
  metrics = metrics_large,
  metrics_selected = best_10,
  cv_method = "none"
)

all_models <- list(
  model_1,
  model_2,
  model_3,
  model_4,
  model_5
)

# Apply all on the test set
test_results <- lapply(all_models, function(mod) {
  apply_nn_metrics(
    landscapes = test_landscapes,
    nn_model = mod,
    return_performance = FALSE
  )
})


# Simple landscapes ---------------------------------------------------------

# Model 6: Easy 2-class problem
model_6 <- train_nn_metrics(
  metrics = metrics_easy,
  metrics_selected = best_10_easy,
  cv_method = "none"
)

# Apply values
res_6 <- apply_nn_metrics(
  landscapes = test_landscapes_easy,
  nn_model = model_6,
  return_performance = TRUE
)

# Step 8: Compare Raw vs Softmax Outputs ----------------------------------
cat("\n=== STEP 8: Inspect Raw Neural Network Outputs ===\n")

# Take first test landscape
test_single <- test_landscapes_easy[1]
test_metrics_single <- calculate_landscape_metrics(
  test_single,
  level = "landscape"
)

# Get scaled predictors as the model would use them
predictors <- test_metrics_single |>
  dplyr::filter(metric %in% model_6$features) |>
  tidyr::pivot_wider(
    id_cols = landscape_id,
    names_from = metric,
    values_from = value
  ) |>
  dplyr::select(-landscape_id)

# Scale using model's scaling parameters
predictors_scaled <- scale(
  predictors,
  center = model_6$scaling$center,
  scale = model_6$scaling$scale
)

# Get raw predictions
pred_raw <- predict(
  model_6$model,
  newdata = predictors_scaled,
  type = "raw"
)

# Apply softmax manually
softmax <- function(x) {
  exp_x <- exp(x - max(x))
  exp_x / sum(exp_x)
}

pred_probs <- softmax(pred_raw[1, ])

pred_probs
pred_raw

sum(pred_probs)

# Now the same with a more complex landscpae and model -
test_single_complex <- test_landscapes[1]
test_metrics_single_complex <- calculate_landscape_metrics(
  test_single_complex,
  level = "landscape"
)

# Get scaled predictors as the model would use them
predictors <- test_metrics_single_complex |>
  dplyr::filter(metric %in% model_1$features) |>
  tidyr::pivot_wider(
    id_cols = landscape_id,
    names_from = metric,
    values_from = value
  ) |>
  dplyr::select(-landscape_id)

# Scale using model's scaling parameters
predictors_scaled <- scale(
  predictors,
  center = model_1$scaling$center,
  scale = model_1$scaling$scale
)

# Get raw predictions
pred_raw <- predict(
  model_1$model,
  newdata = predictors_scaled,
  type = "raw"
)

# Apply softmax manually
softmax <- function(x) {
  exp_x <- exp(x - max(x))
  exp_x / sum(exp_x)
}

pred_probs <- softmax(pred_raw[1, ])

pred_probs
pred_raw

sum(pred_probs)
