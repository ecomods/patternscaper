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
    cli::cli_abort("Input must be either a matrix or SpatRaster object")
  }
}
