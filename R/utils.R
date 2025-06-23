#' Validate Raster Object
#'
#' Validates that a raster meets specified requirements.
#'
#' @param raster SpatRaster. The raster to validate.
#' @param categorical Logical. Whether to check if the raster has categorical values (default: FALSE).
#' @param max_size Numeric. Maximum allowed raster size in pixels (default: 10000).
#' @param verbose Logical. Whether to print additional information (default: FALSE).
#'
#' @return If verbose=FALSE: No return value, throws error if validation fails.
#'         If verbose=TRUE: List with raster size and unique classes.
#' @export
validate_raster <- function(
  raster,
  categorical = FALSE,
  max_size = 10000,
  verbose = FALSE
) {
  # 1. Check if input is a valid SpatRaster object
  # 2. If categorical=TRUE, check if values are categorical (discrete)
  # 3. Check if raster size exceeds max_size and issue a warning
  # 4. Verify that raster has valid dimensions
  # 5. If verbose=TRUE, return size and unique class information
}


#' Convert Matrix to Raster
#'
#' Converts a binary matrix to a SpatRaster object.
#'
#' @param matrix Matrix. Binary landscape matrix to convert.
#' @param resolution Numeric. Spatial resolution of output raster (default: 1).
#' @param crs Character. Coordinate reference system (default: NULL).
#'
#' @return SpatRaster. Raster representation of input matrix.
#' @export
matrix_to_raster <- function(
  matrix,
  resolution = 1,
  crs = NULL
) {
  # 1. Convert binary matrix to SpatRaster object
  # 2. Set resolution if provided
  # 3. Set CRS if provided
  # 4. Return the resulting SpatRaster
}
