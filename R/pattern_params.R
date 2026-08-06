#' Build a Validated Pattern Parameter List
#'
#' Shared constructor behind the \code{pattern_*()} functions. Validates the
#' supplied parameters against \code{\link{landscape_param_specs}} and tags the
#' result with the pattern it was built for.
#'
#' The \code{pattern_*()} functions declare the generators' real defaults so
#' that they show up in the rendered \code{\\usage}, but pass on only the
#' parameters the caller actually set. Anything unset stays out, leaving the
#' generator -- or, in the batch path, the default sampling range -- to decide.
#'
#' @param params Named list holding only the parameters the caller supplied.
#' @param pattern Character. Pattern the parameters belong to.
#'
#' @return Named list of the supplied parameters, with class
#'     \code{"landscape_params"} and a \code{pattern} attribute.
#'
#' @keywords internal
#' @noRd
new_landscape_params <- function(params, pattern) {
  specs <- get_valid_param_specs()[[pattern]]

  for (name in names(params)) {
    spec <- specs[[name]]

    switch(
      spec$type,
      logical = validate_logical_param(params[[name]], name, pattern),
      integer = validate_integer_param(params[[name]], name, pattern, spec),
      numeric = validate_numeric_param(params[[name]], name, pattern, spec)
    )
  }

  structure(
    params,
    class = c("landscape_params", "list"),
    pattern = pattern
  )
}

#' Parameters for the Random Pattern
#'
#' Builds a validated parameter list for the \code{"random"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_random
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape("random", params = pattern_random(veg_prop = 0.3))
#'
#' @export
pattern_random <- function(veg_prop = 0.5) {
  params <- list()

  if (!missing(veg_prop)) {
    params$veg_prop <- veg_prop
  }

  new_landscape_params(params, pattern = "random")
}

#' Parameters for the Bare Pattern
#'
#' Builds a validated parameter list for the \code{"bare"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_bare
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape("bare", params = pattern_bare(veg_prop = 0.05))
#'
#' @export
pattern_bare <- function(veg_prop = 0.1) {
  params <- list()

  if (!missing(veg_prop)) {
    params$veg_prop <- veg_prop
  }

  new_landscape_params(params, pattern = "bare")
}

#' Parameters for the Dense Pattern
#'
#' Builds a validated parameter list for the \code{"dense"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_dense
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape("dense", params = pattern_dense(veg_prop = 0.95))
#'
#' @export
pattern_dense <- function(veg_prop = 0.9) {
  params <- list()

  if (!missing(veg_prop)) {
    params$veg_prop <- veg_prop
  }

  new_landscape_params(params, pattern = "dense")
}

#' Parameters for the Sharp Pattern
#'
#' Builds a validated parameter list for the \code{"sharp"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_sharp
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape("sharp", params = pattern_sharp(boundary_position = 0.3))
#'
#' # Rotation is an argument of create_landscape(), not a pattern parameter
#' create_landscape(
#'   "sharp",
#'   params = pattern_sharp(noise_bare_to_veg = 0.1),
#'   rotation = 45
#' )
#'
#' @export
pattern_sharp <- function(
  boundary_position = 0.5,
  noise_veg_to_bare = 0,
  noise_bare_to_veg = 0
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }
  if (!missing(noise_veg_to_bare)) {
    params$noise_veg_to_bare <- noise_veg_to_bare
  }
  if (!missing(noise_bare_to_veg)) {
    params$noise_bare_to_veg <- noise_bare_to_veg
  }

  new_landscape_params(params, pattern = "sharp")
}

#' Parameters for the Diffuse Pattern
#'
#' Builds a validated parameter list for the \code{"diffuse"} pattern, to pass
#' to \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_diffuse
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape(
#'   "diffuse",
#'   params = pattern_diffuse(steepness = 0.1, boundary_position = 0.3)
#' )
#'
#' @export
pattern_diffuse <- function(
  steepness = 0.5,
  boundary_position = 0.2
) {
  params <- list()

  if (!missing(steepness)) {
    params$steepness <- steepness
  }
  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }

  new_landscape_params(params, pattern = "diffuse")
}

#' Parameters for the Fingers Pattern
#'
#' Builds a validated parameter list for the \code{"fingers"} pattern, to pass
#' to \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_fingers
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape(
#'   "fingers",
#'   params = pattern_fingers(sine_length_mean = 15, sine_height_mean = 10)
#' )
#'
#' @export
pattern_fingers <- function(
  boundary_position = 0.5,
  noise_veg_to_bare = 0,
  noise_bare_to_veg = 0,
  sine_length_mean = 20,
  sine_length_sd = 12,
  sine_height_mean = 5,
  sine_height_sd = 4
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }
  if (!missing(noise_veg_to_bare)) {
    params$noise_veg_to_bare <- noise_veg_to_bare
  }
  if (!missing(noise_bare_to_veg)) {
    params$noise_bare_to_veg <- noise_bare_to_veg
  }
  if (!missing(sine_length_mean)) {
    params$sine_length_mean <- sine_length_mean
  }
  if (!missing(sine_length_sd)) {
    params$sine_length_sd <- sine_length_sd
  }
  if (!missing(sine_height_mean)) {
    params$sine_height_mean <- sine_height_mean
  }
  if (!missing(sine_height_sd)) {
    params$sine_height_sd <- sine_height_sd
  }

  new_landscape_params(params, pattern = "fingers")
}

