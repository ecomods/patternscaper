#' Create a Landscape with Randomly Distributed Trees
#'
#' Generates a binary landscape with randomly distributed trees.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param tree_prop Numeric. Probability of tree presence (0-1) (default: 0.5).
#'    Higher values result in a denser tree cover.
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'    If NULL, no seed is set explicitly.
#'    If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#'
#' @return A landscape object with pattern "random" containing the generated landscape data and parameters.
#'
#' @keywords internal
#'
#' @examples
#' # Default randomly distributed trees
#' random_default <- create_landscape_random()
#'
#' # Modified random trees with higher density
#' random_modified <- create_landscape_random(
#'   tree_prop = 0.7
#' )
create_landscape_random <- function(
  width = 100,
  height = 100,
  tree_prop = 0.5,
  rotation = 0,
  seed = NULL
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Get landscape with random distribution of trees
  mat <- matrix(
    rbinom(width_actual * height_actual, size = 1, prob = tree_prop),
    nrow = height_actual,
    ncol = width_actual
  )

  # Apply rotation if specified
  if (rotation != 0) {
    mat <- rotate_and_crop_landscape(
      mat,
      rotation,
      width,
      height
    )
  }

  # Create and return landscape object
  landscape(
    data = mat,
    pattern = "random",
    params = list(
      width = width,
      height = height,
      tree_prop = tree_prop,
      rotation = rotation,
      seed = seed
    )
  )
}
