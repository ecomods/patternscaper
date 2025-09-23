#Tests to determine useful ranges for
#landscape parameters for
#clustered, sine_bands, spots, banded

# clustered = list(
#   treeline_position = c(0.4, 0.6),
#   num_clusters = c(5, 20),
#   cluster_radius = c(5, 10),
#   scatter_zone_prop = c(0.2, 0.4),
#   elongation_x = c(0.5, 2),
#   elongation_y = c(0.5, 2),
#   seed = seed
# ),
# sine_bands = list(
#   treeline_position = c(0.4, 0.6),
#   band_thickness = c(1, 7),
#   band_spacing = c(5, 15),
#   frequency = c(0.1, 1),
#   amplitude = c(2, 10),
#   noise_sd = c(0, 2),
#   seed = seed
# ),
# spots = list(
#   n_spots = c(5, 20),
#   spot_radius = c(2, 10),
#   noise_radius_sd = c(0, 2),
#   invert_landscape = c(TRUE, FALSE),
#   seed = seed
# ),
# banded = list(
#   nbands = c(3, 10),
#   noise_sd = c(0, 0.5),
#   seed = seed
# )


# load all functions
devtools::load_all()
test <- create_landscape_clustered_trees(
  width = 100,
  height = 100,
  treeline_position = 0.5, #c(0.4, 0.6),
  num_clusters = 20, #c(5, 20),
  cluster_radius = 10, #c(5, 10),
  scatter_zone_prop = 0.2, #c(0.2, 1),
  elongation_x = 0.7, #c(0.5, 2),
  elongation_y = 1.4, #c(0.5, 2),
  seed = NULL
)

plot_landscape(test)
