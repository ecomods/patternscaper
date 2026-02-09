# Classify real, binarized landscapes based on metrics and pixels

# Load required libraries -------------------------------------------------

# library(spatPatClassifyR)

# load all analysis functions
devtools::load_all()

# Initialize globals ------------------------------------------------------

# directory for the landscape images
# images_directory <- "data-raw/landscape_images"
images_directory <- "inst/pics_for_paper/Pics"

# Create binarized images
source("inst/analyses/functions/binarize_images.R")

plot_landscape_list(pics_landscapes, show_legend = FALSE)

# Directory to save the output figures
# fig_directory <- "figures"
# fig_directory_supp <- file.path(fig_directory, "supplementary")

# # Save model and metrics results for later evaluation
# result_path <- "data/classify_images/"
# model_path_metrics <- file.path(result_path, "models")
# model_path_pixels <- file.path(result_path, "models")

# # Save metrics used
# metrics_path <- file.path(result_path, "metrics")

# # Save predictions
# predictions_path <- file.path(result_path, "predictions")

# Read in and binarize the real landscapes --------------------------------

# Read, binarize and convert the real landscapes to landscape objects
# images_binary <- binarize_images(images_directory)

# plot_landscape_list(images_binary, show_legend = FALSE)

# Create training landscapes -----------------------------------------------

# Here we create training landscpapes with user defined pattern parameters.
# This is done so that the training landscapes are more similar to the real
# landscapes that we want to classify.

selforg_patterns = c(
  "random",
  "spots",
  "labyrinth",
  "gaps"
)

l_size <- 200

training_landscapes <- list()

n_landscapes_per_pattern <- 20

# Set seed for reproducibility
set.seed(321)


training_landscapes <- purrr::map(1:n_landscapes_per_pattern, \(i) {
  # Create gaps
  n_sp <- sample(3:20, 1)
  n_rad <- sample(round(90 / n_sp):round(250 / n_sp), 1)

  temp_gaps <- create_landscape(
    pattern = "gaps",
    width = l_size,
    height = l_size,
    n_spots = n_sp,
    spot_radius = n_rad,
    spot_radius_sd = sample(3:5, 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.4),
    regular_spots = TRUE,
    name = paste0("gaps_", i)
  )

  # Create spots
  n_sp <- sample(3:12, 1)
  n_rad <- sample(round(150 / n_sp):round(200 / n_sp), 1)

  temp_spots <- create_landscape(
    pattern = "spots",
    width = l_size,
    height = l_size,
    n_spots = n_sp,
    spot_radius = n_rad,
    spot_radius_sd = sample(3:5, 1),
    radius_noise_fraction = runif(1, 0.05, 0.4),
    regular_spots = TRUE,
    name = paste0("spots_", i)
  )

  # Create labyrinth
  temp_labyrinth <- create_landscape(
    pattern = "labyrinth",
    width = l_size,
    height = l_size,
    frequency = runif(1, 2.6, 3.2),
    veg_threshold = runif(1, 0.48, 0.52),
    band_fuzziness = runif(1, 0.06, 0.2),
    octaves = sample(2:4, 1),
    name = paste0("labyrinth_", i)
  )

  # Create random
  temp_random <- create_landscape(
    pattern = "random",
    width = l_size,
    height = l_size,
    tree_prop = runif(1, 0.01, 0.99),
    name = paste0("random_", i)
  )

  # Put all landscapes in a list
  list(
    gaps = temp_gaps,
    spots = temp_spots,
    labyrinth = temp_labyrinth,
    random = temp_random
  )
})

training_landscapes <- purrr::flatten(training_landscapes)

# plot first 36 landscapes
plot_landscape_list(training_landscapes, show_legend = FALSE)

# Approach 1: Classify based on landscape metrics --------------------------
# Calculate landscape metrics for the training landscapes -------------------
landscape_metrics <- calculate_landscape_metrics(
  landscapes = training_landscapes,
  level = "class"
)

# Focus only on the vegetation class (no bare soil)
landscape_metrics <- landscape_metrics |>
  dplyr::filter(class == 1)

# Find the 10 best metrics that differentiate self-organized patterns based on
# Kruskal-Wallis p-value
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)

# Save the metrics filtered by the best 10 metrics for later use in the evaluation
# write_csv(
#   landscape_metrics |>
#     dplyr::filter(
#       metric %in% best_10
#     ),
#   file.path(
#     metrics_path,
#     paste0("landscape_metrics_ntest_", n_landscapes_per_pattern, ".csv")
#   )
# )

# Plot the 10 best metrics
fig_metrics <- plot_metrics(
  metrics = landscape_metrics,
  selected_metrics = best_10,
  force = TRUE
)

# Train model based on the 10 best metrics ---------------------------------
model_metrics <- train_nn_metrics(
  metrics = landscape_metrics,
  metrics_selected = best_10,
  cv_method = "none"
)

# Approach 2: Classify based on the input data itself (pixels) -------------

# Set seed for reproducibility of each run
set_random_seed(123456)

# Train model directly on pixel values
model_pixels <- train_nn_pixels(
  landscapes = training_landscapes,
  cv_method = "none",
  learning_rate = 0.0001,
  epochs = 20
)

# Apply the models to the binarized images --------------------------------
predictions_metrics <- apply_nn_metrics(
  landscapes = pics_landscapes,
  nn_model = model_metrics
)

predictions_pixel <- apply_nn_pixels(
  landscapes = pics_landscapes,
  nn_model = model_pixels
)

# Save as csv file
# readr::write_csv(
#   predictions_metrics,
#   file.path(
#     predictions_path,
#     paste0("predictions_metrics_n_", n_landscapes_per_pattern, ".csv")
#   )
# )
# readr::write_csv(
#   predictions_pixel,
#   file.path(
#     predictions_path,
#     paste0("predictions_pixel_n_", n_landscapes_per_pattern, ".csv")
#   )
# )
