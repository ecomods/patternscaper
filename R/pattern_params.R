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
#' Vegetation is placed independently in each cell, without spatial structure.
#'
#' @param veg_prob Numeric. Probability that each cell is vegetated (0-1,
#'     default: 0.5). Higher values give a denser vegetation cover.
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with a fixed value
#' create_landscape("random", params = pattern_random(veg_prob = 0.3))
#'
#' # A batch, with veg_prob drawn from a range once per landscape
#' create_landscapes(
#'   n = 4,
#'   patterns = "random",
#'   params_list = list(random = pattern_random(veg_prob = c(0.2, 0.8)))
#' )
#'
#' @evalRd rd_param_ranges("random")
#'
#' @export
pattern_random <- function(veg_prob = 0.5) {
  params <- list()

  if (!missing(veg_prob)) {
    params$veg_prob <- veg_prob
  }

  new_landscape_params(params, pattern = "random")
}

#' Parameters for the Bare Pattern
#'
#' Sparse vegetation is placed independently in each cell, without spatial
#' structure.
#'
#' @param veg_prob Numeric. Probability that each cell is vegetated (0-1,
#'     default: 0.1). Higher values give a denser vegetation cover.
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with a fixed value
#' create_landscape("bare", params = pattern_bare(veg_prob = 0.05))
#'
#' # A batch, with veg_prob drawn from a range once per landscape
#' create_landscapes(
#'   n = 4,
#'   patterns = "bare",
#'   params_list = list(bare = pattern_bare(veg_prob = c(0, 0.1)))
#' )
#'
#' @evalRd rd_param_ranges("bare")
#'
#' @export
pattern_bare <- function(veg_prob = 0.1) {
  params <- list()

  if (!missing(veg_prob)) {
    params$veg_prob <- veg_prob
  }

  new_landscape_params(params, pattern = "bare")
}

#' Parameters for the Dense Pattern
#'
#' Dense vegetation is placed independently in each cell, without spatial
#' structure.
#'
#' @param veg_prob Numeric. Probability that each cell is vegetated (0-1,
#'     default: 0.9). Higher values give a denser vegetation cover.
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with a fixed value
#' create_landscape("dense", params = pattern_dense(veg_prob = 0.95))
#'
#' # A batch, with veg_prob drawn from a range once per landscape
#' create_landscapes(
#'   n = 4,
#'   patterns = "dense",
#'   params_list = list(dense = pattern_dense(veg_prob = c(0.85, 1)))
#' )
#'
#' @evalRd rd_param_ranges("dense")
#'
#' @export
pattern_dense <- function(veg_prob = 0.9) {
  params <- list()

  if (!missing(veg_prob)) {
    params$veg_prob <- veg_prob
  }

  new_landscape_params(params, pattern = "dense")
}

#' Parameters for the Sharp Pattern
#'
#' A vegetated and a bare zone separated by a sharp boundary.
#'
#' @param boundary_position Numeric. Relative position of the horizontal
#'     vegetation boundary (if not rotated) from the top (0-1, default: 0.5).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with a fixed value
#' create_landscape("sharp", params = pattern_sharp(boundary_position = 0.3))
#'
#' # A batch, with boundary_position drawn from a range once per landscape
#' create_landscapes(
#'   n = 4,
#'   patterns = "sharp",
#'   params_list = list(sharp = pattern_sharp(boundary_position = c(0.2, 0.8)))
#' )
#'
#' # Rotation is an argument of create_landscape(), not a pattern parameter
#' create_landscape(
#'   "sharp",
#'   params = pattern_sharp(boundary_position = 0.3),
#'   rotation = 45
#' )
#'
#' @evalRd rd_param_ranges("sharp")
#'
#' @export
pattern_sharp <- function(boundary_position = 0.5) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }

  new_landscape_params(params, pattern = "sharp")
}

