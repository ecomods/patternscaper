#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to ecotones (or random)
ecotone_types = c(
  "random",
  "sharp",
  "diffuse",
  "curvy",
  "fingers",
  "scattered",
  "clustered",
  "sine_bands"
)
n_ecotones <- length(ecotone_types)

#--------------------------------------------------------------------
# Generate landscapes for example figure (each type one landscape)
#--------------------------------------------------------------------

# generate landscapes
landscapes_manuscript <- create_training_landscapes(
  n = n_ecotones,
  seed = 42,
  patterns = ecotone_types
)

# plot all landscapes
plot_landscape_list(
  landscapes_manuscript,
  ncol = n_ecotones,
  show_legend = FALSE
)

#--------------------------------------------------------------------
# Generate training landscapes and take a look
#--------------------------------------------------------------------

#generate all training landscapes
ecotone_landscapes <- create_training_landscapes(
  n = 200,
  seed = 42,
  patterns = ecotone_types
)

# check how many landscapes of each pattern were generated
table(purrr::map_chr(ecotone_landscapes, ~ .x$pattern))

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
model_ecotones_lm <- train_nn_metrics(
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
plot_classified_landscapes(
  classification = model_ecotones_lm$validation_results,
  landscapes = ecotone_landscapes,
  only_misclassified = TRUE
)

# -------------------------------------------------------------------
# Apply the models to new landscapes
# -------------------------------------------------------------------

# generate test landscapes
test_landscapes_ecotone <- create_training_landscapes(
  seed = 43,
  n = 50,
  add_rotation = TRUE,
  patterns = ecotone_types
)

# plot first 20 landscapes
plot_landscape_list(test_landscapes_ecotone[1:20])

# apply the model to the test landscapes
validation_results_ecotone_lm <- apply_nn_metrics(
  landscapes = test_landscapes_ecotone,
  nn_model = model_ecotones_lm
)

validation_results_ecotone_lm

#show landscapes that are not classified correctly
plot_classified_landscapes(
  classification = validation_results_ecotone_lm$predictions,
  landscapes = test_landscapes_ecotone,
  only_misclassified = TRUE
)

# -------------------------------------------------------------------
# Apply the model to pictures NOT FINISHED YET
# -------------------------------------------------------------------

# Read in the satellite image
pic_dir <- "inst/examples/Ecotone/" #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

i <- 1
image <- terra::rast(paste(pic_dir, pic_names[i], sep = ""))
# If it's a multi-band image
band1 <- image[[1]]
# Apply threshold
binary_class <- band1 < 70 #this parameter determines the sensitivity towards
#classification as vegetation - the higher the more vegetation
test_matrix <- as.matrix(binary_class, wide = TRUE)
test_raster <- terra::rast(test_matrix)

#test plotting of binary categorization
par(mfrow = c(1, 2), pty = "s")
raster::plot(
  raster::flip(band1),
  col = terrain.colors(25),
  main = "Initial Landscape"
)
raster::plot(
  raster::flip(test_raster),
  col = c(terrain.colors(25)[25], terrain.colors(25)[1]),
  main = "Binary Landscape"
)
par(mfrow = c(1, 1))

# Bring the test raster in the right format for package functions
test_raster_l <- landscape(data = test_raster, name = "test raster")

#apply the neural metwork model to the picture
result_pics <- apply_nn_metrics(
  landscapes = test_raster_l,
  nn_model = model_ecotones_lm
)

#show predicted type
pic_names[i]
result_pics$predictions
