#' Create a Landscape with Sharp Treeline
#'
#' Generates a binary landscape with a sharp treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default sharp treeline
#' sharp_default <- create_landscape_sharp_treeline()
#'
#' # Modified sharp treeline with higher treeline position
#' sharp_modified <- create_landscape_sharp_treeline(
#'   treeline_position = 0.7
#' )
#'
#' # Landscape with rotation
#' sharp_rotated <- create_landscape_sharp_treeline(
#'   treeline_position = 0.3,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_sharp_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Convert position from proportion to row number
  treeline_row <- round(height_actual * treeline_position)

  # Create the landscape matrix
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill in mangrove area (1) based on treeline position
  if (treeline_row > 0) {
    landscape[1:treeline_row, ] <- 1
  }

  # Rotate the landscape, crop and fill NAs if specified
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
      type = "sharp",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        rotation = rotation,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
