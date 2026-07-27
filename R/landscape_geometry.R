#' Summarise the geometry of a landscape
#'
#' Internal helper returning the spatial geometry of a single landscape object:
#' its cell dimensions, resolution, aspect ratio and number of missing cells.
#' Used to compare training and application landscapes so that mismatches in
#' extent, resolution, aspect ratio or missing data can be reported.
#'
#' @param landscape A landscape object.
#'
#' @return A one-row tibble with columns `n_row`, `n_col`, `cell_size_x`,
#'   `cell_size_y`, `aspect_ratio` (`n_col / n_row`) and `n_na`.
#'
#' @keywords internal
#' @importFrom tibble tibble
landscape_geometry <- function(landscape) {
  if (!is_landscape(landscape)) {
    cli::cli_abort("{.arg landscape} must be a landscape object.")
  }

  data <- landscape$data
  resolution <- terra::res(data)

  tibble::tibble(
    n_row = terra::nrow(data),
    n_col = terra::ncol(data),
    cell_size_x = resolution[1],
    cell_size_y = resolution[2],
    aspect_ratio = terra::ncol(data) / terra::nrow(data),
    n_na = sum(is.na(terra::values(data)))
  )
}

#' Summarise the geometry of several landscapes
#'
#' Internal helper mapping \code{\link{landscape_geometry}} over a list of landscapes and
#' row-binding the results, one row per landscape.
#'
#' @param landscapes A list of landscape objects.
#'
#' @return A tibble with one row per landscape (columns as in
#'   \code{\link{landscape_geometry}}).
#'
#' @keywords internal
#' @importFrom purrr map_dfr
landscapes_geometry <- function(landscapes) {
  purrr::map_dfr(landscapes, landscape_geometry)
}
