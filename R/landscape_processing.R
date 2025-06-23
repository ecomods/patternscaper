#' Rotate and Crop Landscape
#'
#' Rotates a landscape and crops out NA cells at the edges.
#'
#' @param landscape Matrix or SpatRaster. Landscape to rotate.
#' @param angle Numeric. Rotation angle in degrees (default: 0).
#' @param fill_value Numeric. Value to fill new cells created during rotation (default: NA).
#'
#' @return SpatRaster. Rotated landscape with NA cells cropped out.
#' @export
rotate_and_crop_landscape <- function(
  landscape,
  angle = 0,
  fill_value = NA
) {
  # 1. Convert input to SpatRaster if not already
  # 2. Rotate the landscape by the specified angle
  # 3. Crop the result to remove NA cells at the edges
  # 4. Return the rotated and cropped landscape
}

#' Fill NA Values with Nearest Non-NA Values
#'
#' Replaces NA values in a raster with values from nearest non-NA cells.
#'
#' @param landscape SpatRaster. Landscape with NA values to fill.
#' @param max_distance Numeric. Maximum distance to search for non-NA values (default: 5).
#'
#' @return SpatRaster. Landscape with NA values filled.
#' @export
fill_na_with_nearest <- function(
  landscape,
  max_distance = 5
) {
  # 1. Identify NA cells in the input raster
  # 2. For each NA cell, search for nearest non-NA cells within max_distance
  # 3. Replace NA values with values from nearest non-NA cells
  # 4. Return filled landscape raster
}