#' Parameters for the Clustered Pattern
#'
#' Builds a validated parameter list for the \code{"clustered"} pattern, to
#' pass to \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_clustered
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape(
#'   "clustered",
#'   params = pattern_clustered(n_clusters = 8, cluster_radius = 7)
#' )
#'
#' @export
pattern_clustered <- function(
  boundary_position = 0.5,
  noise_veg_to_bare = 0,
  noise_bare_to_veg = 0,
  n_clusters = 10,
  cluster_radius = 5,
  scatter_zone_prop = 0.3,
  elongation_x = 1,
  elongation_y = 1
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }
  if (!missing(noise_veg_to_bare)) {
    params$noise_veg_to_bare <- noise_veg_to_bare
  }
  if (!missing(noise_bare_to_veg)) {
    params$noise_bare_to_veg <- noise_bare_to_veg
  }
  if (!missing(n_clusters)) {
    params$n_clusters <- n_clusters
  }
  if (!missing(cluster_radius)) {
    params$cluster_radius <- cluster_radius
  }
  if (!missing(scatter_zone_prop)) {
    params$scatter_zone_prop <- scatter_zone_prop
  }
  if (!missing(elongation_x)) {
    params$elongation_x <- elongation_x
  }
  if (!missing(elongation_y)) {
    params$elongation_y <- elongation_y
  }

  new_landscape_params(params, pattern = "clustered")
}

#' Parameters for the Bands Pattern
#'
#' Builds a validated parameter list for the \code{"bands"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_bands
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape(
#'   "bands",
#'   params = pattern_bands(band_thickness = 4, band_spacing = 12)
#' )
#'
#' @export
pattern_bands <- function(
  boundary_position = 0.5,
  band_zone_prop = 0.2,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 2 * pi / 100,
  amplitude = 5,
  noise_sd = 0
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }
  if (!missing(band_zone_prop)) {
    params$band_zone_prop <- band_zone_prop
  }
  if (!missing(band_thickness)) {
    params$band_thickness <- band_thickness
  }
  if (!missing(band_spacing)) {
    params$band_spacing <- band_spacing
  }
  if (!missing(frequency)) {
    params$frequency <- frequency
  }
  if (!missing(amplitude)) {
    params$amplitude <- amplitude
  }
  if (!missing(noise_sd)) {
    params$noise_sd <- noise_sd
  }

  new_landscape_params(params, pattern = "bands")
}

#' Parameters for the Spots Pattern
#'
#' Builds a validated parameter list for the \code{"spots"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @inheritParams create_landscape_spots
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' # A single landscape
#' create_landscape("spots", params = pattern_spots(n_spots = 15))
#'
#' # A range, sampled once per landscape
#' create_landscapes(
#'   n = 4,
#'   patterns = "spots",
#'   params_list = list(spots = pattern_spots(n_spots = c(5, 15)))
#' )
#'
#' @export
pattern_spots <- function(
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_spots = FALSE,
  invert_landscape = FALSE
) {
  params <- list()

  if (!missing(n_spots)) {
    params$n_spots <- n_spots
  }
  if (!missing(spot_radius)) {
    params$spot_radius <- spot_radius
  }
  if (!missing(spot_radius_sd)) {
    params$spot_radius_sd <- spot_radius_sd
  }
  if (!missing(radius_noise_fraction)) {
    params$radius_noise_fraction <- radius_noise_fraction
  }
  if (!missing(regular_spots)) {
    params$regular_spots <- regular_spots
  }
  if (!missing(invert_landscape)) {
    params$invert_landscape <- invert_landscape
  }

  new_landscape_params(params, pattern = "spots")
}

#' Resolve Pattern Parameters for a Single Landscape
#'
#' Checks a \code{pattern_*()} parameter list, or falls back to parameters
#' passed individually. The two cannot be combined: parameters come from one
#' place or the other, so there is only ever one way to read a call.
#'
#' @param params Output of a \code{pattern_*()} constructor, or \code{NULL}.
#' @param dots Named list of individually supplied parameters.
#' @param pattern Character. Pattern being generated.
#'
#' @return Named list of parameters to pass to the generator.
#'
#' @keywords internal
#' @noRd
resolve_pattern_params <- function(params, dots, pattern) {
  if (is.null(params)) {
    return(dots)
  }

  if (length(dots) > 0) {
    cli::cli_abort(c(
      "Parameters must come either from {.arg params} or on their own, not both.",
      "x" = "Also supplied individually: {.val {names(dots)}}.",
      "i" = "{cli::qty(dots)}Add {?it/them} to {.code pattern_{pattern}()}."
    ))
  }

  if (!inherits(params, "landscape_params")) {
    cli::cli_abort(c(
      "{.arg params} must come from a {.fn pattern_} constructor.",
      "i" = "Did you mean {.code params = pattern_{pattern}(...)}?"
    ))
  }

  params_pattern <- attr(params, "pattern")

  if (!identical(params_pattern, pattern)) {
    cli::cli_abort(c(
      "{.arg params} was built for pattern {.val {params_pattern}}, but {.arg pattern} is {.val {pattern}}.",
      "i" = "Use {.code pattern_{pattern}()} instead."
    ))
  }

  ranges <- names(params)[lengths(params) > 1]

  if (length(ranges) > 0) {
    cli::cli_abort(c(
      "{.fn create_landscape} needs a single value per parameter, not a range.",
      "x" = "Range{?s} supplied for {.val {ranges}}.",
      "i" = "Ranges are sampled per landscape by {.fn create_landscapes}."
    ))
  }

  unclass(params)
}
