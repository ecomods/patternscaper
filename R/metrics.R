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
#' @param metrics Character vector. Abbreviations of the metrics to calculate
#'   (default: NULL for all available metrics at the specified level). Use
#'   \code{\link[landscapemetrics]{list_lsm}} to look up the available
#'   abbreviations and the full metric name each one stands for.
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
#'     \item{metric_name}{Metric abbreviation without the class suffix, e.g.
#'       "ai". Identical to \code{metric} for landscape-level metrics.}
#'     \item{metric}{Metric abbreviation identifying the row, e.g. "ai". For
#'       class-level metrics the class is appended, e.g. "ai_1", so that each
#'       class gets its own identifier.}
#'     \item{value}{Calculated metric value}
#'     \item{warnings}{Any warnings generated during calculation (NA if none)}
#'     \item{n_row, n_col}{Cell dimensions of the landscape the row was computed from}
#'     \item{cell_size_x, cell_size_y}{Cell resolution (from \code{\link[terra]{res}})}
#'     \item{n_na}{Number of NA cells in the landscape}
#'   }
#'   Metrics are identified by their abbreviation throughout. To see what an
#'   abbreviation stands for, look it up with
#'   \code{\link[landscapemetrics]{list_lsm}}; \code{\link{evaluate_metrics}}
#'   reports the full names in its ranking table, and \code{\link{plot_metrics}}
#'   can use them as facet labels via \code{metric_labels = "name"}.
#'
#'   The last five columns record each landscape's geometry so it stays attached to
#'   the metrics (e.g. through \code{\link[readr]{write_csv}}); they are used for
#'   geometry-mismatch checks and are never used as model predictors.
#'
#' @references
#' Hesselbarth, M.H.K., Sciaini, M., With, K.A., Wiegand, K., & Nowosad, J.
#' (2019). landscapemetrics: an open-source R tool to calculate landscape
#' metrics. *Ecography*, 42(10), 1648-1657. \doi{10.1111/ecog.04617}
#'
#' @seealso \code{\link{plot_metrics}},
#'   \code{\link[landscapemetrics]{list_lsm}} for the available metrics and
#'   their full names
#' @family metrics
#' @export
#' @importFrom dplyr mutate relocate
#' @importFrom purrr map_dfr
#'
#' @examples
#' \donttest{
#' # Calculate all landscape-level metrics for a single landscape
#' landscape <- create_landscape(pattern = "labyrinth")
#' metrics <- calculate_metrics(landscape)
#'
#' # Calculate specific metrics for multiple landscapes
#' landscapes <- create_landscapes(n = 10, patterns = "spots")
#' metrics <- calculate_metrics(
#'   landscapes,
#'   metrics = c("ai", "lsi"),
#'   level = "landscape"
#' )
#'
#' }
calculate_metrics <- function(
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
    cli::cli_abort(
      "All elements must be landscape objects. Invalid element(s) at index(es): {paste(invalid_indices, collapse = ', ')}"
    )
  }

  # Check if level parameter is valid
  valid_levels <- c("class", "landscape")
  if (!all(level %in% valid_levels) || length(level) != 1) {
    cli::cli_abort(
      "Invalid level: {paste(level, collapse = ', ')}. Valid options are a single value of: 'class', or 'landscape'"
    )
  }

  # Check if metrics parameter is valid
  available_metrics <- landscapemetrics::list_lsm(level = level)

  # Filter metrics if specified
  if (!is.null(metrics)) {
    # Check if all requested metrics exist
    invalid_metrics <- metrics[!metrics %in% available_metrics$metric]
    if (length(invalid_metrics) > 0) {
      cli::cli_warn(
        "The following metrics were not found and will be ignored: {.val {invalid_metrics}}"
      )
    }

    # Filter available metrics to only those requested
    available_metrics <- available_metrics[
      available_metrics$metric %in% metrics,
    ]

    if (nrow(available_metrics) == 0) {
      cli::cli_abort("No valid metrics selected for the specified level(s).")
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

  # Remove unused id column (this is only interesting for the patch level
  # which the package does not support)
  all_results <- all_results |>
    select(-id)

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

  # Attach per-landscape geometry (dimensions, resolution, NA count) so it travels
  # with the metrics. It survives a write_csv()/read_csv() round-trip, unlike an
  # attribute, so a user who caches the metrics can still get geometry-mismatch
  # checks at model training and application. metrics_to_wide() selects an explicit
  # column set, so these never enter the model predictors.
  geometry <- landscapes_geometry(landscapes) |>
    dplyr::mutate(landscape_id = dplyr::row_number()) |>
    dplyr::select(
      landscape_id,
      n_row,
      n_col,
      cell_size_x,
      cell_size_y,
      n_na
    )

  all_results <- all_results |>
    dplyr::left_join(geometry, by = "landscape_id")

  return(all_results)
}

#' Look Up Full Metric Names
#'
#' Internal helper translating metric abbreviations into the full names from
#' \code{\link[landscapemetrics]{list_lsm}}, used wherever abbreviations are
#' shown to users (facet strips in \code{\link{plot_metrics}}, the ranking table
#' from \code{\link{evaluate_metrics}}).
#'
#' The lookup is keyed on `base_metric` rather than `metric` because class-level
#' metrics carry the class id as a suffix ("ai_1"), which `list_lsm()` does not
#' know.
#'
#' Two things `list_lsm()` names do not distinguish are appended in brackets so
#' the label identifies exactly one metric:
#' \itemize{
#'   \item The aggregation statistic. Metrics summarising per-patch values come
#'     as a `_cv`/`_mn`/`_sd` triple that all share one name -- `area_cv`,
#'     `area_mn` and `area_sd` are all "patch area". Half the landscape-level
#'     metrics are in such a triple, so without this the label is ambiguous.
#'   \item The class id, for class-level metrics.
#' }
#' Both go in a single bracket when both apply ("Patch area (mean, class 1)").
#'
#' Unknown abbreviations fall back to the abbreviation itself, so a metric that
#' `landscapemetrics` does not document still labels sensibly. Whether that is
#' worth a warning depends on the caller: `plot_metrics(metric_labels = "name")`
#' warns because the user explicitly asked for names and silently getting
#' abbreviations would be confusing, while `evaluate_metrics()` does not,
#' because its `name` column is supplied unasked and users may legitimately
#' rank metrics that `landscapemetrics` never defined.
#'
#' @param metric Character vector of metric identifiers as they appear to the
#'   user (class-level ones suffixed with the class id).
#' @param base_metric Character vector, parallel to `metric`, holding the
#'   unsuffixed abbreviation to look up. Identical to `metric` at the landscape
#'   level.
#' @param level Either "landscape" or "class".
#' @param warn Logical. Warn about abbreviations that could not be resolved.
#'
#' @return Character vector of display names, the same length as `metric`.
#' @noRd
lookup_metric_names <- function(metric, base_metric, level, warn = TRUE) {
  metric <- as.character(metric)
  base_metric <- as.character(base_metric)

  lsm_lookup <- landscapemetrics::list_lsm(level = level)
  name <- lsm_lookup$name[match(base_metric, lsm_lookup$metric)]

  unmatched <- is.na(name)
  if (warn && any(unmatched)) {
    cli::cli_warn(
      "Could not find full name(s) for metric(s) {.val {unique(metric[unmatched])}}; showing abbreviation instead."
    )
  }

  # list_lsm() names are all lowercase, so str_to_sentence() lowercasing the
  # rest of the string changes nothing
  name[!unmatched] <- stringr::str_to_sentence(name[!unmatched])
  name[unmatched] <- metric[unmatched]

  # The aggregation statistic, from the abbreviation's trailing token. These
  # three are the only ones landscapemetrics uses, and every metric carrying
  # one shares its name with the other two of its triple.
  statistic <- c(cv = "CV", mn = "mean", sd = "SD")[
    sub("^.*_", "", base_metric)
  ]

  # Whatever follows the base abbreviation is the class id. Empty at the
  # landscape level, where metric and base_metric are identical.
  class_id <- substring(metric, nchar(base_metric) + 2)

  qualifier <- mapply(
    function(stat, cls) paste(stats::na.omit(c(stat, cls)), collapse = ", "),
    statistic,
    ifelse(nzchar(class_id), paste0("class ", class_id), NA_character_)
  )

  # Unmatched names are bare abbreviations, which already carry both
  has_qualifier <- !unmatched & nzchar(qualifier)
  name[has_qualifier] <- paste0(
    name[has_qualifier],
    " (",
    qualifier[has_qualifier],
    ")"
  )

  name
}
