#' Create a Landscape with Clustered Trees
#'
#' Generates a binary landscape with clustered trees below a treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param num_clusters Integer. Number of cluster centers (default: 10).
#' @param cluster_radius Numeric. Radius of clusters in pixels (default: 5).
#' @param scatter_zone_prop Numeric. Proportion of height for scatter zone (default: 0.3).
#' @param elongation_x Numeric. Horizontal elongation factor for clusters (default: 1).
#' @param elongation_y Numeric. Vertical elongation factor for clusters (default: 1).
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'   If NULL, no seed is set explicitly.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default clustered trees
#' clustered_default <- create_landscape_clustered_trees()
#'
#' # Modified clustered trees with more elongated clusters and fixed seeed
#' clustered_modified <- create_landscape_clustered_trees(
#'   treeline_position = 0.2,
#'   num_clusters = 8,
#'   cluster_radius = 7,
#'   scatter_zone_prop = 0.6,
#'   elongation_x = 2.5,
#'   elongation_y = 0.5,
#'   seed = 42
#' )
#'
#' # With rotation and random seed
#' clustered_rotated <- create_landscape_clustered_trees(
#'   num_clusters = 20,
#'   cluster_radius = 2,
#'   scatter_zone_prop = 0.5,
#'   elongation_x = 1.8,
#'   elongation_y = 1.4,
#'   rotation = 45
#' )
#' @export
create_landscape_clustered_trees <- function(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  num_clusters = 10,
  cluster_radius = 5,
  scatter_zone_prop = 0.3,
  elongation_x = 1,
  elongation_y = 1,
  seed = NULL,
  rotation = 0,
  as_raster = TRUE,
  crs = NULL,
  add_metadata = TRUE
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }
  # Input validation
  if (!is.numeric(width) || width <= 0) {
    stop("'width' must be a positive number")
  }
  if (!is.numeric(height) || height <= 0) {
    stop("'height' must be a positive number")
  }
  if (
    !is.numeric(treeline_position) ||
      treeline_position < 0 ||
      treeline_position > 1
  ) {
    stop("'treeline_position' must be between 0 and 1")
  }
  if (!is.numeric(num_clusters) || num_clusters < 1) {
    stop("'num_clusters' must be a positive integer")
  }
  if (!is.numeric(cluster_radius) || cluster_radius <= 0) {
    stop("'cluster_radius' must be a positive number")
  }
  if (
    !is.numeric(scatter_zone_prop) ||
      scatter_zone_prop <= 0 ||
      scatter_zone_prop > 1
  ) {
    stop("'scatter_zone_prop' must be between 0 and 1")
  }
  if (!is.numeric(elongation_x) || elongation_x <= 0) {
    stop("'elongation_x' must be a positive number")
  }
  if (!is.numeric(elongation_y) || elongation_y <= 0) {
    stop("'elongation_y' must be a positive number")
  }
  if (!is.numeric(rotation)) {
    stop("'rotation' must be a number")
  }

  result <- tryCatch(
    {
      # Calculate dimensions based on rotation
      height_actual <- ifelse(rotation == 0, height, height * 1.5)
      width_actual <- ifelse(rotation == 0, width, width * 1.5)

      # Get base landscape with sharp treeline
      landscape <- create_landscape_sharp_treeline(
        width = width_actual,
        height = height_actual,
        treeline_position = treeline_position,
        as_raster = FALSE,
        add_metadata = FALSE
      )

      # Define scatter zone
      if (rotation == 0) {
        treeline_row <- round(height_actual * treeline_position)
        scatter_zone_end <- min(
          height_actual,
          treeline_row + round(height_actual * scatter_zone_prop)
        )
        # Generate random cluster centers
        cluster_centers <- data.frame(
          row = sample(
            round((treeline_row + cluster_radius + 1), 0):round(
              (scatter_zone_end - cluster_radius),
              0
            ),
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
        #Generate random cluster centers
        cluster_centers <- data.frame(
          row = sample(
            round((treeline_row + cluster_radius + 1), 0):round(
              (scatter_zone_end - cluster_radius),
              0
            ),
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
      for (i in seq_len(nrow(cluster_centers))) {
        center_row <- cluster_centers$row[i]
        center_col <- cluster_centers$col[i]

        # Define cluster boundaries (accounting for elongation)
        row_min <- max(1, center_row - cluster_radius * elongation_y)
        row_max <- min(
          height,
          center_row + cluster_radius * elongation_y
        )
        col_min <- max(1, center_col - cluster_radius * elongation_x)
        col_max <- min(width, center_col + cluster_radius * elongation_x)

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

      # Get the result either as matrix or SpatRaster
      if (as_raster) {
        landscape <- matrix_to_raster(
          landscape,
          crs = crs
        )
      }
      landscape
    },
    error = function(e) {
      # Add context to the error for easier debugging
      stop("Error in create_landscape_clusters: ", e$message, call. = FALSE)
    }
  )

  # Return with metadata if requested
  if (add_metadata) {
    return(list(
      landscape = result,
      type = "clustered",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        num_clusters = num_clusters,
        cluster_radius = cluster_radius,
        scatter_zone_prop = scatter_zone_prop,
        elongation_x = elongation_x,
        elongation_y = elongation_y,
        seed = seed,
        rotation = rotation,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
