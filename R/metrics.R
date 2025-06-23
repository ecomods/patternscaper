#' List Available Landscape Metrics
#'
#' Lists metrics available for landscape analysis from the landscapemetrics package.
#'
#' @param level Character. Level(s) of metrics to list: "patch", "class", "landscape",
#'        or "all". Can be a single string or vector of multiple levels (default: "all").
#' @param sort Logical. Whether to sort metrics alphabetically (default: TRUE).
#'
#' @return data.frame. Table of available metrics with descriptions.
#' @export
list_available_metrics <- function(
  level = "all",
  sort = TRUE
) {
  # Get available metrics from landscapemetrics
  metrics <- landscapemetrics::list_lsm()

  # Define valid levels
  valid_levels <- c("patch", "class", "landscape", "all")

  # Handle level filtering
  if (length(level) == 1 && level == "all") {
    # Keep all metrics - no filtering needed
  } else {
    # Check if all provided levels are valid
    if (!all(level %in% valid_levels)) {
      invalid_levels <- level[!level %in% valid_levels]
      stop(paste(
        "Invalid level(s):",
        paste(invalid_levels, collapse = ", "),
        "\nValid options are: 'patch', 'class', 'landscape', or 'all'"
      ))
    }

    # Filter metrics by the specified level(s)
    # Remove "all" from filtering if it's mixed with specific levels
    level <- level[level != "all"]

    if (length(level) > 0) {
      metrics <- metrics[metrics$level %in% level, ]

      # Check if metrics list is empty after filtering
      if (nrow(metrics) == 0) {
        warning(paste(
          "No metrics found for specified level(s):",
          paste(level, collapse = ", ")
        ))
        return(data.frame())
      }
    }
  }

  # Sort if requested
  if (sort) {
    metrics <- metrics[order(metrics$metric), ]
  }

  # Select only relevant columns
  result <- metrics[, c("metric", "name", "type", "level", "function_name")]

  return(result)
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
