#' Calculate a Single Landscape Metric
#'
#' Internal function to calculate a specific landscape metric for a single landscape.
#' This function handles both plain SpatRaster lists and lists with metadata structure.
#'
#' @param landscapes A list of landscape objects
#' @param function_name Character. The name of the landscapemetrics function to call.
#' @return tibble. Results from the metric calculation including any warnings.
#' @keywords internal
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate
#' @importFrom utils getFromNamespace
calculate_single_metric <- function(landscapes, function_name) {
  # Get the function from landscapemetrics namespace
  func <- getFromNamespace(function_name, "landscapemetrics")
  purrr::map_dfr(
    seq_along(landscapes),
    \(i) {
      current <- landscapes[[i]]$data
      warnings_captured <- character(0)

      # Use withCallingHandlers to capture warnings
      result <- withCallingHandlers(
        {
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
          landscape_name = landscapes[[i]]$name,
          pattern = landscapes[[i]]$pattern,
          warnings = if (length(warnings_captured) > 0) {
            paste(warnings_captured, collapse = "; ")
          } else {
            NA_character_
          }
        )
    }
  )
}

#' Calculate Landscape Metrics
#'
#' Calculates selected landscape metrics for one or more landscapes using functions
#' from the landscapemetrics package. Returns a standardized tibble with results
#' including landscape identifiers, metric values, and any warnings.
#'
#' @param landscapes A single landscape object (created with \code{\link{create_landscape}})
#'   or a list of landscape objects (e.g. created with \code{\link{create_landscapes}}).
#'   Each landscape object should contain a \code{data}
#'   element with a SpatRaster, plus \code{name} and \code{pattern} metadata.
#' @param metrics Character vector. Names of metrics to calculate (default: NULL for all
#'   available metrics at the specified level). Use \code{list_lsm()} from landscapemetrics
#'   to see available metrics.
#' @param level Character. Level(s) of metrics to calculate:"class", "landscape"
#'   (default: "landscape").
#'
#' @return A tibble with the following columns:
#'   \describe{
#'     \item{landscape_id}{Numeric identifier for each landscape in the input list}
#'     \item{landscape_name}{Name of the landscape from the landscape object}
#'     \item{pattern}{Pattern type from the landscape object (e.g., "labyrinth", "spots")}
#'     \item{layer}{Layer number (from landscapemetrics output)}
#'     \item{level}{Metric level: "class", or "landscape"}
#'     \item{class}{Class value (for class-level metrics, NA for landscape-level)}
#'     \item{metric}{Name of the calculated metric}
#'     \item{value}{Calculated metric value}
#'     \item{warnings}{Any warnings generated during calculation (NA if none)}
#'   }
#'
#' @export
#' @importFrom dplyr mutate relocate
#' @importFrom purrr map_dfr
#'
#' @examples
#' \dontrun{
#' # Calculate all landscape-level metrics for a single landscape
#' landscape <- create_landscape(pattern = "labyrinth")
#' metrics <- calculate_landscape_metrics(landscape)
#'
#' # Calculate specific metrics for multiple landscapes
#' landscapes <- create_landscapes(n = 10, patterns = "spots")
#' metrics <- calculate_landscape_metrics(
#'   landscapes,
#'   metrics = c("ai", "lsi"),
#'   level = "landscape"
#' )
#'
#' }
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
  if (any(!vapply(landscapes, is_landscape, logical(1)))) {
    # find out which element is not a landscape
    invalid_indices <- which(!vapply(landscapes, is_landscape, logical(1)))
    stop(
      "All elements must be landscape objects. Invalid element(s) at index(es): ",
      paste(invalid_indices, collapse = ", ")
    )
  }

  # Check if level parameter is valid
  valid_levels <- c("class", "landscape")
  if (!all(level %in% valid_levels) || length(level) != 1) {
    stop(paste(
      "Invalid level:",
      paste(level, collapse = ", "),
      "\nValid options are a single value of: 'class', or 'landscape'"
    ))
  }

  # Check if metrics parameter is valid
  available_metrics <- landscapemetrics::list_lsm(level = level)

  # Filter metrics if specified
  if (!is.null(metrics)) {
    # Check if all requested metrics exist
    invalid_metrics <- metrics[!metrics %in% available_metrics$metric]
    if (length(invalid_metrics) > 0) {
      warning(paste(
        "The following metrics were not found and will be ignored:",
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

  # If the level is class, add the class id to the metric column
  # and store the original metric name in a new column
  all_results <- all_results |>
    mutate(
      metric_name = metric,
      metric = ifelse(
        level == "class",
        paste0(metric, "_", class),
        metric
      )
    )

  # Reorganize columns for better readability
  all_results <- all_results |>
    dplyr::relocate(
      landscape_id,
      landscape_name,
      pattern,
      level,
      layer,
      class,
      metric_name,
      metric,
      value,
      warnings
    )

  return(all_results)
}
