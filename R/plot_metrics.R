#' Plot Landscape Metrics
#'
#' Creates a visualization of landscape metric values across landscape types.
#'
#' @param metrics Data frame. Metrics dataframe from calculate_landscape_metrics.
#'    Needs to contain columns: "level", "type", "metric", "value", and optionally "pattern".
#' @param selected_metrics Character vector. Metrics to visualize.
#'
#' @return ggplot object. Visualization of selected metrics across landscape types.
#' @export
plot_metrics <- function(
  calculated_metrics,
  selected_metrics,
  title = "Landscape Metrics"
) {
  # Validate input data
  if (!is.data.frame(calculated_metrics)) {
    stop("metrics must be a data frame from calculate_landscape_metrics()")
  }
  if (!is.character(selected_metrics)) {
    stop("selected_metrics must be a character vector of metric names")
  }
  # check if metrics data has columns we need
  required_cols <- c("level", "pattern", "metric", "value")
  if (!all(required_cols %in% names(calculated_metrics))) {
    stop(paste(
      "metrics data frame must contain the following columns:",
      paste(required_cols, collapse = ", ")
    ))
  }
  if (length(selected_metrics) == 0) {
    stop("selected_metrics must contain at least one metric to plot")
  }

  # extract level at which metrics were calculated
  level <- unique(calculated_metrics$level)

  # Prepare the data for plotting
  plot_data <- calculated_metrics |>
    dplyr::filter(metric %in% selected_metrics) |>
    # Order metrics by their order in selected_metrics
    dplyr::mutate(
      metric = factor(metric, levels = selected_metrics),
      pattern = as.factor(pattern)
    )

  # Create the base plot (depends on the level at which metrics were calculated)
  if (level == "landscape") {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = pattern, y = value))
  } else if (level == "class") {
    p <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = pattern, y = value, fill = class)
    )
  } else {
    stop("Plotting for patch-level metrics is not implemented yet.")
  }

  p <- p +
    ggplot2::geom_boxplot() +
    ggplot2::geom_jitter(
      position = ggplot2::position_jitter(width = 0.1),
      size = 1,
      alpha = 0.7
    ) +
    ggplot2::facet_wrap(~metric, scales = "free_x") +
    ggplot2::coord_flip() +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
    ) +
    ggplot2::labs(
      x = "Landscape Pattern",
      y = "Metric Value"
    )
  return(p)
}
