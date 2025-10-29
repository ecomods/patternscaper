#' Calculate a Single Landscape Metric
#'
#' Internal function to calculate a specific landscape metric for a single landscape.
#' This function handles both plain SpatRaster lists and lists with metadata structure.
#'
#' @param landscapes A list of landscape objects
#' @param function_name Character. The name of the landscapemetrics function to call.
#' @return tibble. Results from the metric calculation including any warnings.
#' @noRd
calculate_single_metric <- function(landscapes, function_name) {
  # Extract landscape names
  landscape_names <- purrr::map_chr(landscapes, function(x) x$name)

  # Try to calculate the metric
  result <- tryCatch(
    {
      purrr::map2_dfr(
        landscape_names,
        seq_along(landscapes),
        \(name, i) {
          current <- landscapes[[i]]$data

          # Create a wrapper that captures warnings
          warnings_captured <- character(0)

          # Use withCallingHandlers to capture warnings
          result <- withCallingHandlers(
            {
              # Get the function from landscapemetrics namespace
              func <- getFromNamespace(function_name, "landscapemetrics")
              func(current)
            },
            warning = function(w) {
              warnings_captured <<- c(warnings_captured, conditionMessage(w))
              invokeRestart("muffleWarning")
            }
          )

          # Add landscape name, type, and any warnings to the result
          result |>
            dplyr::mutate(
              landscape_id = i,
              landscape_name = name,
              pattern = landscapes[[i]]$pattern,
              warnings = ifelse(
                length(warnings_captured) > 0,
                paste(warnings_captured, collapse = "; "),
                NA_character_
              )
            )
        }
      )
    },
    error = function(e) {
      warning(paste("Error calculating", function_name, ":", e$message))
      return(NULL)
    }
  )

  return(result)
}

#' Calculate Landscape Metrics
#'
#' Calculates selected landscape metrics for one or more landscapes.
#'
#' @param landscapes A single landscape object or a list of landscape objects.
#' @param metrics Character vector. Names of metrics to calculate (default: NULL for all).
#' @param level Character. Level(s) of metrics to calculate ("patch", "class", "landscape" or a vector) (default: "landscape").
#'
#' @return tibble. Standardized metrics table with landscape name, type (if available), metric name,
#'         class (if applicable), and value.
#' @export
calculate_landscape_metrics <- function(
  landscapes,
  metrics = NULL,
  level = "landscape"
) {
  # Validate inputs

  # If landscapes is a single landscape, wrap it into a list
  if (is_landscape(landscapes)) {
    # Wrap single landscape into a list
    landscapes <- list(landscapes)
  }

  # Check if landscapes is a list of landscape objects
  if (any(!sapply(landscapes, is_landscape))) {
    # find out which element is not a landscape
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    stop(
      "All elements must be landscape objects. Invalid element(s) at index(es): ",
      paste(invalid_indices, collapse = ", ")
    )
  }

  # Get available metrics for the requested level(s)
  available_metrics <- list_available_metrics(level = level)

  # Filter metrics if specified
  if (!is.null(metrics)) {
    # Check if all requested metrics exist
    invalid_metrics <- metrics[!metrics %in% available_metrics$metric]
    if (length(invalid_metrics) > 0) {
      warning(paste(
        "The following metrics were not found:",
        paste(invalid_metrics, collapse = ", ")
      ))
    }

    # Filter available metrics to only those requested
    available_metrics <- available_metrics[
      available_metrics$metric %in% metrics,
    ]

    if (nrow(available_metrics) == 0) {
      stop("No valid metrics selected for the specified level(s).")
    }
  }

  available_function_names <- available_metrics$function_name

  # calculate all selected metrics for all landscapes
  all_results <- purrr::map_dfr(
    available_function_names,
    ~ calculate_single_metric(landscapes = landscapes, function_name = .x),
    .progress = TRUE
  )

  # Reorganize columns for better readability
  all_results <- all_results |>
    dplyr::relocate(
      landscape_id,
      landscape_name,
      pattern,
      layer,
      level,
      class,
      id,
      metric,
      layer,
      value,
      warnings
    )

  return(all_results)
}
