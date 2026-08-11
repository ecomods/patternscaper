#' Create a Landscape with Clustered Features
#'
#' Generates a binary landscape with clustered features below a vegetation
#' boundary. Features are arranged in clusters within a scatter zone that
#' extends below the boundary. Clusters can be elongated in x or y directions
#' to create elliptical patterns.
#'
#' Parameters are documented on \code{\link{pattern_clustered}}.
#'
#' @return A landscape object with pattern "clustered" containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "clustered"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @noRd
#' @importFrom stats runif
#' @importFrom terra as.matrix
#' @importFrom cli cli_abort
#'
#' @examples
#' \dontrun{
#' # Default clustered features
#' clustered_default <- create_landscape_clustered()
#'
#' # Modified clustered features with horizontally elongated clusters
#' clustered_modified <- create_landscape_clustered(
#'   boundary_position = 0.2,
#'   n_clusters = 8,
#'   cluster_radius = 7,
#'   scatter_zone_prop = 0.6,
#'   elongation_x = 2.5,
#'   elongation_y = 0.5
#' )
#'
#' # Rotated landscape with mixed parameters
#' clustered_rotated <- create_landscape_clustered(
#'   n_clusters = 20,
#'   cluster_radius = 2,
#'   scatter_zone_prop = 0.5,
#'   elongation_x = 1.8,
#'   elongation_y = 1.4,
#'   rotation = 45
#' )
#' }
create_landscape_clustered <- function(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  n_clusters = 10,
  cluster_radius = 5,
  scatter_zone_prop = 0.3,
  elongation_x = 1,
  elongation_y = 1,
  rotation = 0
) {
  # Input validation
  validate_dimensions(width = width, height = height)
  validate_boundary_position(boundary_position = boundary_position)
  validate_rotation(rotation = rotation)

  # n_clusters must be a positive integer
  # Validate before conversion
  if (
    !is.numeric(n_clusters) ||
      length(n_clusters) != 1 ||
      is.na(n_clusters) ||
      n_clusters < 1
  ) {
    cli::cli_abort(c(
      "{.arg n_clusters} must be a positive number.",
      "x" = "You supplied {.val {n_clusters}}"
    ))
  }

  # Convert to integer (truncates decimals like 12.7 -> 12)
  n_clusters <- as.integer(n_clusters)

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

  # Scale factor for rotated landscapes: 1.5x provides sufficient padding
  # to prevent clipping of rotated content
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

  # Get base landscape with sharp vegetation boundary
  base_landscape <- create_landscape_sharp(
    width = width_actual,
    height = height_actual,
    boundary_position = boundary_position,
    rotation = 0
  )

  # Extract matrix from landscape object
  mat <- terra::as.matrix(base_landscape$data, wide = TRUE)

  # Define scatter zone boundaries
  boundary_row <- round(height_actual * boundary_position)

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
    boundary_row + floor(max_row * scatter_zone_prop)
  )

  # Validate that cluster centers can be placed within scatter zone
  sample_row_start <- boundary_row + cluster_radius + 1
  sample_row_end <- floor(scatter_zone_end - cluster_radius)

  if (sample_row_start > sample_row_end) {
    cli::cli_abort(c(
      "Cannot place clusters: insufficient vertical space in scatter zone.",
      "i" = "Row range [{sample_row_start}, {sample_row_end}] is invalid.",
      "i" = "Increase {.arg scatter_zone_prop} or decrease {.arg cluster_radius}."
    ))
  }

  if (min_col > max_col) {
    cli::cli_abort(c(
      "Cannot place clusters: insufficient horizontal space.",
      "i" = "Column range [{min_col}, {max_col}] is invalid.",
      "i" = "This may indicate an issue with rotation parameters."
    ))
  }

  # Generate random cluster centers within safe boundaries
  cluster_centers <- data.frame(
    row = sample(
      sample_row_start:sample_row_end,
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
      boundary_position = boundary_position,
      n_clusters = n_clusters,
      cluster_radius = cluster_radius,
      scatter_zone_prop = scatter_zone_prop,
      elongation_x = elongation_x,
      elongation_y = elongation_y,
      rotation = rotation
    )
  )
}
