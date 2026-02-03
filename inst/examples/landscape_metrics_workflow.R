# An example workflow to classify landscapes using landscapemetrics in
# generated landscapes

# load all functions
devtools::load_all()

# For reproducibility, you have to set the seed
set.seed(123)

# ----------------------------------------------------------------------------#
# Step 1: Generate some landscapes ---------------------------------------
# ----------------------------------------------------------------------------#

# Create some landscapes (the more the better)
landscapes <- create_landscapes(
  n = 100,
  patterns = c("labyrinth", "spots", "labyrinth"),
  add_rotation = TRUE
)

# Check how many landscapes of each type were generated
table(purrr::map_chr(landscapes, ~ .x$pattern))

# Plot all landscapes (plot only 20)
plot_landscape_list(landscapes[1:20])

# ----------------------------------------------------------------------------#
# Step 2: Calculate landscape metrics ---------------------------------------
# ----------------------------------------------------------------------------#
# List available landscape metrics
landscapemetrics::list_lsm() |> dplyr::arrange(metric)

# Calculate landscape metrics on the landscape level
landscape_metrics <- calculate_landscape_metrics(
  landscapes,
  level = "landscape"
)

# find the 10 best metrics based on coefficient of variation
# Verbose = TRUE will print details on which metrics are excluded because of which reasons
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_metrics,
  metrics_number = 10,
  verbose = TRUE
)

# There are different methods to select the best metrics
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_metrics,
  method = "kruskal_p", # one of: "coeffvar_all", "lin_mod_r2", "mean_groups", "fisher_score", "kruskal_p"
  metrics_number = 10
)

# Plot the 10 best metrics
plot_metrics(
  metrics = landscape_metrics,
  selected_metrics = best_10
)

# Train a network -----------------------------------------------
# use k-fold cross-validation with 3 folds
# warning will tell you that folds need to be reduced to 2
model <- train_nn_metrics(
  metrics = landscape_metrics,
  metrics_selected = best_10,
  cv_method = "k-fold"
)

# Look at the model object
model

# Apply the model ----------------------------------------------------
# generate test landscapes
test_landscapes <- create_landscapes(
  patterns = c("labyrinth", "spots", "labyrinth"),
  n = 20,
  add_rotation = TRUE
)

# plot all landscapes
plot_landscape_list(test_landscapes)

# or generate just a single landscape
test_labyrinth <- create_landscape(
  pattern = "labyrinth",
  width = 100,
  height = 100
)
plot_landscape(test_labyrinth)

# Apply the model to the test landscape(s)
apply_nn_metrics(
  landscapes = test_labyrinth,
  nn_model = model
)

validation_results <- apply_nn_metrics(
  landscapes = test_landscapes,
  nn_model = model
)

plot_classified_landscapes(
  classification = validation_results,
  landscapes = test_landscapes,
  only_misclassified = FALSE
)

# ----------------------------------------------------------------------------#
# Example of a workflow on class level metrics -------------------------------
# ----------------------------------------------------------------------------#
# Calculate class-level metrics
class_metrics <- calculate_landscape_metrics(
  landscapes,
  level = "class"
)

# find the 10 best metrics based on coefficient of variation
best_10_class <- evaluate_landscape_metrics(
  metrics = class_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)

# Train a network -----------------------------------------------
model_class <- train_nn_metrics(
  metrics = class_metrics,
  metrics_selected = best_10_class,
  cv_method = "loo"
)

# Apply the model ----------------------------------------------------
validation_results <- apply_nn_metrics(
  landscapes = test_landscapes,
  nn_model = model_class
)

plot_classified_landscapes(
  classification = validation_results,
  landscapes = test_landscapes,
  only_misclassified = FALSE
)
