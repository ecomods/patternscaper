#' Create a Landscape with Specified Pattern
#'
#' A generic function that creates various types of landscape matrices using
#' specialized functions. The type of landscape is determined by the 'pattern'
#' parameter.
#'
#' @param pattern Character. Type of landscape to generate: "sharp", "diffuse",
#'        "curvy", "fingers", "scattered", "sine_bands", "clusters"
#' @param ... Parameters passed to specific landscape functions. See the documentation
#'        of the individual functions for details on required and optional parameters.
#' @param add_metadata Logical. Whether to include metadata in output (default: TRUE).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata)
#'
#' @seealso
#' \code{\link{create_landscape_sharp_treeline}} for "sharp" pattern parameters
#'
#' \code{\link{create_landscape_diffuse_treeline}} for "diffuse" pattern parameters
#'
#' \code{\link{create_landscape_curvy_treeline}} for "curvy" pattern parameters
#'
#' \code{\link{create_landscape_fingers}} for "fingers" pattern parameters
#'
#' \code{\link{create_landscape_scattered_trees}} for "scattered" pattern parameters
#'
#' \code{\link{create_landscape_clustered_trees}} for "clusters" pattern parameters
#'
#' \code{\link{create_landscape_sine_bands}} for "sine_bands" pattern parameters
#'
#' \code{\link{create_landscape_spots}} for "spots" pattern parameters
#'
#' \code{\link{create_landscape_banded}} for "banded" pattern parameters
#'
#'\code{\link{create_landscape_labyrinth}} for "labyrinth" pattern parameters
#'
#' @examples
#' # Create a default landscape of various types
#' sharp_default <- create_landscape("sharp")
#' diffuse_default <- create_landscape("diffuse")
#' clustered_default <- create_landscape("clustered")
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
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "scattered",
    "clustered",
    "sine_bands",
    "spots",
    "gaps",
    "banded",
    "labyrinth"
  ),
  ...,
  add_metadata = TRUE
) {
  # Define valid patterns
  valid_patterns <- eval(formals()$pattern)

  # Check if pattern is a valid string
  if (!is.character(pattern)) {
    stop("'pattern' must be a character string")
  }

  # Try to match the pattern argument with partial matching
  matched <- NULL
  matches <- grep(paste0("^", pattern), valid_patterns, value = TRUE)

  if (length(matches) == 1) {
    # One match - use it with a warning if it's partial
    if (matches != pattern) {
      warning("Partial pattern '", pattern, "' matched to '", matches, "'")
    }
    matched <- matches
  } else if (length(matches) > 1) {
    # Multiple matches - provide informative error
    stop(
      "Ambiguous pattern '",
      pattern,
      "'. Matches multiple options: ",
      paste(matches, collapse = ", ")
    )
  } else {
    # No matches
    stop(
      "Invalid pattern '",
      pattern,
      "'. Valid options are: ",
      paste(valid_patterns, collapse = ", ")
    )
  }

  # Extract the dots arguments
  dots <- list(...)
  # Add the add_metadata parameter if it's not already in dots
  if (!"add_metadata" %in% names(dots)) {
    dots$add_metadata <- add_metadata
  }

  # Call the appropriate function based on the pattern with metadata parameter
  landscape <- switch(
    matched,
    sharp = do.call(create_landscape_sharp_treeline, dots),
    diffuse = do.call(create_landscape_diffuse_treeline, dots),
    curvy = do.call(create_landscape_curvy_treeline, dots),
    fingers = do.call(create_landscape_fingers, dots),
    scattered = do.call(create_landscape_scattered_trees, dots),
    clustered = do.call(create_landscape_clustered_trees, dots),
    sine_bands = do.call(create_landscape_sine_bands, dots),
    spots = do.call(create_landscape_spots, dots),
    gaps = do.call(create_landscape_gaps, dots),
    banded = do.call(create_landscape_banded, dots),
    labyrinth = do.call(create_landscape_labyrinth, dots)
  )

  # Check if landscape was created successfully
  if (is.null(landscape)) {
    stop(
      "Failed to create landscape with pattern '",
      matched,
      "'. Check that all required parameters are provided."
    )
  }

  # If we didn't get metadata but need it, add it here
  if (add_metadata && !is.list(landscape)) {
    landscape <- list(
      landscape = landscape,
      type = matched,
      params = dots[setdiff(names(dots), "add_metadata")] # Exclude add_metadata from params
    )
  }

  return(landscape)
}


