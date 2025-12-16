devtools::load_all()

# Get binarized images as variable pics_landscapes
source("inst/analyses/functions/binarize_images.R")

set.seed(12345)

#create new landscapes for training (20 of each type) manually ----------------
training_landscapes <- list()
for (i in 1:20) {
  j <- (i - 1) * 5 + 1
  temp_landscape <- create_landscape_gaps(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(20, 25), size = 1),
    spot_radius_sd = sample(x = seq(3, 8), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = sample(x = c(T, F), size = 1)
  )
  plot_landscape(temp_landscape)
  landscape_name <- paste("landscape_gaps_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_spots(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(20, 25), size = 1),
    spot_radius_sd = sample(x = seq(3, 8), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = sample(x = c(T, F), size = 1)
  )
  landscape_name <- paste("landscape_spots_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  wh <- sample(seq(120, 150), 1)
  temp_landscape <- create_landscape_labyrinth(
    width = wh,
    height = wh,
    frequency = runif(n = 1, min = 1, max = 10) * wh / 100,
    veg_threshold = runif(n = 1, min = 0.5, max = 0.7),
    band_fuzziness = runif(n = 1, min = 0, max = 0.005),
    octaves = sample(x = seq(1, 5), size = 1)
  )
  landscape_name <- paste("landscape_labyrinth_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    tree_prop = runif(n = 1, min = 0.01, max = 0.2)
  )
  temp_landscape$pattern <- "bare"
  landscape_name <- paste("landscape_bare_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    tree_prop = runif(n = 1, min = 0.8, max = 0.99)
  )
  temp_landscape$pattern <- "dense"
  landscape_name <- paste("landscape_dense_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
}

# check how many landscapes of each pattern were generated
table(purrr::map_chr(training_landscapes, ~ .x$pattern))

# calculate landscape metrics at the class level
landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = training_landscapes,
  level = "class"
)

#focus on vegetation class only
metric_class <- 1
landscape_class_metrics <- landscape_class_metrics_all %>%
  filter(class == metric_class)

#determine best 10 metrics to distinguish pattern types
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)
best_10


#--------------------------------------------------------------------
# Train neural network with landscapes metrics
#--------------------------------------------------------------------

# train a network
model_selforga_pics <- train_nn_metrics(
  metrics = landscape_class_metrics,
  metrics_selected = best_10,
  cv_method = "k-fold"
)

# look at the model object
model_selforga_pics$performance$accuracy

# And not with less manually selected landscapes-------------------------------
training_landscapes_automatic <- create_training_landscapes(
  n = 100,
  patterns = c(
    "bare",
    "spots",
    "labyrinth",
    "gaps",
    "dense"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = c(0, 45, 90, 135, 180)
)

# calculate landscape metrics at the class level
landscape_class_metrics_all_automatic <- calculate_landscape_metrics(
  landscapes = training_landscapes_automatic,
  level = "class"
)

#focus on vegetation class only
metric_class <- 1
landscape_class_metrics_automatic <- landscape_class_metrics_all_automatic %>%
  filter(class == metric_class)

#determine best 10 metrics to distinguish pattern types
best_10_automatic <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics_automatic,
  metrics_number = 10,
  method = "kruskal_p"
)

# train a network
model_selforga_pics_automatic <- train_nn_metrics(
  metrics = landscape_class_metrics_automatic,
  metrics_selected = best_10_automatic,
  cv_method = "k-fold"
)

# Classify the images and check which model is better --------------------------
plot_landscape_list(pics_landscapes, titles = "both")

# Apply the model to the pictures
picture_classification <- apply_nn_metrics(
  nn_model = model_selforga_pics,
  landscapes = pics_landscapes
)
picture_classification_automatic <- apply_nn_metrics(
  nn_model = model_selforga_pics_automatic,
  landscapes = pics_landscapes
)
