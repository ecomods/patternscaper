devtools::load_all()

# Reproducible with same landscapes every time (is also default if seed is not set)
landscapes <- generate_training_landscapes(n = 20, seed = 42)
# different landscapes every time
landscapes <- generate_training_landscapes(n = 20, seed = NULL)

# generate only specific landscape types
landscapes <- generate_training_landscapes(
  n = 20,
  seed = 42,
  types = c("banded", "spots", "clustered")
)

# give different weights for the landscapes (higher weights will be generated more often)
landscapes <- generate_training_landscapes(
  n = 20,
  seed = 42,
  types = c("banded", "spots", "clustered"),
  type_probs = c(0.1, 1, 0.2)
)

landscapes <- generate_training_landscapes(
  n = 20,
  seed = NULL,
  types = c("spots", "banded")
)

# plot all training landscapes
plot_landscape_list(landscapes)

# Test individual landscape functions -----------------------------------------

# Sharp treeline --------------------------------------------------------------
# Default sharp treeline
sharp_default <- create_landscape("sharp")

# Modified sharp treeline with higher treeline position
sharp_modified <- create_landscape(
  "sharp",
  treeline_position = 0.7
)

# One landscape with rotation
sharp_rotated <- create_landscape(
  "sharp",
  treeline_position = 0.3,
  rotation = 45
)

# Plot all sharp treelines together
plot_landscape_list(list(
  sharp_default,
  sharp_modified,
  sharp_rotated
), title = c("Default", "Modified", "Rotated"))

# Diffuse treeline -----------------------------------------------------------
# Default diffuse treeline
diffuse_default <- create_landscape("diffuse")

# Modified diffuse treeline with greater steepness
diffuse_modified <- create_landscape(
  "diffuse",
  treeline_position = 0.2,
  steepness = 0.1
)

plot_landscape(diffuse_modified)

# One landscape with rotation
diffuse_rotated <- create_landscape(
  "diffuse",
  treeline_position = 0.3,
  steepness = 2,
  rotation = 45
)

# Plot all diffuse treelines together
plot_landscape_list(list(
  diffuse_default,
  diffuse_modified,
  diffuse_rotated
), title = c("Default", "Modified", "Rotated"))

# Curvy treeline -------------------------------------------------------------
# Default curvy treeline
curvy_default <- create_landscape("curvy")

# Modified curvy treeline with increased sine parameters
curvy_modified <- create_landscape(
  "curvy",
  treeline_position = 0.3,
  sine_length = 40,
  sine_height = 10
)

# One landscape with rotation
curvy_rotated <- create_landscape(
  "curvy",
  treeline_position = 0.6,
  sine_length = 10,
  sine_height = 6,
  rotation = 45
)

# Plot all curvy treelines together
plot_landscape_list(list(
  curvy_default,
  curvy_modified,
  curvy_rotated
), title = c("Default", "Modified", "Rotated"))

# Fingers --------------------------------------------------------------------
# Default fingers pattern
fingers_default <- create_landscape("fingers")

# Modified fingers with more, thinner fingers and bending
fingers_modified <- create_landscape(
  "fingers",
  treeline_position = 0.2,
  num_fingers = 7,
  finger_width = 5,
  finger_length_prop = 0.5,
  bend = TRUE
)

# One landscape with rotation
fingers_rotated <- create_landscape(
  "fingers",
  num_fingers = 10,
  finger_width = 4,
  finger_length_prop = 1,
  bend = TRUE,
  rotation = 45
)

# Plot all fingers together
plot_landscape_list(list(
  fingers_default,
  fingers_modified,
  fingers_rotated
), title = c("Default", "Modified", "Rotated"))

# Scattered trees ------------------------------------------------------------
# Default scattered trees
scattered_default <- create_landscape("scattered")

# Modified scattered trees with higher density in a larger scatter zone
scattered_modified <- create_landscape(
  "scattered",
  treeline_position = 0.3,
  scatter_density = 0.7,
  scatter_zone_prop = 0.2
)

