#' Create a Landscape with Specified Pattern
#'
#' A generic function that creates various types of landscape matrices using
#' specialized functions. The type of landscape is determined by the 'pattern'
#' parameter.
#'
#' @param pattern Character. Type of landscape to generate: "sharp", "diffuse",
#'        "curvy", "fingers", "bent_fingers", "scattered", "sine_bands", "clusters"
#' @param ... Parameters passed to specific landscape functions. See the documentation
#'        of the individual functions for details on required and optional parameters.
#'
#' @return SpatRaster. Generated landscape of specified pattern.
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
#' \code{\link{create_landscape_bent_fingers}} for "bent_fingers" pattern parameters
#'
#' \code{\link{create_landscape_scattered_trees}} for "scattered" pattern parameters
#'
#' \code{\link{create_landscape_clustered_trees}} for "clusters" pattern parameters
#'
#' \code{\link{create_landscape_sine_bands}} for "sine_bands" pattern parameters
#'
#' @examples
#' # Create a sharp treeline landscape
#' sharp_landscape <- create_landscape("sharp", width = 200, height = 200)
#'
#' # Create a landscape with fingers
#' fingers_landscape <- create_landscape(
#'   "fingers",
#'   width = 150,
#'   height = 150,
#'   num_fingers = 7,
#'   finger_width = 5
#' )
#'
#' @export
create_landscape <- function(
  pattern = c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "bent_fingers",
    "scattered",
    "clustered",
    "sine_bands"
  ),
  ...
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

  # Call the appropriate function based on the pattern
  landscape <- switch(
    matched,
    sharp = create_landscape_sharp_treeline(...),
    diffuse = create_landscape_diffuse_treeline(...),
    curvy = create_landscape_curvy_treeline(...),
    fingers = create_landscape_fingers(...),
    bent_fingers = create_landscape_bent_fingers(...),
    scattered = create_landscape_scattered_trees(...),
    clustered = create_landscape_clustered_trees(...),
    sine_bands = create_landscape_sine_bands(...)
  )

  # Check if landscape was created successfully
  if (is.null(landscape)) {
    stop(
      "Failed to create landscape with pattern '",
      matched,
      "'. Check that all required parameters are provided."
    )
  }

  return(landscape)
}


#' Generate Training Landscapes
#'
#' Generates a series of landscape models with variations for training purposes.
#' Creates a total of n landscapes distributed across different landscape types.
#'
#' @param n Integer. Total number of landscapes to generate (default: 10).
#' @param types Character vector. Types of landscapes to sample from (default: all types).
#' @param width Integer. Width of all landscapes in pixels (default: 100).
#' @param height Integer. Height of all landscapes in pixels (default: 100).
#' @param add_rotation Logical. Whether to include rotated versions (default: TRUE).
#' @param rotation_angles Numeric vector. Rotation angles in degrees (default: c(0, 45, 90, 135)).
#' @param params_list List. List of parameter ranges for each landscape type (default: NULL).
#' @param seed Integer. Random seed for reproducibility (default: 123).
#' @param crs Character. Coordinate reference system (default: NULL).
#' @param type_weights Numeric vector. Relative weights for sampling landscape types (default: NULL).
#'
#' @return List. Named list of n generated landscapes with attributes for type and parameters.
#' @export
generate_training_landscapes <- function(
  n = 10,
  types = c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "bent_fingers",
    "scattered",
    "clustered",
    "sine_bands"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = c(0, 45, 90, 135),
  params_list = NULL,
  seed = NULL,
  crs = NULL,
  type_weights = NULL
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
    "bent_fingers",
    "scattered",
    "clustered",
    "sine_bands"
  )
  types <- intersect(types, valid_types)

  if (length(types) == 0) {
    stop("No valid landscape types specified")
  }

  # Set seed for reproducibility
  # If seed is NULL, use the current time
  if (is.null(seed)) {
    seed <- as.integer(Sys.time())
  } else if (!is.numeric(seed) || length(seed) != 1 || seed < 0) {
    stop("'seed' must be a non-negative integer")
  }
  set.seed(seed)

  # Create default parameter ranges if not provided
  if (is.null(params_list)) {
    params_list <- list(
      sharp = list(
        treeline_position = c(0.3, 0.7)
      ),
      diffuse = list(
        steepness = c(1, 4)
      ),
      curvy = list(
        treeline_position = c(0.3, 0.7),
        sine_length = c(10, 40),
        sine_height = c(3, 10)
      ),
      fingers = list(
        treeline_position = c(0.3, 0.7),
        num_fingers = c(3, 8),
        finger_width = c(2, 6),
        finger_length_prop = c(0.1, 0.4)
      ),
      bent_fingers = list(
        treeline_position = c(0.3, 0.7),
        num_fingers = c(3, 8),
        finger_width = c(2, 6),
        finger_length_prop = c(0.1, 0.4),
        bend_factor = c(1, 5)
      ),
      scattered = list(
        treeline_position = c(0.3, 0.7),
        scatter_density = c(0.05, 0.3),
        scatter_zone_prop = c(0.3, 0.7)
      ),
      clustered = list(
        treeline_position = c(0.3, 0.7),
        num_clusters = c(3, 10),
        cluster_radius = c(3, 10),
        scatter_zone_prop = c(0.3, 0.7)
      ),
      sine_bands = list(
        treeline_position = c(0.3, 0.7),
        band_thickness = c(1, 5),
        band_spacing = c(5, 15),
        frequency = c(0.01, 0.1),
        amplitude = c(2, 10),
        noise = c(TRUE, FALSE)
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

  # Setup type weights for sampling
  if (is.null(type_weights)) {
    type_weights <- rep(1, length(types))
  } else if (length(type_weights) != length(types)) {
    warning(
      "Length of type_weights doesn't match length of types. Using equal weights."
    )
    type_weights <- rep(1, length(types))
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

  # Sample the landscape types
  sampled_types <- sample(
    types,
    size = n,
    replace = TRUE,
    prob = type_weights
  )

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
