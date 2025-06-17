#' Create a Landscape with Sine Wave Bands
#'
#' Generates a binary landscape with parallel sine-wave bands.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param band_thickness Integer. Thickness of each band in pixels (default: 3).
#' @param band_spacing Integer. Spacing between bands in pixels (default: 10).
#' @param frequency Numeric. Frequency of sine wave (default: 2*pi/100).
#' @param amplitude Numeric. Amplitude of sine wave in pixels (default: 5).
#' @param noise Logical. Whether to add random noise to bands (default: FALSE).
#' @param noise_sd Numeric. Standard deviation for random noise (default: 1).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer. Random seed for reproducibility (default: NULL).
#'
#' @return SpatRaster. Binary landscape with parallel sine-wave bands.
#' @export
create_landscape_sine_bands <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 2 * pi / 100,
  amplitude = 5,
  noise = FALSE,
  noise_sd = 1,
  rotation = 0,
  seed = NULL
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Initialize empty landscape
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Base sine wave, used for both treeline and bands
  base_sine <- amplitude * sin(frequency * (1:width_actual))

  # Treeline (smooth)
  base_treeline <- round(height_actual * treeline_position + base_sine)
  base_treeline <- pmin(pmax(base_treeline, 1), height_actual)

  # Draw treeline: trees above the treeline
  for (x in 1:width_actual) {
    y <- base_treeline[x]
    landscape[1:y, x] <- 1
  }

  # Create tree bands below treeline
  num_bands <- floor((height_actual - max(base_treeline)) / band_spacing)
  band_offsets <- seq(band_spacing, by = band_spacing, length.out = num_bands)

  for (offset in band_offsets) {
    # Generate new noise just for this band
    band_noise <- if (noise)
      stats::rnorm(width_actual, mean = 0, sd = noise_sd) else
      rep(0, width_actual)

    for (x in 1:width_actual) {
      y_center <- base_treeline[x] + offset + band_noise[x]

      y_min <- max(1, floor(y_center - floor(band_thickness / 2)))
      y_max <- min(
        height_actual,
        ceiling(y_center + ceiling(band_thickness / 2))
      )

      if (y_min <= y_max) {
        landscape[y_min:y_max, x] <- 1
      }
    }
  }

  # Apply rotation if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }

  return(landscape)
}
