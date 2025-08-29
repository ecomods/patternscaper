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
#' @param noise Boolean. Are random effects included (noise)
#' @param noise_sd Numeric. If random effects, which standard deviation
#' @param rotation Numeric. Degrees of rotation to apply (counterclockwise). Default is 0 (no rotation).
#'
#' @return A matrix representing the landscape with banded vegetation, where 1 indicates vegetation and 0 indicates bare soil.
#' @export
create_banded_vegetation <- function(
  width = 100,
  height = 100,
  hilltop = c(30, 20, 25),
  slope = c(0.2, 0.1, 0.3),
  nbands = 7,
  x_ext_hill = c(1.7, 2, 1.3),
  y_ext_hill = c(1.2, 1, 1.6),
  noise = TRUE,
  noise_sd = 0.1,
  rotation = 0
) {
  #Calculate position of the hills
  xpos_hill <- c(floor(width * 0.2), floor(width * 0.9), floor(width * 0.1))
  ypos_hill <- c(floor(height * 0.7), floor(height * 0.3), floor(height * 0.2))

  #Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)
  xpos_hill_actual <- NA
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
      if (noise) {
        elevation[x, y] <- elevation[x, y] + rnorm(1, mean = 0, sd = noise_sd)
      }
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

  #plot_landscape(landscape)

  # Apply rotation if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }

  plot_landscape(landscape)

  return(landscape)
}