#' Generate Training Landscapes
#'
#' Generates a series of landscape models with variations for training purposes.
#' Creates a total of n landscapes distributed across different landscape types.
#'
#' @param n Integer. Total number of landscapes to generate (default: 50).
#' @param types Character vector. Types of landscapes to sample from (default: all types).
#' @param width Integer. Width of all landscapes in pixels (default: 100).
#' @param height Integer. Height of all landscapes in pixels (default: 100).
#' @param add_rotation Logical. Whether to include rotated versions (default: TRUE).
#' @param rotation_angles Numeric vector. Rotation angles in degrees (default: c(0, 45, 90, 135)).
#' @param params_list List. List of parameter ranges for each landscape type (default: NULL).
#' @param seed Integer or NULL. Random seed for reproducibility (default: 42).
#'   If NULL, a random seed based on system time will be used, producing different landscapes on each call.
#'   If a specific integer is provided, the same landscape will be generated on repeated calls with that seed.
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param type_probs Numeric vector. Probability that a specific landscape type is chosen.
#'     By default, all types have equal probability (1) of being chosen.
#'     Must be the same length as 'types' (default NULL which means equal probability).
#' @param balance_types Logical. If TRUE, ensures all landscape types appear approximately equally.
#'     This overrides type_probs unless it's explicitly set. (default: TRUE)
#'
#' @return List. Named list of n generated landscapes with attributes for type and parameters.
#' @export
generate_training_landscapes <- function(
  n = 50,
  types = c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
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
  seed = 42,
  crs = NULL,
  type_probs = NULL,
  balance_types = TRUE
) {
  # Validate inputs
  if (!is.numeric(n) || n < 1) {
    stop("'n' must be a positive integer")
  }

  # Filter out invalid types
  valid_types <- c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "scattered",
    "clustered",
    "sine_bands",
    "spots",
    "gaps",
    "banded",
    "labyrinth"
  )
  types <- intersect(types, valid_types)

  if (length(types) == 0) {
    stop("No valid landscape types specified")
  }

  # Set seed for reproducibility
  # If seed is NULL, use the current time
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  }
  set.seed(seed)

  # Set default parameter ranges if not provided
  if (is.null(params_list)) {
    params_list <- list(
      sharp = list(
        treeline_position = c(0.2, 0.8)
      ),
      diffuse = list(
        steepness = c(0.1, 3),
        treeline_position = c(0.1, 0.4),
        seed = seed
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
      scattered = list(
        treeline_position = c(0.4, 0.6),
        scatter_density = c(0.1, 0.8),
        scatter_zone_prop = c(0.1, 0.4),
        seed = seed
      ),
      clustered = list(
        treeline_position = c(0.4, 0.6), # numeric
        num_clusters = c(5, 15), # integer
        cluster_radius = c(3, 7), # integer
        scatter_zone_prop = c(0.2, 1), # numeric
        elongation_x = c(0.5, 1.5), # numeric
        elongation_y = c(0.5, 1.5), # numeric
        seed = seed
      ),
      sine_bands = list(
        treeline_position = c(0.3, 0.5), # numeric
        band_zone_prop = c(0.2, 0.5), # numeric
        band_thickness = c(2, 7), #integer
        band_spacing = c(5, 15), #integer
        frequency = c(0.1, 0.3), # numeric
        amplitude = c(0, 6), # integer
        noise_sd = c(0, 1.5), # numeric
        seed = seed
      ),
      spots = list(
        n_spots = c(10, 30), # integer
        spot_radius = c(5, 12), # integer
        noise_radius_sd = c(0, 2), # numeric
        regular_spots = c(TRUE, FALSE), #Bool
        invert_landscape = c(FALSE),
        seed = seed
      ),
      gaps = list(
        n_spots = c(10, 30), # integer
        spot_radius = c(5, 12), # integer
        noise_radius_sd = c(0, 2), # numeric
        regular_spots = c(TRUE, FALSE), #Bool
        invert_landscape = c(TRUE),
        seed = seed
      ),
      banded = list(
        # parameter ranges are given in test_landscape_values_BT.R - sampling has to be changed
        nbands = c(3, 10),
        noise_sd = c(0, 0.25),
        seed = seed
      ),
      labyrinth = list(
        frequency = c(2, 5), # integer
        veg_threshold = c(0.4, 0.5), # numeric
        band_fuzziness = c(0, 0.1), #numeric
        octaves = c(1, 3), #integer
        seed = seed
      )
    )
  }

  # Ensure all selected types have parameter ranges
  for (type in types) {
    if (!(type %in% names(params_list))) {
      warning(
        "Type '",
        type,
        "' not found in params_list. Using default parameters."
      )
      # Add default parameters for missing types
      params_list[[type]] <- list(treeline_position = c(0.3, 0.7))
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

  # Determine how to distribute landscape types
  if (balance_types) {
    # Calculate how many of each type to generate
    num_types <- length(types)
    landscapes_per_type <- floor(n / num_types)
    extras <- n - (landscapes_per_type * num_types)

    # Create balanced distribution
    sampled_types <- rep(types, each = landscapes_per_type)

    # Distribute any remaining landscapes randomly
    if (extras > 0) {
      extra_types <- sample(types, extras, replace = TRUE)
      sampled_types <- c(sampled_types, extra_types)
    }

    # Shuffle the types to avoid patterns
    sampled_types <- sample(sampled_types)
  } else {
    # Setup type weights for sampling
    if (is.null(type_probs)) {
      type_probs <- rep(1, length(types))
    } else if (length(type_probs) != length(types)) {
      warning(
        "Length of type_probs doesn't match length of types. Using equal weights."
      )
      type_probs <- rep(1, length(types))
    }
    # Use weighted sampling as before
    sampled_types <- sample(
      types,
      size = n,
      replace = TRUE,
      prob = type_probs
    )
  }

  # Generate each landscape
  for (i in 1:n) {
    type <- sampled_types[i]
    rotation <- sampled_rotations[i]

    # Get parameter ranges for this type
    type_params <- params_list[[type]]

    # Sample parameter values from ranges
    sampled_params <- list()
    for (param_name in names(type_params)) {
      param_range <- type_params[[param_name]]
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
    sampled_params$crs <- crs
    sampled_params$add_metadata <- FALSE

    # Generate the landscape
    tryCatch(
      {
        landscape <- do.call(
          create_landscape,
          c(list(pattern = type), sampled_params)
        )

        # Store landscape with metadata as a structured list
        all_landscapes[[i]] <- list(
          landscape = landscape,
          type = type,
          params = sampled_params
        )

        # Set list name
        names(all_landscapes)[i] <- paste0(
          type,
          "_",
          i,
          if (rotation != 0) paste0("_rot", rotation) else ""
        )
      },
      error = function(e) {
        warning(
          "Error generating landscape ",
          i,
          " of type '",
          type,
          "': ",
          e$message
        )
        # Return NULL for this landscape (will be filtered out later)
        all_landscapes[[i]] <- NULL
      }
    )
  }

  # Remove any NULL entries (from errors)
  all_landscapes <- all_landscapes[!sapply(all_landscapes, is.null)]

  return(all_landscapes)
}
