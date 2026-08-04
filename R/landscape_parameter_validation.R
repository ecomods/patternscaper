#' Validate Landscape Dimensions
#'
#' Validates width and height parameters common to all landscape generators.
#'
#' @param width Integer. Width of the landscape in pixels.
#' @param height Integer. Height of the landscape in pixels.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_dimensions <- function(width, height) {
  if (!is.numeric(width) || width <= 0 || width != as.integer(width)) {
    cli::cli_abort(c(
      "{.arg width} must be a positive integer.",
      "x" = "You supplied {.val {width}}"
    ))
  }

  if (!is.numeric(height) || height <= 0 || height != as.integer(height)) {
    cli::cli_abort(c(
      "{.arg height} must be a positive integer.",
      "x" = "You supplied {.val {height}}"
    ))
  }

  invisible(NULL)
}

#' Validate Rotation Parameter
#'
#' Validates rotation angle parameter(s).
#'
#' @param rotation Numeric. Angle(s) to rotate landscape in degrees.
#'     Can be a single value or a vector of values.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_rotation <- function(rotation) {
  if (!is.numeric(rotation)) {
    cli::cli_abort(c(
      "{.arg rotation} must be numeric.",
      "x" = "You supplied {.type {rotation}}"
    ))
  }

  if (any(is.na(rotation))) {
    cli::cli_abort(c(
      "{.arg rotation} cannot contain NA values.",
      "x" = "You supplied {.val {rotation}}"
    ))
  }

  if (any(rotation < 0) || any(rotation > 360)) {
    cli::cli_abort(c(
      "{.arg rotation} must be between 0 and 360 degrees.",
      "x" = "You supplied {.val {rotation}}"
    ))
  }

  invisible(NULL)
}

#' Validate Treeline Position Parameter
#'
#' Validates treeline position parameter for treeline-based landscapes.
#'
#' @param boundary_position Numeric. Relative position of treeline from top (0-1).
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_boundary_position <- function(boundary_position) {
  if (
    !is.numeric(boundary_position) ||
      boundary_position < 0 ||
      boundary_position > 1
  ) {
    cli::cli_abort(c(
      "{.arg boundary_position} must be between 0 and 1.",
      "x" = "You supplied {.val {boundary_position}}"
    ))
  }

  invisible(NULL)
}

#' Validate Random Spots Parameter
#'
#' Validates random_spots parameter for landscapes with random cell flipping.
#'
#' @param random_spots Numeric vector of length 2. Probabilities for flipping
#'   cells: [1→0, 0→1].
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_random_spots <- function(random_spots) {
  if (
    !is.numeric(random_spots) ||
      length(random_spots) != 2 ||
      any(random_spots < 0) ||
      any(random_spots > 1)
  ) {
    cli::cli_abort(c(
      "{.arg random_spots} must be a numeric vector of length 2 with values between 0 and 1.",
      "x" = "You supplied {.val {random_spots}}"
    ))
  }

  invisible(NULL)
}

