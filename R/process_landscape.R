#' Rotate and Crop a Landscape Matrix
#'
#' Rotates a given landscape matrix by a specified angle and crops the rotated
#' matrix to the target width and height, centering the crop. Any missing values
#' after cropping are filled with the values of their nearest neighbors.
#'
#' @param mat A matrix representing the landscape to be rotated and cropped.
#' @param rotation Numeric value specifying the rotation angle (in degrees).
#' @param target_width Integer specifying the desired width of the cropped matrix.
#' @param target_height Integer specifying the desired height of the cropped matrix.
#'
#' @return A matrix of size \code{target_width} x \code{target_height}, rotated
#'   and cropped from the input landscape, with missing values filled.
#'
#' @details The function uses \code{omnibus::rotateMatrix} for rotation and
#'   centers the crop on the rotated matrix. Missing values after cropping are
#'   filled using the \code{fill_na_with_nearest} function.
#'
#' @seealso \code{\link[omnibus]{rotateMatrix}}, \code{fill_na_with_nearest}
rotate_and_crop_matrix <- function(
  mat,
  rotation,
  target_width,
  target_height
) {
  # check if the mat is a matrix
  if (!is.matrix(mat)) {
    stop("mat must be a matrix, but is of class: ", class(mat))
  }
  # rotate mat and crop it to the original size
  mat <- omnibus::rotateMatrix(mat, rotation)
  # # crop the rotated mat to the original size (take the center)
  # get dimensions of rotated mat
  rotated_nrow <- nrow(mat)
  rotated_ncol <- ncol(mat)

  # calculate the indices to crop the center
  start_row <- ceiling((rotated_nrow - target_width) / 2)
  end_row <- start_row + target_width - 1

  start_col <- ceiling((rotated_ncol - target_height) / 2)
  end_col <- start_col + target_height - 1

  # crop the rotated mat to the target size (take the center)
  mat <- mat[start_row:end_row, start_col:end_col]
  # fill the last missing values with the values of their nearest neighbors
  # first turn to raster
  mat <- fill_na_with_nearest(mat, binarize = TRUE)
  return(mat)
}

#' Fill NA Values in a Matrix Using Nearest Neighbor Interpolation
#'
#' This function fills NA values in a matrix by applying nearest neighbor interpolation
#' row-wise sing the \code{na.approx} function from the \code{zoo} package.
#' Optionally, the function can binarize the resulting matrix based on a threshold of 0.5.
#'
#' @param matrix_with_na A numeric matrix containing NA values to be filled.
#' @param binarize Logical. If TRUE (default), the output matrix will be binarized,
#'   with values < 0.5 set to 0 and values >= 0.5 set to 1. If FALSE, the interpolated
#'   values are returned as is.
#'
#' @return A numeric matrix with NA values filled using nearest neighbor interpolation.
#'   If \code{binarize = TRUE}, the matrix will contain only 0s and 1s.
#'
#' @details The function applies \code{zoo::na.approx} with \code{rule = 2} to ensure that
#'   NA values at the edges are filled with the nearest non-NA value. The interpolation
#'   is performed first row by row and then column by column to ensure all NA values are filled.
fill_na_with_nearest <- function(matrix_with_na, binarize = TRUE) {
  # Check if the input is a matrix
  if (!is.matrix(matrix_with_na)) {
    stop(
      "matrix_with_na must be a matrix, but is of class: ",
      class(matrix_with_na)
    )
  }

  # Apply na.approx row by row
  for (i in 1:nrow(matrix_with_na)) {
    matrix_with_na[i, ] <- zoo::na.approx(
      matrix_with_na[i, ],
      na.rm = FALSE,
      rule = 2
    )
  }

  if (binarize) {
    matrix_with_na[matrix_with_na < 0.5] <- 0
    matrix_with_na[matrix_with_na >= 0.5] <- 1
  }

  return(matrix_with_na)
}
