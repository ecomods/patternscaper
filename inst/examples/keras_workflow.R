# Load all functions
devtools::load_all()

# -----------------------------------------------------------------------------#
# Setup keras ------------------------------------------------------------------
# -----------------------------------------------------------------------------#
# You need to have a python version <=3.11 installed
# install.packages("keras3")
# keras3::install_keras()

# ----------------------------------------------------------------------------#
# Prewarm Keras ---------------------------------------------------------------
# ----------------------------------------------------------------------------#
# The first time tensorflow is set up, it takes time. Therefore, we do it outside
# the training function to make the setup explicit. This is just a placehodler for
# later
prewarm_keras <- function() {
  cat("Initializing keras3/TensorFlow backend...\n")

  start_time <- Sys.time()

  # The simplest operation that triggers TensorFlow initialization
  # You don't need a full model!
  keras3::to_categorical(0)

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  cat(sprintf("✓ Backend ready (%.1f seconds)\n", elapsed))
  invisible(TRUE)
}

# Call the function
prewarm_keras()

# Test Keras NN ---------------------------------------------------------
# Increase number of landscapes for better training
training_landscapes <- create_training_landscapes(
  n = 100, # Larger dataset for better generalization
  patterns = c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "clustered",
    "bands"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = c(0, 45, 90, 135, 180)
)

# Train a model
model <- train_nn_landscapes(
  landscapes = training_landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 10,
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
plot_classified_landscapes(
  classification = model$validation_results,
  landscapes = training_landscapes,
  only_misclassified = TRUE
)

# Apply the model ----------------------------------------------------
# create test landscapes
test_landscapes <- create_training_landscapes(
  n = 20,
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
apply_nn_landscapes(
  landscape = test_cluster,
  nn_model = model
)

validation_results <- apply_nn_landscapes(
  landscape = test_landscapes,
  nn_model = model
)

plot_classified_landscapes(
  classification = validation_results$predictions,
  landscapes = test_landscapes,
  only_misclassified = FALSE
)
