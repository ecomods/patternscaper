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
#' @param seed Integer or NULL. Random seed for reproducibility (default: NULL).
#'     If NULL, seed will not be set explicitly.
#'     If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param regular_spots Boolean. Should the spots be arranged in a regular way (on a hexagon using k-means) or randomly?
#'     (default: FALSE)
#' @param rotation Unused parameter for compatibility with other landscape functions (default: 0).
#'     Is only needed because in the function \link{generate_training_landscapes}
#'     all landscape functions need to have a rotation parameter.
#'
#' @return A landscape object with class "spots" containing the generated landscape data and parameters.
#'
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
#' @keywords internal
create_landscape_spots <- function(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  noise_radius_sd = 0,
  spot_jitter = 0,
  invert_landscape = FALSE,
  seed = NULL,
  regular_spots = FALSE,
  rotation = 0
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (regular_spots) {
    #hexangon for spots (to make them more regular)
    spacing <- 2 * spot_radius * 1.1
    n_cols <- ceiling(width / spacing)
    n_rows <- ceiling(height / (sqrt(3) / 2 * spacing))

    grid_points <- data.frame()
    for (r in 0:(n_rows - 1)) {
      for (c in 0:(n_cols - 1)) {
        x <- c * spacing + spot_radius
        y <- r * (sqrt(3) / 2 * spacing) + spot_radius
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
      cluster_centers$row <- pmin(
        height,
        pmax(1, cluster_centers$row + runif(n_spots, -spot_jitter, spot_jitter))
      )
      cluster_centers$col <- pmin(
        width,
        pmax(1, cluster_centers$col + runif(n_spots, -spot_jitter, spot_jitter))
      )
    }
  } else {
    # Generate random cluster centers
    cluster_centers <- data.frame(
      row = sample(
        round((spot_radius + 1), 0):round((height - spot_radius), 0),
        n_spots,
        replace = TRUE
      ),
      col = sample(1:width, n_spots, replace = TRUE)
    )
  }

  #prepare landscape
  mat <- matrix(0, nrow = height, ncol = width)

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
            mat[r, c] <- 1
          }
        }
      }
    }
  }

  # Invert landscape if specified (zeroes become ones and vice versa)
  if (invert_landscape) {
    mat <- 1 - mat
  }

  # Create and return landscape object
  landscape(
    data = mat,
    class = "spots",
    params = list(
      width = width,
      height = height,
      invert_landscape = invert_landscape,
      n_spots = n_spots,
      spot_radius = spot_radius,
      noise_radius_sd = noise_radius_sd,
      spot_jitter = spot_jitter,
      regular_spots = regular_spots,
      seed = seed,
      rotation = rotation
    )
  )
}
