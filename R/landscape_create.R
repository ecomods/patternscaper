#' Create a Single Landscape
#'
#' @description
#' Generates one binary landscape with the requested spatial pattern. Use the
#' matching \code{pattern_*()} constructor to set pattern-specific parameters.
#'
#' \itemize{
#'   \item \strong{Control} patterns have no spatial structure and differ only
#'     in vegetation cover: \code{\link[=pattern_bare]{"bare"}},
#'     \code{\link[=pattern_random]{"random"}},
#'     \code{\link[=pattern_dense]{"dense"}}.
#'   \item \strong{Ecotone} patterns have a vegetated and a bare zone separated
#'     by a transition: \code{\link[=pattern_sharp]{"sharp"}} (abrupt),
#'     \code{\link[=pattern_diffuse]{"diffuse"}} (gradual),
#'     \code{\link[=pattern_fingers]{"fingers"}} (finger-like extensions),
#'     \code{\link[=pattern_clustered]{"clustered"}} (scattered clusters),
#'     \code{\link[=pattern_bands]{"bands"}} (sinusoidal bands).
#'   \item \strong{Patch} patterns are self-organized, without a boundary:
#'     \code{\link[=pattern_spots]{"spots"}} (vegetation patches),
#'     \code{\link[=pattern_gaps]{"gaps"}} (bare gaps),
#'     \code{\link[=pattern_labyrinth]{"labyrinth"}} (maze-like bands).
#' }
#'
#' @param width Integer. Landscape width in pixels (default: 100).
#' @param height Integer. Landscape height in pixels (default: 100).
#' @param pattern Character. Pattern to generate.
#'     Valid patterns are: "random", "bare", "dense", "sharp", "diffuse",
#'     "fingers", "clustered", "bands", "spots", "gaps", "labyrinth".
#' @param name Character. Optional landscape name (default: NULL).
#' @param params Output of the \code{pattern_*()} constructor matching
#'     \code{pattern}, such as \code{\link{pattern_spots}} (default: NULL).
#'     Parameters must be single values; length-2 sampling ranges apply only to
#'     \code{\link{create_landscapes}}.
#' @param rotation Numeric. Rotation angle in degrees (0-360, default: 0).
#'     Only "sharp", "diffuse", "fingers", "clustered", and "bands" are
#'     rotated. Other patterns ignore this argument and issue a warning.
#'
#' @return A \code{\link{landscape}} object, containing:
#'   \item{data}{SpatRaster of the generated pattern (0 = bare ground,
#'     1 = vegetation).}
#'   \item{pattern}{Character pattern name.}
#'   \item{params}{Parameters used to generate the landscape.}
#'   \item{name}{Character landscape name, or \code{NA} if none was given.}
#'
#' @family landscape creation
#' @seealso \code{\link{landscape}} to wrap an existing raster, for example a
#'     real map, into the same object type; \code{\link{plot_landscapes}} to
#'     plot the result.
#'
#' @examples
#' # Create a default landscape of various patterns
#' random_default <- create_landscape("random")
#' sharp_default <- create_landscape("sharp")
#' diffuse_default <- create_landscape("diffuse")
#' clustered_default <- create_landscape("clustered")
#'
#' # Set pattern parameters through the matching constructor
#' random_modified <- create_landscape(
#'   "random",
#'   params = pattern_random(veg_prob = 0.3)
#' )
#'
#' diffuse_modified <- create_landscape(
#'   "diffuse",
#'   params = pattern_diffuse(boundary_position = 0.3, steepness = 0.1)
#' )
#'
#' # Rotation is an argument of create_landscape(), not a pattern parameter
#' bands_rotated <- create_landscape(
#'   "bands",
#'   params = pattern_bands(
#'     band_thickness = 4,
#'     band_spacing = 12,
#'     amplitude = 6,
#'     noise_sd = 2
#'   ),
#'   rotation = 45
#' )
#'
#' @export
create_landscape <- function(
  pattern,
  width = 100,
  height = 100,
  name = NULL,
  params = NULL,
  rotation = 0
) {
  if (!missing(pattern) && length(pattern) != 1) {
    cli::cli_abort(c(
      "{.arg pattern} must be a single pattern name.",
      "x" = "You supplied {length(pattern)} value{?s}.",
      "i" = "Use {.fn create_landscapes} to create landscapes with several patterns."
    ))
  }

  matched <- rlang::arg_match(pattern, values = valid_patterns())

  if (!is.null(name)) {
    if (!is.character(name) || length(name) != 1) {
      cli::cli_abort("'name' must be a single character string or NULL")
    }
  }

  validate_rotation(rotation)

  generator <- switch(
    matched,
    random = create_landscape_random,
    bare = create_landscape_bare,
    dense = create_landscape_dense,
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    bands = create_landscape_bands,
    spots = create_landscape_spots,
    gaps = create_landscape_gaps,
    labyrinth = create_landscape_labyrinth
  )

  pattern_params <- resolve_pattern_params(params, matched)

  # Rotation is applied after generation, not stored as a pattern parameter.
  # Only supported generators receive it.
  if (!missing(rotation) && matched %in% rotatable_patterns()) {
    pattern_params$rotation <- rotation
  } else if (!missing(rotation) && rotation != 0) {
    cli::cli_warn(c(
      "{.arg rotation} is ignored for pattern {.val {matched}}.",
      "i" = "Only {paste(rotatable_patterns(), collapse = ', ')} support rotation."
    ))
  }

  landscape <- do.call(
    generator,
    c(list(width = width, height = height), pattern_params)
  )

  if (!is.null(name)) {
    landscape <- set_landscape_name(landscape, name)
  }

  return(landscape)
}


