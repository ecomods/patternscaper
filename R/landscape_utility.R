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
