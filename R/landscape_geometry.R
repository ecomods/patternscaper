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

#' Compact geometry summary from a per-landscape geometry table
#'
#' Internal core that condenses a per-landscape geometry table (columns `n_row`,
#' `n_col`, `cell_size_x`, `cell_size_y`) into a one-row record stored in a
#' trained model. It records the representative dimensions and resolution (the
#' median, which equals the common value when all landscapes match) plus whether
#' the set is homogeneous in dimensions *and* resolution, so that
#' \code{\link{apply_metrics_model}} and \code{\link{apply_pixel_model}} can warn when application
#' landscapes differ from the data the model was trained on.
#'
#' @param geometry A per-landscape geometry tibble (see \code{\link{landscapes_geometry}}).
#'
#' @return A one-row tibble with columns `n_landscapes`, `n_row`, `n_col`,
#'   `cell_size_x`, `cell_size_y` and `homogeneous`.
#'
#' @keywords internal
#' @importFrom tibble tibble
summarise_geometry <- function(geometry) {
  tibble::tibble(
    n_landscapes = nrow(geometry),
    n_row = stats::median(geometry$n_row),
    n_col = stats::median(geometry$n_col),
    cell_size_x = stats::median(geometry$cell_size_x),
    cell_size_y = stats::median(geometry$cell_size_y),
    homogeneous = nrow(unique(
      geometry[, c("n_row", "n_col", "cell_size_x", "cell_size_y")]
    )) ==
      1
  )
}

#' Compact geometry summary of a set of landscapes
#'
#' Internal helper: computes the per-landscape geometry of a list of landscapes
#' and condenses it via \code{\link{summarise_geometry}}. Used by \code{\link{train_pixel_model}},
#' which receives landscape objects directly.
#'
#' @param landscapes A list of landscape objects.
#'
#' @return A one-row tibble (see \code{\link{summarise_geometry}}).
#'
#' @keywords internal
summarise_training_geometry <- function(landscapes) {
  summarise_geometry(landscapes_geometry(landscapes))
}

#' Training-geometry summary from a metrics tibble
#'
#' Internal helper: extracts the per-landscape geometry columns that
#' \code{\link{calculate_metrics}} attaches to its output and condenses them via
#' \code{\link{summarise_geometry}}. Used by \code{\link{train_metrics_model}}, which receives the
#' metrics tibble rather than the landscapes. Returns `NULL` when the geometry
#' columns are absent (e.g. a metrics table cached before geometry was recorded,
#' or built by hand), so callers can skip geometry checks gracefully.
#'
#' @param metrics A metrics tibble from \code{\link{calculate_metrics}}.
#'
#' @return A one-row tibble (see \code{\link{summarise_geometry}}), or `NULL`.
#'
#' @keywords internal
#' @importFrom dplyr distinct
training_geometry_from_metrics <- function(metrics) {
  geometry_cols <- c(
    "landscape_id",
    "n_row",
    "n_col",
    "cell_size_x",
    "cell_size_y"
  )
  if (!all(geometry_cols %in% colnames(metrics))) {
    return(NULL)
  }

  geometry <- dplyr::distinct(
    metrics,
    landscape_id,
    n_row,
    n_col,
    cell_size_x,
    cell_size_y
  )
  summarise_geometry(geometry)
}
