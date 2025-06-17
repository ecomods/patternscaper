#' List Available Landscape Metrics
#'
#' Lists metrics available for landscape analysis from the landscapemetrics package.
#'
#' @param level Character. Level of metrics to list ("patch", "class", "landscape", or "all") (default: "all").
#' @param sort Logical. Whether to sort metrics alphabetically (default: TRUE).
#'
#' @return data.frame. Table of available metrics with descriptions.
#' @export
list_available_metrics <- function(
  level = "all",
  sort = TRUE
) {
  # Function implementation will go here
}

#' Calculate Landscape Metrics
#'
#' Calculates selected landscape metrics for one or more landscapes.
#'
#' @param landscapes List or SpatRaster. Landscape(s) to analyze.
#' @param metrics Character vector. Names of metrics to calculate (default: NULL for all).
#' @param level Character. Level of metrics to calculate ("patch", "class", "landscape") (default: "class").
#' @param progress Logical. Whether to show progress bar (default: TRUE).
#'
#' @return tibble. Standardized metrics table.
#' @export
calculate_landscape_metrics <- function(
  landscapes,
  metrics = NULL,
  level = "class",
  progress = TRUE
) {
  # Function implementation will go here
}