#' Canonical Landscape Parameter Specifications
#'
#' Single source of truth for per-pattern parameter type/bounds and default
#' batch-sampling ranges. \code{\link{get_valid_param_specs}} (validation) and
#' \code{\link{build_default_params_list}} (batch defaults for
#' \code{\link{create_landscapes}}) both derive from this table instead of
#' maintaining separate, independently-drifting copies.
#'
#' @return Named list, keyed by pattern, of named lists of parameter specs.
#'     Each spec has \code{type} ("numeric", "integer", or "logical"),
#'     \code{min}/\code{max} bounds (numeric/integer only), and
#'     \code{batch_range} which is the default range \code{\link{create_landscapes}}
#'     samples from. \code{batch_range} is a literal vector, a
#'     \code{function(width, height)} for ranges that scale with landscape
#'     size, or \code{NULL} if the parameter is validation-only (not part of
#'     the default batch distribution).
#'
#' @keywords internal
#' @noRd
landscape_param_specs <- function() {
  list(
    random = list(
      veg_prop = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.1, 0.9)
      )
    ),
    bare = list(
      veg_prop = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0, 0.1)
      )
    ),
    dense = list(
      veg_prop = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.8, 1)
      )
    ),
    sharp = list(
      boundary_position = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.2, 0.8)
      )
    ),
    diffuse = list(
      steepness = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = c(0.1, 1)
      ),
      boundary_position = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.1, 0.4)
      )
    ),
    fingers = list(
      boundary_position = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.3, 0.6)
      ),
      sine_length_mean = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0.2, 0.5) * width
      ),
      sine_length_sd = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0.1, 0.5) * width
      ),
      sine_height_mean = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0.05, 0.2) * height
      ),
      sine_height_sd = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0.05, 0.25) * height
      )
    ),
    clustered = list(
      boundary_position = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.4, 0.6)
      ),
      n_clusters = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = c(5, 12)
      ),
      cluster_radius = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = c(5, 10)
      ),
      scatter_zone_prop = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.2, 1)
      ),
      elongation_x = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = c(0.5, 1.5)
      ),
      elongation_y = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = c(0.5, 1.5)
      )
    ),
    bands = list(
      boundary_position = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.3, 0.5)
      ),
      band_zone_prop = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.3, 0.6)
      ),
      band_thickness = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = function(width, height) c(0.02, 0.04) * height
      ),
      band_spacing = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = function(width, height) c(0.1, 0.2) * height
      ),
      frequency = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = c(0.1, 0.3)
      ),
      amplitude = list(
        type = "integer",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0, 0.06) * height
      ),
      noise_sd = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0, 0.01) * height
      )
    ),
    spots = list(
      n_spots = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = c(5, 10)
      ),
      spot_radius = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = function(width, height) c(0.1, 0.2) * width
      ),
      spot_radius_sd = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0, 0.02) * width
      ),
      radius_noise_fraction = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = NULL
      ),
      regular_spots = list(type = "logical", batch_range = c(TRUE, FALSE)),
      invert_landscape = list(type = "logical", batch_range = c(FALSE))
    ),
    gaps = list(
      n_spots = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = c(5, 10)
      ),
      spot_radius = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = function(width, height) c(0.1, 0.2) * width
      ),
      spot_radius_sd = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = function(width, height) c(0, 0.02) * width
      ),
      radius_noise_fraction = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = NULL
      ),
      regular_spots = list(type = "logical", batch_range = c(TRUE, FALSE))
    ),
    labyrinth = list(
      frequency = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = c(2.5, 3.5)
      ),
      veg_threshold = list(
        type = "numeric",
        min = 0,
        max = 1,
        batch_range = c(0.45, 0.55)
      ),
      band_fuzziness = list(
        type = "numeric",
        min = 0,
        max = Inf,
        batch_range = c(0.06, 0.25)
      ),
      octaves = list(
        type = "integer",
        min = 1,
        max = Inf,
        batch_range = c(2, 4)
      )
    )
  )
}

#' Get Valid Parameter Specifications
#'
#' Returns specifications for all valid landscape pattern parameters.
#'
#' @return Named list of parameter specifications by pattern.
#'
#' @details
#'     Is used in \code{\link{validate_params_list}} to check that user-supplied
#'     parameters in \code{\link{create_landscapes}} are valid.
#'
#' @keywords internal
#' @noRd
get_valid_param_specs <- function() {
  specs <- landscape_param_specs()

  lapply(specs, function(pattern_specs) {
    lapply(pattern_specs, function(spec) {
      spec$batch_range <- NULL
      spec
    })
  })
}

#' Build Default Batch-Sampling Parameter Ranges
#'
#' Derives \code{\link{create_landscapes}}'s default per-pattern parameter
#' ranges from \code{\link{landscape_param_specs}}, resolving width/height-
#' dependent ranges. Parameters with \code{batch_range = NULL} (validation-only)
#' are excluded, matching \code{\link{create_landscapes}}'s defaults.
#'
#' @param width Integer. Landscape width.
#' @param height Integer. Landscape height.
#'
#' @return Named list, keyed by pattern, of named lists of parameter ranges.
#'
#' @keywords internal
#' @noRd
build_default_params_list <- function(width, height) {
  specs <- landscape_param_specs()

  lapply(specs, function(pattern_specs) {
    pattern_specs <- Filter(
      function(spec) !is.null(spec$batch_range),
      pattern_specs
    )

    lapply(pattern_specs, function(spec) {
      if (is.function(spec$batch_range)) {
        spec$batch_range(width, height)
      } else {
        spec$batch_range
      }
    })
  })
}