#' Parameters for the Diffuse Pattern
#'
#' A vegetated and a bare zone with a gradual transition between them, where
#' the chance of a cell being vegetated decreases with distance from the
#' boundary.
#'
#' @param steepness Numeric. Transition gradient (0-1, default: 0.5). Lower
#'     values create sharper transitions; higher values extend diffuse
#'     vegetation farther below the boundary.
#' @param boundary_position Numeric. Relative position of the horizontal
#'     vegetation boundary (if not rotated) from the top (0-1, default: 0.2).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape(
#'   "diffuse",
#'   params = pattern_diffuse(steepness = 0.1, boundary_position = 0.3)
#' )
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "diffuse",
#'   params_list = list(
#'     diffuse = pattern_diffuse(
#'       steepness = c(0.1, 1),
#'       boundary_position = c(0.1, 0.4)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "diffuse",
#'   params_list = list(
#'     diffuse = pattern_diffuse(
#'       steepness = 0.5,
#'       boundary_position = c(0.1, 0.4)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("diffuse")
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
#' Finger-like extensions of vegetation growing into the bare zone.
#'
#' @param boundary_position Numeric. Relative position of the horizontal
#'     vegetation boundary (if not rotated) from the top (0-1, default: 0.5).
#' @param sine_length_mean Numeric. Mean wavelength of sinusoidal curve in pixels.
#'     Larger values produce longer, more widely spaced bends (default: 20).
#' @param sine_length_sd Numeric. Standard deviation of wavelength in pixels.
#'     Larger values produce less regular curves (default: 12).
#' @param sine_height_mean Numeric. Mean amplitude of sinusoidal curve in pixels.
#'     Larger values produce more pronounced bends (default: 5).
#' @param sine_height_sd Numeric. Standard deviation of amplitude in pixels.
#'     Larger values increase variation in bend height (default: 5).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape(
#'   "fingers",
#'   params = pattern_fingers(sine_length_mean = 15, sine_height_mean = 10)
#' )
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "fingers",
#'   params_list = list(
#'     fingers = pattern_fingers(
#'       sine_length_mean = c(10, 30),
#'       sine_height_mean = c(5, 15)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "fingers",
#'   params_list = list(
#'     fingers = pattern_fingers(
#'       sine_length_mean = 20,
#'       sine_height_mean = c(5, 15)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("fingers")
#'
#' @export
pattern_fingers <- function(
  boundary_position = 0.5,
  sine_length_mean = 20,
  sine_length_sd = 12,
  sine_height_mean = 5,
  sine_height_sd = 5
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
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
#' Vegetation clusters scattered into the bare zone.
#'
#' @param boundary_position Numeric. Relative position of the horizontal
#'     vegetation boundary (if not rotated) from the top (0-1, default: 0.5).
#' @param n_clusters Integer. Number of cluster centers (default: 10).
#' @param cluster_radius Numeric. Radius of clusters in pixels (default: 5).
#' @param cluster_zone Numeric. Proportion of height for the cluster zone,
#'     measured downward from the vegetation boundary (0-1, default: 0.3).
#' @param elongation_x Numeric. Horizontal elongation factor for clusters.
#'     Values above 1 stretch clusters horizontally; values below 1 compress
#'     them (default: 1).
#' @param elongation_y Numeric. Vertical elongation factor for clusters.
#'     Values above 1 stretch clusters vertically; values below 1 compress
#'     them (default: 1).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape(
#'   "clustered",
#'   params = pattern_clustered(n_clusters = 8, cluster_radius = 7)
#' )
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "clustered",
#'   params_list = list(
#'     clustered = pattern_clustered(
#'       n_clusters = c(5, 12),
#'       cluster_radius = c(4, 8)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "clustered",
#'   params_list = list(
#'     clustered = pattern_clustered(
#'       n_clusters = 8,
#'       cluster_radius = c(4, 8)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("clustered")
#'
#' @export
pattern_clustered <- function(
  boundary_position = 0.5,
  n_clusters = 10,
  cluster_radius = 5,
  cluster_zone = 0.3,
  elongation_x = 1,
  elongation_y = 1
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }
  if (!missing(n_clusters)) {
    params$n_clusters <- n_clusters
  }
  if (!missing(cluster_radius)) {
    params$cluster_radius <- cluster_radius
  }
  if (!missing(cluster_zone)) {
    params$cluster_zone <- cluster_zone
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
#' Sinusoidal vegetation bands running parallel to the boundary.
#'
#' @param boundary_position Numeric. Relative position of the horizontal
#'     vegetation boundary (if not rotated) from the top (0-1, default: 0.5).
#' @param band_zone Numeric. Proportion of the total landscape height to
#'     allocate for bands below the vegetation boundary (0-1, default: 0.3). If
#'     the band zone is too small for the given band spacing, no bands are drawn
#'     and a warning is issued.
#' @param band_thickness Integer. Thickness of each band in pixels (default: 3).
#' @param band_spacing Integer. Spacing between bands in pixels (default: 10).
#' @param frequency Numeric. Frequency of the bands' sine wave (default:
#'     4*pi/100).
#' @param amplitude Numeric. Amplitude of the bands' sine wave in pixels
#'     (default: 5).
#' @param noise_sd Numeric. Standard deviation of each band's vertical
#'     deviation from its baseline along the x-axis (default: 0).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape(
#'   "bands",
#'   params = pattern_bands(band_thickness = 4, band_spacing = 12)
#' )
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "bands",
#'   params_list = list(
#'     bands = pattern_bands(
#'       band_thickness = c(2, 5),
#'       band_spacing = c(8, 16)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "bands",
#'   params_list = list(
#'     bands = pattern_bands(
#'       band_thickness = 3,
#'       band_spacing = c(8, 16)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("bands")
#'
#' @export
pattern_bands <- function(
  boundary_position = 0.5,
  band_zone = 0.3,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 4 * pi / 100,
  amplitude = 5,
  noise_sd = 0
) {
  params <- list()

  if (!missing(boundary_position)) {
    params$boundary_position <- boundary_position
  }
  if (!missing(band_zone)) {
    params$band_zone <- band_zone
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
#' Circular vegetation patches on bare ground.
#'
#' @param n_spots Integer. Number of spots (default: 5). Regular placement may
#'     reduce this number if the landscape cannot accommodate the requested
#'     count with the given \code{spot_radius}.
#' @param spot_radius Numeric. Mean radius of each spot in pixels (default: 10).
#'     Must be positive and smaller than landscape dimensions.
#' @param spot_radius_sd Numeric. Standard deviation of normally sampled spot
#'     radii (default: 0, no variation).
#' @param radius_noise_fraction Numeric. Fraction of the spot radius with a
#'     gradual edge transition (0-1). Zero gives sharp edges; 1 applies
#'     probabilistic cell inclusion across the full radius. For example, 0.2
#'     applies the transition to the outer 20\%. This is independent of
#'     \code{spot_radius_sd}, which varies overall spot size.
#' @param regular_spots Logical. Arrange spots on a hexagonal grid using k-means
#'     clustering rather than placing them randomly (default: FALSE).
#' @param invert_landscape Logical. Create bare patches in vegetated ground,
#'     equivalent to the "gaps" pattern (default: FALSE).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape("spots", params = pattern_spots(n_spots = 15))
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "spots",
#'   params_list = list(
#'     spots = pattern_spots(
#'       n_spots = c(5, 15),
#'       spot_radius = c(4, 8)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "spots",
#'   params_list = list(
#'     spots = pattern_spots(
#'       n_spots = 10,
#'       spot_radius = c(4, 8)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("spots")
#'
#' @export
pattern_spots <- function(
  n_spots = 5,
  spot_radius = 10,
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
#' Circular bare gaps in vegetated ground.
#'
#' @details
#' This is the inverse of \code{\link{pattern_spots}} and therefore has no
#' \code{invert_landscape} parameter.
#'
#' @param n_gaps Integer. Number of gaps (default: 5). Regular placement may
#'     reduce this number if the landscape cannot accommodate the requested
#'     count with the given \code{gap_radius}.
#' @param gap_radius Numeric. Mean radius of each gap in pixels (default: 10).
#'     Must be positive and smaller than landscape dimensions.
#' @param gap_radius_sd Numeric. Standard deviation of normally sampled gap
#'     radii (default: 0, no variation).
#' @param radius_noise_fraction Numeric. Fraction of the gap radius with a
#'     gradual edge transition (0-1). Zero gives sharp edges; 1 applies
#'     probabilistic cell inclusion across the full radius. For example, 0.2
#'     applies the transition to the outer 20\%. This is independent of
#'     \code{gap_radius_sd}, which varies overall gap size.
#' @param regular_gaps Logical. Arrange gaps on a hexagonal grid using k-means
#'     clustering rather than placing them randomly (default: FALSE).
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape("gaps", params = pattern_gaps(n_gaps = 5, gap_radius = 8))
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "gaps",
#'   params_list = list(
#'     gaps = pattern_gaps(
#'       n_gaps = c(4, 10),
#'       gap_radius = c(5, 10)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "gaps",
#'   params_list = list(
#'     gaps = pattern_gaps(
#'       n_gaps = 6,
#'       gap_radius = c(5, 10)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("gaps")
#'
#' @export
pattern_gaps <- function(
  n_gaps = 5,
  gap_radius = 10,
  gap_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_gaps = FALSE
) {
  params <- list()

  if (!missing(n_gaps)) {
    params$n_gaps <- n_gaps
  }
  if (!missing(gap_radius)) {
    params$gap_radius <- gap_radius
  }
  if (!missing(gap_radius_sd)) {
    params$gap_radius_sd <- gap_radius_sd
  }
  if (!missing(radius_noise_fraction)) {
    params$radius_noise_fraction <- radius_noise_fraction
  }
  if (!missing(regular_gaps)) {
    params$regular_gaps <- regular_gaps
  }

  new_landscape_params(params, pattern = "gaps")
}

#' Parameters for the Labyrinth Pattern
#'
#' Maze-like vegetation bands that mimic a Turing pattern.
#'
#' @param frequency Numeric. Spatial scale of the noise pattern. Lower values
#'     produce broad, smooth bands; higher values produce finer, more maze-like
#'     structures (default: 3).
#' @param veg_threshold Numeric. Threshold separating vegetated and bare cells
#'     (0-1, default: 0.5). Values above it become vegetation. Lower thresholds
#'     increase vegetation cover; higher thresholds reduce it.
#' @param band_fuzziness Numeric. Probability that an edge cell is eroded after
#'     thresholding (0-1, default: 0.08). This changes edge roughness without
#'     changing the underlying noise field. Zero gives deterministic boundaries;
#'     values around 0.05 to 0.1 add slight irregularities while largely
#'     preserving topology. Higher values may fragment bands, and values above
#'     roughly 0.3 can appear increasingly random rather than maze-like.
#' @param octaves Integer. Number of noise layers combined into the continuous
#'     field (at least 1, default: 2). One octave emphasizes smooth, large-scale
#'     structure. Two to three add fine-scale variation while preserving a
#'     dominant wavelength. Higher values add fractal-like detail that can
#'     obscure the bands.
#'
#' @return A named \code{"landscape_params"} list containing the supplied
#'     parameters.
#'
#' @family landscape creation
#'
#' @examples
#' # A single landscape, with fixed values
#' create_landscape(
#'   "labyrinth",
#'   params = pattern_labyrinth(frequency = 3.5, octaves = 3)
#' )
#'
#' # A batch, with parameters drawn from ranges once per landscape.
#' # Parameters left unset vary too, over their default ranges
#' create_landscapes(
#'   n = 4,
#'   patterns = "labyrinth",
#'   params_list = list(
#'     labyrinth = pattern_labyrinth(
#'       frequency = c(2.5, 4),
#'       octaves = c(2, 4)
#'     )
#'   )
#' )
#'
#' # A batch, mixing a fixed value with a range
#' create_landscapes(
#'   n = 4,
#'   patterns = "labyrinth",
#'   params_list = list(
#'     labyrinth = pattern_labyrinth(
#'       frequency = 3,
#'       octaves = c(2, 4)
#'     )
#'   )
#' )
#'
#' @evalRd rd_param_ranges("labyrinth")
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

#' Render a Pattern's Valid and Sampled Ranges as Rd
#'
#' Builds the "Valid values and batch sampling" section for a
#' \code{pattern_*()} help page from \code{\link{landscape_param_specs}}, so the
#' documented bounds cannot drift from the ones actually enforced, nor the
#' documented ranges from the ones actually sampled. Called from
#' \code{@evalRd} in each constructor's roxygen block.
#'
#' The section also carries the sentence on how single values and length-2
#' ranges are treated, which would otherwise be repeated on all eleven pages.
#'
#' @param pattern Character. Pattern to describe.
#'
#' @return Character vector of Rd markup, one element per line.
#'
#' @keywords internal
#' @noRd
rd_param_ranges <- function(pattern) {
  specs <- landscape_param_specs()[[pattern]]

  # Report dimension-dependent ranges for the default landscape size
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

  describe_bounds <- function(spec) {
    if (identical(spec$type, "logical")) {
      return("TRUE or FALSE")
    }

    if (isTRUE(spec$exclusive_min)) {
      lower <- sprintf("greater than %s", format(spec$min))
      if (is.finite(spec$max)) {
        return(sprintf("%s, up to %s", lower, format(spec$max)))
      }
      return(lower)
    }

    if (is.finite(spec$max)) {
      return(sprintf("%s to %s", format(spec$min), format(spec$max)))
    }

    sprintf("%s or more", format(spec$min))
  }

  rows <- vapply(
    names(specs),
    function(name) {
      sprintf(
        "\\code{%s} \\tab %s \\tab %s \\cr",
        name,
        describe_bounds(specs[[name]]),
        describe_range(specs[[name]]$batch_range)
      )
    },
    character(1)
  )

  c(
    "\\section{Valid values and batch sampling}{",
    "A single value fixes a parameter. A length-2 vector is a range, sampled",
    "once per landscape by \\code{\\link{create_landscapes}} and rejected by",
    "\\code{\\link{create_landscape}}. The table below shows for each parameter: ",
    "",
    "\\emph{valid} values that \\code{\\link{create_landscape}} accepts, and",
    "\\emph{sampled} ranges that \\code{\\link{create_landscapes}} draws from",
    "once per landscape for any parameter left unset. The defaults shown in",
    "Usage therefore apply to \\code{\\link{create_landscape}} only. Ranges that",
    sprintf(
      "scale with landscape size are shown for the default %d by %d.",
      width,
      height
    ),
    "\\tabular{lll}{",
    "\\strong{Parameter} \\tab \\strong{Valid} \\tab \\strong{Sampled} \\cr",
    unname(rows),
    "}",
    "}"
  )
}

#' Resolve Pattern Parameters for a Single Landscape
#'
#' Checks a \code{pattern_*()} parameter list and unwraps it for the generator.
#'
#' @param params Output of a \code{pattern_*()} constructor, or \code{NULL}.
#' @param pattern Character. Pattern being generated.
#'
#' @return Named list of parameters to pass to the generator.
#'
#' @keywords internal
#' @noRd
resolve_pattern_params <- function(params, pattern) {
  if (is.null(params)) {
    return(list())
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
