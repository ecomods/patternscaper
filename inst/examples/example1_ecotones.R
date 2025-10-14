#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to ecotones (or random)
ecotone_types = c("random","sharp", "diffuse", "curvy", "fingers","scattered","clustered","sine_bands")
ecotone_types_title = c("random","sharp", "diffuse", "curvy", "fingers","scattered","clustered","sine bands")

#--------------------------------------------------------------------
# Generate landscapes for example figure (each type one landscape)
#--------------------------------------------------------------------

# generate landscapes
landscapes_manuscript <- generate_training_landscapes(
  n = 8,
  seed = 42,
  types = ecotone_types
)

# plot all landscapes
plot_landscape_list(landscapes_manuscript,ncol=8, titles = "", show_legend = FALSE)

#--------------------------------------------------------------------
# Generate training landscapes and take a look
#--------------------------------------------------------------------

#generate all training landscapes
ecotone_landscapes <- generate_training_landscapes(
  n = 200,
  seed = 42,
  types = ecotone_types
)

# check how many landscapes of each type were generated
table(purrr::map_chr(ecotone_landscapes, "type"))

# plot first 20 landscapes
plot_landscape_list(ecotone_landscapes[1:20])

#--------------------------------------------------------------------
# Calculate landscapes metrics and determine best ones
#--------------------------------------------------------------------

# calculate landscape metrics on the landscape level
landscape_metrics <- calculate_landscape_metrics(
  ecotone_landscapes,
  level = "landscape"
)

# find the 10 best metrics based on coefficient of variation
best_10 <- evaluate_landscape_metrics(
  calculated_metrics = landscape_metrics,
  metrics_number = 10
)

# plot the 10 best metrics
plot_metrics(
  calculated_metrics = landscape_metrics,
  selected_metrics = best_10
)

#--------------------------------------------------------------------
# Train neural network with landscapes metrics
#--------------------------------------------------------------------

# train a network
# use k-fold cross-validation with 3 folds
# warning will tell you that folds need to be reduced to 2
model_ecotones_lm <- train_nn(
  metrics = landscape_metrics,
  metrics_selected = best_10,
  cv_method = "k-fold",
  seed = 123
)

# look at the model object
model_ecotones_lm

#--------------------------------------------------------------------
# Look at classification results
# -------------------------------------------------------------------

# visualize classification results
# get all plots in a list
all_plots <- plot_classification_results(model_ecotones_lm, return_all = TRUE)
patchwork::wrap_plots(all_plots)

# Or create individual plots with the wrapper
plot_classification_results(model_ecotones_lm, plot_type = "confusion")
plot_classification_results(model_ecotones_lm, plot_type = "probabilities")
plot_classification_results(model_ecotones_lm, plot_type = "confidence")
plot_classification_results(model_ecotones_lm, plot_type = "misclassifications")

# Plot the landscapes that were misclassified
plot_nn_classification_landscapes(
  classification = model_ecotones_lm$validation_results,
  landscape_list = ecotone_landscapes,
  only_misclassified = TRUE
)

# -------------------------------------------------------------------
# Apply the models to new landscapes
# -------------------------------------------------------------------

# generate test landscapes
test_landscapes_ecotone <- generate_training_landscapes(
  seed = 43,
  n = 20,
  add_rotation = TRUE,
  types = ecotone_types
)

# plot all landscapes
plot_landscape_list(test_landscapes_ecotone)

# apply the model to the test landscapes
validation_results_ecotone_lm <- apply_nn(
  landscapes = test_landscapes_ecotone,
  nn_model = model_ecotones_lm
)

#show landscapes that are not classified correctly
plot_nn_classification_landscapes(
  classification = validation_results_ecotone_lm$predictions,
  landscape_list = test_landscapes_ecotone,
  only_misclassified = FALSE
)

# -------------------------------------------------------------------
# Apply the model to pictures ???
# -------------------------------------------------------------------




