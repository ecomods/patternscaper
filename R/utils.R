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


#' Ensure Landscape is a SpatRaster
#' Validates that the input landscape is either a matrix or a SpatRaster object.
#'
#' @param landscape Matrix or SpatRaster. The landscape to validate.
#' @return SpatRaster. Converted or validated SpatRaster object.
#'
#' @noRd
ensure_spatraster <- function(landscape) {
  if (is.matrix(landscape)) {
    message("Converting matrix to SpatRaster...")
    return(matrix_to_raster(landscape))
  } else if (class(landscape)[1] == "SpatRaster") {
    return(landscape)
  } else {
    stop("Input must be either a matrix or SpatRaster object")
  }
}
