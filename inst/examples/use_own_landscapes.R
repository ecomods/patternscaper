# This example script shows how to read your own landscapes in and bring them
# in the correct format to use with the package functions

devtools::load_all()

pic_dir <- "inst/examples/Ecotone/" #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

pic_paths <- list.files(
  path = "inst/examples/Ecotone",
  pattern = "png",
  full.names = TRUE
)

# read all images as pasters
pics <- lapply(pic_paths, function(pic) {
  terra::rast(pic)
})

# Checkout the first picture
pics[[1]] # Its a SpatRaster
terra::nlyr(pics[[1]]) # It has 4 layers
terra::values(pics[[1]][[1]]) |> summary() # Check values of first layer

# Classify the landscapes
# Matrix to classify by (columns are read as from, to, new value)
rcl_matrix <- matrix(c(-Inf, 70, 0, 70, Inf, 1), ncol = 3, byrow = TRUE)

binarized_pics <- lapply(pics, function(pic) {
  band1 <- pic[[1]] # Use first band
  binary_class <- terra::classify(band1, rcl = rcl_matrix)
  return(binary_class)
})

terra::values(binarized_pics[[1]]) |> summary()
terra::values(binarized_pics[[1]]) |> unique()

# Convert own landscapes into landscape objects needed by package -------------

# The package takes as input either a matrix or a SpatRaster object

# Convert a single landscape
landscape1 <- landscape(
  data = binarized_pics[[1]],
  name = "my first landscape", # optional name
  pattern = "my_pattern" # optional pattern
)
# Check how a landscape prints
landscape1

# Convert all landscapes
landscape_list <- lapply(
  binarized_pics,
  landscape
)
# Set all names and patterns for the landscapes (optional)
# Can be custom names, but need to be same length as landscape_list
landscape_names <- paste("landscape", seq_along(landscape_list))
landscape_patterns <- rep("my_pattern", seq_along(landscape_list))

# First check how the landscape prints without names and patterns
landscape_list

landscape_list <- purrr::map2(
  landscape_list,
  landscape_names,
  set_landscape_name
)
landscape_list <- purrr::map2(
  landscape_list,
  landscape_patterns,
  set_landscape_pattern
)

# Now name and pattern are added to the landscape objects
landscape_list

plot_landscape_list(landscape_list)
