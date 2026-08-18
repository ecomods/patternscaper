#' Create Circular Vegetation Patches
#'
#' Places circular patches with optional radius variation, fuzzy edges, and
#' regular spacing. Inversion produces bare gaps in vegetated ground.
#'
#' Parameters are documented on \code{\link{pattern_spots}}.
#'
#' @return A landscape object with pattern "spots".
#'
#' @noRd
#' @importFrom stats kmeans rnorm runif
#' @importFrom cli cli_alert_warning
create_landscape_spots <- function(
  width = 100,
  height = 100,
  n_spots = 5,
  spot_radius = 10,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  invert_landscape = FALSE,
  regular_spots = FALSE
) {
  # Validate inputs
  validate_dimensions(width = width, height = height)

  # Coerce counts to whole values before validation
  n_spots <- as.integer(n_spots)

  # Validate pattern parameters
  if (!is.numeric(n_spots) || n_spots < 1) {
    cli::cli_abort(c(
      "{.arg n_spots} must be a positive integer.",
      "x" = "You supplied {.val {n_spots}}"
    ))
  }

  if (!is.numeric(spot_radius) || spot_radius <= 0) {
    cli::cli_abort(c(
      "{.arg spot_radius} must be a positive number.",
      "x" = "You supplied {.val {spot_radius}}"
    ))
  }

  if (spot_radius >= min(width, height) / 2) {
    cli::cli_abort(c(
      "{.arg spot_radius} is too large for the landscape dimensions.",
      "i" = "Maximum recommended: {min(width, height) / 2}",
      "x" = "You supplied {.val {spot_radius}}"
    ))
  }

  if (!is.numeric(spot_radius_sd) || spot_radius_sd < 0) {
    cli::cli_abort(c(
      "{.arg spot_radius_sd} must be a non-negative number.",
      "x" = "You supplied {.val {spot_radius_sd}}"
    ))
  }

  if (
    !is.numeric(radius_noise_fraction) ||
      radius_noise_fraction < 0 ||
      radius_noise_fraction > 1
  ) {
    cli::cli_abort(c(
      "{.arg radius_noise_fraction} must be between 0 and 1.",
      "x" = "You supplied {.val {radius_noise_fraction}}"
    ))
  }

  if (!is.logical(invert_landscape) || length(invert_landscape) != 1) {
    cli::cli_abort(c(
      "{.arg invert_landscape} must be a single logical value (TRUE or FALSE).",
      "x" = "You supplied {.val {invert_landscape}}"
    ))
  }

  if (!is.logical(regular_spots) || length(regular_spots) != 1) {
    cli::cli_abort(c(
      "{.arg regular_spots} must be a single logical value (TRUE or FALSE).",
      "x" = "You supplied {.val {regular_spots}}"
    ))
  }

  if (regular_spots) {
    # Build a hexagonal grid for regular placement
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

    # Reduce the request when fewer grid positions fit
    if (n_spots > n_available) {
      cli::cli_warn(c(
        "Regular spot placement requested {n_spots} spots but only ~{n_available} positions fit.",
        "i" = " Adjusting to maximum feasible spots. Consider decreasing {.arg spot_radius}."
      ))
      n_spots <- n_available
    }

    # Select a spatially distributed subset with k-means
    if (n_spots < n_available) {
      # Suppress expected convergence warnings that do not affect placement
      km <- suppressWarnings(
        stats::kmeans(grid_points, centers = n_spots, nstart = 5, iter.max = 50)
      )
      cluster_centers <- as.data.frame(km$centers)
    } else {
      cluster_centers <- grid_points
    }
  } else {
    # Sample random centers
    cluster_centers <- data.frame(
      row = sample(
        round((spot_radius + 1), 0):round((height - spot_radius), 0),
        n_spots,
        replace = TRUE
      ),
      col = sample(1:width, n_spots, replace = TRUE)
    )
  }

  # Draw spots into an initially bare landscape
  mat <- matrix(0, nrow = height, ncol = width)

  for (i in seq_len(nrow(cluster_centers))) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Vary radius between spots
    if (spot_radius_sd > 0) {
      adjusted_radius <- max(
        1,
        spot_radius + stats::rnorm(1, 0, spot_radius_sd)
      )
    } else {
      adjusted_radius <- spot_radius
    }

    # Restrict distance calculations to the local bounding box
    row_min <- max(1, floor(center_row - adjusted_radius))
    row_max <- min(height, ceiling(center_row + adjusted_radius))
    col_min <- max(1, floor(center_col - adjusted_radius))
    col_max <- min(width, ceiling(center_col + adjusted_radius))

    # Fill the core and sample cells within the fuzzy rim
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
          if (stats::runif(1) < prop_veg) {
            mat[r, c] <- 1
          }
        }
      }
    }
  }

  # Invert vegetation and bare ground for gaps
  if (invert_landscape) {
    mat <- 1 - mat
  }

  # Store the raster and its generation metadata
  landscape(
    data = mat,
    pattern = "spots",
    params = list(
      width = width,
      height = height,
      invert_landscape = invert_landscape,
      n_spots = n_spots,
      spot_radius = spot_radius,
      spot_radius_sd = spot_radius_sd,
      radius_noise_fraction = radius_noise_fraction,
      regular_spots = regular_spots
    )
  )
}
