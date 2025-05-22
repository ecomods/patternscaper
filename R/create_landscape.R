#' Create a landscape matrix with specified pattern
#'
#' A generic function that creates various types of landscape matrices using
#' specialized functions. The type of landscape is determined by the 'pattern'
#' parameter, and additional arguments are passed to the specialized function.
#'
#' @param pattern Character. The type of landscape to create. Options are:
#'   "sharp" (sharp treeline),
#'   "diffuse" (diffuse treeline),
#'   "curvy" (curvy treeline),
#'   "scattered" (randomly scattered trees),
#'   "clusters" (clustered trees),
#'   "fingers" (finger-like extensions),
#'   "bent_fingers" (bent finger-like extensions),
#'   "sine_bands" (sine wave bands)
#' @param ... Additional arguments passed to the specific landscape creation function.
#'   Common parameters for most functions include:
#'     \item{width}{Integer. Width of the landscape (default: 100).}
#'     \item{height}{Integer. Height of the landscape (default: 100).}
#'     \item{treeline_position}{Numeric. Position of the treeline (0-1).}
#'     \item{rotation}{Numeric. Rotation angle in degrees (default: 0).}
#'
#'   See the documentation for specific pattern functions for additional parameters.
#'
#' @return A binary matrix representing the generated landscape.
#'
#' @examples
#' # Create a sharp treeline landscape
#' sharp <- create_landscape("sharp", width = 80, height = 80)
#'
#' # Create a scattered treeline landscape with rotation
#' scattered <- create_landscape("scattered", rotation = 45, scatter_density = 0.2)
#'
#' # Create a sine bands landscape
#' bands <- create_landscape("sine_bands", amplitude = 8, frequency = pi/50)
#'
#' @export
create_landscape <- function(
  pattern = c(
    "sharp",
    "diffuse",
    "curvy",
    "scattered",
    "clusters",
    "fingers",
    "bent_fingers",
    "sine_bands"
  ),
  ...
) {
  # Define valid patterns
  valid_patterns <- eval(formals()$pattern)

  # Check if pattern is a valid string
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
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
    sharp = create_sharp_treeline(...),
    diffuse = create_diffuse_treeline(...),
    curvy = create_curvy_treeline(...),
    scattered = create_random_scatter(...),
    clusters = create_clusters(...),
    fingers = create_fingers(...),
    bent_fingers = create_bent_fingers(...),
    sine_bands = create_sine_bands(...)
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
