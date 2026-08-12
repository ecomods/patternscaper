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
    cli::cli_abort("Input must be a matrix")
  }

  if (!is.numeric(x)) {
    cli::cli_abort("Matrix must contain numeric values")
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
#' landscapes <- mapply(
#'   set_landscape_name, landscapes, names_vec,
#'   SIMPLIFY = FALSE
#' )
#' @family landscape objects
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
#' landscapes <- mapply(
#'   set_landscape_pattern, landscapes, patterns_vec,
#'   SIMPLIFY = FALSE
#' )
#' @family landscape objects
#' @export
set_landscape_pattern <- function(x, pattern) {
  stopifnot(inherits(x, "landscape"))
  stopifnot(is.character(pattern) && length(pattern) == 1)

  x$pattern <- pattern
  return(x)
}

#' Rotate and Crop a Landscape Matrix
#'
#' Rotates a given landscape matrix by a specified angle and crops the rotated
#' matrix to the target dimensions, centering the crop. Any missing values
#' after cropping are filled using nearest neighbor interpolation and binarized.
#'
#' @param mat A matrix representing the landscape to be rotated and cropped.
#' @param rotation Numeric value specifying the rotation angle (in degrees).
#' @param target_width Integer specifying the desired number of columns in the output.
#' @param target_height Integer specifying the desired number of rows in the output.
#'
#' @return A matrix with \code{target_height} rows and \code{target_width} columns,
#'   rotated and cropped from the input landscape, with missing values filled.
#'
#' @details The function uses \code{omnibus::rotateMatrix} for rotation and
#'   centers the crop on the rotated matrix. Missing values after cropping are
#'   filled using the \code{fill_and_binarize_matrix} function.
#'
#' @seealso \code{\link[omnibus]{rotateMatrix}}, \code{fill_and_binarize_matrix}
#' @keywords internal
rotate_and_crop_matrix <- function(
  mat,
  rotation,
  target_width,
  target_height
) {
  # Rotate matrix
  mat <- omnibus::rotateMatrix(mat, rotation)

  # Get dimensions of rotated matrix
  rotated_nrow <- nrow(mat)
  rotated_ncol <- ncol(mat)

  # Calculate the indices to crop the center
  start_row <- ceiling((rotated_nrow - target_height) / 2) + 1
  end_row <- start_row + target_height - 1

  start_col <- ceiling((rotated_ncol - target_width) / 2) + 1
  end_col <- start_col + target_width - 1

  # Crop the rotated matrix to the target size (take the center)
  mat <- mat[start_row:end_row, start_col:end_col]

  # Fill missing values with nearest neighbor interpolation
  mat <- fill_and_binarize_matrix(mat, binarize = TRUE)

  return(mat)
}

#' Fill NA Values in a Matrix Using Linear Interpolation
#'
#' This function fills NA values in a matrix by applying linear interpolation
#' row-wise and then column-wise using \code{zoo::na.approx}. Optionally, the
#' function can binarize the resulting matrix based on a threshold of 0.5.
#'
#' @param mat A numeric matrix containing NA values to be filled.
#' @param binarize Logical. If TRUE (default), the output matrix will be binarized,
#'   with values < 0.5 set to 0 and values >= 0.5 set to 1. If FALSE, the
#'   interpolated values are returned as is.
#'
#' @return A numeric matrix with NA values filled using linear interpolation.
#'   If \code{binarize = TRUE}, the matrix will contain only 0s and 1s.
#'
#' @details The function applies \code{zoo::na.approx} with \code{rule = 2} to
#'   ensure that NA values at the edges are filled with the nearest non-NA value.
#'   Interpolation is performed first row-wise, then column-wise to fill all
#'   remaining NAs. If any NAs remain after both passes, they are filled with 0.
#'
#' @keywords internal
fill_and_binarize_matrix <- function(mat, binarize = TRUE) {
  # Check if the input is a matrix
  if (!is.matrix(mat)) {
    cli::cli_abort("mat must be a matrix, but is of class: {class(mat)}")
  }

  # Apply na.approx row by row
  for (i in seq_len(nrow(mat))) {
    mat[i, ] <- zoo::na.approx(mat[i, ], na.rm = FALSE, rule = 2)
  }

  # Apply na.approx column by column to catch remaining NAs
  for (j in seq_len(ncol(mat))) {
    mat[, j] <- zoo::na.approx(mat[, j], na.rm = FALSE, rule = 2)
  }

  # Fill any remaining NAs (e.g., entire corners) with 0
  mat[is.na(mat)] <- 0

  if (binarize) {
    mat[mat < 0.5] <- 0
    mat[mat >= 0.5] <- 1
  }

  return(mat)
}
