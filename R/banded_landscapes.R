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
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
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
  seed = NULL,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
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
    band_noise <- if (noise) {
      stats::rnorm(width_actual, mean = 0, sd = noise_sd)
    } else {
      rep(0, width_actual)
    }

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
        noise = noise,
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

#' Create a Landscape with banded vegetation along a hill line ("tiger striped vegetation")
#'
#' Generates a landscape with banded vegetation of plants and bare soil.
#' the strips are perpendicular to the slope of the hill.
#' The landscape can optionally be rotated.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param hilltop List of Numerics/Integers. Elevation of hilltop.
#' @param slope List of Numerics. Slopes of each hill.
#' @param nbands Integer. Number of bands at the hill, one band is vegetated plus bare stripe.
#' @param x_ext_hill  List of Numerics. Extention/distortion of a hill into x-direction
#' @param y_ext_hill  List of Numerics. Extention/distortion of a hill into y-direction
#' @param noise_sd Numeric. If random effects, which standard deviation
#' @param rotation Numeric. Degrees of rotation to apply (counterclockwise). Default is 0 (no rotation).
#' @param seed Integer. Random seed for reproducibility (default: NULL).
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return A matrix representing the landscape with banded vegetation, where 1 indicates vegetation and 0 indicates bare soil.
#' @export
create_landscape_banded <- function(
  width = 100,
  height = 100,
  hilltop = c(30, 20, 25),
  slope = c(0.2, 0.1, 0.3),
  nbands = 7,
  x_ext_hill = c(1.7, 2, 1.3),
  y_ext_hill = c(1.2, 1, 1.6),
  noise_sd = 0.1,
  rotation = 0,
  seed = NULL,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }
  #Calculate position of the hills
  xpos_hill <- c(floor(width * 0.2), floor(width * 0.9), floor(width * 0.1))
  ypos_hill <- c(floor(height * 0.7), floor(height * 0.3), floor(height * 0.2))

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Calculate position of hills based on rotation
  if (rotation == 0) {
    xpos_hill_actual <- xpos_hill
    ypos_hill_actual <- ypos_hill
  } else {
    xpos_hill_actual <- floor(xpos_hill * 1.5)
    ypos_hill_actual <- floor(ypos_hill * 1.5)
  }

  #Create hills and their elevation
  nhill <- length(hilltop)
  hill_distance_elevation <- array(
    data = NA,
    dim = c(width_actual, height_actual, nhill)
  )
  elevation <- matrix(data = NA, nrow = width_actual, ncol = height_actual)
  for (x in 1:width_actual) {
    for (y in 1:height_actual) {
      for (h in 1:nhill) {
        hill_distance_elevation[x, y, h] <- hilltop[h] -
          slope[h] *
            sqrt(
              ((x - xpos_hill_actual[h]) / x_ext_hill[h])^2 +
                ((y - ypos_hill_actual[h]) / y_ext_hill[h])^2
            )
      }
      elevation[x, y] <- max(hill_distance_elevation[x, y, ])
      # add noise
      elevation[x, y] <- elevation[x, y] + rnorm(1, mean = 0, sd = noise_sd)
    }
  }
  #Assign vegetation according to elevation
  min_elevation <- min(elevation)
  max_elevation <- max(elevation)
  band_change_elevation <- (max_elevation - min_elevation) / (nbands * 2)
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)
  for (b in seq(1, 2 * nbands - 1, by = 2)) {
    landscape[
      (elevation >= ((min_elevation + (b - 1) * band_change_elevation))) &
        (elevation < (min_elevation + b * band_change_elevation))
    ] <- 1
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
      type = "spots",
      params = list(
        width = width,
        height = height,
        hilltop = hilltop,
        slope = slope,
        nbands = nbands,
        x_ext_hill = x_ext_hill,
        y_ext_hill = y_ext_hill,
        noise = noise,
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
