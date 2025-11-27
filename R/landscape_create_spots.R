#' Create a Landscape with Spots Pattern
#'
#' Generates a binary landscape with circular spots.
#'
#' @param width Integer. Number of columns in the landscape.
#' @param height Integer. Number of rows in the landscape.
#' @param n_spots Integer. Number of non-vegetated spots
#' @param spot_radius Integer. Radius of each spot
#' @param noise_radius_sd Numeric. If random effects, which standard deviation (Default is 0 - no random effects)
#' @param radius_noise_fraction Numeric (between 0 and 1). 0 means no noise, the higher the larger the circle with noise
#' @param spot_jitter Integer. Should the regular spots be slightly shifted - how many cells (Default is 0 - no jitter)
#' @param invert_landscape Boolean. Invert vegetated and unvegetated areas.
#'     Switches the landscape from vegetated with bare spots to bare with vegetated spots (default: FALSE).
#' @param regular_spots Boolean. Should the spots be arranged in a regular way (on a hexagon using k-means) or randomly?
#'     (default: FALSE)
#' @param rotation Unused parameter for compatibility with other landscape functions (default: 0).
#'     Is only needed because in the function \link{generate_training_landscapes}
#'     all landscape functions need to have a rotation parameter.
#'
#' @return A landscape object with pattern "spots" containing the generated landscape data and parameters.
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
  radius_noise_fraction = 0,
  spot_jitter = 0,
  invert_landscape = FALSE,
  regular_spots = FALSE,
  rotation = 0
) {
  n_spots <- as.integer(n_spots)
  # Validate and adjust n_spots for regular placement
  if (regular_spots) {
    # Calculate maximum possible spots based on hexagonal grid
    spacing <- 2 * spot_radius * 1.1
    n_cols <- ceiling(width / spacing)
    n_rows <- ceiling(height / (sqrt(3) / 2 * spacing))
    max_spots <- n_cols * n_rows

    if (n_spots > max_spots) {
      cli::cli_alert_warning(c(
        "Regular spot placement requested {n_spots} spots but only ~{max_spots} positions fit.",
        "i" = "Adjusting to maximum feasible spots. Consider decreasing {.arg spot_radius}."
      ))
      n_spots <- max_spots
    }
  }

  if (regular_spots) {
    # Generate hexagonal grid for regular spot placement
    spacing <- 2 * spot_radius * 1.1
    n_cols <- ceiling(width / spacing)
    n_rows <- ceiling(height / (sqrt(3) / 2 * spacing))

    grid_points <- data.frame(row = numeric(), col = numeric())
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

    n_available <- nrow(grid_points)

    # Final adjustment if actual grid points differ from estimate
    if (n_spots > n_available) {
      n_spots <- n_available
    }

    # Use k-means for subset selection
    if (n_spots < n_available) {
      km <- suppressWarnings(
        kmeans(grid_points, centers = n_spots, nstart = 5, iter.max = 50)
      )
      cluster_centers <- as.data.frame(km$centers)
    } else {
      cluster_centers <- grid_points
    }

    # Apply jitter if requested
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

    # --- Radius-Variation ---
    if (noise_radius_sd > 0) {
      adjusted_radius <- max(1, spot_radius + rnorm(1, 0, noise_radius_sd))
    } else {
      adjusted_radius <- spot_radius
    }

    # --- Pixelgrenzen bestimmen ---
    row_min <- max(1, floor(center_row - adjusted_radius))
    row_max <- min(height, ceiling(center_row + adjusted_radius))
    col_min <- max(1, floor(center_col - adjusted_radius))
    col_max <- min(width, ceiling(center_col + adjusted_radius))

    # --- Sauber gefüllter Kreis ---
    for (r in row_min:row_max) {
      for (c in col_min:col_max) {
        dx <- c - center_col
        dy <- r - center_row
        dist <- sqrt(dx * dx + dy * dy)

        noise_start <- adjusted_radius * (1 - radius_noise_fraction)
        if (dist <= noise_start) {
          mat[r, c] <- 1
        } else if (dist <= adjusted_radius) {
          prop_veg <- (1 -
            0.5 * (dist - noise_start) / (adjusted_radius - noise_start))
          if (runif(1) < prop_veg) {
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
    pattern = "spots",
    params = list(
      width = width,
      height = height,
      invert_landscape = invert_landscape,
      n_spots = n_spots,
      spot_radius = spot_radius,
      noise_radius_sd = noise_radius_sd,
      spot_jitter = spot_jitter,
      regular_spots = regular_spots,
      rotation = rotation
    )
  )
}
