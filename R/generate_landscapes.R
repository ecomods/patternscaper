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
    "clusters",
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
    clusters = create_landscape_clustered_trees(...),
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
#'
#' @param n Integer. Number of landscapes to generate per type (default: 10).
#' @param types Character vector. Types of landscapes to generate (default: all types).
#' @param width Integer. Width of landscapes in pixels (default: 100).
#' @param height Integer. Height of landscapes in pixels (default: 100).
#' @param add_rotation Logical. Whether to include rotated versions (default: TRUE).
#' @param rotation_angles Numeric vector. Rotation angles in degrees (default: c(0, 45, 90, 135)).
#' @param params_list List. List of parameter ranges for each landscape type (default: NULL).
#' @param seed Integer. Master random seed (default: NULL).
#'
#' @return List. Named list of generated landscapes with attributes for type.
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
  seed = NULL
) {
  # Function implementation will go here
}
