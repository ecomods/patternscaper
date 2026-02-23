#' Create a Landscape with Gaps Pattern
#'
#' Generates a binary landscape with circular gaps (bare patches in vegetated ground).
#' This is a convenience wrapper around \code{\link{create_landscape_spots}} with
#' \code{invert_landscape = TRUE} by default, making "gaps" and "spots" semantically
#' distinct pattern names for the same underlying algorithm.
#'
#' @inheritParams create_landscape_spots
#'
#' @details
#' The distinction between "spots" and "gaps":
#' \itemize{
#'   \item \strong{gaps}: Bare patches in vegetation matrix)
#'   \item \strong{spots}: Vegetation patches in bare ground)
#' }
#'
#' Both patterns use the same algorithm; the pattern name primarily serves as a semantic
#' label for training data organization.
#'
#' @return A landscape object with pattern "gaps" containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "gaps"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @seealso \code{\link{create_landscape_spots}} for the underlying implementation
#' @export
#' @examples
#' # Default gaps (vegetation patches in bare ground)
#' gaps_default <- create_landscape_gaps()
#'
#' # More gaps with size variation
#' gaps_modified <- create_landscape_gaps(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   spot_radius_sd = 2
#' )
#'
create_landscape_gaps <- function(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_spots = FALSE
) {
  # Call create_landscape_spots with invert_landscape = TRUE
  result <- create_landscape_spots(
    width = width,
    height = height,
    n_spots = n_spots,
    spot_radius = spot_radius,
    spot_radius_sd = spot_radius_sd,
    radius_noise_fraction = radius_noise_fraction,
    invert_landscape = TRUE,
    regular_spots = regular_spots
  )

  # Update pattern to "gaps"
  result$pattern <- "gaps"

  return(result)
}
