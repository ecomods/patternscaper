#' Create a Landscape with Labyrinths as in Turing patterns
#'
#' Generates a landscape with banded and spotted vegetation (labyrinth),
#' this mimics Turing patterns.
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
#'    More octaves add detail and complexity, similar to fractal patterns (default: 6).
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
#' @keywords internal
#' @importFrom ambient long_grid gen_perlin
#' @importFrom stats rbinom
create_landscape_labyrinth <- function(
  width = 100,
  height = 100,
  rotation = 0,
  frequency = 5,
  veg_threshold = 0.5,
  band_fuzziness = 0.1,
  octaves = 6
) {
  # Validate common parameters
  validate_dimensions(width = width, height = height)
  validate_rotation(rotation = rotation)

  # Validate frequency
  if (!is.numeric(frequency) || frequency <= 0) {
    cli::cli_abort(c(
      "{.arg frequency} must be a positive number.",
      "x" = "You supplied {.val {frequency}}"
    ))
  }

  # Validate veg_threshold
  if (!is.numeric(veg_threshold) || veg_threshold < 0 || veg_threshold > 1) {
    cli::cli_abort(c(
      "{.arg veg_threshold} must be between 0 and 1.",
      "x" = "You supplied {.val {veg_threshold}}"
    ))
  }

  # Validate band_fuzziness
  if (!is.numeric(band_fuzziness) || band_fuzziness < 0) {
    cli::cli_abort(c(
      "{.arg band_fuzziness} must be a non-negative number.",
      "x" = "You supplied {.val {band_fuzziness}}"
    ))
  }

  # Validate octaves - must be a positive number
  if (
    !is.numeric(octaves) ||
      length(octaves) != 1 ||
      is.na(octaves) ||
      octaves < 1
  ) {
    cli::cli_abort(c(
      "{.arg octaves} must be a positive number.",
      "x" = "You supplied {.val {octaves}}"
    ))
  }

  # Convert to integer (truncates decimals like 2.7 -> 2)
  octaves <- as.integer(octaves)

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Create coordinate grid for noise generation
  # Perlin noise requires x,y coordinates for each pixel
  aspect_ratio <- width_actual / height_actual
  grid <- ambient::long_grid(
    x = seq(0, aspect_ratio, length.out = width_actual),
    y = seq(0, 1, length.out = height_actual)
  )

  # Generate fractal Brownian motion noise field
  # Combines multiple octaves of Perlin noise for natural-looking patterns
  grid$noise <- fbm_perlin(
    x = grid$x,
    y = grid$y,
    frequency = frequency,
    octaves = octaves
  )

  # Normalize noise values to 0-1 range
  # Makes threshold comparisons consistent regardless of noise amplitude
  noise_normalized <- (grid$noise - min(grid$noise)) /
    (max(grid$noise) - min(grid$noise))

  # Apply initial hard threshold using median
  # Creates base binary pattern before adding fuzzy boundaries
  landscape_vec <- ifelse(noise_normalized > veg_threshold, 1, 0)

  # Add probabilistic fuzziness around veg_threshold boundary
  # Identifies cells within the fuzzy transition zone
  in_fuzzy_zone <- abs(noise_normalized - veg_threshold) < band_fuzziness

  # Calculate probability of vegetation for cells in fuzzy zone
  # Linear transition from 0 to 1 across the fuzzy band width
  transition_prob <- (noise_normalized - (veg_threshold - band_fuzziness)) /
    (2 * band_fuzziness)
  transition_prob <- pmin(pmax(transition_prob, 0), 1) # Clamp to [0, 1]

  # Apply probabilistic assignment only in fuzzy boundary zone
  # Adds natural irregularity to vegetation edges
  landscape_vec[in_fuzzy_zone] <- stats::rbinom(
    n = sum(in_fuzzy_zone),
    size = 1,
    prob = transition_prob[in_fuzzy_zone]
  )

  # Convert vector back to matrix format
  mat <- matrix(
    landscape_vec,
    nrow = height_actual,
    ncol = width_actual,
    byrow = TRUE
  )

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
    pattern = "labyrinth",
    params = list(
      width = width,
      height = height,
      rotation = rotation,
      frequency = frequency,
      veg_threshold = veg_threshold,
      band_fuzziness = band_fuzziness,
      octaves = octaves
    )
  )
}

#' Calculates fractal Perlin noise value for coordinates x,y
#'
#' Generates a fractal Brownian motion (fBm) noise value by combining multiple
#' layers (octaves) of Perlin noise at increasing frequencies and decreasing
#' amplitudes. Used internally for generating labyrinth structures.
#'
#' @param x Numeric. x-coordinate at which to evaluate the noise.
#' @param y Numeric. y-coordinate at which to evaluate the noise.
#' @param frequency Numeric. Base frequency for the first octave of Perlin noise.
#' @param octaves Integer. Number of noise layers to combine. Default: 6.
#' @param lacunarity Numeric. Multiplier applied to the frequency at each octave. Default: 2.
#' @param gain Numeric. Multiplier applied to the amplitude at each octave. Default: 0.5.
#'
#' @return A combined noise value for coordinate x,y
#' @keywords internal
fbm_perlin <- function(
  x,
  y,
  frequency,
  octaves = 6,
  lacunarity = 2,
  gain = 0.5
) {
  total_noise <- 0
  amplitude <- 1
  current_frequency <- frequency

  # Sum contributions from each octave
  # Each octave adds detail at a finer scale with reduced amplitude
  for (i in seq_len(octaves)) {
    # Add this octave's Perlin noise, scaled by current amplitude
    total_noise <- total_noise +
      amplitude *
        ambient::gen_perlin(
          x = x * current_frequency,
          y = y * current_frequency
        )

    # Increase frequency and decrease amplitude for next octave
    # Creates self-similar fractal pattern across scales
    current_frequency <- current_frequency * lacunarity
    amplitude <- amplitude * gain
  }

  total_noise
}
