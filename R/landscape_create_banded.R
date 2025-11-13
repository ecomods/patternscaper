#' Create a Landscape with banded vegetation along a hill line ("tiger striped vegetation")
#'
#' Generates a landscape with banded vegetation of plants and bare soil.
#' the strips are perpendicular to the slope of the hill.
#' The landscape can optionally be rotated.
#'
#' @param width Integer. Number of columns in the landscape. Default is 100.
#' @param height Integer. Number of rows in the landscape. Default is 100.
#' @param nhills Integer. Number of hills in the landscape. Default is 2.
#' @param regular_hilltop Boolean. Regular or random position of the hilltops. Default is TRUE.
#' @param top_elevation_mean Numeric. Mean elevation of hilltops. Default is 30.
#' @param top_elevation_sd Numeric. Standard deviation of hilltop elevations. Default is 2.
#' @param slope_mean Numeric. Mean slope of hills 0.2 (per pixel). Default is 0.2.
#' @param slope_sd Numeric. Standard deviation of slope. Default is 0.05.
#' @param nbands Integer. Number of vegetation bands per hill. Default is 7.
#' @param x_ext_hill_sd Numeric. Standard deviation of extension of slope into x direction. Default is 0.4.
#' @param y_ext_hill_sd Numeric. Standard deviation of extension of slope into y direction. Default is 0.4.
#' @param noise_sd Numeric. Standard deviation for random elevation effects. Default is 0.1.
#' @param rotation Numeric. Degrees of rotation to apply (counterclockwise). Default is 0 (no rotation).
#'
#' @return A landscape object with pattern "bands" containing the generated landscape data and parameters.
#'
#' @examples
#' # Default banded vegetation
#' banded_default <- create_landscape_banded()
#'
#' # Modified banded vegetation with more bands and different hill parameters
#' banded_modified <- create_landscape_banded(
#'   nhills = 2,
#'   nbands = 5,
#'   slope_mean = 0.5,
#'   regular_hilltop = FALSE,
#'   noise_sd = 0.5
#' )
#'
#' # With rotation
#' banded_rotated <- create_landscape_banded(
#'   nhills = 3,
#'   nbands = 7,
#'   regular_hilltop = TRUE,
#'   noise_sd = 0,
#'   rotation = 45
#' )
#' @keywords internal
#' @importFrom stats rnorm kmeans
create_landscape_banded <- function(
  width = 100,
  height = 100,
  nhills = 2,
  regular_hilltop = TRUE,
  top_elevation_mean = 30,
  top_elevation_sd = 2,
  slope_mean = 0.2,
  slope_sd = 0.05,
  nbands = 7,
  x_ext_hill_sd = 0.4,
  y_ext_hill_sd = 0.4,
  noise_sd = 0.1,
  rotation = 0
) {
  if (regular_hilltop) {
    # Hexagon for spots (to make them more regular)
    spacing <- 6 # minimum of 5 between hilltops
    n_cols <- ceiling(width / spacing)
    n_rows <- ceiling(height / (sqrt(3) / 2 * spacing))

    grid_points <- data.frame()
    for (r in 0:(n_rows - 1)) {
      for (c in 0:(n_cols - 1)) {
        x <- c * 1.5 * spacing
        y <- r * (sqrt(3) / 2 * spacing) + spacing / 2
        if (r %% 2 == 1) {
          x <- x + spacing / 2
        }
        if (x <= width & y <= height) {
          grid_points <- rbind(grid_points, data.frame(row = y, col = x))
        }
      }
    }

    # Choose regularly distributed centers with k-means
    km <- kmeans(grid_points, centers = nhills, nstart = 10)
    hill_tops <- as.data.frame(round(km$centers, 0))
    hill_tops$col <- pmin(width, pmax(1, hill_tops$col))
  } else {
    # Generate random cluster centers
    hill_tops <- data.frame(
      row = sample(1:height, nhills, replace = TRUE),
      col = sample(1:width, nhills, replace = TRUE)
    )
  }

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Calculate position of hills (with/without rotation)
  if (rotation == 0) {
    xpos_hill_actual <- hill_tops$row
    ypos_hill_actual <- hill_tops$col
  } else {
    xpos_hill_actual <- floor(hill_tops$row * 1.5)
    ypos_hill_actual <- floor(hill_tops$col * 1.5)
  }

  # Create hills and their elevation
  hill_distance_elevation <- array(
    data = NA,
    dim = c(width_actual, height_actual, nhills)
  )
  elevation <- matrix(data = NA, nrow = width_actual, ncol = height_actual)
  x_ext_hill <- rnorm(n = nhills, mean = 1, sd = x_ext_hill_sd)
  y_ext_hill <- rnorm(n = nhills, mean = 1, sd = y_ext_hill_sd)
  top_elevation <- rnorm(
    n = nhills,
    mean = top_elevation_mean,
    sd = top_elevation_sd
  )
  slope <- rnorm(n = nhills, mean = slope_mean, sd = slope_sd)

  for (x in 1:width_actual) {
    for (y in 1:height_actual) {
      for (h in 1:nhills) {
        hill_distance_elevation[x, y, h] <- top_elevation[h] -
          slope[h] *
            sqrt(
              ((x - xpos_hill_actual[h]) / x_ext_hill[h])^2 +
                ((y - ypos_hill_actual[h]) / y_ext_hill[h])^2
            )
      }
      elevation[x, y] <- max(hill_distance_elevation[x, y, ], na.rm = TRUE)
      # Add noise (if sd > 0)
      elevation[x, y] <- elevation[x, y] + rnorm(1, mean = 0, sd = noise_sd)
    }
  }

  # Assign vegetation according to elevation
  min_elevation <- min(elevation)
  max_elevation <- max(elevation)
  band_change_elevation <- (max_elevation - min_elevation) / (nbands * 2)
  mat <- matrix(0, nrow = height_actual, ncol = width_actual)

  for (b in seq(1, 2 * nbands - 1, by = 2)) {
    mat[
      (elevation >= ((min_elevation + (b - 1) * band_change_elevation))) &
        (elevation < (min_elevation + b * band_change_elevation))
    ] <- 1
  }

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
    pattern = "banded",
    params = list(
      width = width,
      height = height,
      nhills = nhills,
      regular_hilltop = regular_hilltop,
      top_elevation_mean = top_elevation_mean,
      top_elevation_sd = top_elevation_sd,
      slope_mean = slope_mean,
      slope_sd = slope_sd,
      nbands = nbands,
      x_ext_hill_sd = x_ext_hill_sd,
      y_ext_hill_sd = y_ext_hill_sd,
      noise_sd = noise_sd,
      rotation = rotation
    )
  )
}
