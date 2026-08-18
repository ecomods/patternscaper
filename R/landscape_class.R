#' Create a new landscape object
#'
#' Internal constructor for landscape objects.
#' @param data SpatRaster containing landscape data
#' @param pattern Character string specifying landscape pattern
#' @param name Character string specifying landscape name
#' @param params List of parameters used to create the landscape
#' @return A landscape object
#' @keywords internal
new_landscape <- function(
  data,
  pattern = NA_character_,
  name = NA_character_,
  params = NULL
) {
  stopifnot(inherits(data, "SpatRaster"))

  structure(
    list(
      data = data,
      pattern = pattern,
      name = name,
      params = params
    ),
    class = "landscape"
  )
}

#' Create a Landscape Object
#'
#' Wraps a matrix or SpatRaster with pattern, name, and generation-parameter
#' metadata into a landscape object that can be used by other patternscaper
#' functions.
#' @param data Matrix or \code{SpatRaster} containing landscape data.
#' @param pattern Character. Known pattern label, or \code{NA} if unknown
#'     (default).
#' @param name Character. Landscape name, or \code{NA} if unnamed (default).
#' @param params List. Parameters used to generate the landscape (default: NULL).
#'     \code{\link{create_landscape}} and \code{\link{create_landscapes}} fill
#'     this automatically.
#' @return A landscape object containing the data and metadata.
#' @examples
#' # Create from a binary matrix (0 = bare ground, 1 = vegetation)
#' mat <- matrix(rbinom(100, 1, 0.5), nrow = 10, ncol = 10)
#' l <- landscape(mat)
#'
#' # Create with pattern and name
#' l <- landscape(mat, pattern = "random", name = "test_landscape")
#'
#' # Create with parameters
#' l <- landscape(
#'   mat,
#'   pattern = "sharp",
#'   name = "alpine_treeline",
#'   params = list(boundary_position = 0.5, rotation = 0)
#' )
#'
#' # Create from SpatRaster
#' rast <- terra::rast(mat)
#' l <- landscape(rast, name = "my_raster")
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#' @family landscape objects
#' @export
landscape <- function(
  data,
  pattern = NA_character_,
  name = NA_character_,
  params = NULL
) {
  # Validate inputs
  if (!is.matrix(data) && !inherits(data, "SpatRaster")) {
    cli::cli_abort("'data' must be a matrix or SpatRaster")
  }

  if (!is.na(pattern) && !is.character(pattern)) {
    cli::cli_abort("'pattern' must be a character string or NA")
  }

  if (!is.na(name) && !is.character(name)) {
    cli::cli_abort("'name' must be a character string or NA")
  }

  if (!is.null(params) && !is.list(params)) {
    cli::cli_abort("'params' must be a list or NULL")
  }

  # Store all landscape data as a SpatRaster
  if (is.matrix(data)) {
    data <- matrix_to_raster(data)
  }

  new_landscape(data, pattern, name, params)
}

#' Check if an object is a landscape
#'
#' @param x Object to check
#' @return Logical indicating if x is a landscape object
#' @keywords internal
is_landscape <- function(x) {
  inherits(x, "landscape")
}
