#' Create a Landscape with Curvy Fingers Treeline
#'
#' Generates a binary landscape with a curvy finger treeline following a sine wave pattern
#' with random lenght of each sine wave and random height
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param sine_length_mean Numeric. Mean wavelength of sinusoidal curve in pixels (default: 20).
#' @param sine_length_sd Numeric. Standard deviation of wavelength of sinusoidal curve in pixels (default: 20).
#' @param sine_height_mean Numeric. Mean amplitude of sinusoidal curve in pixels (default: 5).
#' @param sine_height_sd Numeric. Standard deviation of  amplitude of sinusoidal curve in pixels (default: 5).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "curvy" containing the generated landscape data and parameters.
#'
#' @keywords internal
#'
#' @examples
#' # Default curvy treeline
#' curvy_default <- create_landscape_curvy_treeline()
#'
#' # Modified curvy treeline with increased sine parameters
#' curvy_modified <- create_landscape_curvy_treeline(
#'   treeline_position = 0.3,
#'   sine_length_mean = 40,
#'   sine_length_sd = 0,
#'   sine_height_mean = 10,
#'   sine_height_sd = 0
#' )
#'
#' # With rotation and random waves
#' curvy_rotated <- create_landscape_curvy_treeline(
#'   treeline_position = 0.6,
#'   sine_length_mean = 10,
#'   sine_length_sd = 6,
#'   sine_height_mean = 6,
#'   sine_height_sd = 4,
#'   rotation = 45
#' )
#'
create_landscape_curvyfingers <- function(
    width = 100,
    height = 100,
    treeline_position = 0.5,#
    random_spots = c(0,0),
    sine_length_mean = 20,
    sine_length_sd = 12,
    sine_height_mean = 5,
    sine_height_sd = 4,
    rotation = 0
) {

  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Convert position from proportion to row number
  treeline_row <- round(height_actual * treeline_position)

  # Create the landscape matrix
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill in other vegetation area (1) based on treeline position
  if (treeline_row > 0) {
    mat[1:treeline_row, ] <- 1
  }

  set.seed(1)  #to make it reproducible - maybe delete

  # slightly shifting curves
  x_seq <- 1:width_actual

  # random trends
  noise_smooth <- function(x, mean_val, sd_val, smooth_span = 0.1) {
    raw <- rnorm(length(x), mean_val, sd_val)
    smooth <- stats::loess(raw ~ x, span = smooth_span)$fitted
    smooth[smooth < 0.1] <- 0.1
    return(smooth)
  }

  sine_length_vec <- noise_smooth(x_seq, sine_length_mean, sine_length_sd)
  sine_height_vec <- noise_smooth(x_seq, sine_height_mean, sine_height_sd)

  #produce sine wave
  phase <- 0
  for (j in x_seq) {
    current_length <- sine_length_vec[j]
    current_height <- sine_height_vec[j]

    # make more smooth
    phase <- phase + (2 * pi / current_length)
    y_sine <- treeline_row + sin(phase) * current_height

    for (i in 1:height_actual) {
      mat[i, j] <- ifelse(i > y_sine, 0, 1)
    }
  }

  # --- Add random spots if requested ---
  if (!is.null(random_spots) && length(random_spots) == 2 &&
      any(random_spots > 0)) {
    # Indices for each type
    idx_1 <- which(mat == 1)
    idx_0 <- which(mat == 0)

    # Flip some cells based on probabilities
    flip_to_0 <- idx_1[rbinom(length(idx_1), 1, random_spots[1]) == 1]
    flip_to_1 <- idx_0[rbinom(length(idx_0), 1, random_spots[2]) == 1]

    mat[flip_to_0] <- 0
    mat[flip_to_1] <- 1
  }


  # Rotate the landscape, crop and fill NAs if specified
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
    pattern = "curvyfingers",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      sine_length_mean = sine_length_mean,
      sine_length_sd= sine_length_sd,
      sine_height_mean = sine_height_mean,
      sine_height_sd = sine_height_sd,
      rotation = rotation
    )
  )
}
