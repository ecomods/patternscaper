# Load all functions in the package (Keyboard shortcut in RStudio: Ctrl+Shift+L)
# If you change functions, run it again
# You can call ?function to open up the help
devtools::load_all()

# For reproducibility, you have to set the seed
set.seed(123)
# ----------------------------------------------------------------------------#
# Generate multiple training landscapes --------------------------------------
# ----------------------------------------------------------------------------#

landscapes <- create_training_landscapes(n = 20)

# Randomly sampled landscape types (by default the function balances the types)
landscapes <- create_training_landscapes(
  n = 20,
  balance_patterns = FALSE
)

# generate only specific landscape types
landscapes <- create_training_landscapes(
  n = 20,
  patterns = c("banded", "spots", "clustered")
)

# give different weights for the landscapes (higher weights will be generated more often)
landscapes <- create_training_landscapes(
  n = 20,
  patterns = c("banded", "spots", "clustered"),
  balance_patterns = FALSE,
  pattern_probs = c(0.1, 1, 0.2)
)

landscapes <- create_training_landscapes(
  n = 20,
  patterns = c("spots", "banded")
)

# Look at landscape objects (printed with info in the console)
landscapes[[1]]

# Change the name and pattern of a landscape
landscapes[[1]] <- set_landscape_pattern(
  landscapes[[1]],
  pattern = "custom_pattern"
)
landscapes[[1]] <- set_landscape_name(
  landscapes[[1]],
  name = "My first landscape"
)


# plot all training landscapes (default titles are both name and pattern)
plot_landscape_list(landscapes)
# only plot names and patterns as titles
plot_landscape_list(landscapes, title = "both")
# Plot custom titles
my_titles <- paste0("Landscape ", 1:length(landscapes))
plot_landscape_list(landscapes, title = my_titles)

# ----------------------------------------------------------------------------#
# Generate individual landscapes ----------------------------------------------
# ----------------------------------------------------------------------------#

# Sharp treeline --------------------------------------------------------------
# Default sharp treeline
sharp_default <- create_landscape("sharp")
# by default the landscape does not have a name
sharp_default
# But you can create it with a name
sharp_default <- create_landscape("sharp", name = "Default")
sharp_default

# Modified sharp treeline with higher treeline position
sharp_modified <- create_landscape(
  "sharp",
  name = "Modified",
  treeline_position = 0.7
)

# One landscape with rotation
sharp_rotated <- create_landscape(
  "sharp",
  name = "Rotated",
  treeline_position = 0.3,
  rotation = 45
)

# Plot all sharp treelines together
plot_landscape_list(
  list(
    sharp_default,
    sharp_modified,
    sharp_rotated
  )
)

# Diffuse treeline -----------------------------------------------------------
# Default diffuse treeline
diffuse_default <- create_landscape("diffuse", name = "Default")

# Modified diffuse treeline with greater steepness
diffuse_modified <- create_landscape(
  "diffuse",
  name = "Modified",
  treeline_position = 0.2,
  steepness = 0.1
)

plot_landscape(diffuse_modified)

# One landscape with rotation
diffuse_rotated <- create_landscape(
  "diffuse",
  name = "Rotated",
  treeline_position = 0.3,
  steepness = 2,
  rotation = 45
)

# Plot all diffuse treelines together
plot_landscape_list(
  list(
    diffuse_default,
    diffuse_modified,
    diffuse_rotated
  )
)

# Curvy treeline -------------------------------------------------------------
# Default curvy treeline
curvy_default <- create_landscape("curvy", name = "Default")

# Modified curvy treeline with increased sine parameters
curvy_modified <- create_landscape(
  "curvy",
  name = "Modified",
  treeline_position = 0.3,
  sine_length = 40,
  sine_height = 10
)

# One landscape with rotation
curvy_rotated <- create_landscape(
  "curvy",
  name = "Rotated",
  treeline_position = 0.6,
  sine_length = 10,
  sine_height = 6,
  rotation = 45
)

# Plot all curvy treelines together
plot_landscape_list(
  list(
    curvy_default,
    curvy_modified,
    curvy_rotated
  )
)

# Fingers --------------------------------------------------------------------
# Default fingers pattern
fingers_default <- create_landscape("fingers", name = "Default")

