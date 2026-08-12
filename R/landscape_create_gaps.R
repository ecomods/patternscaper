#' Create a Landscape with Gaps Pattern
#'
#' Generates a binary landscape with circular gaps (bare patches in vegetated ground).
#' This is a convenience wrapper around \code{\link{create_landscape_spots}} with
#' \code{invert_landscape = TRUE} by default, making "gaps" and "spots" semantically
#' distinct pattern names for the same underlying algorithm.
#'
#' Parameters are documented on \code{\link{pattern_gaps}}.
#'
#' @details
#' The distinction between "spots" and "gaps":
#' \itemize{
#'   \item \strong{gaps}: Bare patches in vegetation matrix
#'   \item \strong{spots}: Vegetation patches in bare ground
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
#' @noRd
create_landscape_gaps <- function(
  width = 100,
  height = 100,
  n_gaps = 5,
  gap_radius = 10,
  gap_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_gaps = FALSE
) {
  # Call create_landscape_spots with invert_landscape = TRUE. The shared
  # implementation speaks in spots, so the gap names are translated here.
  result <- create_landscape_spots(
    width = width,
    height = height,
    n_spots = n_gaps,
    spot_radius = gap_radius,
    spot_radius_sd = gap_radius_sd,
    radius_noise_fraction = radius_noise_fraction,
    invert_landscape = TRUE,
    regular_spots = regular_gaps
  )

  # Update pattern to "gaps"
  result$pattern <- "gaps"

  # Report the parameters back as gaps. Renaming the keys rather than
  # rebuilding the list keeps the values create_landscape_spots() actually
  # used, which are not always the ones passed in: it coerces the count to
  # integer, and reduces it to what fits under regular placement.
  gap_names <- c(
    n_spots = "n_gaps",
    spot_radius = "gap_radius",
    spot_radius_sd = "gap_radius_sd",
    regular_spots = "regular_gaps"
  )
  renamed <- names(result$params) %in% names(gap_names)
  names(result$params)[renamed] <- gap_names[names(result$params)[renamed]]

  return(result)
}
