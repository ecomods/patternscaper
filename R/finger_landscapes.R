#' Create a landscape matrix with "fingers" extending from the treeline
#'
#' Generates a binary matrix representing a landscape with a sharp treeline and
#' finger-like extensions. Allows control over landscape size, number and width
#' of fingers, finger length, cropping, and rotation.
#'
#' @param width Integer. Width of the landscape (default: 100).
#' @param height Integer. Height of the landscape (default: 100).
#' @param treeline_position Numeric. Relative position of treeline (0-1, default: 0.5).
#' @param num_fingers Integer. Number of fingers to create (default: 5).
#' @param finger_width Integer. Width of each finger in columns (default: 3).
#' @param finger_length_prop Numeric. Proportion of height for finger length (default: 0.3).
#' @param cropped Logical. Whether to crop the landscape after rotation (default: FALSE).
#' @param rotation Numeric. Degrees to rotate the landscape (default: 0).
#' @param as_raster Logical. Whether to return the landscape as a raster (default: TRUE).
#' @param crs Character. Coordinate reference system for the raster (default: NULL).
#'
#' @return A matrix representing the landscape with fingers.
create_landscape_fingers <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_fingers = 5,
  finger_width = 3,
  finger_length_prop = 0.3,
  cropped = FALSE,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL
) {
  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # if rotated, the landscape will be cropped. Therefore we set
  # the cropped parameter to TRUE
  if (rotation != 0) {
    cropped <- TRUE
  }

  # Get base landscape with sharp treeline
  landscape <- create_landscape_sharp_treeline(
    width_actual,
    height_actual,
    treeline_position,
    as_raster = FALSE
  )

  # Calculate finger parameters
  if (!cropped) {
    treeline_row <- round(height_actual * treeline_position)
    finger_length <- round(height_actual * finger_length_prop)
    finger_positions <- round(seq(
      1,
      width_actual,
      length.out = num_fingers + 2
    )[
      -c(1, num_fingers + 2)
    ])
  } else {
    treeline_row <- round(height_actual * treeline_position)
    finger_length <- round((2 / 3 * height_actual) * finger_length_prop)
    finger_positions <- round(seq(
      (1 / 6 * width_actual),
      (5 / 6 * width_actual),
      length.out = num_fingers + 2
    )[-c(1, num_fingers + 2)])
  }

  # Create fingers extending from treeline
  for (pos in finger_positions) {
    start_col <- max(1, pos - floor(finger_width / 2))
    end_col <- min(width_actual, pos + floor(finger_width / 2))
    end_row <- min(height_actual, treeline_row + finger_length)

    landscape[treeline_row:end_row, start_col:end_col] <- 1
  }
  print(class(landscape))

  # Apply rotation if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }
  # Convert to raster if requested
  if (as_raster) {
    return(matrix_to_raster(landscape, crs = crs))
  }

  return(landscape)
}

#' Create a Landscape with Bent Finger-like Extensions
#'
#' Generates a binary landscape with bent finger-like extensions from the treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param num_fingers Integer. Number of fingers (default: 5).
#' @param finger_width Integer. Width of each finger in pixels (default: 3).
#' @param finger_length_prop Numeric. Length of fingers as proportion of height (default: 0.3).
#' @param bend_factor Numeric. Degree of finger bending (default: 3).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param as_raster Logical. Whether to return as SpatRaster (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#'
#' @return SpatRaster. Binary landscape with bent finger-like extensions.
#' @export
create_landscape_bent_fingers <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_fingers = 5,
  finger_width = 3,
  finger_length_prop = 0.3,
  bend_factor = 3,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL
) {
  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # In case of rotation, the finger width needs to be downscaled, otherwise the
  # fingers will be too wide because the rotation landscape will be larger at first
  if (rotation != 0) {
    finger_width <- round(finger_width / 1.5, 0)
    finger_length_prop <- finger_length_prop / 1.5
  }

  # Get base landscape with sharp treeline
  landscape <- create_landscape_sharp_treeline(
    width_actual,
    height_actual,
    treeline_position,
    as_raster = FALSE
  )

  # Calculate finger parameters
  treeline_row <- round(height_actual * treeline_position)
  finger_length <- round(height_actual * finger_length_prop)
  finger_positions <- round(seq(1, width_actual, length.out = num_fingers + 2)[
    -c(1, num_fingers + 2)
  ])
  end_row <- min(round(5 / 6 * height_actual), treeline_row + finger_length)

  # Create fingers extending from treeline
  for (pos in finger_positions) {
    for (fin in treeline_row:end_row) {
      w <- pos + round(sin(2 * pi * fin / 10) * 3)
      for (fw in ((-floor(finger_width / 2)):(ceiling(finger_width / 2)))) {
        if ((w + fw) > 0 && (w + fw) < width_actual) {
          landscape[fin, w + fw] <- 1
        }
      }
    }
  }

  # Rotate and crop the landscape if specified
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
