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
  treeline_position = 0.2,
  steepness = 0.9,
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
  random_spots = c(0.05, 0.05),
  sine_length = 100,
  sine_height = 50
)
plot_landscape(curvy_modified)

# One landscape with rotation
curvy_rotated <- create_landscape(
  "curvy",
  name = "Rotated",
  treeline_position = 0.6,
  sine_length = 10,
  sine_height = 10,
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

# Curvy fingers ---------------------------------------------------------------
# Default fingers pattern
fingers_default <- create_landscape(
  "fingers",
  name = "Default",
  pattern = "curvy"
)
fingers_modified <- create_landscape(
  "fingers",
  name = "Modified",
  sine_length_mean = 15,
  sine_length_sd = 10,
  sine_height_mean = 10,
  sine_height_sd = 15
)
fingers_rotated <- create_landscape(
  pattern = "fingers",
  name = "Rotated",
  rotation = 45,
  sine_length_mean = 20,
  sine_length_sd = 10,
  sine_height_mean = 15,
  sine_height_sd = 20
)

plot_landscape_list(list(
  fingers_default,
  fingers_modified,
  fingers_rotated
))

# Clustered trees ------------------------------------------------------------
all_clustered <- function() {
  # Default clustered trees
  clustered_default <- create_landscape("clustered", name = "Default")

  # Modified treeline position (higher = more area below treeline)
  clustered_high_treeline <- create_landscape(
    "clustered",
    name = "High Treeline",
    treeline_position = 0.7,
    scatter_zone_prop = 0.4
  )

  # Large scatter zone with many small clusters
  clustered_many_small <- create_landscape(
    "clustered",
    name = "Many Small",
    n_clusters = 30,
    cluster_radius = 2,
    scatter_zone_prop = 0.6
  )

  # Few large clusters
  clustered_few_large <- create_landscape(
    "clustered",
    name = "Few Large",
    n_clusters = 5,
    cluster_radius = 12,
    scatter_zone_prop = 0.5
  )

  # Horizontally elongated clusters
  clustered_horizontal <- create_landscape(
    "clustered",
    name = "Horizontal",
    n_clusters = 15,
    cluster_radius = 5,
    elongation_x = 3,
    elongation_y = 1,
    scatter_zone_prop = 0.4
  )

  # Vertically elongated clusters
  clustered_vertical <- create_landscape(
    "clustered",
    name = "Vertical",
    n_clusters = 15,
    cluster_radius = 5,
    elongation_x = 1,
    elongation_y = 3,
    scatter_zone_prop = 0.4
  )

  # With random spots added
  clustered_with_noise <- create_landscape(
    "clustered",
    name = "With Noise",
    n_clusters = 12,
    cluster_radius = 5,
    scatter_zone_prop = 0.4,
    random_spots = c(0.05, 0.05)
  )

  # Rotated with mixed parameters
  clustered_rotated <- create_landscape(
    "clustered",
    name = "Rotated Mixed",
    n_clusters = 20,
    cluster_radius = 4,
    scatter_zone_prop = 0.5,
    elongation_x = 1.8,
    elongation_y = 1.4,
    rotation = 45
  )

  # Narrow scatter zone with dense clusters
  clustered_narrow_dense <- create_landscape(
    "clustered",
    name = "Narrow Dense",
    treeline_position = 0.3,
    n_clusters = 20,
    cluster_radius = 4,
    scatter_zone_prop = 0.2,
    rotation = 45
  )
  return(
    list(
      clustered_default,
      clustered_high_treeline,
      clustered_many_small,
      clustered_few_large,
      clustered_horizontal,
      clustered_vertical,
      clustered_narrow_dense,
      clustered_with_noise,
      clustered_rotated
    )
  )
}
# Plot all clustered trees together
plot_landscape_list(
  all_clustered(),
  title = "name"
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
  noise_radius_sd = 10
)

spots_regular <- create_landscape(
  "spots",
  name = "Regular",
  n_spots = 15,
  spot_radius = 20,
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

set.seed(123)
many_spots <- create_training_landscapes(
  patterns = "spots",
  n = 20
)
plot_landscape_list(many_spots)

# which spots are regular
regular <- purrr::map_lgl(many_spots, \(x) x$params$regular_spots)
plot_landscape_list(many_spots[regular])


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
