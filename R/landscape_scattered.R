#' Create a Landscape with Scattered Trees
#'
#' Generates a binary landscape with randomly scattered trees below a treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param scatter_density Numeric. Probability of tree presence in the scatter zone (0-1) (default: 0.1).
#'    Higher values result in a denser tree cover in the scatter zone.
#' @param scatter_zone_prop Numeric. Proportion of height for scatter zone (default: 0.5).
#'   Defines how far below the treeline scattered trees can appear.
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'   If NULL, no seed is set explicitly.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default scattered trees
#' scattered_default <- create_landscape_scattered_trees()
#'
#' # Modified scattered trees with higher density in a larger scatter zone
#' scattered_modified <- create_landscape_scattered_trees(
#'   treeline_position = 0.3,
#'   scatter_density = 0.7,
#'   scatter_zone_prop = 0.2
#' )
#'
#' # With rotation
#' scattered_rotated <- create_landscape_scattered_trees(
#'   treeline_position = 0.3,
#'   scatter_density = 0.2,
#'   scatter_zone_prop = 0.1,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_scattered_trees <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  scatter_density = 0.1,
  scatter_zone_prop = 0.2,
  rotation = 0,
  seed = NULL,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Get base landscape with sharp treeline
  landscape <- create_landscape_sharp_treeline(
    width_actual,
    height_actual,
    treeline_position,
    as_raster = FALSE,
    add_metadata = FALSE
  )

  # Define scatter zone
  treeline_row <- round(height_actual * treeline_position)
  scatter_zone_end <- min(
    height_actual,
    treeline_row + round(height_actual * scatter_zone_prop)
  )

  # Randomly place trees in scatter zone
  for (i in (treeline_row + 1):scatter_zone_end) {
    for (j in 1:width_actual) {
      if (stats::runif(1) < scatter_density) {
        landscape[i, j] <- 1
      }
    }
  }

  # Apply rotation if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }

  # Get the result either as matrix or SpatRaster
  result <- if (as_raster) {
    matrix_to_raster(landscape, crs = crs)
  } else {
    landscape
  }

  # Return with metadata if requested
  if (add_metadata) {
    return(list(
      landscape = result,
      type = "scattered",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        scatter_density = scatter_density,
        scatter_zone_prop = scatter_zone_prop,
        rotation = rotation,
        seed = seed,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
