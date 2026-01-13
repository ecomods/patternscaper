#' Create a Landscape with Randomly Distributed Trees
#'
#' Generates a binary landscape with randomly distributed trees.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param tree_prop Numeric. Probability of tree presence (0-1) (default: 0.5).
#'    Higher values result in a denser tree cover.
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
#'
#' @importFrom stats rbinom
create_landscape_random <- function(
  width = 100,
  height = 100,
  tree_prop = 0.5
) {
  # Validate common parameters
  validate_dimensions(width = width, height = height)

  # Validate tree_prop
  if (!is.numeric(tree_prop) || tree_prop < 0 || tree_prop > 1) {
    cli::cli_abort(c(
      "{.arg tree_prop} must be between 0 and 1.",
      "x" = "You supplied {.val {tree_prop}}"
    ))
  }

  # Get landscape with random distribution of trees
  mat <- matrix(
    stats::rbinom(width * height, size = 1, prob = tree_prop),
    nrow = height,
    ncol = width
  )

  # Create and return landscape object
  landscape(
    data = mat,
    pattern = "random",
    params = list(
      width = width,
      height = height,
      tree_prop = tree_prop
    )
  )
}
