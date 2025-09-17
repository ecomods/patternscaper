# Load all functions
devtools::load_all()

# Test Keras NN ---------------------------------------------------------
# Increase number of landscapes for better training
training_landscapes <- generate_training_landscapes(
  seed = 42,
  n = 100, # Larger dataset for better generalization
  types = c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "scattered",
    "clustered",
    "sine_bands"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = c(0, 45, 90, 135, 180)
)

# Train a model
model <- train_nn_keras(
  landscapes = training_landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 30,
  model_path = "models/landscape_classifier"
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
plot_nn_classification_landscapes(
  classification = model$validation_results,
  landscape_list = training_landscapes,
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
apply_nn_keras(
  landscape = test_cluster,
  nn_model = model
)

validation_results <- apply_nn_keras(
  landscape = test_landscapes,
  nn_model = model
)

plot_nn_classification_landscapes(
  classification = validation_results$predictions,
  landscape_list = test_landscapes,
  only_misclassified = FALSE
)
