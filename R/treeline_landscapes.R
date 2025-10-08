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

#' Create a Landscape with Diffuse Treeline
#'
#' Generates a binary landscape with a diffuse treeline where tree probability decreases with distance.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param steepness Numeric. Steepness of the transition (default: 2).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default diffuse treeline
#' diffuse_default <- create_landscape_diffuse_treeline()
#'
#' # Modified diffuse treeline with greater steepness
#' diffuse_modified <- create_landscape_diffuse_treeline(
#'   treeline_position = 0.2,
#'   steepness = 0.1
#' )
#'
#' # With rotation
#' diffuse_rotated <- create_landscape_diffuse_treeline(
#'   treeline_position = 0.3,
#'   steepness = 2,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_diffuse_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  steepness = 2,
  rotation = 0,
  seed = 42,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # If seed is NULL, use random seed; otherwise use the provided seed
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)

  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Create empty landscape
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Determine the center of the transition zone
  transition_center <- round(height_actual * treeline_position)

  # Fill with tree cover probability that changes based on distance from transition center
  for (i in 1:height_actual) {
    # Calculate normalized position relative to transition center
    # Ranges from -1 (top of image) to +1 (bottom of image)
    relative_pos <- (i - transition_center) / (height_actual * 0.5)

    # Calculate probability for tree cover:
    # prob = 1 for rows above transition (relative_pos <= 0)
    # prob decreases from 1 to 0 below transition following power curve
    if (relative_pos <= 0) {
      prob <- 1
    } else {
      prob <- max(0, 1 - (relative_pos)^steepness)
    }

    # Apply probability to each cell in this row
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
      type = "diffuse",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        steepness = steepness,
        rotation = rotation,
        seed = seed,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
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
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default curvy treeline
#' curvy_default <- create_landscape_curvy_treeline()
#'
#' # Modified curvy treeline with increased sine parameters
#' curvy_modified <- create_landscape_curvy_treeline(
#'   treeline_position = 0.3,
#'   sine_length = 40,
#'   sine_height = 10
#' )
#'
#' # With rotation
#' curvy_rotated <- create_landscape_curvy_treeline(
#'   treeline_position = 0.6,
#'   sine_length = 10,
#'   sine_height = 6,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_curvy_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  sine_length = 20,
  sine_height = 5,
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
  # Fill in tree area (1) based on sine wave around the treeline position
  # sine_height determines how many cells around tree_line are affected
  # sine_length determines the wave length
  for (i in 1:height_actual) {
    for (j in 1:width_actual) {
      landscape[i, j] <- ifelse(
        i > (treeline_row + sin(2 * pi * j / sine_length) * sine_height),
        0,
        1
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
      type = "curvy",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        sine_length = sine_length,
        sine_height = sine_height,
        rotation = rotation,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
