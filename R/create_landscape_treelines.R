#' Create a sharp treeline landscape matrix
#'
#' Generates a binary matrix representing a landscape with a sharp treeline.
#' The treeline can be positioned and rotated as specified.
#'
#' @param width Integer. Width of the landscape (default: 100).
#' @param height Integer. Height of the landscape (default: 100).
#' @param treeline_position Numeric. Proportion (0-1) for treeline position
#'   (default: 0.5).
#' @param rotation Numeric. Rotation angle in degrees (default: 0).
#'
#' @return A matrix with values 0 (non-mangrove) and 1 (mangrove).
create_sharp_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  rotation = 0
) {
  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Convert position from proportion to row number
  treeline_row <- round(height_actual * treeline_position)

  # Create the landscape matrix
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill in mangrove area (1) based on treeline position
  landscape[1:treeline_row, ] <- 1

  # Rotate the landscape, crop and fill NAs if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }
  return(landscape)
}

#' Create a Diffuse Treeline Landscape
#'
#' Generates a landscape with a gradual transition from 100% mangrove (tree) cover at the top
#' to full saltmarsh (no trees) at the bottom. The transition is controlled by a steepness parameter,
#' where higher values result in a more abrupt decline in tree cover.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param steepness Numeric. Controls the rate of decline in tree cover. A value of 1 provides a linear decline,
#' higher values result in a more abrupt drop.
#' @param rotation Numeric. Degrees to rotate the landscape (default is 0).
#'
#' @return A matrix representing the diffuse treeline landscape, where 1 indicates mangrove (tree) and 0 indicates saltmarsh.
#' @export
create_diffuse_treeline <- function(
  width = 100,
  height = 100,
  steepness = 1,
  rotation = 0
) {
  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Create empty landscape
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)

  # Fill with tree cover probability that decreases from 1 to 0 with increasing row index
  for (i in 1:height_actual) {
    # Normalize row index [0,1] starting at 0
    normalized_row <- (i - 1) / (height_actual - 1)
    # Calculate probability for tree cover (starts 1 and decreases to 0)
    prob <- 1 - normalized_row^steepness
    for (j in 1:width_actual) {
      if (stats::runif(1) < prob) {
        landscape[i, j] <- 1
      }
    }
  }

  # Rotate the landscape, crop and fill NAs if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }

  return(landscape)
}

#' Create a curvy treeline landscape matrix
#'
#' Generates a binary matrix representing a landscape with a curvy treeline,
#' where the treeline is defined by a sine wave. The landscape can be rotated.
#'
#' @param width Integer. Width of the landscape (number of columns).
#' @param height Integer. Height of the landscape (number of rows).
#' @param treeline_position Numeric. Proportion (0-1) for treeline vertical position.
#' @param sine_length Numeric. Length of the sine wave (affects wave frequency).
#' @param sine_height Numeric. Height of the sine wave (affects amplitude).
#' @param rotation Numeric. Degrees to rotate the landscape (default is 0).
#'
#' @return A matrix with values 0 (non-mangrove) and 1 (mangrove).
create_curvy_treeline <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  sine_length = 20,
  sine_height = 5,
  rotation = 0
) {
  # calculate width and height of the actual landscape to produce
  # in case of rotation, the landscape needs to be larger
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Convert position from proportion to row number
  treeline_row <- round(height_actual * treeline_position)

  # Create the landscape matrix
  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)
  # Fill in mangrove area (1) based on sine wave around treeline position
  #sine_height determines how many cells around tree_line are affected
  #sine_length dtermines the lenght of the wave
  for (i in 1:height_actual) {
    for (j in 1:width_actual) {
      landscape[i, j] <- ifelse(
        i > (treeline_row + sin(2 * pi * j / sine_length) * sine_height),
        1,
        0
      )
    }
  }

  # Rotate the landscape, crop and fill NAs if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }

  return(landscape)
}
