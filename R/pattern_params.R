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

  new_landscape_params_unchecked(params, pattern)
}

#' Tag a Pattern Parameter List Without Validating It
#'
#' For callers holding values that are already known good. The batch path
#' samples from ranges \code{\link{validate_params_list}} has already checked,
#' so re-validating every draw would add a failure mode inside
#' \code{\link{try_create_landscape}}'s \code{tryCatch}, where an error becomes
#' a silently dropped landscape rather than a message.
#'
#' @param params Named list of parameters.
#' @param pattern Character. Pattern the parameters belong to.
#'
#' @return Named list with class \code{"landscape_params"} and a \code{pattern}
#'     attribute.
#'
#' @keywords internal
#' @noRd
new_landscape_params_unchecked <- function(params, pattern) {
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
#' @param veg_prop Numeric. Probability of vegetation presence (0-1) (default: 0.5).
#'    Higher values result in a denser vegetation cover.
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
#' @evalRd rd_batch_ranges("random")
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
#' @param veg_prop Numeric. Proportion of cells with vegetation (0-1). Default: 0.1.
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
#' @evalRd rd_batch_ranges("bare")
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
#' @param veg_prop Numeric. Proportion of cells with vegetation (0-1). Default: 0.9.
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
#' @evalRd rd_batch_ranges("dense")
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
#' @param boundary_position Numeric. Relative position of vegetation boundary
#'     from top (0-1) (default: 0.5).
#' @param noise_veg_to_bare Numeric. Probability of flipping a vegetated cell to
#'     bare, adding gaps within the vegetation (0-1, default: 0).
#' @param noise_bare_to_veg Numeric. Probability of flipping a bare cell to
#'     vegetated, scattering vegetation beyond the boundary (0-1, default: 0).
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
#' @evalRd rd_batch_ranges("sharp")
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
#' @param steepness Numeric. Controls the transition gradient (0-1).
#'   Lower values (e.g., 0.1) create sharper transitions.
#'   Higher values (e.g., 0.9) create more gradual, diffuse transitions
#'   where vegetation probability persists further below the vegetation boundary (default: 0.5).
#' @param boundary_position Numeric. Relative position of vegetation boundary from top (0-1) (default: 0.2).
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
#' @evalRd rd_batch_ranges("diffuse")
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
#' @param boundary_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param noise_veg_to_bare Numeric. Probability of flipping a vegetated cell to
#'     bare, adding gaps within the vegetation (0-1, default: 0).
#' @param noise_bare_to_veg Numeric. Probability of flipping a bare cell to
#'     vegetated, scattering vegetation beyond the treeline (0-1, default: 0).
#' @param sine_length_mean Numeric. Mean wavelength of sinusoidal curve in pixels (default: 20).
#' @param sine_length_sd Numeric. Standard deviation of wavelength in pixels (default: 12).
#' @param sine_height_mean Numeric. Mean amplitude of sinusoidal curve in pixels (default: 5).
#' @param sine_height_sd Numeric. Standard deviation of amplitude in pixels (default: 4).
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
#' @evalRd rd_batch_ranges("fingers")
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
#' @param boundary_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param noise_veg_to_bare Numeric. Probability of flipping a vegetated cell
#'   to bare, adding gaps within the vegetation. Applied to the underlying
#'   sharp treeline, before the clusters are placed (0-1, default: 0).
#' @param noise_bare_to_veg Numeric. Probability of flipping a bare cell to
#'   vegetated, scattering vegetation beyond the treeline. Applied to the
#'   underlying sharp treeline, before the clusters are placed (0-1,
#'   default: 0).
#' @param n_clusters Integer. Number of cluster centers (default: 10).
#' @param cluster_radius Numeric. Radius of clusters in pixels (default: 5).
#' @param scatter_zone_prop Numeric. Proportion of height for scatter zone
#'   measured downward from treeline (0-1, default: 0.3).
#' @param elongation_x Numeric. Horizontal elongation factor for clusters.
#'   Values > 1 stretch clusters horizontally, creating wider ellipses.
#'   Values < 1 compress horizontally (default: 1).
#' @param elongation_y Numeric. Vertical elongation factor for clusters.
#'   Values > 1 stretch clusters vertically, creating taller ellipses.
#'   Values < 1 compress vertically (default: 1).
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
#' @evalRd rd_batch_ranges("clustered")
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
#' @param boundary_position Numeric. Relative position of treeline from top (0-1) (default: 0.5).
#' @param band_zone_prop Numeric. Proportion of height of the total landscape to
#'     allocate for bands below the treeline (default: 0.2). If the band zone is too small
#'     for the given band spacing, no bands will be drawn and a warning will be issued.
#' @param band_thickness Integer. Thickness of each band in pixels (default: 3).
#' @param band_spacing Integer. Spacing between bands in pixels (default: 10).
#' @param frequency Numeric. Frequency of sine wave (default: 2*pi/100).
#' @param amplitude Numeric. Amplitude of sine wave in pixels (default: 5).
#' @param noise_sd Numeric. Standard deviation for random noise (default: 0).
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
#' @evalRd rd_batch_ranges("bands")
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
#'     For example, 0.2 means the outer 20\% of the radius has a gradient transition.
#'     Works independently of `spot_radius_sd` (which varies the overall size,
#'     while this parameter affects edge sharpness).
#' @param regular_spots Logical. If TRUE, spots are arranged on a hexagonal grid
#'     using k-means clustering. If FALSE, spots are placed randomly (default: FALSE).
#' @param invert_landscape Logical. If TRUE, creates bare patches in vegetated ground
#'     (equivalent to "gaps" pattern). If FALSE (default), creates vegetated spots in bare ground.
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
#' @evalRd rd_batch_ranges("spots")
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

#' Parameters for the Gaps Pattern
#'
#' Builds a validated parameter list for the \code{"gaps"} pattern, to pass to
#' \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' Gaps are bare patches in vegetated ground, the inverse of
#' \code{\link{pattern_spots}}. The inversion is what distinguishes the two
#' patterns, so unlike \code{\link{pattern_spots}} this has no
#' \code{invert_landscape} parameter.
#'
#' @param n_spots Integer. Number of circular gaps to generate.
#'     For regular placement, this may be automatically reduced if the landscape
#'     cannot accommodate the requested number at the given `spot_radius`.
#' @param spot_radius Numeric. Mean radius of each gap in cells.
#'     Must be positive and smaller than landscape dimensions.
#' @param spot_radius_sd Numeric. Standard deviation for random variation in gap radius.
#'     Each gap's radius is sampled from N(spot_radius, spot_radius_sd).
#'     (default: 0 - no variation)
#' @param radius_noise_fraction Numeric (0 to 1). Proportion of the gap radius
#'     where gradual edge noise is applied. 0 creates sharp circular edges,
#'     1 applies probabilistic cell inclusion across the entire radius.
#'     For example, 0.2 means the outer 20\% of the radius has a gradient transition.
#'     Works independently of `spot_radius_sd` (which varies the overall size,
#'     while this parameter affects edge sharpness).
#' @param regular_spots Logical. If TRUE, gaps are arranged on a hexagonal grid
#'     using k-means clustering. If FALSE, gaps are placed randomly (default: FALSE).
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape("gaps", params = pattern_gaps(n_spots = 5, spot_radius = 8))
#'
#' @evalRd rd_batch_ranges("gaps")
#'
#' @export
pattern_gaps <- function(
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_spots = FALSE
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

  new_landscape_params(params, pattern = "gaps")
}

#' Parameters for the Labyrinth Pattern
#'
#' Builds a validated parameter list for the \code{"labyrinth"} pattern, to
#' pass to \code{\link{create_landscape}} or \code{\link{create_landscapes}}.
#'
#' @details
#' A single value fixes a parameter. A length-2 vector is a range, sampled once
#' per landscape by \code{\link{create_landscapes}} and rejected by
#' \code{\link{create_landscape}}.
#'
#' @param frequency Numeric. Controls the spatial scale of the noise pattern:
#'    Lower values produce broad, smooth bands, higher values produce finer, maze-like structures (default: 3).
#' @param veg_threshold Numeric between 0 and 1. Defines the cutoff value that separates vegetated
#'    from non-vegetated cells. Values above the threshold become vegetation.
#'    Adjusting this changes the overall proportion of vegetated area (default: 0.5).
#' @param band_fuzziness Numeric between 0 and 0.5. Controls the amount of
#'    geometric edge roughness applied *after* thresholding. At 0, vegetation
#'    boundaries are sharp and fully deterministic. Small values (≈ 0.05–0.1)
#'    introduce slight, irregular boundary perturbations without changing the
#'    overall topology of the pattern. Larger values progressively erode vegetation
#'    edges and can fragment bands if set too high. This parameter affects boundary
#'    geometry only and does not influence the global structure or connectivity
#'    of the labyrinth. (default: 0.08)
#' @param octaves Integer >= 1. Number of noise layers (octaves) combined to
#'    generate the underlying continuous field. A single octave produces very smooth,
#'    large-scale bands. Using two to three octaves adds limited fine structure while preserving
#'    a dominant wavelength, which is characteristic of labyrinth (Turing-like)
#'    patterns. Higher values introduce fractal detail at smaller scales and can obscure
#'    the banded structure, making patterns less clearly classifiable as
#'    labyrinths. (default: 2).
#'
#' @return A named list of the supplied parameters, classed
#'     \code{"landscape_params"}.
#'
#' @family landscape creation
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#'
#' @examples
#' create_landscape(
#'   "labyrinth",
#'   params = pattern_labyrinth(frequency = 3.5, octaves = 3)
#' )
#'
#' @evalRd rd_batch_ranges("labyrinth")
#'
#' @export
pattern_labyrinth <- function(
  frequency = 3,
  veg_threshold = 0.5,
  band_fuzziness = 0.08,
  octaves = 2
) {
  params <- list()

  if (!missing(frequency)) {
    params$frequency <- frequency
  }
  if (!missing(veg_threshold)) {
    params$veg_threshold <- veg_threshold
  }
  if (!missing(band_fuzziness)) {
    params$band_fuzziness <- band_fuzziness
  }
  if (!missing(octaves)) {
    params$octaves <- octaves
  }

  new_landscape_params(params, pattern = "labyrinth")
}

#' Render a Pattern's Batch Sampling Ranges as Rd
#'
#' Builds the "Defaults in create_landscapes()" section for a
#' \code{pattern_*()} help page from \code{\link{landscape_param_specs}}, so the
#' documented ranges cannot drift from the ones actually sampled. Called from
#' \code{@evalRd} in each constructor's roxygen block.
#'
#' @param pattern Character. Pattern to describe.
#'
#' @return Character vector of Rd markup, one element per line.
#'
#' @keywords internal
#' @noRd
rd_batch_ranges <- function(pattern) {
  specs <- landscape_param_specs()[[pattern]]

  # Width/height-dependent ranges are reported at the default landscape size
  width <- 100
  height <- 100

  describe_range <- function(range) {
    if (is.null(range)) {
      return("not sampled")
    }

    if (is.logical(range)) {
      if (length(range) == 1) {
        return(paste("always", range))
      }
      return(paste(range, collapse = " or "))
    }

    if (is.function(range)) {
      value <- range(width, height)
      return(sprintf(
        "%s to %s, scales with size",
        format(value[1]),
        format(value[2])
      ))
    }

    if (length(range) == 1) {
      return(paste("always", format(range)))
    }

    sprintf("%s to %s", format(range[1]), format(range[2]))
  }

  rows <- vapply(
    names(specs),
    function(name) {
      sprintf(
        "\\code{%s} \\tab %s \\cr",
        name,
        describe_range(specs[[name]]$batch_range)
      )
    },
    character(1)
  )

  c(
    "\\section{Defaults in create_landscapes()}{",
    "\\code{\\link{create_landscapes}} samples a value per landscape for every",
    "parameter left unset, so the defaults shown in Usage apply to",
    "\\code{\\link{create_landscape}} only. Ranges that scale with landscape",
    sprintf(
      "size are shown for the default %d by %d. What a batch uses instead:",
      width,
      height
    ),
    "\\tabular{ll}{",
    unname(rows),
    "}",
    "}"
  )
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
