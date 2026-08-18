#' Create a Diffuse Vegetation Boundary
#'
#' Generates a binary landscape with a diffuse vegetation boundary where
#' vegetation probability decreases with distance.
#'
#' Parameters are documented on \code{\link{pattern_diffuse}}.
#'
#' @return A landscape object with pattern \code{"diffuse"}.
#'
#' @noRd
#' @importFrom cli cli_abort
#' @importFrom stats runif
create_landscape_diffuse <- function(
  width = 100,
  height = 100,
  boundary_position = 0.2,
  steepness = 0.5,
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_boundary_position(boundary_position = boundary_position)
  validate_rotation(rotation = rotation)

  if (!is.numeric(steepness) || steepness < 0 || steepness > 1) {
    cli::cli_abort(c(
      "{.arg steepness} must be numeric and between 0 and 1.",
      "x" = "You supplied {.val {steepness}}"
    ))
  }

  # Pad rotated landscapes before cropping to avoid clipped corners
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Create empty landscape
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Determine the center of the transition zone
  transition_center <- round(height_actual * boundary_position)

  # Fill with vegetation cover probability that changes based on distance from transition center
  for (i in 1:height_actual) {
    # Calculate normalized position relative to transition center
    # Ranges from -1 (top of image) to +1 (bottom of image)
    relative_pos <- (i - transition_center) / (height_actual * 0.5)

    # Above the boundary, vegetation probability is 1. Below it, a power
    # curve gives sharper transitions at lower steepness values
    if (relative_pos <= 0) {
      prob <- 1
    } else {
      prob <- max(0, 1 - (relative_pos)^steepness)
    }

    # Draw cells independently within each row
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

  # Store the raster and its generation metadata
  landscape(
    data = mat,
    pattern = "diffuse",
    params = list(
      width = width,
      height = height,
      boundary_position = boundary_position,
      steepness = steepness,
      rotation = rotation
    )
  )
}
