#' Create a Landscape with Labyrinths as in Turing patterns
#'
#' Generates a landscape with banded and spotted vegetation (labyrinth),
#' this mimics Touring patterns
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param rotation Numreric. Number between 0 and 360 giving the degree of landscape rotation
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
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'   If NULL, no seed is set explicitly.
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
  rotation = 0,
  frequency = 5,
  veg_threshold = 0.5,
  band_fuzziness = 0.1,
  octaves = 1,
  seed = NULL,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # make coordinates (required by gen_perlin())
  grid <- ambient::long_grid(
    x = seq(0, 1, length.out = width),
    y = seq(0, 1, length.out = height)
  )
  # Initialize empty landscape
  landscape <- matrix(0, nrow = height, ncol = width)

  # calculate Perlin Noise
  grid$noise <- ambient::gen_perlin(
    x = grid$x,
    y = grid$y,
    frequency = frequency,
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