# One landscape with rotation
scattered_rotated <- create_landscape(
  "scattered",
  treeline_position = 0.3,
  scatter_density = 0.2,
  scatter_zone_prop = 0.1,
  rotation = 45
)

# Plot all scattered trees together
plot_landscape_list(list(
  scattered_default,
  scattered_modified,
  scattered_rotated
), titles = c("Default", "Modified", "Rotated"))

# Clustered trees ------------------------------------------------------------
# Default clustered trees
clustered_default <- create_landscape("clustered")

# Modified clustered trees with more elongated clusters
clustered_modified <- create_landscape(
  "clustered",
  treeline_position = 0.2,
  num_clusters = 8,
  cluster_radius = 7,
  scatter_zone_prop = 0.6,
  elongation_x = 2.5,
  elongation_y = 0.5
)

# One landscape with rotation
clustered_rotated <- create_landscape(
  "clustered",
  num_clusters = 20,
  cluster_radius = 2,
  scatter_zone_prop = 0.5,
  elongation_x = 1.8,
  elongation_y = 1.4,
  rotation = 45,
  seed = NULL
)

# Plot all clustered trees together
plot_landscape_list(list(
  clustered_default,
  clustered_modified,
  clustered_rotated
), titles = c("Default", "Modified", "Rotated"))

# Sine bands -----------------------------------------------------------------
# Default sine bands
sine_bands_default <- create_landscape("sine_bands")

# Modified sine bands with thicker bands, wider spacing and noise
sine_bands_modified <- create_landscape(
  "sine_bands",
  treeline_position = 0.3,
  band_zone_prop = 0.5,
  band_thickness = 5,
  band_spacing = 15,
  frequency = 1,
  amplitude = 8,
  noise_sd = 1.5
)

# One landscape with rotation
sine_bands_rotated <- create_landscape(
  "sine_bands",
  band_thickness = 4,
  band_spacing = 12,
  amplitude = 6,
  noise_sd = 2,
  rotation = 45
)

# Plot all sine bands together
plot_landscape_list(list(
  sine_bands_default,
  sine_bands_modified,
  sine_bands_rotated
), titles = c("Default", "Modified", "Rotated"))

# Spots ----------------------------------------------------------------------
# Default spots
spots_default <- create_landscape("spots")

# Modified spots with more spots and random radius variation
spots_modified <- create_landscape(
  "spots",
  n_spots = 15,
  spot_radius = 8,
  noise_radius_sd = 2
)

# Modified spots with more spots and random radius variation
spots_inverted <- create_landscape(
  "spots",
  n_spots = 15,
  spot_radius = 8,
  invert_landscape = TRUE,
  noise_radius_sd = 2
)


# Plot all spots together
plot_landscape_list(list(
  spots_default,
  spots_modified,
  spots_inverted
), titles = c("Default", "Modified", "Inverted"))

# Banded vegetation ----------------------------------------------------------
# Default banded vegetation
banded_default <- create_landscape("banded")

# Modified banded vegetation with more bands and different hill parameters
banded_modified <- create_landscape(
  "banded",
  nbands = 9,
  hilltop = c(35, 25, 30),
  slope = c(0.3, 0.15, 0.25),
  x_ext_hill = c(1.5, 2.2, 1.8),
  y_ext_hill = c(1.3, 1.1, 1.9),
  noise_sd = 0.5
)

# One landscape with rotation
banded_rotated <- create_landscape(
  "banded",
  nbands = 7,
  hilltop = c(30, 22, 28),
  slope = c(0.25, 0.12, 0.2),
  x_ext_hill = c(1.4, 2.0, 1.6),
  y_ext_hill = c(1.2, 1.0, 1.7),
  noise_sd = 0.15,
  rotation = 45
)

# Plot all banded vegetation together
plot_landscape_list(list(
  default = banded_default,
  modified = banded_modified,
  rotated = banded_rotated
))
