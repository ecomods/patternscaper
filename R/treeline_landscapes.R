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
#' @param as_raster Logical. Whether to return as SpatRaster (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#'
#' @return SpatRaster. Binary landscape with diffuse treeline (decreasing probability with row).
#' @export
create_landscape_diffuse_treeline <- function(
  width = 100,
  height = 100,
  steepness = 2,
  rotation = 0,
  seed = NULL,
  as_raster = TRUE,
  crs = NULL
) {
  # Set seed to current time if not  provided
  if (!is.null(seed)) {
    set.seed(as.integer(Sys.time()))
  }

  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Create empty landscape
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill with tree cover probability that decreases from 1 to 0 with increasing row index
  for (i in 1:height_actual) {
    # Normalize row index [0,1] starting at 0
    normalized_row <- (i - 1) / (height_actual - 1)
    # Calculate probability for tree cover (starts 1 and decreases to 0)
    prob <- 1 - normalized_row^steepness
    for (j in 1:width_actual) {
      if (stats::runif(1) < prob) {
        landscape[i, j] <- 1
      }
    }
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

  if (as_raster) {
    return(matrix_to_raster(landscape, crs = crs))
  }
  return(landscape)
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
#' @param as_raster Logical. Whether to return as SpatRaster (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#'
#' @return SpatRaster. Binary landscape with curvy treeline.
#' @export
create_landscape_curvy_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  sine_length = 20,
  sine_height = 5,
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
  # Fill in mangrove area (1) based on sine wave around treeline position
  #sine_height determines how many cells around tree_line are affected
  #sine_length dtermines the lenght of the wave
  for (i in 1:height_actual) {
    for (j in 1:width_actual) {
      landscape[i, j] <- ifelse(
        i > (treeline_row + sin(2 * pi * j / sine_length) * sine_height),
        1,
        0
      )
    }
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

  # Convert to SpatRaster if requested
  if (as_raster) {
    return(matrix_to_raster(landscape, crs = crs))
  }

  return(landscape)
}
