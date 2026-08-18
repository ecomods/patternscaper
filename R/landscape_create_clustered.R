#' Create Vegetation Clusters Below a Boundary
#'
#' Places circular or elliptical clusters within a zone below a sharp
#' vegetation boundary.
#'
#' Parameters are documented on \code{\link{pattern_clustered}}.
#'
#' @return A landscape object with pattern "clustered".
#'
#' @noRd
#' @importFrom stats runif
#' @importFrom terra as.matrix
#' @importFrom cli cli_abort
create_landscape_clustered <- function(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  n_clusters = 10,
  cluster_radius = 5,
  cluster_zone = 0.3,
  elongation_x = 1,
  elongation_y = 1,
  rotation = 0
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)
  validate_boundary_position(boundary_position = boundary_position)
  validate_rotation(rotation = rotation)

  # Validate before truncating fractional cluster counts
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
    !is.numeric(cluster_zone) ||
      cluster_zone <= 0 ||
      cluster_zone > 1
  ) {
    cli::cli_abort(c(
      "{.arg cluster_zone} must be between 0 and 1.",
      "x" = "You supplied {.val {cluster_zone}}"
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

  # Pad rotated landscapes before cropping to avoid clipped corners
  rotation_scale_factor <- 1.5
  height_actual <- ifelse(rotation == 0, height, height * rotation_scale_factor)
  width_actual <- ifelse(rotation == 0, width, width * rotation_scale_factor)

  # Ensure the cluster zone can contain the full vertical cluster extent
  min_cluster_zone <- 2 * cluster_radius * max(elongation_y, 1)
  if (cluster_zone * height_actual < min_cluster_zone) {
    cli::cli_abort(c(
      "Cluster zone too small for cluster size.",
      "i" = "Need at least {min_cluster_zone} pixels but got {cluster_zone * height_actual}.",
      "i" = "Increase {.arg cluster_zone} or decrease {.arg cluster_radius}."
    ))
  }

  # Start from a sharp vegetation boundary
  base_landscape <- create_landscape_sharp(
    width = width_actual,
    height = height_actual,
    boundary_position = boundary_position,
    rotation = 0
  )

  mat <- terra::as.matrix(base_landscape$data, wide = TRUE)

  # Define cluster zone boundaries
  boundary_row <- round(height_actual * boundary_position)

  # Keep centers in the inner two-thirds so cropping removes edge artifacts
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

  cluster_zone_end <- min(
    max_row,
    boundary_row + floor(max_row * cluster_zone)
  )

  # Check that cluster centers fit inside the available zone
  sample_row_start <- boundary_row + cluster_radius + 1
  sample_row_end <- floor(cluster_zone_end - cluster_radius)

  if (sample_row_start > sample_row_end) {
    cli::cli_abort(c(
      "Cannot place clusters: insufficient vertical space in cluster zone.",
      "i" = "Row range [{sample_row_start}, {sample_row_end}] is invalid.",
      "i" = "Increase {.arg cluster_zone} or decrease {.arg cluster_radius}."
    ))
  }

  if (min_col > max_col) {
    cli::cli_abort(c(
      "Cannot place clusters: insufficient horizontal space.",
      "i" = "Column range [{min_col}, {max_col}] is invalid.",
      "i" = "This may indicate an issue with rotation parameters."
    ))
  }

  # Sample cluster centers within safe bounds
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

  # Draw elliptical clusters with occupancy decreasing from each center
  for (i in seq_len(nrow(cluster_centers))) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Limit work to the elongated bounding box
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

    for (r in floor(row_min):ceiling(row_max)) {
      for (c in floor(col_min):ceiling(col_max)) {
        # Scale coordinates to define the ellipse
        dx <- (c - center_col) / elongation_x
        dy <- (r - center_row) / elongation_y
        dist <- sqrt(dx^2 + dy^2)

        # Use a quadratic radial probability within the cluster radius
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

  # Store the raster and its generation metadata
  landscape(
    data = mat,
    pattern = "clustered",
    params = list(
      width = width,
      height = height,
      boundary_position = boundary_position,
      n_clusters = n_clusters,
      cluster_radius = cluster_radius,
      cluster_zone = cluster_zone,
      elongation_x = elongation_x,
      elongation_y = elongation_y,
      rotation = rotation
    )
  )
}
