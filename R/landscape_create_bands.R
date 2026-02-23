#' Create a Landscape with Sine Wave Bands
#'
#' Generates a binary landscape with parallel sine-wave bands.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param boundary_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param band_zone_prop Numeric. Proportion of height of the total landscape to
#'     allocate for bands below the treeline (default: 0.2). If the band zone is too small
#'     for the given band spacing, no bands will be drawn and a warning will be issued.
#' @param band_thickness Integer. Thickness of each band in pixels (default: 3).
#' @param band_spacing Integer. Spacing between bands in pixels (default: 10).
#' @param frequency Numeric. Frequency of sine wave (default: 2*pi/100).
#' @param amplitude Numeric. Amplitude of sine wave in pixels (default: 5).
#' @param noise_sd Numeric. Standard deviation for random noise (default: 0).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "bands" containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "bands"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @family landscape creation
#' @export
#' @examples
#' # Default sine bands
#' bands_default <- create_landscape_bands()
#'
#' # Modified sine bands with thicker bands, wider spacing and noise
#' bands_modified <- create_landscape_bands(
#'   boundary_position = 0.3,
#'   band_zone_prop = 0.5,
#'   band_thickness = 5,
#'   band_spacing = 15,
#'   frequency = 1,
#'   amplitude = 8,
#'   noise_sd = 1.5
#' )
#'
#' # With rotation
#' bands_rotated <- create_landscape_bands(
#'   band_thickness = 4,
#'   band_spacing = 12,
#'   amplitude = 6,
#'   noise_sd = 2,
#'   rotation = 45
#' )
#'
#' @importFrom stats rnorm
create_landscape_bands <- function(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  band_zone_prop = 0.2,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 2 * pi / 100,
  amplitude = 5,
  noise_sd = 0,
  rotation = 0
) {
  # Validate common parameters
  validate_dimensions(width = width, height = height)
  validate_rotation(rotation = rotation)
  validate_boundary_position(boundary_position = boundary_position)

  # Validate band_zone_prop
  if (!is.numeric(band_zone_prop) || band_zone_prop < 0 || band_zone_prop > 1) {
    cli::cli_abort(c(
      "{.arg band_zone_prop} must be between 0 and 1.",
      "x" = "You supplied {.val {band_zone_prop}}"
    ))
  }

  # Validate band_thickness
  if (!is.numeric(band_thickness) || band_thickness <= 0) {
    cli::cli_abort(c(
      "{.arg band_thickness} must be a positive number.",
      "x" = "You supplied {.val {band_thickness}}"
    ))
  }

  # Validate band_spacing
  if (!is.numeric(band_spacing) || band_spacing <= 0) {
    cli::cli_abort(c(
      "{.arg band_spacing} must be a positive number.",
      "x" = "You supplied {.val {band_spacing}}"
    ))
  }

  # Validate frequency
  if (!is.numeric(frequency) || frequency < 0) {
    cli::cli_abort(c(
      "{.arg frequency} must be a non-negative number.",
      "x" = "You supplied {.val {frequency}}"
    ))
  }

  # Validate amplitude
  if (!is.numeric(amplitude) || amplitude < 0) {
    cli::cli_abort(c(
      "{.arg amplitude} must be a non-negative number.",
      "x" = "You supplied {.val {amplitude}}"
    ))
  }

  # Validate noise_sd
  if (!is.numeric(noise_sd) || noise_sd < 0) {
    cli::cli_abort(c(
      "{.arg noise_sd} must be a non-negative number.",
      "x" = "You supplied {.val {noise_sd}}"
    ))
  }

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Initialize empty landscape
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Base sine wave, used for both treeline and bands
  base_sine <- amplitude * sin(frequency * seq_len(width_actual))

  # Determine the treeline
  base_treeline <- round(height_actual * boundary_position + base_sine)
  base_treeline <- pmin(pmax(base_treeline, 1), height_actual)

  # Draw treeline: fill all cells above the treeline with trees (1)
  for (x in seq_len(width_actual)) {
    y <- base_treeline[x]
    mat[seq_len(y), x] <- 1
  }

  # Calculate available space for bands below the treeline
  band_zone <- round(height_actual * band_zone_prop)
  available_space <- height_actual - max(base_treeline)

  # Constrain band zone to available space
  band_zone <- min(band_zone, available_space)

  # Calculate number of bands that can fit
  num_bands <- floor(band_zone / band_spacing)

  # Warn if no bands can be drawn because the spacing is too large
  if (num_bands == 0) {
    cli::cli_warn(c(
      "No bands can fit in available space.",
      "i" = "Available space below treeline: {available_space} px",
      "i" = "Band spacing required: {band_spacing} px",
      "i" = "Consider decreasing {.arg band_spacing}, {.arg boundary_position}, or increasing {.arg band_zone_prop}."
    ))
  }

  band_offsets <- seq(band_spacing, by = band_spacing, length.out = num_bands)

  for (offset in band_offsets) {
    # Generate new noise just for this band
    band_noise <- stats::rnorm(width_actual, mean = 0, sd = noise_sd)

    for (x in seq_len(width_actual)) {
      y_center <- base_treeline[x] + offset + band_noise[x]

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

  # Create and return landscape object
  landscape(
    data = mat,
    pattern = "bands",
    params = list(
      width = width,
      height = height,
      boundary_position = boundary_position,
      band_zone_prop = band_zone_prop,
      band_thickness = band_thickness,
      band_spacing = band_spacing,
      frequency = frequency,
      amplitude = amplitude,
      noise_sd = noise_sd,
      rotation = rotation
    )
  )
}
