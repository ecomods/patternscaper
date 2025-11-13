#' Create a Landscape with Diffuse Treeline
#'
#' Generates a binary landscape with a diffuse treeline where tree probability decreases with distance.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param steepness Numeric. Steepness of the transition can be a value between
#'    0 and 100. The higher the number the sharper the treeline becomes (default: 2).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "diffuse" containing the generated landscape data and parameters.
#'
#' @keywords internal
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
create_landscape_diffuse_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  steepness = 2,
  rotation = 0
) {
  # Validate inputs
  if (!is.numeric(width) || width <= 0 || width != as.integer(width)) {
    cli::cli_abort(c(
      "{.arg width} must be a positive integer.",
      "x" = "You supplied {.val {width}}"
    ))
  }

  if (!is.numeric(height) || height <= 0 || height != as.integer(height)) {
    cli::cli_abort(c(
      "{.arg height} must be a positive integer.",
      "x" = "You supplied {.val {height}}"
    ))
  }

  if (
    !is.numeric(treeline_position) ||
      treeline_position < 0 ||
      treeline_position > 1
  ) {
    cli::cli_abort(c(
      "{.arg treeline_position} must be between 0 and 1.",
      "x" = "You supplied {.val {treeline_position}}"
    ))
  }

  if (!is.numeric(rotation) || rotation < 0 || rotation > 360) {
    cli::cli_abort(c(
      "{.arg rotation} must be numeric and between 0 and 360.",
      "x" = "You supplied {.type {rotation}}"
    ))
  }

  if (!is.numeric(steepness) || steepness < 0 || steepness > 100) {
    cli::cli_abort(c(
      "{.arg steepness} must be numeric and between 0 and 100.",
      "x" = "You supplied {.type {steepness}}"
    ))
  }

  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Create empty landscape
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

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
        mat[i, j] <- 1
      }
    }
  }

  # Rotate the landscape, crop and fill NAs if specified
  if (rotation != 0) {
    mat <- rotate_and_crop_matrix(
      mat,
      rotation,
      width,
      height
    )
  }

  # Create and return landscape object
  landscape(
    data = mat,
    pattern = "diffuse",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      steepness = steepness,
      rotation = rotation
    )
  )
}
