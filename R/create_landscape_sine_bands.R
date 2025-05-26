#' Create a Landscape with sine bands parallel to the main treeline
#'
#' Generates a landscape with a transition from 100% mangrove (tree) cover at the top
#' to saltmarsh (no trees) at the bottom. The saltmarsh is interrupted by mangrove strips,
#' that run parallel to the treeline. The landscape can optionally be rotated.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param treeline_position Numeric. position of the treeline relative to the height
#' @param band_thickness Integer. Thickness of mangrove bands in saltmarsh
#' @param band_spacing Integer. Space (thickness) of saltmarsh stripes between mangrove stripes
#' @param frequency Numeric. wave length of sine wave - for 100x100 a value of 0.01-0.5 is recommended
#' @param amplitude Integer. Amplitude of wave (max - mean)
#' @param noise Boolean. Are random effects included (noise)
#' @param noise_sd Numeric. If random effects, which standard deviation
#' @param rotation Numeric. Degrees of rotation to apply (counterclockwise). Default is 0 (no rotation).
#'
#' @return A matrix representing the sine bands landscape, where 1 indicates mangrove (tree) and 0 indicates saltmarsh.
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
  rotation = 0
) {
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
