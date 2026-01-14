#' Create a Landscape with Finger-like Treeline
#'
#' Generates a binary landscape with a curvy finger treeline following a sine wave pattern
#' with random length and amplitude for each wave segment.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param random_spots Numeric vector of length 2. Probabilities for flipping cells: [1→0, 0→1] (default: c(0,0)).
#' @param sine_length_mean Numeric. Mean wavelength of sinusoidal curve in pixels (default: 20).
#' @param sine_length_sd Numeric. Standard deviation of wavelength in pixels (default: 12).
#' @param sine_height_mean Numeric. Mean amplitude of sinusoidal curve in pixels (default: 5).
#' @param sine_height_sd Numeric. Standard deviation of amplitude in pixels (default: 4).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "fingers" containing the generated landscape data and parameters.
#'
#' @keywords internal
#' @importFrom cli cli_warn cli_abort
#'
#' @examples
#' # Default curvy fingers treeline
#' fingers_default <- create_landscape_fingers()
#'
#' # Modified parameters for more variation
#' fingers_modified <- create_landscape_fingers(
#'   sine_length_mean = 15,
#'   sine_length_sd = 10,
#'   sine_height_mean = 10,
#'   sine_height_sd = 6
#' )
#'
#' # With rotation
#' fingers_rotated <- create_landscape_fingers(
#'   rotation = 45
#' )
create_landscape_fingers <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  random_spots = c(0, 0),
  sine_length_mean = 20,
  sine_length_sd = 12,
  sine_height_mean = 5,
  sine_height_sd = 4,
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_treeline_position(treeline_position = treeline_position)
  validate_rotation(rotation = rotation)
  validate_random_spots(random_spots = random_spots)

  # Validate sine_length
  if (!is.numeric(sine_length_mean) || sine_length_mean <= 0) {
    cli::cli_abort("{.arg sine_length_mean} must be a positive numeric value.")
  }

  # Validate sine_height
  if (!is.numeric(sine_height_mean) || sine_height_mean < 0) {
    cli::cli_abort(
      "{.arg sine_height_mean} must be a non-negative numeric value."
    )
  }

  # Validate sine_length_sd
  if (!is.numeric(sine_length_sd) || sine_length_sd < 0) {
    cli::cli_abort(
      "{.arg sine_length_sd} must be a non-negative numeric value."
    )
  }

  # Validate sine_height_sd
  if (!is.numeric(sine_height_sd) || sine_height_sd < 0) {
    cli::cli_abort(
      "{.arg sine_height_sd} must be a non-negative numeric value."
    )
  }

  # Warn if sine_height_mean is large relative to landscape height
  if (sine_height_mean > height * 0.5) {
    cli::cli_warn(
      "{.arg sine_height_mean} ({sine_height_mean}) is large relative to {.arg height} ({height}). This may create unexpected patterns."
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

  # Fill in other vegetation area (1) based on treeline position
  if (treeline_row > 0) {
    mat[1:treeline_row, ] <- 1
  }

  # slightly shifting curves
  x_seq <- 1:width_actual

  # random trends
  noise_smooth <- function(x, mean_val, sd_val, smooth_span = 0.1) {
    raw <- rnorm(length(x), mean_val, sd_val)

    # loess needs at least ceiling(1/span) points for the given span
    min_points_needed <- ceiling(1 / smooth_span)

    if (length(x) < min_points_needed) {
      # Skip smoothing for very small landscapes
      raw[raw < 0.1] <- 0.1
      return(raw)
    }

    smooth <- stats::loess(raw ~ x, span = smooth_span)$fitted
    smooth[smooth < 0.1] <- 0.1
    return(smooth)
  }

  sine_length_vec <- noise_smooth(x_seq, sine_length_mean, sine_length_sd)
  sine_height_vec <- noise_smooth(x_seq, sine_height_mean, sine_height_sd)

  # Produce sine wave with varying wavelength and amplitude
  phase <- 0
  for (j in x_seq) {
    current_length <- sine_length_vec[j]
    current_height <- sine_height_vec[j]

    # Increment phase based on current wavelength
    # Normalize to prevent accumulation issues
    phase <- phase + (2 * pi / current_length)
    phase <- phase %% (2 * pi) # Keep phase bounded

    y_sine <- treeline_row + sin(phase) * current_height

    for (i in 1:height_actual) {
      mat[i, j] <- ifelse(i > y_sine, 0, 1)
    }
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
    pattern = "fingers",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      sine_length_mean = sine_length_mean,
      sine_length_sd = sine_length_sd,
      sine_height_mean = sine_height_mean,
      sine_height_sd = sine_height_sd,
      random_spots = random_spots,
      rotation = rotation
    )
  )
}
