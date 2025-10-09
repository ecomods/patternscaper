# An example workflow to classify landscapes using landscapemetrics in
# generated landscapes

# load all functions
devtools::load_all()

# ----------------------------------------------------------------------------#
# Step 1: Generate some landscapes -------------------------------------------
# ----------------------------------------------------------------------------#

# Create some landscapes (the more the better)
landscapes <- generate_training_landscapes(
  n = 100,
  add_rotation = FALSE,
  seed = NULL,
  types = c("spots","gaps","banded","labyrinth")
)

# Check how many landscapes of each type were generated
table(purrr::map_chr(landscapes, "type"))

# Plot all landscapes (plot only 20)
plot_landscape_list(landscapes[1:20])

# ----------------------------------------------------------------------------#
# Step 2a: Calculate landscape metrics ---------------------------------------
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
  selected_metrics = best_10_linmod_r2
)

# Train a network -----------------------------------------------
# use k-fold cross-validation with 3 folds
# warning will tell you that folds need to be reduced to 2
model_l <- train_nn(
  metrics = landscape_metrics,
  metrics_selected = best_10_group_diff,
  cv_method = "k-fold",
  seed = 123
)

# Look at the model object
model_l


# ----------------------------------------------------------------------------#
# Step 2b: Calculate  model according to keras workflow ----------------------
# ----------------------------------------------------------------------------#

# Train a model
#BRITTA - LÄUFT DERZEIT BEI MIR NICHT
model_k <- train_nn_keras(
  landscapes = landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 30,
  model_path = "models/landscape_classifier"
)

# Look at the model object
model_k


# ----------------------------------------------------------------------------#
# Step 3: Look at classification results  ----------------
# ----------------------------------------------------------------------------#

#-------------------------------------------------
# a) for model using landscapes metrics
#-------------------------------------------------

# Visualize classification results
# Get all plots in a list
all_plots <- plot_classification_results(model_l, return_all = TRUE)
patchwork::wrap_plots(all_plots)

# Or create individual plots with the wrapper
plot_classification_results(model_l, plot_type = "confusion")
plot_classification_results(model_l, plot_type = "probabilities")
plot_classification_results(model_l, plot_type = "confidence")
plot_classification_results(model_l, plot_type = "misclassifications")

# Plot the landscapes that were misclassified
plot_nn_classification_landscapes(
  classification = model_l$validation_results,
  landscape_list = landscapes,
  only_misclassified = TRUE
)

#-------------------------------------------------
# b) for model using keras
#BRITTA - LÄUFT DERZEIT BEI MIR NICHT
#-------------------------------------------------

# Visualize classification results
# Get all plots in a list
all_plots <- plot_classification_results(model_l, return_all = TRUE)
patchwork::wrap_plots(all_plots)

plot_classification_results(model_l, plot_type = "confusion")
plot_classification_results(model_l, plot_type = "probabilities")
plot_classification_results(model_l, plot_type = "confidence")
plot_classification_results(model_l, plot_type = "misclassifications")

# Plot the landscapes that were misclassified
plot_nn_classification_landscapes(
  classification = model_l$validation_results,
  landscape_list = training_landscapes,
  only_misclassified = TRUE
)


# ----------------------------------------------------------------------------#
# Step 4: Apply the models to new landscapes --------------------------------
# ----------------------------------------------------------------------------#

# generate test landscapes
test_landscapes <- generate_training_landscapes(
  seed = 43,
  n = 20,
  add_rotation = FALSE,
  types = c("spots","inverted_spots","banded","labyrinth")
)

# plot all landscapes
plot_landscape_list(test_landscapes)


#-------------------------------------------------
# a) for model using landscapes metrics
#-------------------------------------------------

# Apply the model to the test landscape(s)
validation_results_l <- apply_nn(
  landscapes = test_landscapes,
  nn_model = model_l
)

plot_nn_classification_landscapes(
  classification = validation_results_l$predictions,
  landscape_list = test_landscapes,
  only_misclassified = TRUE
)


#-------------------------------------------------
# b) for model using keras
#BRITTA - LÄUFT DERZEIT BEI MIR NICHT
#-------------------------------------------------

# Apply the model to the test landscape(s)

validation_results_k <- apply_nn_keras(
  landscape = test_landscapes,
  nn_model = model_k
)

plot_nn_classification_landscapes(
  classification = validation_results_k$predictions,
  landscape_list = test_landscapes,
  only_misclassified = FALSE
)

# ----------------------------------------------------------------------------#
# Step 5: Apply the models to pictures --------------------------------------
# does not work, yet!!! --------------------------------------
# ----------------------------------------------------------------------------#
# Read in the satellite image
pic_dir <- "inst/examples/Pics/" #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

#Fehler: 1,3
#Falsch: 2,10 (spots/gaps)
#Korrekt: 4,8,9, 11 (Farben falsch herum)
#Halb Falsch: 5,6,7 (Binary Class Einteilung)

i <- 8
image <- terra::rast(paste(pic_dir,pic_names[i],sep=""))
# If it's a multi-band image
band1 <- image[[1]]
# Apply threshold
binary_class <- band1 > 150
test_matrix <- as.matrix(binary_class, wide = TRUE)
test_matrix <- t(1 - test_matrix)
test_raster <- terra::rast(test_matrix)


raster::plot(band1,col=terrain.colors(25))
image(
  test_matrix,
  col = c("orange2", "darkgreen"),
  main = "Spatial Plot of test_matrix"
)

result_l <- apply_nn(
  landscapes = test_raster,
  nn_model = model_l
)

plot_nn_classification_landscapes(
  classification = validation_results_l$predictions,
  landscape_list = test_landscapes,
  only_misclassified = TRUE
)

result_pics <- apply_nn(
  landscapes = test_raster,
  nn_model = model_l
)

pic_names[i]
result_pics$predictions

plot_nn_classification_landscapes(
  classification = result_pics$predictions,
  landscape_list = list(test_raster),
  only_misclassified = FALSE
)