# Modified fingers with more, thinner fingers and bending
fingers_modified <- create_landscape(
  "fingers",
  name = "Modified",
  treeline_position = 0.2,
  num_fingers = 7,
  finger_width = 5,
  finger_length_prop = 0.5,
  bend = TRUE
)

# One landscape with rotation
fingers_rotated <- create_landscape(
  "fingers",
  name = "Rotated",
  num_fingers = 10,
  finger_width = 4,
  finger_length_prop = 1,
  bend = TRUE,
  rotation = 45
)

# Plot all fingers together
plot_landscape_list(
  list(
    fingers_default,
    fingers_modified,
    fingers_rotated
  )
)

# Scattered trees ------------------------------------------------------------
# Default scattered trees
scattered_default <- create_landscape("scattered", name = "Default")

# Modified scattered trees with higher density in a larger scatter zone
scattered_modified <- create_landscape(
  "scattered",
  name = "Modified",
  treeline_position = 0.3,
  scatter_density = 0.7,
  scatter_zone_prop = 0.2
)

# One landscape with rotation
scattered_rotated <- create_landscape(
  "scattered",
  name = "Rotated",
  treeline_position = 0.3,
  scatter_density = 0.2,
  scatter_zone_prop = 0.1,
  rotation = 45
)

# Plot all scattered trees together
plot_landscape_list(
  list(
    scattered_default,
    scattered_modified,
    scattered_rotated
  )
)

# Clustered trees ------------------------------------------------------------
# Default clustered trees
clustered_default <- create_landscape("clustered", name = "Default")

# Modified clustered trees with more elongated clusters
clustered_modified <- create_landscape(
  "clustered",
  name = "Modified",
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
  name = "Rotated",
  num_clusters = 20,
  cluster_radius = 2,
  scatter_zone_prop = 0.5,
  elongation_x = 1.8,
  elongation_y = 1.4,
  rotation = 45
)

# Plot all clustered trees together
plot_landscape_list(
  list(
    clustered_default,
    clustered_modified,
    clustered_rotated
  )
)

# Sine bands -----------------------------------------------------------------
# Default sine bands
sine_bands_default <- create_landscape("sine_bands", name = "Default")

# Modified sine bands with thicker bands, wider spacing and noise
sine_bands_modified <- create_landscape(
  "sine_bands",
  name = "Modified",
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
  name = "Rotated",
  band_thickness = 4,
  band_spacing = 12,
  amplitude = 6,
  noise_sd = 2,
  rotation = 45
)

# Plot all sine bands together
plot_landscape_list(
  list(
    sine_bands_default,
    sine_bands_modified,
    sine_bands_rotated
  )
)

# Spots ----------------------------------------------------------------------
# Default spots
spots_default <- create_landscape("spots", name = "Default")

# Modified spots with more spots and random radius variation
spots_modified <- create_landscape(
  "spots",
  name = "Modified",
  n_spots = 15,
  spot_radius = 8,
  noise_radius_sd = 2
)

# Modified spots with more spots and random radius variation
spots_inverted <- create_landscape(
  "spots",
  name = "Inverted",
  n_spots = 15,
  spot_radius = 8,
  invert_landscape = TRUE,
  noise_radius_sd = 2
)

spots_regular <- create_landscape(
  "spots",
  name = "Regular",
  n_spots = 15,
  spot_radius = 8,
  noise_radius_sd = 0,
  regular_spots = TRUE
)


# Plot all spots together
plot_landscape_list(
  list(
    spots_default,
    spots_modified,
    spots_inverted,
    spots_regular
  )
)

# Banded vegetation ----------------------------------------------------------
# Default banded vegetation
banded_default <- create_landscape("banded", name = "Default")

# Modified banded vegetation with more bands and different hill parameters
banded_modified <- create_landscape(
  "banded",
  name = "Modified",
  nbands = 9,
  regular_hilltop = FALSE,
  top_elevation_mean = 25,
  noise_sd = 0.5
)

# One landscape with rotation
banded_rotated <- create_landscape(
  "banded",
  name = "Rotated",
  nbands = 9,
  regular_hilltop = FALSE,
  top_elevation_mean = 25,
  noise_sd = 0.5,
  rotation = 45
)

# Plot all banded vegetation together
plot_landscape_list(list(
  banded_default,
  banded_modified,
  banded_rotated
))
