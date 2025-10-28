#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to self-organized ecotones
bare <- create_landscape(
  pattern = "random",
  custom_pattern = "bare", # Change pattern from random to bare
  tree_prop = 0.01,
  seed = 42
)
spots <- create_landscape(
  pattern = "spots",
  n_spots = 12,
  spot_radius = 8,
  noise_radius_sd = 0.2,
  regular_spots = TRUE,
  seed = 42
)
labyrinth <- create_landscape(
  pattern = "labyrinth",
  band_fuzziness = 0.01,
  seed = 42
)

gaps <- create_landscape(
  pattern = "gaps",
  n_spots = 10,
  spot_radius = 8,
  seed = 42,
  regular_spots = TRUE
)

dense <- create_landscape(
  pattern = "random",
  custom_pattern = "dense",
  tree_prop = 0.99,
  seed = 42
)

all_examples <- list(bare, spots, labyrinth, gaps, dense)

plot_landscape_list(
  all_examples,
  show_legend = FALSE,
  ncol = length(all_examples)
)
