# Load all functions
devtools::load_all()

# -----------------------------------------------------------------------------#
# Setup keras ------------------------------------------------------------------
# -----------------------------------------------------------------------------#
# You need to have a python version <=3.11 installed
# install.packages("keras3")
# keras3::install_keras()

set_random_seed(123456)
# Test Keras NN ---------------------------------------------------------
# Increase number of landscapes for better training
training_landscapes <- create_training_landscapes(
  n = 200, # Larger dataset for better generalization
  patterns = c(
    "sharp",
    "diffuse",
    "clustered",
    "fingers",
    "bands",
    "random"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE
)
# create test landscapes
test_landscapes <- create_training_landscapes(
  n = 20,
  patterns = c(
    "sharp",
    "diffuse",
    "clustered",
    "fingers",
    "bands",
    "random"
  ),
  add_rotation = TRUE
)

# Train a model
model <- train_nn_pixels(
  landscapes = training_landscapes,
  cv_method = "k-fold",
  cv_folds = 5
)

# Apply trained model to test landscapes
validation_results <- apply_nn_pixels(
  landscapes = test_landscapes,
  nn_model = model,
  return_performance = TRUE
)

# Look at the model object
model

# Visualize classification results
# Get all plots in a list
all_plots <- plot_classification_results(model, return_all = TRUE)
patchwork::wrap_plots(all_plots)

plot_classification_results(model, plot_type = "confusion")
plot_classification_results(model, plot_type = "probabilities")
plot_classification_results(model, plot_type = "confidence")
plot_classification_results(model, plot_type = "misclassifications")

# Plot the landscapes that were misclassified
plot_classified_landscapes(
  classification = model$performance$validation_results,
  landscapes = training_landscapes,
  only_misclassified = TRUE
)

# Apply the model ----------------------------------------------------
# create test landscapes
test_landscapes <- create_training_landscapes(
  n = 20,
  patterns = c(
    "sharp",
    "diffuse",
    "clustered",
    "fingers",
    "sine_bands",
    "random"
  ),
  add_rotation = TRUE
)

# plot all landscapes
plot_landscape_list(test_landscapes)

# or create just a single landscape
test_cluster <- create_landscape(
  pattern = "clustered",
  width = 100,
  height = 100,
  treeline_position = 0.5,
  n_clusters = 10,
  cluster_radius = 5,
  rotation = 0
)
plot_landscape(test_cluster)

# Apply the model to the test landscape(s)
apply_nn_pixels(
  landscape = test_cluster,
  nn_model = model
)

validation_results <- apply_nn_pixels(
  landscapes = test_landscapes,
  nn_model = model,
  return_performance = TRUE
)

plot_classified_landscapes(
  classification = validation_results$predictions,
  landscapes = test_landscapes,
  only_misclassified = FALSE
)
