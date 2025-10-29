#' Create a Landscape with Sharp Treeline
#'
#' Generates a binary landscape with a sharp treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param random_spots List of Numerics. Probability or random spots of vegetation in the other vegetation type (default: c(0,0))
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "sharp" containing the generated landscape data and parameters.
#'
#' @keywords internal
#'
#' @examples
#' # Default sharp treeline
#' sharp_default <- create_landscape_sharp_treeline()
#'
#' # Modified sharp treeline with higher treeline position
#' sharp_modified <- create_landscape_sharp_treeline(
#'   treeline_position = 0.7
#' )
#'
#' # Landscape with rotation and some spots
#' sharp_rotated <- create_landscape_sharp_treeline(
#'   treeline_position = 0.3,
#'   random_spots = c(0,0.1),
#'   rotation = 45
#' )
create_landscape_sharp_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  random_spots = c(0,0),
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
    pattern = "sharp",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      rotation = rotation
    )
  )
}
