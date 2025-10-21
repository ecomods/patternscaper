#' Create a Landscape with Gaps Pattern
#'
#' Generates a binary landscape with circular spots.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param n_spots Integer. Number of non-vegetated spots
#' @param spot_radius Integer. Radius of each spot
#' @param noise_radius_sd Numeric. If random effects, which standard deviation (Default is 0 - no random effects)
#' @param spot_jitter Integer. Should the regular spots be slightly shifted - how many cells (Default is 0 - no jitter)
#' @param invert_landscape Boolean. Invert vegetated and unvegetated areas.
#'     Switches the landscape from vegetated with bare spots to bare with vegetated spots (default: TRUE).
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'     If NULL, seed will not be set explicitly.
#'     If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param regular_spots Boolean. Should the spots be arranged in a regular way (on a hexagon using k-means) or randomly?
#'     (default: FALSE)
#' @param rotation Unused parameter for compatibility with other landscape functions (default: 0).
#'     Is only needed because in the function \link{generate_training_landscapes}
#'     all landscape functions need to have a rotation parameter.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return A matrix representing the ringed/spotted landscape, where 1 indicates vegetation and 0 indicates bare soil.
#' @examples
#' # Default spots
#' spots_default <- create_landscape_spots()
#'
#' # Modified spots with more spots and random radius variation
#' spots_modified <- create_landscape_spots(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   noise_radius_sd = 2
#' )
#'
#' # Gaps (vegetation outside spots instead of inside)
#' gaps <- create_landscape_spots(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   invert_landscape = TRUE,
#'   noise_radius_sd = 2
#' )
#' @export
create_landscape_gaps <- function(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  noise_radius_sd = 0,
  spot_jitter = 0,
  invert_landscape = TRUE,
  seed = NULL,
  regular_spots = FALSE,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  result <- create_landscape_spots(
    width = width,
    height = height,
    n_spots = n_spots,
    spot_radius = spot_radius,
    noise_radius_sd = noise_radius_sd,
    spot_jitter = spot_jitter,
    invert_landscape = invert_landscape,
    seed = seed,
    regular_spots = regular_spots,
    rotation = rotation,
    as_raster = as_raster,
    crs = crs,
    add_metadata = add_metadata
  )

  return(result)
}
