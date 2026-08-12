#' Create a Landscape with a Sharp Vegetation Boundary
#'
#'
#' Parameters are documented on \code{\link{pattern_sharp}}.
#'
#' @return A landscape object with pattern "sharp" containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "sharp"}
#'   \item{params}{List of all input parameters used to generate the landscape}
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

  # Calculate width and height of the actual landscape to produce
  # In case of rotation, the landscape needs to be larger to avoid cropping pattern
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Convert position from proportion to row number
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

  # Create and return landscape object
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
