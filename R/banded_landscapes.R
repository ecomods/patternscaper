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
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
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
  seed = 42,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # If seed is NULL, use random seed; otherwise use the provided seed
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)

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
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return A matrix representing the landscape with banded vegetation, where 1 indicates vegetation and 0 indicates bare soil.
#'
#' @examples
#' # Default banded vegetation
#' banded_default <- create_landscape_banded()
#'
#' # Modified banded vegetation with more bands and different hill parameters
#' banded_modified <- create_landscape_banded(
#'   nbands = 9,
#'   hilltop = c(35, 25, 30),
#'   slope = c(0.3, 0.15, 0.25),
#'   x_ext_hill = c(1.5, 2.2, 1.8),
#'   y_ext_hill = c(1.3, 1.1, 1.9),
#'   noise_sd = 0.5
#' )
#'
#' # With rotation
#' banded_rotated <- create_landscape_banded(
#'   nbands = 7,
#'   hilltop = c(30, 22, 28),
#'   slope = c(0.25, 0.12, 0.2),
#'   x_ext_hill = c(1.4, 2.0, 1.6),
#'   y_ext_hill = c(1.2, 1.0, 1.7),
#'   noise_sd = 0.15,
#'   rotation = 45
#' )
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
  seed = 42,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {

  # If seed is NULL, use random seed; otherwise use the provided seed
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)
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
      elevation[x, y] <- max(hill_distance_elevation[x, y, ],na.rm=T)
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


#' Create a Landscape with Labyrinths as in Turing patterns
#'
#' Generates a landscape with banded and spotted vegetation (labyrinth),
#' this mimics Touring patterns
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param frequency Numeric. Controls the spatial scale of the noise pattern:
#'    Lower values produce broad, smooth bands, higher values produce finer, maze-like structures.
#'    (default: 5)
#' @param veg_threshold Numeric between 0 and 1. Defines the cutoff value that separates vegetated
#'    from non-vegetated cells. Values above the threshold become vegetation.
#'    Adjusting this changes the overall proportion of vegetated area (default: 0.5)
#' @param band_fuzziness Numeric and << 1. Controls how sharp or soft the vegetation boundary
#'    is around the threshold. At 0, boundaries are sharp, larger values introduce
#'    randomness at the edges, making the pattern more natural and irregular.
#'    (default: 0.1)
#' @param octaves Integer >= 1 The number of layers of noise combined to
#'    generate the pattern. A single octave gives smooth, simple structures.
#'    More octaves add detail and complexity, similar to fractal patterns.(default: 1)
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return A matrix representing the landscape with banded vegetation, where 1 indicates vegetation and 0 indicates bare soil.
#'
#' @examples
create_landscape_labyrinth <- function(
    width = 100,
    height = 100,
    frequency = 5,
    veg_threshold = 0.5,
    band_fuzziness = 0.1,
    octaves = 1,
    seed = 42,
    as_raster = TRUE,
    crs = NULL,
    add_metadata = TRUE
) {

  # make coordinates (required by gen_perlin())
  grid <- long_grid(
    x = seq(0, 1, length.out = width),
    y = seq(0, 1, length.out = height)
  )
  # Initialize empty landscape
  landscape <- matrix(0, nrow = height, ncol = width)

  # calculate Perlin Noise
  grid$noise <- gen_perlin(
    x = grid$x,
    y = grid$y,
    frequency = freq,
    octaves = octaves,
    seed = seed
  )

  #normalize to 0-1
  n <- (grid$noise - min(grid$noise)) / (max(grid$noise) - min(grid$noise))

  # first: strong threshold
  landscape_vec <- ifelse(n > veg_threshold, 1, 0)
  # then fuzziness around boundary
  fuzzy_band <- abs(n - veg_threshold) < band_fuzziness
  prob <- (n - (veg_threshold - band_fuzziness)) / (2 * band_fuzziness)
  prob <- pmin(pmax(prob, 0), 1)
  # randomness only in fuzzy boundary
  landscape_vec[fuzzy_band] <- rbinom(sum(fuzzy_band), 1, prob[fuzzy_band])

  # convert to matrix
  landscape <- matrix(landscape_vec, nrow = height, ncol = width, byrow = TRUE)

  # Get the result either as matrix or SpatRaster
  result <- if (as_raster) {
    matrix_to_raster(landscape, crs = crs)
  } else {
    landscape
  }

  return(result)

}

