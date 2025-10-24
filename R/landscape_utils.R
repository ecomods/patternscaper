#' Convert matrix to SpatRaster
#'
#' Internal utility function to convert a numeric matrix to a SpatRaster object.
#'
#' @param x Matrix; numeric matrix to convert.
#'
#' @return A SpatRaster object.
#'
#' @importFrom terra rast
#' @keywords internal
matrix_to_raster <- function(
  x
) {
  if (!is.matrix(x)) {
    stop("Input must be a matrix")
  }

  if (!is.numeric(x)) {
    stop("Matrix must contain numeric values")
  }

  # Convert matrix to SpatRaster
  raster <- terra::rast(x)

  return(raster)
}

#' Set Landscape Name
#'
#' Sets the name attribute of a landscape object.
#'
#' @param x A landscape object
#' @param name Character string specifying the new name
#' @return The landscape object with updated name
#' @examples
#' # Single landscape
#' landscape <- create_landscape("sharp", width = 10, height = 10)
#' landscape <- set_landscape_name(landscape, "alpine_treeline")
#'
#' # Multiple landscapes with purrr
#' landscapes <- list(
#'   create_landscape("sharp", width = 10, height = 10),
#'   create_landscape("random", width = 10, height = 10)
#' )
#' names_vec <- c("alpine", "subalpine")
#' landscapes <- purrr::map2(landscapes, names_vec, set_landscape_name)
#'
#' # Multiple landscapes with base R
#' landscapes <- mapply(set_landscape_name, landscapes, names_vec, SIMPLIFY = FALSE)
#' @export
set_landscape_name <- function(x, name) {
  stopifnot(inherits(x, "landscape"))
  stopifnot(is.character(name) && length(name) == 1)

  x$name <- name
  return(x)
}

#' Set Landscape pattern
#'
#' Sets the pattern attribute of a landscape object.
#'
#' @param x A landscape object
#' @param pattern Character string specifying the new pattern
#' @return The landscape object with updated pattern
#' @examples
#' # Single landscape
#' landscape <- create_landscape("sharp", width = 10, height = 10)
#' landscape <- set_landscape_pattern(landscape, "sharp_treeline")
#'
#' # Multiple landscapes with purrr
#' landscapes <- list(
#'   create_landscape("sharp", width = 10, height = 10),
#'   create_landscape("random", width = 10, height = 10)
#' )
#' patterns_vec <- c("sharp_treeline", "random_pattern")
#' landscapes <- purrr::map2(landscapes, patterns_vec, set_landscape_pattern)
#'
#' # Multiple landscapes with base R
#' landscapes <- mapply(set_landscape_pattern, landscapes, patterns_vec, SIMPLIFY = FALSE)
#' @export
set_landscape_pattern <- function(x, pattern) {
  stopifnot(inherits(x, "landscape"))
  stopifnot(is.character(pattern) && length(pattern) == 1)

  x$pattern <- pattern
  return(x)
}
