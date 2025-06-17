#' Evaluate Landscape Metrics
#'
#' Identifies the most informative metrics for discriminating between landscape types.
#'
#' @param calculated_metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_number Integer. Number of top metrics to return (default: 10).
#' @param method Character. Selection method (options: "coeffvar_all", "linmod", "lin_mod_r2", "mean_groups") (default: "coeffvar_all").
#' @param plot Logical. Whether to generate visualization (default: FALSE).
#' @param exclude_metrics Character vector. Metrics to exclude (default: NULL).
#'
#' @return Character vector. Names of most sensitive metrics.
#' @export
evaluate_landscape_metrics <- function(
  calculated_metrics,
  metrics_number = 10,
  method = "coeffvar_all",
  plot = FALSE,
  exclude_metrics = NULL
) {
  # Function implementation will go here
}
