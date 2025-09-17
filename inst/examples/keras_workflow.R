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

# Apply to new landscapes

new_landscapes <- generate_training_landscapes(
  seed = 123,
  n = 10,
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

results <- apply_nn_keras(
  landscape = new_landscapes,
  nn_model = model,
  confidence_threshold = 0.7
)

# Plot results
# Make title

plot_landscape_list(new_landscapes)

# Other tests (IGNORE THIS CODE) ----------------------------------------

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
fingers <- create_landscape(
  pattern = "fingers",
  width = 100,
  height = 100,
  num_fingers = 5,
  finger_width = 3,
  rotation = 0
) |>
  plot_landscape()

fingers_rotate <- create_landscape(
  pattern = "fingers",
  width = 100,
  height = 100,
  num_fingers = 5,
  finger_width = 3,
  rotation = 45
) |>
  plot_landscape()

# bent fingers
bent_fingers <- create_landscape(
  pattern = "fingers",
  bend = TRUE,
  width = 100,
  height = 100,
  num_fingers = 5,
  finger_width = 3,
  rotation = 0
) |>
  plot_landscape()

bent_fingers_rotate <- create_landscape(
  pattern = "bent_fingers",
  bend = TRUE,
  width = 100,
  height = 100,
  num_fingers = 5,
  finger_width = 3,
  rotation = 45
) |>
  plot_landscape()

patchwork::wrap_plots(
  fingers,
  fingers_rotate,
  bent_fingers,
  bent_fingers_rotate
)

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
