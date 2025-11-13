#' Create a Landscape with Specified Pattern
#'
#' A generic function that creates various patterns of landscape matrices using
#' specialized functions. The pattern of landscape is determined by the 'pattern'
#' parameter.
#'
#' @param pattern Character. pattern of landscape to generate: "random", "sharp", "diffuse",
#'        "curvy", "fingers", "curvyfingers", "scattered", "sine_bands", "clusters", "spots", "gaps",
#'        "banded", "labyrinth"
#' @param name Character. Optional name for the landscape (default: NULL).
#' @param custom_pattern Character. Optional pattern for the landscape (default: NULL uses the default
#'     pattern of the corresponding function).
#' @param ... Parameters passed to specific landscape functions. See the documentation
#'        of the individual functions for details on required and optional parameters.
#'
#' @return A landscape object with pattern corresponding to the pattern pattern, containing
#'   the generated landscape data and parameters.
#'
#' @seealso
#' \code{\link{create_landscape_random}} for "random" pattern parameters
#'
#' \code{\link{create_landscape_sharp_treeline}} for "sharp" pattern parameters
#'
#' \code{\link{create_landscape_diffuse_treeline}} for "diffuse" pattern parameters
#'
#' \code{\link{create_landscape_curvy_treeline}} for "curvy" pattern parameters
#'
#' \code{\link{create_landscape_fingers}} for "fingers" pattern parameters
#'
#' \code{\link{create_landscape_curvyfingers}} for "curvyfingers" pattern parameters
#'
#' \code{\link{create_landscape_scattered_trees}} for "scattered" pattern parameters
#'
#' \code{\link{create_landscape_clustered_trees}} for "clusters" pattern parameters
#'
#' \code{\link{create_landscape_sine_bands}} for "sine_bands" pattern parameters
#'
#' \code{\link{create_landscape_spots}} for "spots" pattern parameters
#'
#' \code{\link{create_landscape_gaps}} for "gaps" pattern parameters
#'
#' \code{\link{create_landscape_banded}} for "banded" pattern parameters
#'
#' \code{\link{create_landscape_labyrinth}} for "labyrinth" pattern parameters
#'
#' @examples
#' # Create a default landscape of various patterns
#' random_default <- create_landscape("random")
#' sharp_default <- create_landscape("sharp")
#' diffuse_default <- create_landscape("diffuse")
#' clustered_default <- create_landscape("clustered")
#'
#' # Create a modified landscape with custom parameters
#' random_modified <- create_landscape(
#'   "random",
#'   tree_prop = 0.3
#' )
#'
#' # Create a modified landscape with custom parameters
#' scattered_modified <- create_landscape(
#'   "scattered",
#'   treeline_position = 0.3,
#'   scatter_density = 0.7,
#'   scatter_zone_prop = 0.2
#' )
#'
#' # Create a rotated landscape
#' sine_bands_rotated <- create_landscape(
#'   "sine_bands",
#'   band_thickness = 4,
#'   band_spacing = 12,
#'   amplitude = 6,
#'   noise_sd = 2,
#'   rotation = 45
#' )
#'
#' @export
create_landscape <- function(
  pattern = c(
    "random",
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "curvyfingers",
    "scattered",
    "clustered",
    "sine_bands",
    "spots",
    "gaps",
    "banded",
    "labyrinth"
  ),
  name = NULL,
  custom_pattern = NULL,
  ...
) {
  # Define valid patterns
  valid_patterns <- eval(formals()$pattern)

  # Check if pattern is a valid string
  if (!is.character(pattern) || length(pattern) != 1) {
    cli::cli_abort("'pattern' must be a single character string")
  }

  # Check for exact match first
  if (pattern %in% valid_patterns) {
    matched <- pattern
  } else {
    cli::cli_abort(c(
      "Invalid pattern '{pattern}'",
      "i" = "Valid options are: {paste(valid_patterns, collapse = ', ')}"
    ))
  }

  # Validate the name parameter
  if (!is.null(name)) {
    if (!is.character(name) || length(name) != 1) {
      cli::cli_abort("'name' must be a single character string or NULL")
    }
  }

  # Call the appropriate function based on the pattern
  landscape <- switch(
    matched,
    random = create_landscape_random(...),
    sharp = create_landscape_sharp_treeline(...),
    diffuse = create_landscape_diffuse_treeline(...),
    curvy = create_landscape_curvy_treeline(...),
    fingers = create_landscape_fingers(...),
    curvyfingers = create_landscape_curvyfingers(...),
    scattered = create_landscape_scattered_trees(...),
    clustered = create_landscape_clustered_trees(...),
    sine_bands = create_landscape_sine_bands(...),
    spots = create_landscape_spots(...),
    gaps = create_landscape_gaps(...),
    banded = create_landscape_banded(...),
    labyrinth = create_landscape_labyrinth(...)
  )

  # Set the name if provided
  if (!is.null(name)) {
    landscape <- set_landscape_name(landscape, name)
  }
  # Set a pattern different from the default if requested
  if (!is.null(custom_pattern)) {
    landscape <- set_landscape_pattern(landscape, custom_pattern)
  }

  return(landscape)
}


