#' Create a Landscape with Specified Pattern
#'
#' A generic function that creates various patterns of landscape matrices using
#' specialized functions. The pattern of landscape is determined by the 'pattern'
#' parameter.
#'
#' @param pattern Character. pattern of landscape to generate: "random", "sharp", "diffuse",
#'        "fingers", "bands", "clusters", "spots", "gaps",
#'        "labyrinth"
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
#' \code{\link{create_landscape_random}} for "random" pattern parameters. "bare" and "dense" are aliases but
#'     are produced either with low or high tree probabilities
#'
#' \code{\link{create_landscape_sharp_treeline}} for "sharp" pattern parameters
#'
#' \code{\link{create_landscape_diffuse_treeline}} for "diffuse" pattern parameters
#'
#' \code{\link{create_landscape_fingers}} for "fingers" pattern parameters
#'
#' \code{\link{create_landscape_clustered}} for "clusters" pattern parameters
#'
#' \code{\link{create_landscape_bands}} for "bands" pattern parameters
#'
#' \code{\link{create_landscape_spots}} for "spots" pattern parameters
#'
#' \code{\link{create_landscape_gaps}} for "gaps" pattern parameters
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
#' diffuse_modified <- create_landscape(
#'   "diffuse",
#'   treeline_position = 0.3,
#'   scatter_density = 0.7,
#'   scatter_zone_prop = 0.2
#' )
#'
#' # Create a rotated landscape
#' bands_rotated <- create_landscape(
#'   "bands",
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
    "bare",
    "dense",
    "sharp",
    "diffuse",
    "fingers",
    "clustered",
    "bands",
    "spots",
    "gaps",
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
    bare = create_landscape_bare(...),
    dense = create_landscape_dense(...),
    sharp = create_landscape_sharp_treeline(...),
    diffuse = create_landscape_diffuse_treeline(...),
    fingers = create_landscape_fingers(...),
    clustered = create_landscape_clustered(...),
    bands = create_landscape_bands(...),
    spots = create_landscape_spots(...),
    gaps = create_landscape_gaps(...),
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
#' @param balance_patterns Logical. If TRUE, ensures all landscape patterns appear approximately equally,
#'     overriding any weights specified in pattern_probs. (default: TRUE)
#' @param max_retries Integer. Maximum number of retries for failed landscape generations (default: 3).
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
    "bare",
    "dense",
    "sharp",
    "diffuse",
    "fingers",
    "clustered",
    "bands",
    "spots",
    "gaps",
    "labyrinth"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = 0:360,
  params_list = NULL,
  pattern_probs = NULL,
  balance_patterns = TRUE,
  max_retries = 3
) {
  # Validate inputs
  if (!is.numeric(n) || length(n) != 1) {
    cli::cli_abort("'n' must be a single numeric value")
  }

  n <- as.integer(n)

  if (is.na(n) || n < 1) {
    cli::cli_abort("'n' must be a positive integer")
  }

  # Validate width and height
  validate_dimensions(width, height)

  # Validate rotation angles
  if (!is.null(rotation_angles)) {
    validate_rotation(rotation_angles)
  }

  # Filter out invalid patterns
  valid_patterns <- c(
    "random",
    "bare",
    "dense",
    "sharp",
    "diffuse",
    "fingers",
    "clustered",
    "bands",
    "spots",
    "gaps",
    "labyrinth"
  )
  patterns <- intersect(patterns, valid_patterns)

  if (length(patterns) == 0) {
    cli::cli_abort("No valid landscape patterns specified")
  }

  # Create full default parameter list
  default_params_list <- list(
    random = list(tree_prop = c(0.1, 0.9)),
    bare = list(tree_prop = c(0, 0.1)),
    dense = list(tree_prop = c(0.8, 1)),
    sharp = list(treeline_position = c(0.2, 0.8)),
    diffuse = list(
      steepness = c(0.1, 1),
      treeline_position = c(0.1, 0.4)
    ),
    fingers = list(
      treeline_position = c(0.3, 0.6),
      sine_length_mean = c(0.3, 0.7) * width,
      sine_length_sd = c(0.05, 0.2) * width,
      sine_height_mean = c(0.05, 0.2) * height,
      sine_height_sd = c(0.02, 0.15) * height
    ),
    clustered = list(
      treeline_position = c(0.4, 0.6),
      n_clusters = c(5, 12),
      cluster_radius = c(5, 10),
      scatter_zone_prop = c(0.2, 1),
      elongation_x = c(0.5, 1.5),
      elongation_y = c(0.5, 1.5)
    ),
    bands = list(
      treeline_position = c(0.3, 0.5),
      band_zone_prop = c(0.3, 0.6),
      band_thickness = c(0.02, 0.04) * height,
      band_spacing = c(0.1, 0.2) * height,
      frequency = c(0.1, 0.3),
      amplitude = c(0, 0.06) * height,
      noise_sd = c(0, 0.01) * height
    ),
    spots = list(
      n_spots = c(5, 10),
      spot_radius = c(0.1, 0.2) * width,
      spot_radius_sd = c(0, 0.02) * width,
      regular_spots = c(TRUE, FALSE),
      invert_landscape = c(FALSE)
    ),
    gaps = list(
      n_spots = c(5, 10),
      spot_radius = c(0.1, 0.2) * width,
      spot_radius_sd = c(0, 0.02) * width,
      regular_spots = c(TRUE, FALSE),
      invert_landscape = c(TRUE)
    ),
    labyrinth = list(
      frequency = c(2, 6),
      veg_threshold = c(0.4, 0.5),
      band_fuzziness = c(0, 0.1),
      octaves = c(1, 6)
    )
  )

  # If user provided params, validate and merge with defaults
  if (!is.null(params_list)) {
    # Validate and clean user-provided params
    params_list <- validate_params_list(params_list, patterns)

    # Merge with defaults
    merged_params <- list()
    for (pattern in patterns) {
      if (pattern %in% names(params_list)) {
        # Start with defaults for this pattern
        merged_params[[pattern]] <- default_params_list[[pattern]]

        # Override with user-specified parameters
        for (param_name in names(params_list[[pattern]])) {
          merged_params[[pattern]][[param_name]] <- params_list[[pattern]][[
            param_name
          ]]
        }
      } else {
        # Pattern missing entirely, use all defaults
        merged_params[[pattern]] <- default_params_list[[pattern]]
      }
    }

    params_list <- merged_params
  } else {
    # No user params, use defaults for all requested patterns
    params_list <- default_params_list[patterns]
  }

  # Initialize results list
  all_landscapes <- list()

  # Define which parameters should be integers so they are not treated
  # as numeric
  integer_params <- c(
    "n_clusters",
    "cluster_radius",
    "band_thickness",
    "band_spacing",
    "n_spots",
    "spot_radius",
    "nhills",
    "nbands",
    "frequency",
    "octaves",
    "amplitude"
  )

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
      cli::cli_alert_warning(
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

  # Define which patterns support rotation
  patterns_with_rotation <- c(
    "sharp",
    "diffuse",
    "fingers",
    "clustered",
    "bands",
    "spots",
    "gaps"
  )

  # Generate each landscape
  for (i in 1:n) {
    pattern <- sampled_patterns[i]
    landscape <- NULL
    retry_count <- 0

    # Retry loop
    while (is.null(landscape) && retry_count <= max_retries) {
      # Sample parameters (new sample each retry)
      sampled_params <- sample_landscape_params(
        params_list[[pattern]],
        integer_params,
        width,
        height
      )

      # Handle rotation for patterns that support it
      if (pattern %in% patterns_with_rotation) {
        rotation <- if (add_rotation) sample(rotation_angles, 1) else 0
        sampled_params$rotation <- rotation
      } else {
        rotation <- 0
      }

      # Attempt to create landscape
      landscape <- try_create_landscape(pattern, sampled_params, i, rotation)

      # Handle failure
      if (is.null(landscape)) {
        if (retry_count < max_retries) {
          cli::cli_alert_info(
            "Retry {retry_count + 1}/{max_retries} for landscape {i} (pattern: {pattern})"
          )
        } else {
          cli::cli_alert_warning(
            "Failed to create landscape {i} (pattern: {pattern}) after {max_retries} retries"
          )
        }
      }

      retry_count <- retry_count + 1
    }

    # Store result (NULL if all retries failed)
    if (!is.null(landscape)) {
      all_landscapes[[i]] <- landscape
      names(all_landscapes)[i] <- landscape$name
    } else {
      all_landscapes[[i]] <- NULL
    }
  }

  n_requested <- n
  n_failed <- sum(sapply(all_landscapes, is.null))
  all_landscapes <- Filter(Negate(is.null), all_landscapes)
  n_actual <- length(all_landscapes)

  if (n_failed > 0) {
    cli::cli_alert_warning(
      "Generated {n_actual}/{n_requested} landscapes ({n_failed} failed)"
    )
  } else {
    cli::cli_alert_success(
      "Successfully generated all {n_requested} training landscapes"
    )
  }

  return(all_landscapes)
}

#' Sample Parameters for Landscape Generation
#'
#' Samples random values from parameter ranges for landscape creation.
#'
#' @param pattern_params List. Parameter ranges for a pattern.
#' @param integer_params Character vector. Names of integer parameters.
#' @param width Integer. Landscape width.
#' @param height Integer. Landscape height.
#'
#' @return List of sampled parameter values.
#'
#' @keywords internal
#' @noRd
sample_landscape_params <- function(
  pattern_params,
  integer_params,
  width,
  height
) {
  sampled_params <- list()

  for (param_name in names(pattern_params)) {
    param_range <- pattern_params[[param_name]]

    if (is.logical(param_range)) {
      sampled_params[[param_name]] <- sample(param_range, 1)
    } else if (length(param_range) == 1) {
      sampled_params[[param_name]] <- param_range
    } else if (param_name %in% integer_params) {
      sampled_params[[param_name]] <- sample(
        seq(from = param_range[1], to = param_range[2], by = 1),
        size = 1
      )
    } else {
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

  sampled_params
}

#' Attempt to Create a Single Landscape
#'
#' Tries to generate a landscape with given parameters, handling errors gracefully.
#'
#' @param pattern Character. Pattern type.
#' @param params List. Parameters for landscape creation.
#' @param index Integer. Landscape index in the sequence.
#' @param rotation Numeric. Rotation angle.
#'
#' @return Landscape object on success, NULL on failure.
#'
#' @keywords internal
#' @noRd
try_create_landscape <- function(pattern, params, index, rotation) {
  tryCatch(
    {
      landscape <- do.call(
        create_landscape,
        c(list(pattern = pattern), params)
      )

      # Set descriptive name
      landscape_name <- paste0(
        pattern,
        "_",
        index,
        if (rotation != 0) paste0("_rot", rotation) else ""
      )
      landscape <- set_landscape_name(landscape, landscape_name)

      landscape
    },
    error = function(e) {
      NULL
    }
  )
}
