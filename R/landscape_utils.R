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

#' Set Landscape Class
#'
#' Sets the class attribute of a landscape object.
#'
#' @param x A landscape object
#' @param class Character string specifying the new class
#' @return The landscape object with updated class
#' @examples
#' # Single landscape
#' landscape <- create_landscape("sharp", width = 10, height = 10)
#' landscape <- set_landscape_class(landscape, "sharp_treeline")
#'
#' # Multiple landscapes with purrr
#' landscapes <- list(
#'   create_landscape("sharp", width = 10, height = 10),
#'   create_landscape("random", width = 10, height = 10)
#' )
#' classes_vec <- c("sharp_treeline", "random_pattern")
#' landscapes <- purrr::map2(landscapes, classes_vec, set_landscape_class)
#'
#' # Multiple landscapes with base R
#' landscapes <- mapply(set_landscape_class, landscapes, classes_vec, SIMPLIFY = FALSE)
#' @export
set_landscape_class <- function(x, class) {
  stopifnot(inherits(x, "landscape"))
  stopifnot(is.character(class) && length(class) == 1)

  x$class <- class
  return(x)
}
