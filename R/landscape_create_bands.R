#' Create Sinusoidal Vegetation Bands
#'
#' Adds parallel sine-wave bands below a vegetated boundary.
#'
#' Parameters are documented on \code{\link{pattern_bands}}.
#'
#' @return A landscape object with pattern "bands".
#'
#' @noRd
#' @importFrom stats rnorm
create_landscape_bands <- function(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  band_zone = 0.3,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 4 * pi / 100,
  amplitude = 5,
  noise_sd = 0,
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_rotation(rotation = rotation)
  validate_boundary_position(boundary_position = boundary_position)

  # Validate pattern parameters
  if (!is.numeric(band_zone) || band_zone < 0 || band_zone > 1) {
    cli::cli_abort(c(
      "{.arg band_zone} must be between 0 and 1.",
      "x" = "You supplied {.val {band_zone}}"
    ))
  }

  if (!is.numeric(band_thickness) || band_thickness <= 0) {
    cli::cli_abort(c(
      "{.arg band_thickness} must be a positive number.",
      "x" = "You supplied {.val {band_thickness}}"
    ))
  }

  if (!is.numeric(band_spacing) || band_spacing <= 0) {
    cli::cli_abort(c(
      "{.arg band_spacing} must be a positive number.",
      "x" = "You supplied {.val {band_spacing}}"
    ))
  }

  if (!is.numeric(frequency) || frequency < 0) {
    cli::cli_abort(c(
      "{.arg frequency} must be a non-negative number.",
      "x" = "You supplied {.val {frequency}}"
    ))
  }

  if (!is.numeric(amplitude) || amplitude < 0) {
    cli::cli_abort(c(
      "{.arg amplitude} must be a non-negative number.",
      "x" = "You supplied {.val {amplitude}}"
    ))
  }

  if (!is.numeric(noise_sd) || noise_sd < 0) {
    cli::cli_abort(c(
      "{.arg noise_sd} must be a non-negative number.",
      "x" = "You supplied {.val {noise_sd}}"
    ))
  }

  # Pad rotated landscapes before cropping to avoid clipped corners
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Initialize empty landscape
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Base sine wave, used for both the vegetation boundary and the bands
  base_sine <- amplitude * sin(frequency * seq_len(width_actual))

  # Determine the vegetation boundary
  base_boundary <- round(height_actual * boundary_position + base_sine)
  base_boundary <- pmin(pmax(base_boundary, 1), height_actual)

  # Fill the area above the boundary
  for (x in seq_len(width_actual)) {
    y <- base_boundary[x]
    mat[seq_len(y), x] <- 1
  }

  # Calculate available space for bands below the boundary
  band_zone_height <- round(height_actual * band_zone)
  available_space <- height_actual - max(base_boundary)

  # Constrain band zone to available space
  band_zone_height <- min(band_zone_height, available_space)

  # Calculate number of bands that can fit
  num_bands <- floor(band_zone_height / band_spacing)

  # Report when the requested spacing leaves no room for a band
  if (num_bands == 0) {
    cli::cli_warn(c(
      "No bands can fit in available space.",
      "i" = "Available space below the vegetation boundary: {available_space} px",
      "i" = "Band spacing required: {band_spacing} px",
      "i" = "Consider decreasing {.arg band_spacing}, {.arg boundary_position}, or increasing {.arg band_zone}."
    ))
  }

  band_offsets <- seq(band_spacing, by = band_spacing, length.out = num_bands)

  # Draw each band with independent vertical noise
  for (offset in band_offsets) {
    band_noise <- stats::rnorm(width_actual, mean = 0, sd = noise_sd)

    for (x in seq_len(width_actual)) {
      y_center <- base_boundary[x] + offset + band_noise[x]

      y_min <- max(1, floor(y_center - floor(band_thickness / 2)))
      y_max <- min(
        height_actual,
        ceiling(y_center + ceiling(band_thickness / 2))
      )

      if (y_min <= y_max) {
        mat[seq(y_min, y_max), x] <- 1
      }
    }
  }

  # Apply rotation if specified
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
    pattern = "bands",
    params = list(
      width = width,
      height = height,
      boundary_position = boundary_position,
      band_zone = band_zone,
      band_thickness = band_thickness,
      band_spacing = band_spacing,
      frequency = frequency,
      amplitude = amplitude,
      noise_sd = noise_sd,
      rotation = rotation
    )
  )
}
