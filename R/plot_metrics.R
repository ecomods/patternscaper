#' Plot Landscape Metrics
#'
#' Creates a visualization of landscape metric values across landscape types using
#' boxplots with overlaid jittered points. Metrics are displayed in separate facets.
#'
#' The function automatically limits the number of metrics based on the number of
#' patterns to maintain readability:
#' - 1-3 patterns: up to 12 metrics (3 rows x 4 columns)
#' - 4-5 patterns: up to 8 metrics (2 rows x 4 columns)
#' - 6+ patterns: up to 6 metrics (2 rows x 3 columns)
#'
#' @param metrics Data frame from \code{\link{calculate_metrics}}.
#'   Must contain columns: "level", "pattern", "metric", and "value".
#'   For class-level metrics, must also contain "class".
#' @param selected_metrics Character vector of metric names to visualize.
#'   Must be present in the metrics data. If NULL (default), all available metrics
#'   are plotted in alphabetical order, subject to automatic limits based on the
#'   number of patterns.
#' @param force Logical. Override automatic metric limits (default: FALSE).
#'   When TRUE, all selected metrics will be plotted regardless of readability.
#'
#' @return A ggplot2 object showing boxplots of metric values by pattern type.
#'
#' @seealso \code{\link{calculate_metrics}}, \code{\link{evaluate_landscape_metrics}}
#' @family visualization
#' @export
#' @importFrom dplyr filter mutate
#' @importFrom ggplot2 ggplot aes geom_boxplot geom_jitter position_jitter facet_wrap coord_flip theme element_blank labs
#'
#' @examples
#' landscapes <- create_landscapes(n = 20, patterns = c("labyrinth", "spots"))
#' metrics <- calculate_metrics(landscapes, level = "landscape")
#' plot_metrics(metrics, selected_metrics = c("ai", "lsi"))
#'
#' # With many patterns and metrics, automatic limiting applies
#' many_metrics <- c("ai", "lsi", "ed", "np", "pd", "cohesion", "division",
#'                   "split", "mesh", "enn_mn", "area_mn", "core_mn")
#' plot_metrics(metrics, selected_metrics = many_metrics)
#'
#' # Override limits if needed
#' plot_metrics(metrics, selected_metrics = many_metrics, force = TRUE)
plot_metrics <- function(
  metrics,
  selected_metrics = NULL,
  force = FALSE
) {
  # Visual parameters (internal only, adjust during development)
  jitter_width <- 0.1
  point_size <- 1
  point_alpha <- 0.7

  # Validate input data
  if (!is.data.frame(metrics)) {
    cli::cli_abort(
      "metrics must be a data frame from calculate_metrics()"
    )
  }

  # Check required columns
  required_cols <- c("level", "pattern", "metric", "value")
  missing_cols <- setdiff(required_cols, names(metrics))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "metrics is missing required columns: {paste(missing_cols, collapse = ', ')}"
    )
  }
  # Validate selected_metrics
  if (!is.null(selected_metrics)) {
    if (!is.character(selected_metrics) || length(selected_metrics) == 0) {
      cli::cli_abort(
        "selected_metrics must be a non-empty character vector of metric names"
      )
    }
  } else {
    selected_metrics <- sort(unique(metrics$metric))
  }

  # Validate selected metrics exist in data
  available_metrics <- unique(metrics$metric)
  invalid_metrics <- setdiff(selected_metrics, available_metrics)
  if (length(invalid_metrics) > 0) {
    warning(
      paste(
        "The following metrics are not in the data and will be ignored:",
        paste(invalid_metrics, collapse = ", ")
      ),
      call. = FALSE
    )
    # Remove invalid metrics from selected_metrics
    selected_metrics <- setdiff(selected_metrics, invalid_metrics)

    # Check if any valid metrics remain
    if (length(selected_metrics) == 0) {
      cli::cli_abort("No valid metrics remaining after filtering. Cannot create plot.")
    }
  }

  # Extract and validate level
  level <- unique(metrics$level)
  if (length(level) != 1) {
    cli::cli_abort(
      "metrics contains multiple levels: {paste(level, collapse = ', ')}. Please filter to a single level before plotting."
    )
  }
  if (!level %in% c("landscape", "class")) {
    cli::cli_abort(
      "Invalid level in metrics data. Must be 'landscape' or 'class' but is {level}"
    )
  }

  # For class-level metrics, check class column exists
  if (level == "class" && !"class" %in% names(metrics)) {
    cli::cli_abort(
      "metrics must contain 'class' column for class-level metrics"
    )
  }

  # Count patterns in the data
  n_patterns <- length(unique(metrics$pattern))

  # Limit the number of metrics to display based on the number of patterns
  # Prioritize patterns - more patterns = fewer metrics allowed
  max_metrics <- if (n_patterns <= 3) {
    12 # 3 rows x 4 columns
  } else if (n_patterns <= 5) {
    8 # 2 rows x 4 columns
  } else {
    6 # 2 rows x 3 columns
  }

  # Apply metric limit unless force is TRUE
  if (length(selected_metrics) > max_metrics && !force) {
    warning(
      sprintf(
        "With %d pattern%s, limiting to %d of %d requested metrics for readability.\nShowing: %s\nUse force = TRUE to show all metrics.",
        n_patterns,
        if (n_patterns == 1) "" else "s",
        max_metrics,
        length(selected_metrics),
        paste(selected_metrics[1:max_metrics], collapse = ", ")
      ),
      call. = FALSE
    )
    selected_metrics <- selected_metrics[1:max_metrics]
  }

  # Warn if we still have many facets even with force
  total_facets <- length(selected_metrics)
  if (force && total_facets > 30) {
    warning(
      sprintf(
        "Creating %d facets (%d metrics x %d patterns). Plot may be difficult to read.",
        total_facets,
        length(selected_metrics),
        n_patterns
      ),
      call. = FALSE
    )
  }

  # Prepare plot data
  plot_data <- metrics |>
    dplyr::filter(metric %in% selected_metrics) |>
    dplyr::mutate(
      metric = factor(metric, levels = selected_metrics),
      pattern = factor(pattern)
    )

  # Create base plot based on level
  if (level == "landscape") {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = pattern, y = value))
  } else if (level == "class") {
    plot_data <- plot_data |>
      dplyr::mutate(class = factor(class))
    p <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = pattern, y = value, fill = class)
    )
  }

  # Build complete plot
  p <- p +
    ggplot2::geom_boxplot() +
    ggplot2::geom_jitter(
      position = ggplot2::position_jitter(width = jitter_width),
      size = point_size,
      alpha = point_alpha
    ) +
    ggplot2::facet_wrap(~metric, scales = "free_x") +
    ggplot2::coord_flip() +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::labs(
      x = "Landscape Pattern",
      y = "Metric Value"
    )

  # Adjust theme

  p <- p + ggplot2::theme_bw()

  return(p)
}
