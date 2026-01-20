#' Create a Landscape with Labyrinths as in Turing patterns
#'
#' Generates a landscape with banded and spotted vegetation (labyrinth),
#' this mimics Turing patterns.
#' @param width Integer. Number of columns in the landscape (default: 100).
#' @param height Integer. Number of rows in the landscape (default: 100).
#' @param frequency Numeric. Controls the spatial scale of the noise pattern:
#'    Lower values produce broad, smooth bands, higher values produce finer, maze-like structures (default: 3).
#' @param veg_threshold Numeric between 0 and 1. Defines the cutoff value that separates vegetated
#'    from non-vegetated cells. Values above the threshold become vegetation.
#'    Adjusting this changes the overall proportion of vegetated area (default: 0.5).
#' @param band_fuzziness Numeric between 0 and 0.5. Controls the amount of
#'    geometric edge roughness applied *after* thresholding. At 0, vegetation 
#'    boundaries are sharp and fully deterministic. Small values (≈ 0.05–0.1) 
#'    introduce slight, irregular boundary perturbations without changing the 
#'    overall topology of the pattern. Larger values progressively erode vegetation 
#'    edges and can fragmet bands if set too high. This parameter affects boundary 
#'    geometry only and does not influence the global structure or connectivity 
#'    of the labyrinth. (default: 0.08)
#' @param octaves Integer >= 1. Number of noise layers (octaves) combined to
#'    generate the underlying continuous field. A single octave produces very smooth, 
#'    large-scale bands. Using two to three octaves adds limited fine structure while preserving
#'    a dominant wavelength, which is characteristic of labyrinth (Turing-like)
#'    patterns. Higher values introduce fractal detail at smaller scales and can obscure
#'    the banded structure, making patterns less clearly classifiable as
#'    labyrinths. (default: 2).
#'
#' @return A landscape object with pattern "labyrinth" containing the generated landscape data and parameters.
#'
#' @details
#' The labyrinth pattern is generated using fractal Brownian motion (fBm):
#'
#' 1. **Noise generation**: Creates a continuous noise field using multiple
#'    octaves of Perlin noise with `fbm_perlin()`.
#'
#' 2. **Normalization**: Scales noise values to [0, 1] range.
#'
#' 3. **Thresholding**: Applies `veg_threshold` to create binary pattern.
#'    Cells with noise > threshold become vegetation.
#'
#' 4. **Fuzzy boundaries**: Adds probabilistic transitions within
#'    `band_fuzziness` distance of the threshold for natural-looking edges.
#'
#'
#' The combination of `frequency` and `octaves` controls pattern complexity,
#' while `veg_threshold` determines vegetation proportion.
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
#' # Adjust vegetation coverage
#' labyrinth_sparse <- create_landscape_labyrinth(
#'   veg_threshold = 0.6  # Less vegetation
#' )
#'
#' labyrinth_dense <- create_landscape_labyrinth(
#'   veg_threshold = 0.3  # More vegetation
#' )
#'
#' @keywords internal
#' @importFrom ambient long_grid gen_perlin
create_landscape_labyrinth <- function(
  width = 100,
  height = 100,
  frequency = 3,
  veg_threshold = 0.5,
  band_fuzziness = 0.08,
  octaves = 2
) {
  # Validate common parameters
  validate_dimensions(width = width, height = height)

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
  if (
    !is.numeric(band_fuzziness) || band_fuzziness < 0 || band_fuzziness > 0.5
  ) {
    cli::cli_abort(c(
      "{.arg band_fuzziness} must be between 0 and 0.5.",
      "x" = "You supplied {.val {band_fuzziness}}",
      "i" = "Values above 0.3 produce increasingly random-looking patterns."
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

  # Controlled edge roughness only
  if (band_fuzziness > 0) {
    edge <- mat & stats::filter(
      !mat,
      matrix(1, 3, 3),
      circular = TRUE
    ) > 0

    jitter <- runif(sum(edge)) < band_fuzziness
    mat[which(edge)[jitter]] <- FALSE
  }

  # Create and return landscape object
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
