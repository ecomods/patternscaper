#' Create a Binary Landscape with Randomly Distributed Vegetation
#'
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param veg_prop Numeric. Probability of vegetation presence (0-1) (default: 0.5).
#'    Higher values result in a denser vegetation cover.
#'
#' @return A landscape object with random pattern containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "random"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @examples
#' # Default randomly distributed trees
#' random_default <- create_landscape_random()
#'
#' # Higher tree density
#' random_dense <- create_landscape_random(veg_prop = 0.7)
#'
#' # Custom dimensions
#' random_large <- create_landscape_random(width = 200, height = 150)
#'
#' @export
#' @importFrom stats rbinom
create_landscape_random <- function(
  width = 100,
  height = 100,
  veg_prop = 0.5
) {
  # Validate common parameters
  validate_dimensions(width = width, height = height)

  # Validate veg_prop
  if (!is.numeric(veg_prop) || veg_prop < 0 || veg_prop > 1) {
    cli::cli_abort(c(
      "{.arg veg_prop} must be between 0 and 1.",
      "x" = "You supplied {.val {veg_prop}}"
    ))
  }

  # Get landscape with random distribution of trees
  mat <- matrix(
    stats::rbinom(width * height, size = 1, prob = veg_prop),
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
      veg_prop = veg_prop
    )
  )
}
