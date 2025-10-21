#' Create a Landscape with Sine Wave Bands
#'
#' Generates a binary landscape with parallel sine-wave bands.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param band_zone_prop Numeric. Proportion of height of the total landscape to
#'     allocate for bands below the treeline (default: 0.2). If the band zone is too small
#'     for the given band spacing, no bands will be drawn and a warning will be issued.
#' @param band_thickness Integer. Thickness of each band in pixels (default: 3).
#' @param band_spacing Integer. Spacing between bands in pixels (default: 10).
#' @param frequency Numeric. Frequency of sine wave (default: 2*pi/100).
#' @param amplitude Numeric. Amplitude of sine wave in pixels (default: 5).
#' @param noise_sd Numeric. Standard deviation for random noise (default: 0).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#'   If NULL, no seed is set explicitly.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default sine bands
#' sine_bands_default <- create_landscape_sine_bands()
#'
#' # Modified sine bands with thicker bands, wider spacing and noise
#' sine_bands_modified <- create_landscape_sine_bands(
#'   treeline_position = 0.3,
#'   band_zone_prop = 0.5,
#'   band_thickness = 5,
#'   band_spacing = 15,
#'   frequency = 1,
#'   amplitude = 8,
#'   noise_sd = 1.5
#' )
#'
#' # With rotation
#' sine_bands_rotated <- create_landscape_sine_bands(
#'   band_thickness = 4,
#'   band_spacing = 12,
#'   amplitude = 6,
#'   noise_sd = 2,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_sine_bands <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  band_zone_prop = 0.2,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 2 * pi / 100,
  amplitude = 5,
  noise_sd = 0,
  rotation = 0,
  seed = NULL,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # If seed is NULL, use random seed; otherwise use the provided seed
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

  # Create tree bands below treeline in the band zone
  band_zone <- round(height_actual * band_zone_prop)
  # check if the band zone is large enough for the given band spacing,
  # otherwise warn the user and set band_zone to 0
  if (band_zone > height_actual - max(base_treeline)) {
    print(paste("band zone:", band_zone))
    print(paste("Available space:", height_actual - max(base_treeline)))
    print(paste("Max base treeline:", max(base_treeline)))
    warning("Band zone too small for the given band spacing. No bands drawn.")
    band_zone <- 0
  }

  num_bands <- floor(band_zone / band_spacing)
  band_offsets <- seq(band_spacing, by = band_spacing, length.out = num_bands)

  for (offset in band_offsets) {
    # Generate new noise just for this band
    band_noise <- stats::rnorm(width_actual, mean = 0, sd = noise_sd)

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

  # Get the result either as matrix or SpatRaster
  result <- if (as_raster) {
    matrix_to_raster(landscape, crs = crs)
  } else {
    landscape
  }

  # Return with metadata if requested
  if (add_metadata) {
    return(list(
      landscape = result,
      type = "sine_bands",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        band_thickness = band_thickness,
        band_spacing = band_spacing,
        frequency = frequency,
        amplitude = amplitude,
        noise_sd = noise_sd,
        rotation = rotation,
        seed = seed,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
