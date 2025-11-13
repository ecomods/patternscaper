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
#' Validates rotation angle parameter.
#'
#' @param rotation Numeric. Angle to rotate landscape in degrees.
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_rotation <- function(rotation) {
  if (!is.numeric(rotation) || rotation < 0 || rotation > 360) {
    cli::cli_abort(c(
      "{.arg rotation} must be numeric and between 0 and 360.",
      "x" = "You supplied {.val {rotation}}"
    ))
  }

  invisible(NULL)
}

#' Validate Treeline Position Parameter
#'
#' Validates treeline position parameter for treeline-based landscapes.
#'
#' @param treeline_position Numeric. Relative position of treeline from top (0-1).
#'
#' @return NULL (invisibly). Called for side effects (validation).
#'
#' @keywords internal
#' @noRd
validate_treeline_position <- function(treeline_position) {
  if (
    !is.numeric(treeline_position) ||
      treeline_position < 0 ||
      treeline_position > 1
  ) {
    cli::cli_abort(c(
      "{.arg treeline_position} must be between 0 and 1.",
      "x" = "You supplied {.val {treeline_position}}"
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
