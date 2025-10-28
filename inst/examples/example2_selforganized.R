#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to self-organized ecotones
bare <- create_landscape_random(tree_prop = 0.01, seed = 42)
spots <- create_landscape_spots(
  n_spots = 12, spot_radius = 8, noise_radius_sd = 0.2, regular_spots = T, seed = 42
)
labyrith <- create_landscape_labyrinth(
  band_fuzziness=0.01, seed = 42
)
gaps <- create_landscape_gaps(
  n_spots = 10, spot_radius = 8, seed = 42, regular_spots = T
)
dense <- create_landscape_random(tree_prop = 0.99, seed = 42)
all_examples <- list(bare,spots,labyrith,gaps,dense)
types = c("bare","spots","labyrinth","gaps","dense")
plot_landscape_list(all_examples,titles=types,show_legend = F, ncol=length(all_examples))

