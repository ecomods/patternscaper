#' Create a Landscape with Curvy Treeline
#'
#' Generates a binary landscape with a curvy treeline following a sine wave pattern.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param sine_length Numeric. Wavelength of sinusoidal curve in pixels (default: 20).
#' @param sine_height Numeric. Amplitude of sinusoidal curve in pixels (default: 5).
#' @param random_spots Numeric vector of length 2. Probabilities for flipping cells: [1→0, 0→1] (default: c(0,0)).
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
  random_spots = c(0, 0),
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_treeline_position(treeline_position = treeline_position)
  validate_rotation(rotation = rotation)
  validate_random_spots(random_spots = random_spots)

  # Validate sine_length
  if (!is.numeric(sine_length) || sine_length <= 0) {
    cli::cli_abort("{.arg sine_length} must be a positive numeric value.")
  }

  # Validate sine_height
  if (!is.numeric(sine_height) || sine_height < 0) {
    cli::cli_abort("{.arg sine_height} must be a non-negative numeric value.")
  }

  # Warn if sine_height is larger than landscape height
  if (sine_height > height * 0.5) {
    cli::cli_warn(
      "{.arg sine_height} ({sine_height}) is large relative to {.arg height} ({height}). This may create unexpected patterns."
    )
  }

  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Convert position from proportion to row number
  treeline_row <- round(height_actual * treeline_position)

  # Create the landscape matrix
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill in tree area (1) based on sine wave around the treeline position
  # Vectorized calculation of sine wave boundary for each column
  wave_boundary <- treeline_row +
    sin(2 * pi * seq_len(width_actual) / sine_length) * sine_height

  # For each row, check if it's above the wave boundary
  for (i in seq_len(height_actual)) {
    mat[i, ] <- ifelse(i <= wave_boundary, 1, 0)
  }

  # Add random spots if requested
  if (any(random_spots > 0)) {
    # Indices for each type
    idx_1 <- which(mat == 1)
    idx_0 <- which(mat == 0)

    # Flip some cells based on probabilities
    flip_to_0 <- idx_1[rbinom(length(idx_1), 1, random_spots[1]) == 1]
    flip_to_1 <- idx_0[rbinom(length(idx_0), 1, random_spots[2]) == 1]

    mat[flip_to_0] <- 0
    mat[flip_to_1] <- 1
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
    pattern = "curvy",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      sine_length = sine_length,
      sine_height = sine_height,
      random_spots = random_spots,
      rotation = rotation
    )
  )
}
