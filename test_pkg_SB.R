# A script to test the functions in the package

# load all functions
devtools::load_all()

# List available landscape metrics
list_available_metrics()
list_available_metrics(level = c("class", "landscape"))

# Calculate landscape metrics for all patterns
# ---- Basic Test: Single landscape, all metrics ----
# Create a simple landscape
landscapes <- generate_training_landscapes(add_rotation = TRUE)
plot_landscape_list(landscapes)

test_metrics <- calculate_landscape_metrics(
  landscapes,
  level = "landscape"
)

best_5 <- evaluate_landscape_metrics(test_metrics, metrics_number = 5)

# metric visualizations
plot_raw_metrics(test_metrics, subset = best_5, plot_type = "boxplot")
plot_raw_metrics(test_metrics, plot_type = "heatmap")
all_metric_plots <- plot_raw_metrics(
  test_metrics,
  subset = best_5,
  return_all = TRUE
)
patchwork::wrap_plots(all_metric_plots)

# Train a neural network with the metrics ------------------------------------

# generate more training landscapes
training_landscapes <- generate_training_landscapes(
  seed = 42,
  n = 20,
  add_rotation = TRUE
)
# calculate metrics for the training landscapes
training_metrics <- calculate_landscape_metrics(
  training_landscapes,
  level = "landscape"
)

# select the best 10 metrics for training
best_10 <- evaluate_landscape_metrics(
  calculated_metrics = training_metrics,
  metrics_number = 10
)

# train the neural network model
model <- train_nn(
  metrics = training_metrics,
  metrics_selected = best_10,
  cv_folds = 3,
  test = TRUE
)

# Plot training results ------------------------------------------------------

# Validate the model ---------------------------------------------------------
# generate validation landscapes
validation_landscapes <- generate_training_landscapes(
  seed = 43,
  n = 20,
  add_rotation = TRUE
)


# Test model with new landscapes ---------------------------------------------

# Other tests ----------------------------------------------------------------

landscapes <- test_cluster
calculate_landscape_metrics(test_cluster, level = "landscape")

# Test with single landscape
metrics_single <- calculate_landscape_metrics(
  test_landscapes,
  level = "landscape"
)


# Test function to generate multiple training landscapes
test_landscapes <- generate_training_landscapes(add_rotation = TRUE)
# or deterministically
test_landscapes <- generate_training_landscapes(
  add_rotation = FALSE,
  seed = 42
)

generate_training_landscapes(n = 20) |>
  plot_landscape_list()


# Test landscape creation function
test_cluster <- create_landscape(
  pattern = "clustered",
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_clusters = 10,
  cluster_radius = 5,
  seed = 42,
  rotation = 0,
  add_metadata = TRUE
)
test_cluster_rot <- create_landscape(
  pattern = "clustered",
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_clusters = 10,
  cluster_radius = 5,
  seed = 42,
  rotation = 45,
  add_metadata = TRUE
)

plot_landscape(test_cluster_rot)


# Test with diffuse treeline
create_landscape(
  pattern = "diffuse",
  width = 100,
  height = 100,
  rotation = 45,
  seed = 42
) |>
  plot_landscape()

# curvy treeline
create_landscape(
  pattern = "curvy",
  width = 100,
  height = 100,
  treeline_position = 0.5,
  rotation = 45
) |>
  plot_landscape()

# fingers
create_landscape(
  pattern = "fingers",
  width = 100,
  height = 100,
  num_fingers = 5,
  finger_width = 3,
  rotation = 45
) |>
  plot_landscape()

# bent fingers
create_landscape(
  pattern = "bent_fingers",
  width = 100,
  height = 100,
  num_fingers = 5,
  finger_width = 3,
  rotation = 45
) |>
  plot_landscape()

# scattered trees
create_landscape(
  pattern = "scattered",
  width = 100,
  height = 100,
  treeline_position = 0.5,
  scatter_density = 0.2,
  rotation = 0
) |>
  plot_landscape()

# sine bands
create_landscape(
  pattern = "sine_bands",
  width = 100,
  height = 100,
  amplitude = 8,
  frequency = pi / 50,
  noise = TRUE,
  rotation = 0
) |>
  plot_landscape()

# Test individual landscape creation functions

# Test all individual landscape function with rotation 45
create_landscape_bent_fingers(rotation = 45)
create_landscape_clustered_trees(rotation = 45)
create_landscape_curvy_treeline(rotation = 45)
create_landscape_diffuse_treeline(rotation = 45)
create_landscape_fingers(rotation = 45)
create_landscape_scattered_trees(rotation = 45, as_raster = FALSE)


# clustered trees
test_cluster <- create_landscape_clustered_trees(rotation = 45)
plot_landscape(test_cluster)

# diffuse treeline
test_diffuse <- create_landscape_diffuse_treeline()
plot_landscape(test_diffuse)

# curvy treeline
test_curvy <- create_landscape_curvy_treeline()
plot_landscape(test_curvy)

# fingers
test_fingers <- create_landscape_fingers()
plot_landscape(test_fingers)

# bent fingers
test_bent_fingers <- create_landscape_bent_fingers()
plot_landscape(test_bent_fingers)

# scattered trees
test_scattered <- create_landscape_scattered_trees(rotation = 45)
plot_landscape(test_scattered)

# sine bands
test_sine_bands <- create_landscape_sine_bands(noise = TRUE)
plot_landscape(test_sine_bands)

# Test plotting multiple landscapes
landscape_list <- list(
  Clustered = test_cluster,
  Diffuse = test_diffuse,
  Curvy = test_curvy,
  Fingers = test_fingers,
  BentFingers = test_bent_fingers,
  Scattered = test_scattered,
  SineBands = test_sine_bands
)

plot_landscape_list(landscape_list)
