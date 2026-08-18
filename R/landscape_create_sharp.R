#' Create a Sharp Vegetation Boundary
#'
#' Parameters are documented on \code{\link{pattern_sharp}}.
#'
#' @return A landscape object with pattern \code{"sharp"}.
#'
#' @noRd
create_landscape_sharp <- function(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_boundary_position(boundary_position = boundary_position)
  validate_rotation(rotation = rotation)

  # Pad rotated landscapes before cropping to avoid clipped corners
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Build the unrotated binary boundary
  boundary_row <- round(height_actual * boundary_position)

  # Create the landscape matrix
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill in other vegetation area (1) based on boundary position
  if (boundary_row > 0) {
    mat[1:boundary_row, ] <- 1
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

  # Store the raster and its generation metadata.
  landscape(
    data = mat,
    pattern = "sharp",
    params = list(
      width = width,
      height = height,
      boundary_position = boundary_position,
      rotation = rotation
    )
  )
}
