#' Create a Landscape with Diffuse Vegetation Boundary
#'
#' Generates a binary landscape with a diffuse vegetation boundary where vegetation probability decreases with distance.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param boundary_position Numeric. Relative position of vegetation boundary from top (0-1) (default: 0.5).
#' @param steepness Numeric. Controls the transition gradient (0-1).
#'   Lower values (e.g., 0.1) create sharper transitions.
#'   Higher values (e.g., 0.9) create more gradual, diffuse transitions
#'   where vegetation probability persists further below the vegetation boundary (default: 0.5).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "diffuse" containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "diffuse"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @family landscape creation
#' @export
#' @importFrom cli cli_abort
#' @importFrom stats runif
#'
#' @examples
#' # Default diffuse vegetation boundary
#' diffuse_default <- create_landscape_diffuse()
#'
#' # Sharp transition (lower steepness)
#' diffuse_sharp <- create_landscape_diffuse(
#'   boundary_position = 0.2,
#'   steepness = 0.1
#' )
#'
#' # Gradual transition (higher steepness)
#' diffuse_gradual <- create_landscape_diffuse(
#'   boundary_position = 0.3,
#'   steepness = 0.9
#' )
#'
#' # With rotation
#' diffuse_rotated <- create_landscape_diffuse(
#'   boundary_position = 0.3,
#'   steepness = 0.7,
#'   rotation = 45
#' )
#'
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

  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
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

    # Calculate probability for vegetation cover following a power curve:
    # - Above vegetation boundary (relative_pos <= 0): prob = 1 (full vegetation cover)
    # - Below vegetation boundary (relative_pos > 0): prob = 1 - (relative_pos)^steepness
    #   * Lower steepness (e.g., 0.1): Higher exponent effect = sharper drop-off
    #   * Higher steepness (e.g., 0.9): Lower exponent effect = gradual transition
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
      boundary_position = boundary_position,
      steepness = steepness,
      rotation = rotation
    )
  )
}
