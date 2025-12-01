#' Create a Landscape with Gaps Pattern
#'
#' Generates a binary landscape with circular gaps (vegetation patches in bare ground).
#' This is a convenience wrapper around \code{\link{create_landscape_spots}} with
#' \code{invert_landscape = TRUE} by default, making "gaps" and "spots" semantically
#' distinct pattern names for the same underlying algorithm.
#'
#' @inheritParams create_landscape_spots
#' @param invert_landscape Logical. If TRUE (default), creates vegetation patches in bare ground
#'     (gaps pattern). If FALSE, creates bare spots in vegetation (equivalent to spots pattern).
#'     Provided for consistency with other landscape generators.
#'
#' @details
#' The distinction between "spots" and "gaps":
#' \itemize{
#'   \item \strong{spots}: Bare patches in vegetation matrix (\code{invert_landscape = FALSE})
#'   \item \strong{gaps}: Vegetation patches in bare ground (\code{invert_landscape = TRUE})
#' }
#'
#' Both patterns use the same algorithm; the pattern name primarily serves as a semantic
#' label for training data organization.
#'
#' @return A landscape object with pattern "gaps" containing the generated landscape data and parameters.
#'
#' @seealso \code{\link{create_landscape_spots}} for the underlying implementation
#'
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
#' @keywords internal
create_landscape_gaps <- function(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  invert_landscape = TRUE,
  regular_spots = FALSE,
  rotation = 0
) {
  # Call create_landscape_spots with invert_landscape = TRUE by default
  result <- create_landscape_spots(
    width = width,
    height = height,
    n_spots = n_spots,
    spot_radius = spot_radius,
    spot_radius_sd = spot_radius_sd,
    radius_noise_fraction = radius_noise_fraction,
    invert_landscape = invert_landscape,
    regular_spots = regular_spots,
    rotation = rotation
  )

  # Update pattern to "gaps"
  result$pattern <- "gaps"

  return(result)
}
