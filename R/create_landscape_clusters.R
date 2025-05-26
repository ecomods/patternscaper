#' Create clustered landscape with optional treeline and rotation
#'
#' Generates a binary landscape matrix with clusters of 1s above a treeline,
#' allowing for control over cluster number, size, elongation, and rotation.
#'
#' @param width Width of the landscape (default: 100)
#' @param height Height of the landscape (default: 100)
#' @param treeline_position Relative position of the treeline (0-1, default: 0.5)
#' @param num_clusters Number of clusters to generate (default: 5)
#' @param cluster_radius Radius of each cluster (default: 5)
#' @param scatter_zone_prop Proportion of area above treeline for clusters (default: 0.3)
#' @param cropped Logical, restrict clusters to central area (default: FALSE)
#' @param elongation_x Elongation factor in x direction (default: 1)
#' @param elongation_y Elongation factor in y direction (default: 1)
#' @param rotation Rotation angle in degrees (default: 0)
#'
#' @return A matrix representing the landscape with clusters
create_landscape_clusters <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_clusters = 5,
  cluster_radius = 5,
  scatter_zone_prop = 0.3,
  cropped = FALSE,
  elongation_x = 1,
  elongation_y = 1,
  rotation = 0
) {
  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Get base landscape with sharp treeline
  landscape <- create_landscape_sharp_treeline(
    width_actual,
    height_actual,
    treeline_position
  )

  # Define scatter zone
  if (!cropped) {
    treeline_row <- round(height_actual * treeline_position)
    scatter_zone_end <- min(
      height_actual,
      treeline_row + round(height_actual * scatter_zone_prop)
    )
    # Generate random cluster centers
    cluster_centers <- data.frame(
      row = sample(
        (treeline_row + 1):scatter_zone_end,
        num_clusters,
        replace = TRUE
      ),
      col = sample(1:width_actual, num_clusters, replace = TRUE)
    )
  } else {
    treeline_row <- round(height_actual * treeline_position)
    scatter_zone_end <- min(
      round(5 / 6 * height_actual),
      treeline_row + round((5 / 6 * height_actual) * scatter_zone_prop)
    )
    # Generate random cluster centers
    cluster_centers <- data.frame(
      row = sample(
        (treeline_row + 1):scatter_zone_end,
        num_clusters,
        replace = TRUE
      ),
      col = sample(
        (round(1 / 6 * width_actual) + 1):round(5 / 6 * width_actual),
        num_clusters,
        replace = TRUE
      )
    )
  }

  # Create clusters around centers
  for (i in 1:nrow(cluster_centers)) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Define cluster boundaries (accounting for elongation)
    row_min <- max(1, center_row - cluster_radius * elongation_y)
    row_max <- min(height_actual, center_row + cluster_radius * elongation_y)
    col_min <- max(1, center_col - cluster_radius * elongation_x)
    col_max <- min(width_actual, center_col + cluster_radius * elongation_x)

    # Fill in cluster with decreasing probability based on distance from center
    for (r in floor(row_min):ceiling(row_max)) {
      for (c in floor(col_min):ceiling(col_max)) {
        # Calculate adjusted distance for elliptical shape
        dx <- (c - center_col) / elongation_x
        dy <- (r - center_row) / elongation_y
        dist <- sqrt(dx^2 + dy^2)

        # Probability decreases with distance
        if (dist <= cluster_radius) {
          prob <- 1 - (dist / cluster_radius)^2
          if (stats::runif(1) < prob) {
            landscape[r, c] <- 1
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

  return(landscape)
}
