#' Create a Landscape with Sharp Treeline
#'
#' Generates a binary landscape with a sharp treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param as_raster Logical. Whether to return as SpatRaster (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#'
#' @return SpatRaster. Binary landscape with sharp treeline (1 above treeline, 0 below).
#' @export
create_landscape_sharp_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL
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
  landscape[1:treeline_row, ] <- 1

  # Rotate the landscape, crop and fill NAs if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }
  if (as_raster) {
    return(matrix_to_raster(landscape))
  }
  return(landscape)
}

#' Create a Landscape with Diffuse Treeline
#'
#' Generates a binary landscape with a diffuse treeline where tree probability decreases with distance.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param steepness Numeric. Steepness of the transition (default: 2).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer. Random seed for reproducibility (default: NULL).
#'
#' @return SpatRaster. Binary landscape with diffuse treeline (decreasing probability with row).
#' @export
create_landscape_diffuse_treeline <- function(
  width = 100,
  height = 100,
  steepness = 2,
  rotation = 0,
  seed = NULL
) {
  # 1. If seed is not NULL, sets random seed
  # 2. Creates a matrix where probability of tree presence decreases with row index
  # 3. For each cell, assigns 1 with probability = 1 - (normalized_row)^steepness
  # 4. Converts matrix to raster
  # 5. If rotation != 0, rotates landscape
  # 6. Returns the resulting landscape
}

#' Create a Landscape with Curvy Treeline
#'
#' Generates a binary landscape with a curvy treeline following a sine wave pattern.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param sine_length Numeric. Wavelength of sinusoidal curve in pixels (default: 20).
#' @param sine_height Numeric. Amplitude of sinusoidal curve in pixels (default: 5).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return SpatRaster. Binary landscape with curvy treeline.
#' @export
create_landscape_curvy_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  sine_length = 20,
  sine_height = 5,
  rotation = 0
) {
  # 1. Calculates treeline row position
  # 2. Creates matrix where cells above curvy treeline = 1, below = 0
  # 3. Uses sine wave to create undulating boundary using formula i > (treeline_row + sin(2π*j/sine_length) * sine_height)
  # 4. Converts to raster and rotates if needed
  # 5. Returns the resulting landscape
}