#' Create Multiple Landscapes
#'
#' @description
#' Generates \code{n} binary landscapes from the requested patterns, sampling
#' pattern-specific parameters independently for each landscape. This supports
#' the construction of training sets.
#'
#' \itemize{
#'   \item \strong{Control} patterns have no spatial structure and differ only
#'     in vegetation cover: \code{\link[=pattern_bare]{"bare"}},
#'     \code{\link[=pattern_random]{"random"}},
#'     \code{\link[=pattern_dense]{"dense"}}.
#'   \item \strong{Ecotone} patterns have a vegetated and a bare zone separated
#'     by a transition: \code{\link[=pattern_sharp]{"sharp"}} (abrupt),
#'     \code{\link[=pattern_diffuse]{"diffuse"}} (gradual),
#'     \code{\link[=pattern_fingers]{"fingers"}} (finger-like extensions),
#'     \code{\link[=pattern_clustered]{"clustered"}} (scattered clusters),
#'     \code{\link[=pattern_bands]{"bands"}} (sinusoidal bands).
#'   \item \strong{Patch} patterns are self-organized, without a boundary:
#'     \code{\link[=pattern_spots]{"spots"}} (vegetation patches),
#'     \code{\link[=pattern_gaps]{"gaps"}} (bare gaps),
#'     \code{\link[=pattern_labyrinth]{"labyrinth"}} (maze-like bands).
#' }
#'
#' @param n Integer. Number of landscapes to generate (default: 50).
#' @param patterns Character vector. Patterns to sample: "random", "bare",
#'     "dense", "sharp", "diffuse", "fingers", "clustered", "bands", "spots",
#'     "gaps", or "labyrinth" (default: all patterns).
#' @param width Integer. Width of each landscape in pixels (default: 100).
#' @param height Integer. Height of each landscape in pixels (default: 100).
#' @param rotation Numeric. Angle in degrees (default: \code{c(0, 360)}).
#'     A single value applies to every rotatable landscape. A length-2 vector
#'     gives the bounds of a uniform range sampled as whole degrees. Only
#'     "sharp", "diffuse", "fingers", "clustered", and "bands" are rotated;
#'     other patterns ignore this argument.
#' @param params_list Named list of pattern parameters (default: NULL). Each name
#'     must match a pattern and each element must come from its \code{pattern_*()}
#'     constructor, for example \code{list(spots = pattern_spots())}. A single
#'     value is fixed across the batch; a length-2 vector is sampled once per
#'     landscape. Omitted patterns use their default sampling ranges.
#' @param pattern_probs Numeric vector of sampling weights, one per element of
#'     \code{patterns} (default: NULL). NULL creates balanced pattern counts. A
#'     vector of the wrong length issues a warning and uses equal weights.
#' @param max_retries Integer. Maximum retries after a failed landscape
#'     generation (default: 3).
#'
#' @return A named list of \code{\link{landscape}} objects, each as returned by
#'     \code{\link{create_landscape}}. Landscape names are \code{"<pattern>_<index>"},
#'     with \code{"_rot<angle>"} appended for rotated landscapes. The list holds
#'     fewer than \code{n} landscapes if generation still fails after
#'     \code{max_retries}; a warning reports the shortfall.
#' @family landscape creation
#' @seealso \code{\link{landscape}} to wrap an existing raster, for example a
#'     real map, into the same object type; \code{\link{plot_landscapes}} to
#'     plot the result.
#'
#' @examples
#' # Generate 20 landscapes
#' landscapes <- create_landscapes(n = 20)
#'
#' # Access a landscape
#' landscapes[[1]]
#'
#' # Check the pattern
#' landscapes[[1]]$pattern
#'
#' # Get all landscape patterns
#' sapply(landscapes, \(x) x$pattern)
#'
#' # Custom parameters, as a single value or as a range sampled per landscape
#' landscapes_custom <- create_landscapes(
#'   n = 12,
#'   patterns = c("spots", "sharp"),
#'   params_list = list(
#'     spots = pattern_spots(n_spots = 15, spot_radius = c(8, 12)),
#'     sharp = pattern_sharp(boundary_position = c(0.4, 0.6))
#'   )
#' )
#'
#' @export
create_landscapes <- function(
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
  rotation = c(0, 360),
  params_list = NULL,
  pattern_probs = NULL,
  max_retries = 3
) {
  if (!is.numeric(n) || length(n) != 1) {
    cli::cli_abort("'n' must be a single numeric value")
  }

  n <- as.integer(n)

  if (is.na(n) || n < 1) {
    cli::cli_abort("'n' must be a positive integer")
  }

  validate_dimensions(width, height)

  validate_rotation(rotation, allow_range = TRUE)

  unknown_patterns <- setdiff(patterns, valid_patterns())

  if (length(unknown_patterns) > 0) {
    cli::cli_abort(c(
      "Invalid pattern(s): {paste(unknown_patterns, collapse = ', ')}",
      "i" = "Valid options are: {paste(valid_patterns(), collapse = ', ')}"
    ))
  }

  default_params_list <- build_default_params_list(width, height)

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

  # Initialize pre-allocated results list
  all_landscapes <- vector("list", n)

  integer_params <- get_integer_param_names()

  # Determine how to distribute landscape patterns
  if (is.null(pattern_probs)) {
    # Calculate how many of each pattern to generate
    num_patterns <- length(patterns)
    landscapes_per_pattern <- floor(n / num_patterns)
    extras <- n - (landscapes_per_pattern * num_patterns)

    # Create balanced distribution
    sampled_patterns <- rep(patterns, each = landscapes_per_pattern)

    # Assign any remainder deterministically, then shuffle the generation order
    if (extras > 0) {
      extra_patterns <- patterns[1:extras]
      sampled_patterns <- c(sampled_patterns, extra_patterns)
    }

    sampled_patterns <- sample(sampled_patterns)
  } else {
    if (length(pattern_probs) != length(patterns)) {
      cli::cli_alert_warning(
        "Length of pattern_probs doesn't match length of patterns. Using equal weights."
      )
      pattern_probs <- rep(1, length(patterns))
    }
    sampled_patterns <- sample(
      patterns,
      size = n,
      replace = TRUE,
      prob = pattern_probs
    )
  }

  patterns_with_rotation <- rotatable_patterns()

  # Generate each landscape
  for (i in 1:n) {
    pattern <- sampled_patterns[i]
    landscape <- NULL
    retry_count <- 0

    while (is.null(landscape) && retry_count <= max_retries) {
      # Each retry draws a fresh parameter set.
      sampled_params <- sample_landscape_params(
        params_list[[pattern]],
        integer_params,
        width,
        height
      )

      if (pattern %in% patterns_with_rotation) {
        if (length(rotation) == 1) {
          current_rotation <- rotation
        } else {
          current_rotation <- round(
            runif(1, min = rotation[1], max = rotation[2])
          )
        }
        sampled_params$rotation <- current_rotation
      } else {
        current_rotation <- 0
      }

      # Outside try_create_landscape()'s tryCatch, so a spec bug aborts
      # instead of being retried and silently dropped from the batch.
      validate_sampled_params(sampled_params, pattern)

      landscape <- try_create_landscape(
        pattern,
        sampled_params,
        i,
        current_rotation
      )

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

    if (!is.null(landscape)) {
      all_landscapes[[i]] <- landscape
      names(all_landscapes)[i] <- landscape$name
    }
  }

  n_requested <- n
  n_failed <- sum(vapply(all_landscapes, is.null, logical(1)))
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

#' Valid Pattern Names
#'
#' The patterns that can be generated. Both \code{\link{create_landscape}} and
#' \code{\link{create_landscapes}} ask here rather than keeping their own
#' copies. \code{create_landscapes()}'s \code{patterns} default repeats the list
#' so it stays visible in the help page's usage section, and a test pins the two
#' together.
#'
#' @return Character vector of pattern names.
#'
#' @keywords internal
#' @noRd
valid_patterns <- function() {
  c(
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
}

#' Patterns That Support Rotation
#'
#' The patterns whose generators take a \code{rotation} argument. Both
#' \code{\link{create_landscape}} and \code{\link{create_landscapes}} ask here
#' rather than keeping their own copies.
#'
#' @return Character vector of pattern names.
#'
#' @keywords internal
#' @noRd
rotatable_patterns <- function() {
  c("sharp", "diffuse", "fingers", "clustered", "bands")
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
      lower <- ceiling(param_range[1])
      upper <- floor(param_range[2])

      if (lower > upper) {
        # A out-of-bounds integer falls back to its rounded midpoint
        int_values <- round(mean(param_range))
      } else {
        int_values <- seq(from = lower, to = upper, by = 1)
      }
      sampled_params[[param_name]] <- int_values[
        sample.int(length(int_values), size = 1)
      ]
    } else {
      sampled_params[[param_name]] <- runif(
        1,
        min = param_range[1],
        max = param_range[2]
      )
    }
  }

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
      # Dimensions and rotation are direct arguments. Sampled pattern values
      # are already validated, so they bypass the public constructors.
      fixed <- c("width", "height", "rotation")

      args <- list(
        pattern = pattern,
        width = params$width,
        height = params$height,
        params = new_landscape_params_unchecked(
          params[setdiff(names(params), fixed)],
          pattern
        )
      )

      # Pass rotation only when set because create_landscape() distinguishes a
      # missing argument from rotation = 0.
      if (!is.null(params$rotation)) {
        args$rotation <- params$rotation
      }

      landscape <- do.call(create_landscape, args)

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
      cli::cli_alert_danger(
        "Landscape {index} (pattern: {pattern}) failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
}
