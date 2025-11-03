#' Convert landscape metrics from long to wide format
#'
#' This function transforms landscape metrics from a long format to a wide
#' format that is needed to train nn models
#'
#' @param metrics A data frame containing landscape metrics in long format.
#'   Expected columns include: `metric`, `class`, `id`, `value`, `pattern`.
#'   Must include either `landscape_id` or `landscape_name` for identification.
#' @param keep_id Logical. Whether to keep the identification column in output (default: FALSE).
#'
#' @return A data frame in wide format where each metric becomes a column and each
#'   row is a landscape. Metric names are modified to include class and patch IDs
#'   when applicable (format: `metric_class_id`).
#' @keywords internal
#' @importFrom dplyr mutate select
#' @importFrom rlang sym
#' @importFrom stringr str_remove
#' @importFrom tidyr pivot_wider
metrics_to_wide <- function(metrics, keep_id = FALSE) {
  # Determine which ID column to use (prefer landscape_id over landscape_name)
  id_col <- if ("landscape_id" %in% colnames(metrics)) {
    "landscape_id"
  } else if ("landscape_name" %in% colnames(metrics)) {
    "landscape_name"
  } else {
    cli::cli_abort(
      "Metrics must contain either 'landscape_id' or 'landscape_name' column"
    )
  }

  # Build metric names with class/patch ID when not at landscape level
  metrics <- metrics |>
    dplyr::mutate(
      metric = stringr::str_remove(
        paste0(metric, "_", class, "_", id),
        "_NA_NA"
      )
    ) |>
    dplyr::select(!!rlang::sym(id_col), metric, value, pattern)

  # Pivot to wide format
  metrics_wide <- metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    )

  # Drop ID column unless requested
  if (!keep_id) {
    metrics_wide <- metrics_wide |>
      dplyr::select(-!!rlang::sym(id_col))
  }

  metrics_wide
}
