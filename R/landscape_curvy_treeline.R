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
#' @return A landscape object with pattern "curvy" containing the generated landscape data and parameters.
#'
#' @keywords internal
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
create_landscape_curvy_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  sine_length = 20,
  sine_height = 5,
  rotation = 0
) {
  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Convert position from proportion to row number
  treeline_row <- round(height_actual * treeline_position)

  # Create the landscape matrix
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill in tree area (1) based on sine wave around the treeline position
  # sine_height determines how many cells around tree_line are affected
  # sine_length determines the wave length
  for (i in 1:height_actual) {
    for (j in 1:width_actual) {
      mat[i, j] <- ifelse(
        i > (treeline_row + sin(2 * pi * j / sine_length) * sine_height),
        0,
        1
      )
    }
  }

  # Rotate the landscape, crop and fill NAs if specified
  if (rotation != 0) {
    mat <- rotate_and_crop_landscape(
      mat,
      rotation,
      width,
      height
    )
  }

  # Create and return landscape object
  landscape(
    data = mat,
    pattern = "curvy",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      sine_length = sine_length,
      sine_height = sine_height,
      rotation = rotation
    )
  )
}
