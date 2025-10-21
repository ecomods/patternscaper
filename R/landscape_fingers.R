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
#' @param finger_width Integer. Width of each finger in pixels (default: 3).
#' @param finger_length_prop Numeric. Proportion of height of the total landscape for finger length (default: 0.3).
#' @param finger_length_sd Numeric. Standard deviation for finger length randomness
#'    in proportion of actual finger length (default: 0, no randomness).
#' @param bend Logical. Should the fingers be bent in a sinus pattern or not? (default: FALSE).
#' @param rotation Numeric. Degrees to rotate the landscape (default: 0).
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system for the raster (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return A matrix, SpatRaster, or List with landscape and metadata
#'
#' @examples
#' # Default fingers pattern
#' fingers_default <- create_landscape_fingers()
#'
#' # Modified fingers with more, thinner fingers and bending
#' fingers_modified <- create_landscape_fingers(
#'   treeline_position = 0.2,
#'   num_fingers = 7,
#'   finger_width = 5,
#'   finger_length_prop = 0.5,
#'   bend = TRUE
#' )
#'
#' # With rotation
#' fingers_rotated <- create_landscape_fingers(
#'   num_fingers = 10,
#'   finger_width = 4,
#'   finger_length_prop = 1,
#'   bend = TRUE,
#'   rotation = 45
#' )
#'
create_landscape_fingers <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_fingers = 5L,
  finger_width = 3L,
  finger_length_prop = 0.3,
  finger_length_sd = 0,
  bend = FALSE,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # Verify inputs
  if (!is.integer(num_fingers)) {
    num_fingers <- as.integer(num_fingers)
  }
  if (!is.integer(finger_width)) {
    finger_width <- as.integer(finger_width)
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

  # Calculate finger parameters
  if (rotation == 0) {
    treeline_row <- round(height_actual * treeline_position)
    finger_length <- round((height_actual - treeline_row) * finger_length_prop)
    # Create finger positions evenly spaced across the width
    # Remove first and last to avoid edge issues
    finger_positions <- round(seq(
      1,
      width_actual,
      length.out = num_fingers + 2
    )[
      -c(1, num_fingers + 2)
    ])
  } else {
    treeline_row <- round(height_actual * treeline_position)
    finger_length <- round(
      (2 / 3 * (height_actual - treeline_row)) * finger_length_prop
    )
    finger_positions <- round(seq(
      (1 / 6 * width_actual),
      (5 / 6 * width_actual),
      length.out = num_fingers + 2
    )[-c(1, num_fingers + 2)])
  }

  # Add randomness to finger length if specified
  finger_lengths <- rep(finger_length, num_fingers) +
    round(rnorm(num_fingers, mean = 0, sd = finger_length_sd * finger_length))

  # Create fingers extending from treeline
  if (bend) {
    # Use the same calculation as the non-bend case
    end_rows <- treeline_row + finger_lengths
    # Ensure end_row does not exceed landscape height
    end_rows <- pmin(end_rows, height_actual)

    # Create fingers extending from treeline
    for (pos in seq_along(finger_positions)) {
      for (fin in treeline_row:end_rows[pos]) {
        w <- finger_positions[pos] + round(sin(2 * pi * fin / 10) * 3)
        for (fw in ((-floor(finger_width / 2)):(ceiling(finger_width / 2)))) {
          if ((w + fw) > 0 && (w + fw) <= width_actual) {
            # Changed < to <= to include edge
            landscape[fin, w + fw] <- 1
          }
        }
      }
    }
  } else {
    # Use the same calculation as the non-bend case
    end_rows <- treeline_row + finger_lengths
    # Ensure end_row does not exceed landscape height
    end_rows <- pmin(end_rows, height_actual)

    for (pos in seq_along(finger_positions)) {
      start_col <- max(1, finger_positions[pos] - floor(finger_width / 2))
      end_col <- min(
        width_actual,
        finger_positions[pos] + floor(finger_width / 2)
      )
      landscape[treeline_row:end_rows[pos], start_col:end_col] <- 1
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
      type = "fingers",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        num_fingers = num_fingers,
        finger_width = finger_width,
        finger_length_prop = finger_length_prop,
        rotation = rotation,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