#' Create Training Landscapes
#'
#' Create a series of landscape models with variations for training purposes.
#' Creates a total of n landscapes distributed across different landscape patterns.
#'
#' @param n Integer. Total number of landscapes to create (default: 50).
#' @param patterns Character vector. patterns of landscapes to sample from (default: all patterns).
#' @param width Integer. Width of all landscapes in pixels (default: 100).
#' @param height Integer. Height of all landscapes in pixels (default: 100).
#' @param add_rotation Logical. Whether to include rotated versions (default: TRUE).
#' @param rotation_angles Numeric vector. Rotation angles in degrees (default: c(0, 45, 90, 135)).
#' @param params_list List. List of parameter ranges for each landscape pattern (default: NULL).
#' @param pattern_probs Numeric vector. Probability that a specific landscape pattern is chosen.
#'     By default, all patterns have equal probability (1) of being chosen.
#'     Must be the same length as 'patterns' (default NULL which means equal probability).
#' @param balance_patterns Logical. If TRUE, ensures all landscape patterns appear approximately equally.
#'     This overrides pattern_probs unless it's explicitly set. (default: TRUE)
#'
#' @return A named list of landscape objects. Names indicate the pattern and optional rotation.
#'
#' @examples
#' # Generate 20 training landscapes
#' landscapes <- create_training_landscapes(n = 20)
#'
#' # Access a landscape
#' landscapes[[1]]
#'
#' # Check the pattern
#' landscapes[[1]]$pattern
#'
#' # Get all landscape patterns
#' sapply(landscapes, function(x) x$pattern)
#'
#' @export
create_training_landscapes <- function(
  n = 50,
  patterns = c(
    "random",
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "curvyfingers",
    "scattered",
    "clustered",
    "sine_bands",
    "spots",
    "gaps",
    "banded",
    "labyrinth"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = c(0, 45, 90, 135),
  params_list = NULL,
  pattern_probs = NULL,
  balance_patterns = TRUE
) {
  # Validate inputs
  if (!is.numeric(n) || n < 1) {
    stop("'n' must be a positive integer")
  }

  # Filter out invalid patterns
  valid_patterns <- c(
    "random",
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "curvyfingers",
    "scattered",
    "clustered",
    "sine_bands",
    "spots",
    "gaps",
    "banded",
    "labyrinth"
  )
  patterns <- intersect(patterns, valid_patterns)

  if (length(patterns) == 0) {
    stop("No valid landscape patterns specified")
  }

  # Set default parameter ranges if not provided
  if (is.null(params_list)) {
    params_list <- list(
      random = list(
        tree_prop = c(0.1, 0.9)
      ),
      sharp = list(
        treeline_position = c(0.2, 0.8)
      ),
      diffuse = list(
        steepness = c(0.1, 1),
        treeline_position = c(0.1, 0.4)
      ),
      curvy = list(
        treeline_position = c(0.3, 0.6),
        sine_length = c(0.2 * width, 0.4 * width),
        sine_height = c(0.03 * height, 0.2 * height)
      ),
      fingers = list(
        treeline_position = c(0.3, 0.6),
        num_fingers = c(3, 8),
        finger_width = c(0.03 * width, 0.1 * width),
        finger_length_prop = c(0.3, 1),
        finger_length_sd = c(0, 0.6),
        bend = c(TRUE, FALSE)
      ),
      curvyfingers = list(
        treeline_position = c(0.3, 0.6),
        sine_length_mean = c(0.2 * width, 0.4 * width),
        sine_length_sd = c(0, 0.6 * width),
        sine_height_mean = c(0.03 * height, 0.2 * height),
        sine_height_mean = c(0, 0.3 * height)
      ),
      scattered = list(
        treeline_position = c(0.4, 0.6),
        scatter_density = c(0.1, 0.8),
        scatter_zone_prop = c(0.1, 0.4)
      ),
      clustered = list(
        treeline_position = c(0.4, 0.6), # numeric
        num_clusters = c(5, 15), # integer
        cluster_radius = c(3, 7), # integer
        scatter_zone_prop = c(0.2, 1), # numeric
        elongation_x = c(0.5, 1.5), # numeric
        elongation_y = c(0.5, 1.5) # numeric
      ),
      sine_bands = list(
        treeline_position = c(0.3, 0.5), # numeric
        band_zone_prop = c(0.2, 0.5), # numeric
        band_thickness = c(2, 7), #integer
        band_spacing = c(5, 15), #integer
        frequency = c(0.1, 0.3), # numeric
        amplitude = c(0, 6), # integer
        noise_sd = c(0, 1.5) # numeric
      ),
      spots = list(
        n_spots = c(10, 30), # integer
        spot_radius = c(5, 12), # integer
        noise_radius_sd = c(0, 2), # numeric
        regular_spots = c(TRUE, FALSE), #Bool
        invert_landscape = c(FALSE)
      ),
      gaps = list(
        n_spots = c(10, 30), # integer
        spot_radius = c(5, 12), # integer
        noise_radius_sd = c(0, 2), # numeric
        regular_spots = c(TRUE, FALSE), #Bool
        invert_landscape = c(TRUE)
      ),
      banded = list(
        nhills = c(1, 5), #integer
        nbands = c(3, 8), #integer
        regular_hilltop = c(TRUE, FALSE), #Bool
        top_elevation_mean = c(25, 35),
        top_elevation_sd = c(0, 3),
        x_ext_hill_sd = c(0, 0.5),
        y_ext_hill_sd = c(0, 0.5),
        noise_sd = c(0, 0.25)
      ),
      labyrinth = list(
        frequency = c(2, 5), # integer
        veg_threshold = c(0.4, 0.5), # numeric
        band_fuzziness = c(0, 0.1), #numeric
        octaves = c(1, 3) #integer
      )
    )
  }

  # Ensure all selected patterns have parameter ranges
  for (pattern in patterns) {
    if (!(pattern %in% names(params_list))) {
      warning(
        "Pattern '",
        pattern,
        "' not found in params_list. Using default parameters."
      )
      # Add default parameters for missing pattern
      params_list[[pattern]] <- list(treeline_position = c(0.3, 0.7))
    }
  }

  # Initialize results list
  all_landscapes <- list()

  # Sample the rotation angles if add_rotation is TRUE
  if (add_rotation) {
    # Each landscape gets a random rotation from rotation_angles
    sampled_rotations <- sample(rotation_angles, n, replace = TRUE)
  } else {
    # All landscapes have 0 rotation
    sampled_rotations <- rep(0, n)
  }

  # Determine how to distribute landscape patterns
  if (balance_patterns) {
    # Calculate how many of each pattern to generate
    num_patterns <- length(patterns)
    landscapes_per_pattern <- floor(n / num_patterns)
    extras <- n - (landscapes_per_pattern * num_patterns)

    # Create balanced distribution
    sampled_patterns <- rep(patterns, each = landscapes_per_pattern)

    # Distribute any remaining landscapes randomly
    if (extras > 0) {
      extra_patterns <- sample(patterns, extras, replace = TRUE)
      sampled_patterns <- c(sampled_patterns, extra_patterns)
    }

    # Shuffle the patterns to avoid patterns
    sampled_patterns <- sample(sampled_patterns)
  } else {
    # Setup pattern weights for sampling
    if (is.null(pattern_probs)) {
      pattern_probs <- rep(1, length(patterns))
    } else if (length(pattern_probs) != length(patterns)) {
      warning(
        "Length of pattern_probs doesn't match length of patterns. Using equal weights."
      )
      pattern_probs <- rep(1, length(patterns))
    }
    # Use weighted sampling as before
    sampled_patterns <- sample(
      patterns,
      size = n,
      replace = TRUE,
      prob = pattern_probs
    )
  }

  # Generate each landscape
  for (i in 1:n) {
    pattern <- sampled_patterns[i]
    rotation <- sampled_rotations[i]

    # Get parameter ranges for this pattern
    pattern_params <- params_list[[pattern]]

    # Sample parameter values from ranges
    sampled_params <- list()
    for (param_name in names(pattern_params)) {
      param_range <- pattern_params[[param_name]]
      if (is.logical(param_range)) {
        # For logical parameters, randomly choose TRUE or FALSE
        sampled_params[[param_name]] <- sample(param_range, 1)
      } else if (length(param_range) == 1) {
        # For single values, use as is
        sampled_params[[param_name]] <- param_range
      } else {
        # For numeric ranges, sample uniformly
        sampled_params[[param_name]] <- runif(
          1,
          min = param_range[1],
          max = param_range[2]
        )
      }
    }

    # Add common parameters
    sampled_params$width <- width
    sampled_params$height <- height
    sampled_params$rotation <- rotation

    # Generate the landscape
    tryCatch(
      {
        landscape <- do.call(
          create_landscape,
          c(list(pattern = pattern), sampled_params)
        )

        # Set descriptive name
        landscape_name <- paste0(
          pattern,
          "_",
          i,
          if (rotation != 0) paste0("_rot", rotation) else ""
        )
        landscape <- set_landscape_name(landscape, landscape_name)

        # Store the landscape object
        all_landscapes[[i]] <- landscape
        names(all_landscapes)[i] <- landscape_name
      },
      error = function(e) {
        warning(
          "Error generating landscape ",
          i,
          " of pattern '",
          pattern,
          "': ",
          e$message
        )
        all_landscapes[[i]] <- NULL
      }
    )
  }

  # Remove any NULL entries (from errors)
  all_landscapes <- all_landscapes[!sapply(all_landscapes, is.null)]

  return(all_landscapes)
}
