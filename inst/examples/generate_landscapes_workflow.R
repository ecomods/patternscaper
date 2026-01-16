# Load all functions in the package (Keyboard shortcut in RStudio: Ctrl+Shift+L)
# If you change functions, run it again
# You can call ?function to open up the help
devtools::load_all()

# For reproducibility, you have to set the seed
set.seed(123)
# ----------------------------------------------------------------------------#
# Generate multiple training landscapes --------------------------------------
# ----------------------------------------------------------------------------#

landscapes <- create_training_landscapes(n = 20) # maximum = 36

# Randomly sampled landscape types (by default the function balances the types)
landscapes <- create_training_landscapes(
  n = 20,
  balance_patterns = FALSE
)

# generate only specific landscape types
landscapes <- create_training_landscapes(
  n = 20,
  patterns = c("stripes", "spots", "clustered")
)

# give different weights for the landscapes (higher weights will be generated more often)
landscapes <- create_training_landscapes(
  n = 20,
  patterns = c("stripes", "spots", "clustered"),
  balance_patterns = FALSE,
  pattern_probs = c(0.1, 1, 0.2)
)

landscapes <- create_training_landscapes(
  n = 20,
  patterns = c("spots", "stripes")
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

# Curvy fingers ---------------------------------------------------------------
# Default fingers pattern
fingers_default <- create_landscape(
  "fingers",
  name = "Default",
  pattern = "fingers"
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

# Sine bands -----------------------------------------------------------------
# Default sine bands
bands_default <- create_landscape("bands", name = "Default")

# Modified sine bands with thicker bands, wider spacing and noise
bands_modified <- create_landscape(
  "bands",
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
bands_rotated <- create_landscape(
  "bands",
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
    bands_default,
    bands_modified,
    bands_rotated
  )
)

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


# Spots ----------------------------------------------------------------------
# Default spots
spots_default <- create_landscape("spots", name = "Default")

# Modified spots with more spots and random radius variation
spots_modified <- create_landscape(
  "spots",
  name = "Modified",
  n_spots = 15,
  spot_radius = 8,
  spot_radius_sd = 2
)

# Modified spots with more spots and random radius variation
spots_inverted <- create_landscape(
  "spots",
  name = "Inverted",
  n_spots = 15,
  spot_radius = 8,
  spot_radius_sd = 10
)

spots_regular <- create_landscape(
  "spots",
  name = "Regular",
  n_spots = 15,
  spot_radius = 20,
  spot_radius_sd = 0,
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

# Random landscapes ---------------------------------------------------------

# Default random landscape
random_default <- create_landscape("random", name = "Default")
# Modified random landscape with higher tree density
random_modified <- create_landscape(
  "random",
  name = "Modified",
  tree_prop = 0.7
)
# One landscape with rotation
random_rotated <- create_landscape(
  "random",
  name = "Rotated",
  tree_prop = 0.2
)
# Plot all random landscapes together
plot_landscape_list(list(
  random_default,
  random_modified,
  random_rotated
))

# Labyrinth vegetation ------------------------------------------------------
# Default labyrinth vegetation
labyrinth_default <- create_landscape("labyrinth", name = "Default")
# Modified labyrinth with higher frequency and multiple octaves
labyrinth_modified <- create_landscape(
  "labyrinth",
  name = "Modified",
  frequency = 8,
  octaves = 3,
  band_fuzziness = 0.05
)
# Plot all labyrinth vegetation together
plot_landscape_list(list(
  labyrinth_default,
  labyrinth_modified
))

# Try the effect of octaves by creating multiple landscapes with different octaves
labyrinth_octaves <- list()
for (i in 1:6) {
  set.seed(123)
  labyrinth_octaves[[i]] <- create_landscape(
    "labyrinth",
    name = paste0("Octaves: ", i),
    frequency = 5,
    veg_threshold = 0.5,
    band_fuzziness = 0,
    octaves = i
  )
}
plot_landscape_list(labyrinth_octaves)

# Understand the effect of veg_threshold
labyrinth_veg_threshold <- list()
for (i in seq(0.3, 0.6, by = 0.05)) {
  set.seed(123)
  labyrinth_veg_threshold[[as.character(i)]] <- create_landscape(
    "labyrinth",
    name = paste0("Veg threshold: ", i),
    frequency = 5,
    veg_threshold = i,
    band_fuzziness = 0.1,
    octaves = 6
  )
}
plot_landscape_list(labyrinth_veg_threshold)

# understand the effect of band_fuzziness
labyrinth_band_fuzziness <- list()
for (i in c(0, 0.05, 0.1, 0.2, 0.3, 0.5)) {
  set.seed(123)
  labyrinth_band_fuzziness[[as.character(i)]] <- create_landscape(
    "labyrinth",
    name = paste0("Band fuzziness: ", i),
    frequency = 5,
    veg_threshold = 0.5,
    band_fuzziness = i,
    octaves = 6
  )
}
plot_landscape_list(labyrinth_band_fuzziness)

# understand the effect of frequency
labyrinth_frequency <- list()
for (i in c(1, 3, 5, 7, 9)) {
  set.seed(123)
  labyrinth_frequency[[as.character(i)]] <- create_landscape(
    "labyrinth",
    name = paste0("Frequency: ", i),
    frequency = i,
    veg_threshold = 0.5,
    band_fuzziness = 0,
    octaves = 6
  )
}
plot_landscape_list(labyrinth_frequency)

# generate a set of labyrinth landscapes
set.seed(123)
labyrinths <- create_training_landscapes(
  patterns = "labyrinth",
  n = 36
)
plot_landscape_list(labyrinths)

# Stripes vegetation ----------------------------------------------------------
# Default stripes vegetation
stripes_default <- create_landscape("stripes", name = "Default")

# Modified stripes vegetation with more stripes and different hill parameters
stripes_modified <- create_landscape(
  "stripes",
  name = "Modified",
  nbands = 9,
  regular_hilltop = FALSE,
  top_elevation_mean = 25,
  noise_sd = 0.5
)

# One landscape with rotation
stripes_rotated <- create_landscape(
  "stripes",
  name = "Rotated",
  nbands = 9,
  regular_hilltop = FALSE,
  top_elevation_mean = 25,
  noise_sd = 0.5,
  rotation = 45
)

# Plot all striped vegetation together
plot_landscape_list(list(
  stripes_default,
  stripes_modified,
  stripes_rotated
))

# Generate a set of each landscape type for showcase --------------------------
spatial_patterns <- c(
  "random",
  "bare",
  "dense",
  "sharp",
  "diffuse",
  "fingers",
  "clustered",
  "bands",
  "spots",
  "gaps",
  "stripes",
  "labyrinth"
)

n <- 36

create_training_landscapes(
  patterns = spatial_patterns[2],
  n = n
) |>
  plot_

t + plot_annotation(title = "Showcase of available spatial patterns")


showcase_landscapes <- spatial_patterns |>
  purrr::map(\(pattern) {
    set.seed(123)
    print(pattern)
    create_training_landscapes(
      patterns = pattern,
      n = n
    )
  })

showcase_plots <- purrr::map2(
  showcase_landscapes,
  spatial_patterns,
  \(landscape_list, pattern) {
    plot <- plot_landscape_list(
      landscape_list,
      title = "none",
      show_legend = FALSE
    )
    plot +
      plot_annotation(title = pattern) &
      ggplot2::theme(plot.title = ggtext::element_markdown(size = 20))
  }
)

# Save them all
purrr::walk2(
  showcase_plots,
  spatial_patterns,
  \(plot, pattern) {
    ggplot2::ggsave(
      filename = paste0("inst/examples/plots/showcase_", pattern, ".png"),
      plot = plot,
      width = 10,
      height = 10
    )
  }
)