#' Get Integer Parameter Names
#'
#' Returns the names of all parameters typed \code{"integer"} across every
#' pattern in \code{\link{landscape_param_specs}}, used by
#' \code{\link{sample_landscape_params}} to sample whole numbers instead of
#' continuous values.
#'
#' @return Character vector of unique parameter names.
#'
#' @keywords internal
#' @noRd
get_integer_param_names <- function() {
  specs <- landscape_param_specs()

  integer_names <- unlist(lapply(specs, function(pattern_specs) {
    names(Filter(function(spec) spec$type == "integer", pattern_specs))
  }))

  unique(integer_names)
}

#' Validate Parameter List Structure
#'
#' Validates that params_list contains valid parameter ranges for each pattern.
#' Removes any unknown parameters with a warning.
#'
#' @param params_list List. Parameter ranges for each landscape pattern.
#' @param patterns Character vector. Patterns to validate.
#'
#' @return List. Cleaned params_list with unknown parameters removed.
#'
#' @keywords internal
#' @noRd
validate_params_list <- function(params_list, patterns) {
  specs <- get_valid_param_specs()
  cleaned_params <- list()

  for (pattern in patterns) {
    if (!pattern %in% names(params_list)) {
      next # Missing patterns will be filled with defaults later
    }

    if (!pattern %in% names(specs)) {
      cli::cli_abort(c(
        "Unknown pattern: {.val {pattern}}",
        "i" = "Valid patterns are: {.val {names(specs)}}"
      ))
    }

    pattern_params <- params_list[[pattern]]
    pattern_specs <- specs[[pattern]]

    if (!is.list(pattern_params)) {
      cli::cli_abort(c(
        "Parameters for pattern {.val {pattern}} must be a list.",
        "x" = "You supplied {.type {pattern_params}}"
      ))
    }

    # Filter to only valid parameters
    cleaned_pattern_params <- list()

    for (param_name in names(pattern_params)) {
      param_value <- pattern_params[[param_name]]

      # Check if parameter is recognized for this pattern
      if (!param_name %in% names(pattern_specs)) {
        cli::cli_alert_warning(
          "Unknown parameter {.val {param_name}} for pattern {.val {pattern}} - will be ignored"
        )
        next # Skip unknown parameter
      }

      spec <- pattern_specs[[param_name]]

      # Validate based on type
      if (spec$type == "logical") {
        validate_logical_param(param_value, param_name, pattern)
      } else if (spec$type == "integer") {
        validate_integer_param(param_value, param_name, pattern, spec)
      } else if (spec$type == "numeric") {
        validate_numeric_param(param_value, param_name, pattern, spec)
      }

      # Keep valid parameter
      cleaned_pattern_params[[param_name]] <- param_value
    }

    cleaned_params[[pattern]] <- cleaned_pattern_params
  }

  cleaned_params
}

#' Validate Logical Parameter
#'
#' Validates that a logical parameter has correct type and length.
#'
#' @param param_value Value provided by user.
#' @param param_name Character. Name of the parameter.
#' @param pattern Character. Name of the pattern.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_logical_param <- function(param_value, param_name, pattern) {
  if (!is.logical(param_value) || any(is.na(param_value))) {
    cli::cli_abort(c(
      "Parameter {.val {param_name}} for pattern {.val {pattern}} must be logical (TRUE/FALSE).",
      "x" = "You supplied {.type {param_value}}"
    ))
  }

  if (length(param_value) == 0 || length(param_value) > 2) {
    cli::cli_abort(c(
      "Parameter {.val {param_name}} for pattern {.val {pattern}} must be length 1 (fixed) or 2 (range).",
      "x" = "You supplied length {length(param_value)}"
    ))
  }

  if (length(param_value) == 2 && param_value[1] == param_value[2]) {
    cli::cli_alert_warning(
      "Parameter {.val {param_name}} for pattern {.val {pattern}} has identical min and max values - consider using a single value instead"
    )
  }

  invisible(NULL)
}

