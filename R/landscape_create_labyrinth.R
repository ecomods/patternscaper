#' Create a Landscape with Labyrinths as in Turing patterns
#'
#' Generates a landscape with banded and spotted vegetation (labyrinth),
#' this mimics Turing patterns.
#'
#' @param width Integer. Number of columns in the landscape (default: 100).
#' @param height Integer. Number of rows in the landscape (default: 100).
#' @param rotation Numeric. Number between 0 and 360 giving the degree of landscape rotation (default: 0).
#' @param frequency Numeric. Controls the spatial scale of the noise pattern:
#'    Lower values produce broad, smooth bands, higher values produce finer, maze-like structures (default: 5).
#' @param veg_threshold Numeric between 0 and 1. Defines the cutoff value that separates vegetated
#'    from non-vegetated cells. Values above the threshold become vegetation.
#'    Adjusting this changes the overall proportion of vegetated area (default: 0.5).
#' @param band_fuzziness Numeric and << 1. Controls how sharp or soft the vegetation boundary
#'    is around the threshold. At 0, boundaries are sharp, larger values introduce
#'    randomness at the edges, making the pattern more natural and irregular (default: 0.1).
#' @param octaves Integer >= 1. The number of layers of noise combined to
#'    generate the pattern. A single octave gives smooth, simple structures.
#'    More octaves add detail and complexity, similar to fractal patterns (default: 1).
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'   If NULL, no seed is set explicitly.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#'
#' @return A landscape object with pattern "labyrinth" containing the generated landscape data and parameters.
#'
#' @examples
#' # Default labyrinth pattern
#' labyrinth_default <- create_landscape_labyrinth()
#'
#' # Modified labyrinth with higher frequency and multiple octaves
#' labyrinth_modified <- create_landscape_labyrinth(
#'   frequency = 8,
#'   octaves = 3,
#'   band_fuzziness = 0.05
#' )
#'
#' # With rotation
#' labyrinth_rotated <- create_landscape_labyrinth(
#'   frequency = 5,
#'   veg_threshold = 0.6,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_labyrinth <- function(
  width = 100,
  height = 100,
  rotation = 0,
  frequency = 5,
  veg_threshold = 0.5,
  band_fuzziness = 0.1,
  octaves = 1,
  seed = NULL
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Make coordinates (required by gen_perlin())
  grid <- ambient::long_grid(
    x = seq(0, 1, length.out = width_actual),
    y = seq(0, 1, length.out = height_actual)
  )

  # Calculate Perlin Noise
  grid$noise <- ambient::gen_perlin(
    x = grid$x,
    y = grid$y,
    frequency = frequency,
    octaves = octaves,
    seed = seed
  )

  # Normalize to 0-1
  n <- (grid$noise - min(grid$noise)) / (max(grid$noise) - min(grid$noise))

  # First: strong threshold
  landscape_vec <- ifelse(n > veg_threshold, 1, 0)

  # Then fuzziness around boundary
  fuzzy_band <- abs(n - veg_threshold) < band_fuzziness
  prob <- (n - (veg_threshold - band_fuzziness)) / (2 * band_fuzziness)
  prob <- pmin(pmax(prob, 0), 1)

  # Randomness only in fuzzy boundary
  landscape_vec[fuzzy_band] <- rbinom(sum(fuzzy_band), 1, prob[fuzzy_band])

  # Convert to matrix
  mat <- matrix(
    landscape_vec,
    nrow = height_actual,
    ncol = width_actual,
    byrow = TRUE
  )

  # Apply rotation if specified
  if (rotation != 0) {
    mat <- rotate_and_crop_landscape(
      mat,
      rotation,
      width,
      height
    )
  }

  # Create and return landscape object
  landscape(
    data = mat,
    pattern = "labyrinth",
    params = list(
      width = width,
      height = height,
      rotation = rotation,
      frequency = frequency,
      veg_threshold = veg_threshold,
      band_fuzziness = band_fuzziness,
      octaves = octaves,
      seed = seed
    )
  )
}
