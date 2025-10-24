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

#' Create a landscape object
#'
#' Converts a matrix or SpatRaster into a landscape object that can be used
#' with landscape analysis functions.
#' @param data Matrix or SpatRaster containing landscape data
#' @param pattern Character string specifying the landscape pattern if known (default NA).
#' @param name Character string specifying the landscape name to distinguish it from other
#'     landscapes (default NA).
#' @param params List of parameters used to create the landscape. Can be empty but
#'     will be filled if landscapes are created automatically by the
#'     \code{\link{create_landscapes}} or the \code{\link{create_training_landscapes}} function.
#'     Default is NULL.
#' @return A landscape object
#' @examples
#' # Create from a matrix
#' mat <- matrix(runif(100), nrow = 10, ncol = 10)
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
#'   params = list(treeline_position = 0.5, rotation = 0)
#' )
#'
#' # Create from SpatRaster
#' rast <- terra::rast(mat)
#' l <- landscape(rast, name = "my_raster")
#' @export
landscape <- function(
  data,
  pattern = NA_character_,
  name = NA_character_,
  params = NULL
) {
  # Validate data type
  if (!is.matrix(data) && !inherits(data, "SpatRaster")) {
    stop("'data' must be a matrix or SpatRaster")
  }

  # Validate pattern
  if (!is.na(pattern) && !is.character(pattern)) {
    stop("'pattern' must be a character string or NA")
  }

  # Validate name
  if (!is.na(name) && !is.character(name)) {
    stop("'name' must be a character string or NA")
  }

  # Validate params
  if (!is.null(params) && !is.list(params)) {
    stop("'params' must be a list or NULL")
  }

  # Convert matrix to SpatRaster if needed
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
