devtools::load_all()

landscapes <- generate_training_landscapes(n = 20)
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
  default = sharp_default,
  modified = sharp_modified,
  rotated = sharp_rotated
))

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
  default = diffuse_default,
  modified = diffuse_modified,
  rotated = diffuse_rotated
))

# Curvy treeline -------------------------------------------------------------
# Default curvy treeline
curvy_default <- create_landscape("curvy")

# Modified curvy treeline with increased sine parameters
curvy_modified <- create_landscape(
  "curvy",
  treeline_position = 0.4,
  sine_length = 35,
  sine_height = 8
)

# One landscape with rotation
curvy_rotated <- create_landscape(
  "curvy",
  treeline_position = 0.6,
  sine_length = 25,
  sine_height = 6,
  rotation = 45
)

# Plot all curvy treelines together
plot_landscape_list(list(
  default = curvy_default,
  modified = curvy_modified,
  rotated = curvy_rotated
))

# Fingers --------------------------------------------------------------------
# Default fingers pattern
fingers_default <- create_landscape("fingers")

# Modified fingers with more, thinner fingers and bending
fingers_modified <- create_landscape(
  "fingers",
  num_fingers = 8,
  finger_width = 3,
  finger_length_prop = 0.35,
  bend = TRUE
)

# One landscape with rotation
fingers_rotated <- create_landscape(
  "fingers",
  num_fingers = 5,
  finger_width = 4,
  finger_length_prop = 0.3,
  bend = TRUE,
  rotation = 45
)

# Plot all fingers together
plot_landscape_list(list(
  default = fingers_default,
  modified = fingers_modified,
  rotated = fingers_rotated
))

# Scattered trees ------------------------------------------------------------
# Default scattered trees
scattered_default <- create_landscape("scattered")

# Modified scattered trees with higher density in a larger scatter zone
scattered_modified <- create_landscape(
  "scattered",
  treeline_position = 0.3,
  scatter_density = 0.25,
  scatter_zone_prop = 0.6
)

# One landscape with rotation
scattered_rotated <- create_landscape(
  "scattered",
  treeline_position = 0.4,
  scatter_density = 0.2,
  scatter_zone_prop = 0.5,
  rotation = 45
)

# Plot all scattered trees together
plot_landscape_list(list(
  default = scattered_default,
  modified = scattered_modified,
  rotated = scattered_rotated
))

# Clustered trees ------------------------------------------------------------
# Default clustered trees
clustered_default <- create_landscape("clustered")

# Modified clustered trees with more elongated clusters
clustered_modified <- create_landscape(
  "clustered",
  num_clusters = 8,
  cluster_radius = 7,
  scatter_zone_prop = 0.6,
  elongation_x = 2.5,
  elongation_y = 1.2
)

# One landscape with rotation
clustered_rotated <- create_landscape(
  "clustered",
  num_clusters = 6,
  cluster_radius = 5,
  scatter_zone_prop = 0.5,
  elongation_x = 1.8,
  elongation_y = 1.4,
  rotation = 45
)

# Plot all clustered trees together
plot_landscape_list(list(
  default = clustered_default,
  modified = clustered_modified,
  rotated = clustered_rotated
))

# Sine bands -----------------------------------------------------------------
# Default sine bands
sine_bands_default <- create_landscape("sine_bands")

# Modified sine bands with thicker bands, wider spacing and noise
sine_bands_modified <- create_landscape(
  "sine_bands",
  band_thickness = 5,
  band_spacing = 15,
  amplitude = 8,
  noise = TRUE,
  noise_sd = 1.5
)

# One landscape with rotation
sine_bands_rotated <- create_landscape(
  "sine_bands",
  band_thickness = 4,
  band_spacing = 12,
  amplitude = 6,
  noise = TRUE,
  noise_sd = 1.0,
  rotation = 45
)

# Plot all sine bands together
plot_landscape_list(list(
  default = sine_bands_default,
  modified = sine_bands_modified,
  rotated = sine_bands_rotated
))

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

# One landscape with rotation
spots_rotated <- create_landscape(
  "spots",
  n_spots = 12,
  spot_radius = 6,
  noise_radius_sd = 1.5,
  rotation = 45
)

# Plot all spots together
plot_landscape_list(list(
  default = spots_default,
  modified = spots_modified,
  rotated = spots_rotated
))

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
  noise_sd = 0.2
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
