#' Create a Finger-like Vegetation Boundary
#'
#' Builds a sine-wave boundary whose wavelength and amplitude vary smoothly
#' across columns.
#'
#' Parameters are documented on \code{\link{pattern_fingers}}.
#'
#' @return A landscape object with pattern "fingers".
#'
#' @noRd
#' @importFrom cli cli_warn cli_abort
create_landscape_fingers <- function(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  sine_length_mean = 20,
  sine_length_sd = 12,
  sine_height_mean = 5,
  sine_height_sd = 5,
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_boundary_position(boundary_position = boundary_position)
  validate_rotation(rotation = rotation)

  # Validate pattern parameters
  if (!is.numeric(sine_length_mean) || sine_length_mean <= 0) {
    cli::cli_abort("{.arg sine_length_mean} must be a positive numeric value.")
  }

  if (!is.numeric(sine_height_mean) || sine_height_mean < 0) {
    cli::cli_abort(
      "{.arg sine_height_mean} must be a non-negative numeric value."
    )
  }

  if (!is.numeric(sine_length_sd) || sine_length_sd < 0) {
    cli::cli_abort(
      "{.arg sine_length_sd} must be a non-negative numeric value."
    )
  }

  if (!is.numeric(sine_height_sd) || sine_height_sd < 0) {
    cli::cli_abort(
      "{.arg sine_height_sd} must be a non-negative numeric value."
    )
  }

  # Flag amplitudes likely to dominate the landscape height
  if (sine_height_mean > height * 0.5) {
    cli::cli_warn(
      "{.arg sine_height_mean} ({sine_height_mean}) is large relative to {.arg height} ({height}). This may create unexpected patterns."
    )
  }

  # Pad rotated landscapes before cropping to avoid clipped corners
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Build the initial horizontal boundary
  boundary_row <- round(height_actual * boundary_position)

  # Create the landscape matrix
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  if (boundary_row > 0) {
    mat[1:boundary_row, ] <- 1
  }

  # Sample smooth wavelength and amplitude trends across columns
  x_seq <- 1:width_actual

  # random trends
  noise_smooth <- function(x, mean_val, sd_val, smooth_span = 0.1) {
    raw <- rnorm(length(x), mean_val, sd_val)

    # Adjust span to be appropriate for landscape size
    # For small landscapes, use larger span to ensure stable loess fit
    n_points <- length(x)
    if (n_points < 50) {
      adjusted_span <- max(0.3, 15 / n_points)
    } else {
      adjusted_span <- smooth_span
    }

    smooth <- stats::loess(raw ~ x, span = adjusted_span)$fitted
    smooth[smooth < 0.1] <- 0.1
    return(smooth)
  }

  sine_length_vec <- noise_smooth(x_seq, sine_length_mean, sine_length_sd)
  sine_height_vec <- noise_smooth(x_seq, sine_height_mean, sine_height_sd)

  # Trace the boundary with varying wavelength and amplitude
  phase <- 0
  for (j in x_seq) {
    current_length <- sine_length_vec[j]
    current_height <- sine_height_vec[j]

    phase <- phase + (2 * pi / current_length)
    phase <- phase %% (2 * pi) # Keep phase bounded to limit accumulation

    y_sine <- boundary_row + sin(phase) * current_height

    for (i in 1:height_actual) {
      mat[i, j] <- ifelse(i > y_sine, 0, 1)
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
    pattern = "fingers",
    params = list(
      width = width,
      height = height,
      boundary_position = boundary_position,
      sine_length_mean = sine_length_mean,
      sine_length_sd = sine_length_sd,
      sine_height_mean = sine_height_mean,
      sine_height_sd = sine_height_sd,
      rotation = rotation
    )
  )
}
