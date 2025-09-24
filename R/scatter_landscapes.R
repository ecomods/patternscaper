#' Create a Landscape with Scattered Trees
#'
#' Generates a binary landscape with randomly scattered trees below a treeline.
#'
#' @param width Integer. Width of the landscape in pixels (default: 100).
#' @param height Integer. Height of the landscape in pixels (default: 100).
#' @param treeline_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param scatter_density Numeric. Probability of tree presence in the scatter zone (0-1) (default: 0.1).
#'    Higher values result in a denser tree cover in the scatter zone.
#' @param scatter_zone_prop Numeric. Proportion of height for scatter zone (default: 0.5).
#'   Defines how far below the treeline scattered trees can appear.
#' @param rotation Numeric. Angle to rotate landscape in degrees (default: 0).
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @examples
#' # Default scattered trees
#' scattered_default <- create_landscape_scattered_trees()
#'
#' # Modified scattered trees with higher density in a larger scatter zone
#' scattered_modified <- create_landscape_scattered_trees(
#'   treeline_position = 0.3,
#'   scatter_density = 0.7,
#'   scatter_zone_prop = 0.2
#' )
#'
#' # With rotation
#' scattered_rotated <- create_landscape_scattered_trees(
#'   treeline_position = 0.3,
#'   scatter_density = 0.2,
#'   scatter_zone_prop = 0.1,
#'   rotation = 45
#' )
#'
#' @export
create_landscape_scattered_trees <- function(
    width = 100,
    height = 100,
    treeline_position = 0.5,
    scatter_density = 0.1,
    scatter_zone_prop = 0.2,
    rotation = 0,
    seed = 42,
    as_raster = TRUE,
    crs = NULL,
    add_metadata = TRUE) {
  # If seed is NULL, use random seed; otherwise use the provided seed
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)

  # Calculate dimensions based on rotation
  height_actual <- ifelse(rotation == 0, height, height * 1.5)
  width_actual <- ifelse(rotation == 0, width, width * 1.5)

  # Get base landscape with sharp treeline
  landscape <- create_landscape_sharp_treeline(
    width_actual,
    height_actual,
    treeline_position,
    as_raster = FALSE,
    add_metadata = FALSE
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
      type = "scattered",
      params = list(
        width = width,
        height = height,
        treeline_position = treeline_position,
        scatter_density = scatter_density,
        scatter_zone_prop = scatter_zone_prop,
        rotation = rotation,
        seed = seed,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}

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
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
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
#' # Modified clustered trees with more elongated clusters
#' clustered_modified <- create_landscape_clustered_trees(
#'   treeline_position = 0.2,
#'   num_clusters = 8,
#'   cluster_radius = 7,
#'   scatter_zone_prop = 0.6,
#'   elongation_x = 2.5,
#'   elongation_y = 0.5
#' )
#'
#' # With rotation and random seed
#' clustered_rotated <- create_landscape_clustered_trees(
#'   num_clusters = 20,
#'   cluster_radius = 2,
#'   scatter_zone_prop = 0.5,
#'   elongation_x = 1.8,
#'   elongation_y = 1.4,
#'   rotation = 45,
#'   seed = NULL
#' )
#'
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
    seed = 42,
    rotation = 0,
    as_raster = TRUE,
    crs = NULL,
    add_metadata = TRUE) {
  # If seed is NULL, use random seed; otherwise use the provided seed
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)
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
  if (!is.numeric(seed) || seed != round(seed)) {
    stop("'seed' must be an integer")
  }

  result <- tryCatch(
    {
      set.seed(seed)
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
            round((treeline_row + cluster_radius + 1),0):round((scatter_zone_end-cluster_radius),0),
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
           round((treeline_row + cluster_radius + 1),0):round((scatter_zone_end-cluster_radius),0),
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

#' Create a Landscape with Spots Pattern
#'
#' Generates a binary landscape with circular spots.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param n_spots Integer. Number of non-vegetated spots
#' @param spot_radius Integer. Radius of each spot
#' @param noise_radius_sd Numeric. If random effects, which standard deviation (Default is 0 - no random effects)
#' @param spot_jitter Integer. Should the regular spots be slightly shifted - how many cells (Default is 0 - no jitter)
#' @param invert_landscape Boolean. Invert vegetated and unvegetated areas.
#'     Switches the landscape from vegetated with bare spots to bare with vegetated spots (default: FALSE).
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'     If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'     If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param rotation Unused parameter for compatibility with other landscape functions (default: 0).
#'     Is only needed because in the function \link{generate_training_landscapes}
#'     all landscape functions need to have a rotation parameter.
#' @param as_raster Logical. Whether to return as SpatRaster or a matrix (default: TRUE).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return A matrix representing the ringed/spotted landscape, where 1 indicates vegetation and 0 indicates bare soil.
#' @examples
#' # Default spots
#' spots_default <- create_landscape_spots()
#'
#' # Modified spots with more spots and random radius variation
#' spots_modified <- create_landscape_spots(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   noise_radius_sd = 2
#' )
#'
#' # Inverted spots (vegetation outside spots instead of inside)
#' spots_inverted <- create_landscape_spots(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   invert_landscape = TRUE,
#'   noise_radius_sd = 2
#' )
#' @export
create_landscape_spots <- function(
    width = 100,
    height = 100,
    n_spots = 15,
    spot_radius = 5,
    noise_radius_sd = 0,
    spot_jitter = 0,
    invert_landscape = FALSE,
    seed = 42,
    rotation = 0,
    as_raster = TRUE,
    crs = NULL,
    add_metadata = TRUE) {

  # If seed is NULL, use random seed; otherwise use the provided seed
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)

  #hexangon for spots (to make them more regular)
  spacing <- 2 * spot_radius * 1.1
  n_cols <- ceiling(width / spacing)
  n_rows <- ceiling(height / (sqrt(3)/2 * spacing))

  grid_points <- data.frame()
  for (r in 0:(n_rows-1)) {
    for (c in 0:(n_cols-1)) {
      x <- c * spacing + spot_radius
      y <- r * (sqrt(3)/2 * spacing) + spot_radius
      if (r %% 2 == 1) {
        x <- x + spacing / 2
      }
      if (x <= width & y <= height) {
        grid_points <- rbind(grid_points, data.frame(row = y, col = x))
      }
    }
  }

  #chose regularly distributed centers with k-means
  km <- kmeans(grid_points, centers = n_spots, nstart = 10)
  cluster_centers <- as.data.frame(km$centers)

  #some jittering if wanted
  if (spot_jitter > 0) {
    cluster_centers$row <- pmin(height, pmax(1, cluster_centers$row + runif(n_spots, -spot_jitter, spot_jitter)))
    cluster_centers$col <- pmin(width, pmax(1, cluster_centers$col + runif(n_spots, -spot_jitter, spot_jitter)))
  }

  #prepare landscape
  landscape <- matrix(0, nrow = height, ncol = width)

  # Create clusters around centers
  for (i in 1:nrow(cluster_centers)) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Create noise if requested
    noise <- rnorm(1, mean = 0, sd = noise_radius_sd)
    # Add noise to the radius, but if radius drops below 0, set it to 1
    adjusted_radius <- max(1, spot_radius + noise)

    row_min <- max(1, center_row - adjusted_radius)
    row_max <- min(height, center_row + adjusted_radius)
    col_min <- max(1, center_col - adjusted_radius)
    col_max <- min(width, center_col + adjusted_radius)

    # Fill in cluster with decreasing probability based on distance from center
    for (r in floor(row_min):ceiling(row_max)) {
      for (c in floor(col_min):ceiling(col_max)) {
        # Calculate distance
        dx <- (c - center_col)
        dy <- (r - center_row)
        dist <- sqrt(dx^2 + dy^2)

        # Probability decreases with distance
        if (dist <= adjusted_radius) {
          prob <- 1 - (dist / adjusted_radius)^2
          if (runif(1) < prob) {
            landscape[r, c] <- 1
          }
        }
      }
    }
  }

  # Invert landscape if specified (zeroes become ones and vice versa)
  if (invert_landscape) {
    landscape <- 1 - landscape
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
        invert_landscape = invert_landscape,
        n_spots = n_spots,
        spot_radius = spot_radius,
        noise_radius_sd = noise_radius_sd,
        seed = seed,
        crs = crs
      )
    ))
  } else {
    return(result)
  }
}
