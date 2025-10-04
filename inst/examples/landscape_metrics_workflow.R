# An example workflow to classify landscapes using landscapemetrics in
# generated landscapes

# load all functions
devtools::load_all()

# ----------------------------------------------------------------------------#
# Step 1: Generate some landscapes ---------------------------------------
# ----------------------------------------------------------------------------#

# Create some landscapes (the more the better)
landscapes <- generate_training_landscapes(
  n = 100,
  types = c("banded", "spots", "labyrinth"),
  add_rotation = TRUE,
  seed = 123
)

# Check how many landscapes of each type were generated
table(purrr::map_chr(landscapes, "type"))

# Plot all landscapes (plot only 20)
plot_landscape_list(landscapes[1:20])

# ----------------------------------------------------------------------------#
# Step 2: Calculate landscape metrics ---------------------------------------
# ----------------------------------------------------------------------------#
# List available landscape metrics
list_available_metrics()
# List available landscape metrics of specific level(s)
list_available_metrics(level = c("class", "landscape"))

# Calculate landscape metrics on the landscape level
landscape_metrics <- calculate_landscape_metrics(
  landscapes,
  level = "landscape"
)

# find the 10 best metrics based on coefficient of variation
best_10 <- evaluate_landscape_metrics(
  calculated_metrics = landscape_metrics,
  metrics_number = 10
)
# Find best 10 based on linear model p-values
best_10_linmod_p <- evaluate_landscape_metrics(
  calculated_metrics = landscape_metrics,
  method = "lin_mod_p",
  metrics_number = 10
)
# Find best 10 based on linear model R-squared
best_10_linmod_r2 <- evaluate_landscape_metrics(
  calculated_metrics = landscape_metrics,
  method = "lin_mod_r2",
  metrics_number = 10
)

# Find best 10 based on difference from group mean
best_10_group_diff <- evaluate_landscape_metrics(
  calculated_metrics = landscape_metrics,
  method = "mean_groups",
  metrics_number = 10
)

# Plot the 10 best metrics
plot_metrics(
  calculated_metrics = landscape_metrics,
  selected_metrics = best_10_group_diff
)

# Train a network -----------------------------------------------
# use k-fold cross-validation with 3 folds
# warning will tell you that folds need to be reduced to 2
model <- train_nn(
  metrics = landscape_metrics,
  metrics_selected = best_10_group_diff,
  cv_method = "k-fold",
  seed = 123
)

# Look at the model object
model

# Visualize classification results
# Get all plots in a list
all_plots <- plot_classification_results(model, return_all = TRUE)
patchwork::wrap_plots(all_plots)

# Or create individual plots with the wrapper
plot_classification_results(model, plot_type = "confusion")
plot_classification_results(model, plot_type = "probabilities")
plot_classification_results(model, plot_type = "confidence")
plot_classification_results(model, plot_type = "misclassifications")

# Plot the landscapes that were misclassified
plot_nn_classification_landscapes(
  classification = model$validation_results,
  landscape_list = landscapes,
  only_misclassified = TRUE
)

# Apply the model ----------------------------------------------------
# generate test landscapes
test_landscapes <- generate_training_landscapes(
  seed = 43,
  n = 20,
  add_rotation = TRUE
)

# plot all landscapes
plot_landscape_list(test_landscapes)

# or generate just a single landscape
test_cluster <- create_landscape(
  pattern = "clustered",
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_clusters = 10,
  cluster_radius = 5,
  seed = 42,
  rotation = 0
)
plot_landscape(test_cluster)

# Apply the model to the test landscape(s)
apply_nn(
  landscapes = test_cluster,
  nn_model = model
)

validation_results <- apply_nn(
  landscapes = test_landscapes,
  nn_model = model
)

plot_nn_classification_landscapes(
  classification = validation_results$predictions,
  landscape_list = test_landscapes,
  only_misclassified = FALSE
)
