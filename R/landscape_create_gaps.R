#' Create a Landscape with Gaps Pattern
#'
#' Generates a binary landscape with circular gaps (inverse of spots).
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param n_spots Integer. Number of non-vegetated spots
#' @param spot_radius Integer. Radius of each spot
#' @param noise_radius_sd Numeric. If random effects, which standard deviation (Default is 0 - no random effects)
#' @param spot_jitter Integer. Should the regular spots be slightly shifted - how many cells (Default is 0 - no jitter)
#' @param invert_landscape Boolean. Invert vegetated and unvegetated areas.
#'     Switches the landscape from vegetated with bare spots to bare with vegetated spots (default: TRUE).
#' @param regular_spots Boolean. Should the spots be arranged in a regular way (on a hexagon using k-means) or randomly?
#'     (default: FALSE)
#' @param rotation Unused parameter for compatibility with other landscape functions (default: 0).
#'     Is only needed because in the function \link{generate_training_landscapes}
#'     all landscape functions need to have a rotation parameter.
#'
#' @return A landscape object with pattern "gaps" containing the generated landscape data and parameters.
#'
#' @keywords internal
#'
#' @examples
#' # Default gaps
#' gaps_default <- create_landscape_gaps()
#'
#' # Modified gaps with more gaps and random radius variation
#' gaps_modified <- create_landscape_gaps(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   noise_radius_sd = 2
#' )
create_landscape_gaps <- function(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  noise_radius_sd = 0,
  spot_jitter = 0,
  invert_landscape = TRUE,
  regular_spots = FALSE,
  rotation = 0
) {
  # Simply call create_landscape_spots with invert_landscape = TRUE by default
  result <- create_landscape_spots(
    width = width,
    height = height,
    n_spots = n_spots,
    spot_radius = spot_radius,
    noise_radius_sd = noise_radius_sd,
    spot_jitter = spot_jitter,
    invert_landscape = invert_landscape,
    regular_spots = regular_spots,
    rotation = rotation
  )

  # Update the pattern to "gaps" instead of "spots"
  result$pattern <- "gaps"

  return(result)
}