#' Validate Integer Parameter
#'
#' Validates that an integer parameter has correct type, range, and bounds.
#'
#' @param param_value Value provided by user.
#' @param param_name Character. Name of the parameter.
#' @param pattern Character. Name of the pattern.
#' @param spec List. Specification with min and max bounds.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_integer_param <- function(param_value, param_name, pattern, spec) {
  # Single value
  if (length(param_value) == 1) {
    if (!is.numeric(param_value) || is.na(param_value)) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}} must be numeric.",
        "x" = "You supplied {.type {param_value}}"
      ))
    }

    if (param_value %% 1 != 0) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}} must be a whole number.",
        "x" = "You supplied {.val {param_value}}"
      ))
    }

    check_numeric_bounds(param_value, param_name, pattern, spec)
    return(invisible(NULL))
  }

  # Range [min, max]
  if (length(param_value) == 2) {
    if (!is.numeric(param_value) || any(is.na(param_value))) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}} must be numeric.",
        "x" = "You supplied {.type {param_value}}"
      ))
    }

    if (any(param_value %% 1 != 0)) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}} must be whole numbers.",
        "x" = "You supplied {.val {param_value}}"
      ))
    }

    if (param_value[1] >= param_value[2]) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}}: min ({param_value[1]}) must be < max ({param_value[2]})."
      ))
    }

    check_numeric_bounds(param_value[1], param_name, pattern, spec)
    check_numeric_bounds(param_value[2], param_name, pattern, spec)
    return(invisible(NULL))
  }

  cli::cli_abort(c(
    "Parameter {.val {param_name}} for pattern {.val {pattern}} must be length 1 (fixed) or 2 (range).",
    "x" = "You supplied length {length(param_value)}"
  ))
}

#' Validate Numeric Parameter
#'
#' Validates that a numeric parameter has correct type, range, and bounds.
#'
#' @param param_value Value provided by user.
#' @param param_name Character. Name of the parameter.
#' @param pattern Character. Name of the pattern.
#' @param spec List. Specification with min and max bounds.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_numeric_param <- function(param_value, param_name, pattern, spec) {
  # Single value
  if (length(param_value) == 1) {
    if (!is.numeric(param_value) || is.na(param_value)) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}} must be numeric.",
        "x" = "You supplied {.type {param_value}}"
      ))
    }

    check_numeric_bounds(param_value, param_name, pattern, spec)
    return(invisible(NULL))
  }

  # Range [min, max]
  if (length(param_value) == 2) {
    if (!is.numeric(param_value) || any(is.na(param_value))) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}} must be numeric.",
        "x" = "You supplied {.type {param_value}}"
      ))
    }

    if (param_value[1] >= param_value[2]) {
      cli::cli_abort(c(
        "Parameter {.val {param_name}} for pattern {.val {pattern}}: min ({param_value[1]}) must be < max ({param_value[2]})."
      ))
    }

    check_numeric_bounds(param_value[1], param_name, pattern, spec)
    check_numeric_bounds(param_value[2], param_name, pattern, spec)
    return(invisible(NULL))
  }

  cli::cli_abort(c(
    "Parameter {.val {param_name}} for pattern {.val {pattern}} must be length 1 (fixed) or 2 (range).",
    "x" = "You supplied length {length(param_value)}"
  ))
}

#' Check Numeric Bounds
#'
#' Helper to check if a numeric value is within specified bounds.
#'
#' @param value Numeric value to check.
#' @param param_name Character. Name of the parameter.
#' @param pattern Character. Name of the pattern.
#' @param spec List. Specification with min and max bounds.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
check_numeric_bounds <- function(value, param_name, pattern, spec) {
  if (!is.null(spec$min) && !is.infinite(spec$min) && value < spec$min) {
    cli::cli_abort(c(
      "Parameter {.val {param_name}} for pattern {.val {pattern}}: value {value} is below minimum {spec$min}."
    ))
  }

  if (!is.null(spec$max) && !is.infinite(spec$max) && value > spec$max) {
    cli::cli_abort(c(
      "Parameter {.val {param_name}} for pattern {.val {pattern}}: value {value} exceeds maximum {spec$max}."
    ))
  }

  invisible(NULL)
}
