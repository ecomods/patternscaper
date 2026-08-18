#' Convert a Matrix to a SpatRaster
#'
#' Converts a numeric matrix to a SpatRaster object.
#'
#' @param x Numeric matrix to convert.
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

  raster <- terra::rast(x)

  return(raster)
}

#' Set a Landscape Name
#'
#' Replaces the name stored in a landscape object.
#'
#' @param x A landscape object.
#' @param name Character. New landscape name to store.
#' @return The landscape object with its updated name.
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

#' Set a Landscape Pattern
#'
#' Replaces the pattern label stored in a landscape object.
#'
#' @param x A landscape object.
#' @param pattern Character. New pattern label to store.
#' @return The landscape object with its updated pattern label.
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
#' Rotates a landscape matrix, takes a centered crop of the requested size,
#' fills missing values by linear interpolation, and restores binary values.
#'
#' @param mat Landscape matrix to rotate and crop.
#' @param rotation Numeric rotation angle in degrees.
#' @param target_width Integer. Number of columns in the output.
#' @param target_height Integer. Number of rows in the output.
#'
#' @return A matrix with \code{target_height} rows and \code{target_width} columns,
#'   rotated and cropped from the input landscape.
#'
#' @details The function uses \code{omnibus::rotateMatrix} for rotation and
#'   \code{fill_and_binarize_matrix} to fill missing values and binarize the
#'   result.
#'
#' @seealso \code{\link[omnibus]{rotateMatrix}}, \code{fill_and_binarize_matrix}
#' @keywords internal
rotate_and_crop_matrix <- function(
  mat,
  rotation,
  target_width,
  target_height
) {
  # Rotate before taking the centered crop
  mat <- omnibus::rotateMatrix(mat, rotation)

  rotated_nrow <- nrow(mat)
  rotated_ncol <- ncol(mat)

  # Centered crop bounds
  start_row <- ceiling((rotated_nrow - target_height) / 2) + 1
  end_row <- start_row + target_height - 1

  start_col <- ceiling((rotated_ncol - target_width) / 2) + 1
  end_col <- start_col + target_width - 1

  # Crop the rotated matrix to the target size (take the center)
  mat <- mat[start_row:end_row, start_col:end_col]

  # Interpolate missing cells and restore binary values
  mat <- fill_and_binarize_matrix(mat, binarize = TRUE)

  return(mat)
}

#' Fill Missing Matrix Values by Linear Interpolation
#'
#' Applies \code{zoo::na.approx} across rows and then columns. The result can
#' optionally be binarized at a threshold of 0.5.
#'
#' @param mat Numeric matrix containing missing values.
#' @param binarize Logical. Whether to set values below 0.5 to 0 and values at
#'   least 0.5 to 1 (default: TRUE).
#'
#' @return A numeric matrix with missing values filled. If
#'   \code{binarize = TRUE}, it contains only 0 and 1.
#'
#' @details The function applies \code{zoo::na.approx} with \code{rule = 2} to
#'   extend edge values. Missing values remaining after both passes are set to
#'   0.
#'
#' @keywords internal
fill_and_binarize_matrix <- function(mat, binarize = TRUE) {
  # Validate input
  if (!is.matrix(mat)) {
    cli::cli_abort("mat must be a matrix, but is of class: {class(mat)}")
  }

  # Interpolate rows
  for (i in seq_len(nrow(mat))) {
    mat[i, ] <- zoo::na.approx(mat[i, ], na.rm = FALSE, rule = 2)
  }

  # Interpolate columns to catch remaining missing values
  for (j in seq_len(ncol(mat))) {
    mat[, j] <- zoo::na.approx(mat[, j], na.rm = FALSE, rule = 2)
  }

  # Fill values that remain missing after both passes
  mat[is.na(mat)] <- 0

  if (binarize) {
    mat[mat < 0.5] <- 0
    mat[mat >= 0.5] <- 1
  }

  return(mat)
}
