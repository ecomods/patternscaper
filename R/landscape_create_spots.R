#' Create a Landscape with Spots Pattern
#'
#' Generates a binary landscape with circular spots representing either vegetated patches
#' in bare ground (spots) or bare patches in vegetated ground (when inverted, gaps).
#'
#' @param width Integer. Number of columns in the landscape (default: 100).
#' @param height Integer. Number of rows in the landscape (default: 100).
#' @param n_spots Integer. Number of circular spots to generate.
#'     For regular placement, this may be automatically reduced if the landscape
#'     cannot accommodate the requested number at the given `spot_radius`.
#' @param spot_radius Numeric. Mean radius of each spot in cells.
#'     Must be positive and smaller than landscape dimensions.
#' @param spot_radius_sd Numeric. Standard deviation for random variation in spot radius.
#'     Each spot's radius is sampled from N(spot_radius, spot_radius_sd).
#'     (default: 0 - no variation)
#' @param radius_noise_fraction Numeric (0 to 1). Proportion of the spot radius
#'     where gradual edge noise is applied. 0 creates sharp circular edges,
#'     1 applies probabilistic cell inclusion across the entire radius.
#'     For example, 0.2 means the outer 20% of the radius has a gradient transition.
#'     Works independently of `spot_radius_sd` (which varies the overall size,
#'     while this parameter affects edge sharpness).
#' @param invert_landscape Logical. If TRUE, creates bare patches in vegetated ground
#'     (equivalent to "gaps" pattern). If FALSE (default), creates vegetated spots in bare ground.
#'
#' @details
#' This function can generate both "spots" and "gaps" patterns depending on \code{invert_landscape}.
#' For semantic clarity in training data, use \code{\link{create_landscape_gaps}} when you
#' want bare patches in vegetated ground, which sets \code{invert_landscape = TRUE} by default
#' and labels the pattern as "gaps".
#'
#' @param regular_spots Logical. If TRUE, spots are arranged on a hexagonal grid
#'     using k-means clustering. If FALSE, spots are placed randomly (default: FALSE).
#'
#' @return A landscape object with pattern "spots" containing:
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "spots"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @examples
#' # Default spots (random placement)
#' spots_default <- create_landscape_spots()
#'
#' # More spots with random size variation
#' spots_modified <- create_landscape_spots(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   spot_radius_sd = 2
#' )
#'
#' # Regular hexagonal arrangement with slight jitter
#' spots_regular <- create_landscape_spots(
#'   n_spots = 12,
#'   spot_radius = 10,
#'   regular_spots = TRUE
#' )
#'
#' # Gradual edges using radius noise fraction
#' spots_gradual <- create_landscape_spots(
#'   n_spots = 10,
#'   spot_radius = 12,
#'   radius_noise_fraction = 0.3
#' )
#'
#' # Inverted (bare patches in vegetated ground)
#' spots_inverted <- create_landscape_spots(
#'   n_spots = 15,
#'   spot_radius = 8,
#'   invert_landscape = TRUE
#' )
#'
#' @importFrom stats kmeans rnorm runif
#' @importFrom cli cli_alert_warning
#' @export
create_landscape_spots <- function(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  invert_landscape = FALSE,
  regular_spots = FALSE
) {
  # Validate common parameters
  validate_dimensions(width = width, height = height)

  n_spots <- as.integer(n_spots)
  # Validate n_spots
  if (!is.numeric(n_spots) || n_spots < 1) {
    cli::cli_abort(c(
      "{.arg n_spots} must be a positive integer.",
      "x" = "You supplied {.val {n_spots}}"
    ))
  }

  # Validate spot_radius
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

  # Validate spot_radius_sd
  if (!is.numeric(spot_radius_sd) || spot_radius_sd < 0) {
    cli::cli_abort(c(
      "{.arg spot_radius_sd} must be a non-negative number.",
      "x" = "You supplied {.val {spot_radius_sd}}"
    ))
  }

  # Validate radius_noise_fraction
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

  # Validate invert_landscape
  if (!is.logical(invert_landscape) || length(invert_landscape) != 1) {
    cli::cli_abort(c(
      "{.arg invert_landscape} must be a single logical value (TRUE or FALSE).",
      "x" = "You supplied {.val {invert_landscape}}"
    ))
  }

  # Validate regular_spots
  if (!is.logical(regular_spots) || length(regular_spots) != 1) {
    cli::cli_abort(c(
      "{.arg regular_spots} must be a single logical value (TRUE or FALSE).",
      "x" = "You supplied {.val {regular_spots}}"
    ))
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
      cli::cli_warn(c(
        "Regular spot placement requested {n_spots} spots but only ~{n_available} positions fit.",
        "i" = " Adjusting to maximum feasible spots. Consider decreasing {.arg spot_radius}."
      ))
      n_spots <- n_available
    }

    # Use k-means for subset selection
    if (n_spots < n_available) {
      # Suppress convergence warnings from kmeans - these are expected
      # and don't affect quality
      km <- suppressWarnings(
        stats::kmeans(grid_points, centers = n_spots, nstart = 5, iter.max = 50)
      )
      cluster_centers <- as.data.frame(km$centers)
    } else {
      cluster_centers <- grid_points
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

  # Prepare landscape
  mat <- matrix(0, nrow = height, ncol = width)

  # Create clusters around centers
  for (i in seq_len(nrow(cluster_centers))) {
    center_row <- cluster_centers$row[i]
    center_col <- cluster_centers$col[i]

    # Apply radius variation
    if (spot_radius_sd > 0) {
      adjusted_radius <- max(
        1,
        spot_radius + stats::rnorm(1, 0, spot_radius_sd)
      )
    } else {
      adjusted_radius <- spot_radius
    }

    # Determine pixel boundaries
    row_min <- max(1, floor(center_row - adjusted_radius))
    row_max <- min(height, ceiling(center_row + adjusted_radius))
    col_min <- max(1, floor(center_col - adjusted_radius))
    col_max <- min(width, ceiling(center_col + adjusted_radius))

    # Fill circular spots
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

  # Invert landscape if specified
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
      spot_radius_sd = spot_radius_sd,
      radius_noise_fraction = radius_noise_fraction,
      regular_spots = regular_spots
    )
  )
}
