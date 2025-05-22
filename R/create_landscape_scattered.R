#' Create a Landscape with a Scattered Tree Pattern
#'
#' Generates a landscape with a transition from forest (trees) to open land (no trees),
#' with scattered trees in the transition zone. The landscape can optionally be rotated.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param treeline_position Numeric. Position of the treeline relative to the height (0-1).
#' @param scatter_density Numeric. Density of scattered trees in the transition zone (0-1).
#' @param scatter_zone_prop Numeric. Proportion of the landscape height to use as the scatter zone.
#' @param rotation Numeric. Degrees of rotation to apply (counterclockwise). Default is 0 (no rotation).
#'
#' @return A matrix representing the scattered landscape, where 1 indicates trees and 0 indicates no trees.
create_random_scatter <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  scatter_density = 0.1,
  scatter_zone_prop = 0.3,
  rotation = 0
) {
  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Get base landscape with sharp treeline
  landscape <- create_sharp_treeline(
    width_actual,
    height_actual,
    treeline_position
  )

  # Define scatter zone
  treeline_row <- round(height_actual * treeline_position)
  scatter_zone_end <- min(
    height_actual,
    treeline_row + round(height_actual * scatter_zone_prop)
  )

  # Randomly place trees in scatter zone
  for (i in (treeline_row + 1):scatter_zone_end) {
    for (j in 1:width_actual) {
      if (stats::runif(1) < scatter_density) {
        landscape[i, j] <- 1
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

  return(landscape)
}
