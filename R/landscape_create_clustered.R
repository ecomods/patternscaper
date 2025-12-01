#' Create a Landscape with Clustered Trees
#'
#' Generates a binary landscape with clustered trees below a treeline.
#' Trees are arranged in clusters within a scatter zone that extends below
#' the treeline. Clusters can be elongated in x or y directions to create
#' elliptical patterns.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param random_spots Numeric vector of length 2. Probabilities for flipping
#'   cells: `[prob(1→0), prob(0→1)]`. Used to add noise to the landscape
#'   (default: c(0,0)).
#' @param n_clusters Integer. Number of cluster centers (default: 10).
#' @param cluster_radius Numeric. Radius of clusters in pixels (default: 5).
#' @param scatter_zone_prop Numeric. Proportion of height for scatter zone
#'   measured downward from treeline (0-1, default: 0.3).
#' @param elongation_x Numeric. Horizontal elongation factor for clusters.
#'   Values > 1 create horizontally elongated clusters (default: 1).
#' @param elongation_y Numeric. Vertical elongation factor for clusters.
#'   Values > 1 create vertically elongated clusters (default: 1).
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#'
#' @return A landscape object with pattern "clustered" containing the generated
#'   landscape data and parameters.
#'
#' @importFrom stats runif
#' @importFrom terra as.matrix
#' @importFrom cli cli_abort
#' @keywords internal
#'
#' @examples
#' # Default clustered trees
#' clustered_default <- create_landscape_clustered_trees()
#'
#' # Modified clustered trees with horizontally elongated clusters
#' clustered_modified <- create_landscape_clustered_trees(
#'   treeline_position = 0.2,
#'   n_clusters = 8,
#'   cluster_radius = 7,
#'   scatter_zone_prop = 0.6,
#'   elongation_x = 2.5,
#'   elongation_y = 0.5
#' )
#'
#' # Rotated landscape with mixed parameters
#' clustered_rotated <- create_landscape_clustered_trees(
#'   n_clusters = 20,
#'   cluster_radius = 2,
#'   scatter_zone_prop = 0.5,
#'   elongation_x = 1.8,
#'   elongation_y = 1.4,
#'   rotation = 45
#' )
create_landscape_clustered_trees <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  random_spots = c(0, 0),
  n_clusters = 10,
  cluster_radius = 5,
  scatter_zone_prop = 0.3,
  elongation_x = 1,
  elongation_y = 1,
  rotation = 0
) {
  # Input validation
  validate_dimensions(width = width, height = height)
  validate_treeline_position(treeline_position = treeline_position)
  validate_random_spots(random_spots = random_spots)
  validate_rotation(rotation = rotation)

  # Convert parameters to the right types
  n_clusters <- as.integer(n_clusters)

  if (
    !is.numeric(n_clusters) ||
      n_clusters < 1 ||
      n_clusters != as.integer(n_clusters)
  ) {
    cli::cli_abort(c(
      "{.arg n_clusters} must be a positive integer.",
      "x" = "You supplied {.val {n_clusters}}"
    ))
  }

  if (!is.numeric(cluster_radius) || cluster_radius <= 0) {
    cli::cli_abort(c(
      "{.arg cluster_radius} must be a positive number.",
      "x" = "You supplied {.val {cluster_radius}}"
    ))
  }

  if (
    !is.numeric(scatter_zone_prop) ||
      scatter_zone_prop <= 0 ||
      scatter_zone_prop > 1
  ) {
    cli::cli_abort(c(
      "{.arg scatter_zone_prop} must be between 0 and 1.",
      "x" = "You supplied {.val {scatter_zone_prop}}"
    ))
  }

  if (!is.numeric(elongation_x) || elongation_x <= 0) {
    cli::cli_abort(c(
      "{.arg elongation_x} must be a positive number.",
      "x" = "You supplied {.val {elongation_x}}"
    ))
  }

  if (!is.numeric(elongation_y) || elongation_y <= 0) {
    cli::cli_abort(c(
      "{.arg elongation_y} must be a positive number.",
      "x" = "You supplied {.val {elongation_y}}"
    ))
  }

  # Calculate dimensions based on rotation
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Ensure scatter zone is large enough for clusters
  min_scatter_zone <- 2 * cluster_radius * max(elongation_y, 1)
  if (scatter_zone_prop * height_actual < min_scatter_zone) {
    cli::cli_abort(c(
      "Scatter zone too small for cluster size.",
      "i" = "Need at least {min_scatter_zone} pixels but got {scatter_zone_prop * height_actual}.",
      "i" = "Increase {.arg scatter_zone_prop} or decrease {.arg cluster_radius}."
    ))
  }

  # Get base landscape with sharp treeline
  base_landscape <- create_landscape_sharp_treeline(
    width = width_actual,
    height = height_actual,
    treeline_position = treeline_position,
    random_spots = random_spots,
    rotation = 0
  )

  # Extract matrix from landscape object
  mat <- terra::as.matrix(base_landscape$data, wide = TRUE)

  # Define scatter zone boundaries
  treeline_row <- round(height_actual * treeline_position)

  # For rotated landscapes, use inner portion to avoid edge artifacts after crop
  rotation_safe_margin <- 1 / 6

  if (rotation != 0) {
    # Restrict to inner 2/3 of dimensions for rotation safety
    max_row <- floor((1 - rotation_safe_margin) * height_actual)
    max_col <- floor((1 - rotation_safe_margin) * width_actual)
    min_col <- floor(rotation_safe_margin * width_actual) + 1
  } else {
    max_row <- height_actual
    max_col <- width_actual
    min_col <- 1
  }

  scatter_zone_end <- min(
    max_row,
    treeline_row + floor(max_row * scatter_zone_prop)
  )

  # Generate random cluster centers within safe boundaries
  cluster_centers <- data.frame(
    row = sample(
      (treeline_row + cluster_radius + 1):floor(
        scatter_zone_end - cluster_radius
      ),
      n_clusters,
      replace = TRUE
    ),
    col = sample(
      min_col:max_col,
      n_clusters,
      replace = TRUE
    )
  )

  # Create clusters around centers
  for (i in seq_len(nrow(cluster_centers))) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Define cluster boundaries (accounting for elongation)
    row_min <- max(1, center_row - cluster_radius * elongation_y)
    row_max <- min(
      height_actual,
      center_row + cluster_radius * elongation_y
    )
    col_min <- max(1, center_col - cluster_radius * elongation_x)
    col_max <- min(
      width_actual,
      center_col + cluster_radius * elongation_x
    )

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
            mat[r, c] <- 1
          }
        }
      }
    }
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
    pattern = "clustered",
    params = list(
      width = width,
      height = height,
      treeline_position = treeline_position,
      n_clusters = n_clusters,
      cluster_radius = cluster_radius,
      scatter_zone_prop = scatter_zone_prop,
      elongation_x = elongation_x,
      elongation_y = elongation_y,
      rotation = rotation,
      random_spots = random_spots
    )
  )
}
