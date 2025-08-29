#' Create a Landscape with rings that have no vegetation or spots that have no vegetation
#'
#' Generates a vegetated landscape with spots with bare soil in between.
#' The landscape can optionally be rotated.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param spot Boolean. Spots or rings: if true: vegetated spots, if false unvegetated rings
#' @param n_spots Integer. Number of non-vegetated spots
#' @param spot_radius Integer. Radius of each spot
#' @param noise_radius Boolean. Are random effects included for spot size (noise)
#' @param noise_radius_sd Numeric. If random effects, which standard deviation
#' @param noise Boolean. Are random effects included (noise)
#' @param noise_sd Numeric. If random effects, which standard deviation
#' @param rotation Numeric. Degrees of rotation to apply (counterclockwise). Default is 0 (no rotation).
#'
#' @return A matrix representing the ringed/spotted landscape, where 1 indicates vegetation and 0 indicates bare soil.
#' @export
create_spot_vegetation <- function(
  width = 100,
  height = 100,
  spot = TRUE,
  n_spots = 15,
  spot_radius = 5,
  noise_radius = FALSE,
  noise_radius_sd = 1,
  rotation = 0,
  seed = NULL,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = FALSE
) {
  #Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Generate random cluster centers
  cluster_centers <- data.frame(
    row = sample(
      1:height_actual,
      n_spots,
      replace = TRUE
    ),
    col = sample(
      1:width_actual,
      n_spots,
      replace = TRUE
    )
  )

  landscape <- matrix(0, nrow = height_actual, ncol = width_actual)
  if (!spot) {
    landscape <- matrix(1, nrow = height_actual, ncol = width_actual)
  }

  # Create clusters around centers
  for (i in 1:nrow(cluster_centers)) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Define cluster boundaries (accounting for elongation)
    adjusted_radius <- ifelse(
      noise_radius,
      spot_radius * rnorm(1, mean = 0, sd = noise_radius_sd),
      spot_radius
    )
    row_min <- max(1, center_row - adjusted_radius)
    row_max <- min(height_actual, center_row + adjusted_radius)
    col_min <- max(1, center_col - adjusted_radius)
    col_max <- min(width_actual, center_col + adjusted_radius)

    # Fill in cluster with decreasing probability based on distance from center
    for (r in floor(row_min):ceiling(row_max)) {
      for (c in floor(col_min):ceiling(col_max)) {
        # Calculate distance
        dx <- (c - center_col)
        dy <- (r - center_row)
        dist <- sqrt(dx^2 + dy^2)

        # Probability decreases with distance
        if (dist <= spot_radius) {
          prob <- 1 - (dist / spot_radius)^2
          if (runif(1) < prob) {
            if (spot) {
              landscape[r, c] <- 1
            } else {
              landscape[r, c] <- 0
            }
          }
        }
      }
    }
  }

  # Apply rotation if specified
  if (rotation != 0) {
    landscape <- rotate_and_crop_landscape(
      landscape,
      rotation,
      width,
      height
    )
  }

  # Get the result either as matrix or SpatRaster
  result <- if (as_raster) {
    matrix_to_raster(landscape, crs = crs)
  } else {
    landscape
  }

  # Return with metadata if requested
  if (add_metadata) {
    return(list(
      landscape = result,
      type = "spots",
      params = list(
        width = width,
        height = height,
        spot = spot,
        n_spots = n_spots,
        spot_radius = spot_radius,
        noise_radius = noise_radius,
        noise_radius_sd = noise_radius_sd,
        rotation = rotation,
        seed = seed,
        crs = crs
      )
    ))
  } else {
    return(result)
  }

  return(landscape)
}
