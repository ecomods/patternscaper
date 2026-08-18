#' Create a Landscape with Labyrinths
#'
#' Generates a landscape with a labyrinth-like vegetation pattern,
#'  this mimics Turing patterns.
#' Parameters are documented on \code{\link{pattern_labyrinth}}.
#'
#' @return A landscape object with pattern "labyrinth".
#'
#' @noRd
#' @importFrom ambient long_grid gen_perlin
create_landscape_labyrinth <- function(
  width = 100,
  height = 100,
  frequency = 3,
  veg_threshold = 0.5,
  band_fuzziness = 0.08,
  octaves = 2
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)

  # Validate pattern parameters
  if (!is.numeric(frequency) || frequency <= 0) {
    cli::cli_abort(c(
      "{.arg frequency} must be a positive number.",
      "x" = "You supplied {.val {frequency}}"
    ))
  }

  if (!is.numeric(veg_threshold) || veg_threshold < 0 || veg_threshold > 1) {
    cli::cli_abort(c(
      "{.arg veg_threshold} must be between 0 and 1.",
      "x" = "You supplied {.val {veg_threshold}}"
    ))
  }

  if (!is.numeric(band_fuzziness) || band_fuzziness < 0 || band_fuzziness > 1) {
    cli::cli_abort(c(
      "{.arg band_fuzziness} must be between 0 and 1.",
      "x" = "You supplied {.val {band_fuzziness}}",
      "i" = "Values above 0.3 produce increasingly random-looking patterns."
    ))
  }

  # Validate before truncating fractional octave counts
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

  octaves <- as.integer(octaves)

  # Create coordinate grid for noise generation
  # Perlin noise requires x,y coordinates for each pixel
  aspect_ratio <- width / height
  grid <- ambient::long_grid(
    x = seq(0, aspect_ratio, length.out = width),
    y = seq(0, 1, length.out = height)
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

  # Apply hard threshold to create base binary pattern
  # Cells above veg_threshold become vegetation (1), below become bare ground (0)
  mat <- matrix(
    noise_normalized > veg_threshold,
    nrow = height,
    byrow = TRUE
  )

  # Erode vegetation edge cells with the requested probability
  if (band_fuzziness > 0) {
    edge <- mat &
      stats::filter(
        !mat,
        matrix(1, 3, 3),
        circular = TRUE
      ) >
        0

    jitter <- runif(sum(edge)) < band_fuzziness
    mat[which(edge)[jitter]] <- FALSE
  }

  # Store the raster and its generation metadata
  landscape(
    data = mat * 1L,
    pattern = "labyrinth",
    params = list(
      width = width,
      height = height,
      frequency = frequency,
      veg_threshold = veg_threshold,
      band_fuzziness = band_fuzziness,
      octaves = octaves
    )
  )
}

#' Generate Fractal Perlin Noise
#'
#' Generates a fractal Brownian motion (fBm) noise value by combining multiple
#' layers (octaves) of Perlin noise at increasing frequencies and decreasing
#' amplitudes. Used internally for generating labyrinth structures.
#'
#' @param x Numeric vector of x coordinates.
#' @param y Numeric vector of y coordinates.
#' @param frequency Numeric. Frequency of the first octave.
#' @param octaves Integer. Number of noise layers (default: 6).
#' @param lacunarity Numeric. Frequency multiplier per octave (default: 2).
#' @param gain Numeric. Amplitude multiplier per octave (default: 0.5).
#'
#' @return Numeric vector of combined noise values.
#' @keywords internal
#' @noRd
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

  # Accumulate successively finer, lower-amplitude octaves
  for (i in seq_len(octaves)) {
    total_noise <- total_noise +
      amplitude *
        ambient::gen_perlin(
          x = x * current_frequency,
          y = y * current_frequency
        )

    # Increase frequency and reduce amplitude for the next octave
    current_frequency <- current_frequency * lacunarity
    amplitude <- amplitude * gain
  }

  total_noise
}
