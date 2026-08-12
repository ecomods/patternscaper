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
#' @param selected_metrics Character vector of metric abbreviations to
#'   visualize, as they appear in the \code{metric} column, or the object
#'   returned by \code{\link{evaluate_metrics}}. Must be present in the metrics
#'   data. If NULL (default), all available metrics are plotted in alphabetical
#'   order, subject to automatic limits based on the number of patterns. Use
#'   \code{\link[landscapemetrics]{list_lsm}} to look up what an abbreviation
#'   stands for, or set \code{metric_labels = "name"} to show the full names.
#' @param force Logical. Override automatic metric limits (default: FALSE).
#'   When TRUE, all selected metrics will be plotted regardless of readability.
#' @param metric_labels Character string controlling how metrics are labelled
#'   in facet strips. One of "abbreviation" (default) to use the metric
#'   abbreviations as they appear in \code{metrics} (e.g. "ai"), or "name" to
#'   use the full metric names from \code{\link[landscapemetrics]{list_lsm}}
#'   (e.g. "Aggregation index"). Metrics that summarise per-patch values get
#'   the statistic in brackets, since \code{list_lsm()} gives the
#'   \code{_cv}/\code{_mn}/\code{_sd} triple a single name: \code{area_mn}
#'   becomes "Patch area (mean)". For class-level metrics the class is added
#'   too (e.g. "Patch area (mean, class 1)"), and the \code{metrics} data must
#'   also contain the \code{metric_name} column produced by
#'   \code{\link{calculate_metrics}}.
#' @param label_wrap_width Integer or NULL (default). Character width at which
#'   to wrap full metric names in facet strips. Only used when
#'   \code{metric_labels = "name"}. If NULL, a width is chosen automatically from the number
#'   of facet columns. The choice wraps by character count rather than rendered text width, so
#'   set it explicitly if your font, figure size, or metric selection needs
#'   something different.
#' @param pattern_order Character vector giving the order in which patterns
#'   should appear along the y-axis, or NULL (default) for alphabetical order.
#'   Must contain exactly the patterns present in \code{metrics}, i.e. every
#'   pattern once and no others. The first element is drawn at the bottom of
#'   the axis.
#' @param jitter_seed Seed controlling the random jitter of the points, passed
#'   to \code{\link[ggplot2]{position_jitter}}. NA (default) draws fresh jitter each
#'   render.
#' @param jitter_width Numeric. Horizontal spread of the points around each
#'   pattern (default: 0.1). Set to 0 to disable jitter. Points are never
#'   displaced along the value axis, so they always sit at their true metric
#'   value.
#' @param point_size Numeric. Size of the data points (default: 1).
#'   Reduce for plots with many landscapes per pattern.
#' @param point_alpha Numeric between 0 and 1. Opacity of the data points
#'   (default: 0.7). Reduce to make overlapping points easier to read.
#'
#' @return A ggplot2 object showing boxplots of metric values by pattern type.
#'
#' @seealso \code{\link{calculate_metrics}}, \code{\link{evaluate_metrics}},
#'   \code{\link[landscapemetrics]{list_lsm}} for the available metrics and
#'   their full names
#' @family visualization
#' @export
#' @importFrom dplyr filter mutate distinct left_join across any_of
#' @importFrom ggplot2 ggplot aes geom_boxplot geom_jitter position_jitter facet_wrap coord_flip theme element_blank labs as_labeller label_wrap_gen label_value
#' @importFrom grDevices n2mfrow
#'
#' @examples
#' landscapes <- create_landscapes(n = 8, patterns = c("labyrinth", "spots"))
#' metrics <- calculate_metrics(landscapes, level = "landscape")
#' plot_metrics(metrics, selected_metrics = c("ai", "lsi"))
#'
#' # With more metrics than fit the grid, automatic limiting applies
#' many_metrics <- c("ai", "lsi", "ed", "np", "pd", "cohesion", "division",
#'                   "split", "mesh", "enn_mn", "area_mn", "core_mn",
#'                   "para_mn")
#' plot_metrics(metrics, selected_metrics = many_metrics)
#'
#' # Override limits if needed
#' plot_metrics(metrics, selected_metrics = many_metrics, force = TRUE)
#'
#' # Use full metric names instead of abbreviations in facet labels
#' plot_metrics(metrics, selected_metrics = c("ai", "lsi"), metric_labels = "name")
#'
#' # Override the automatic wrap width for full metric names
#' plot_metrics(
#'   metrics,
#'   selected_metrics = c("ai", "lsi"),
#'   metric_labels = "name",
#'   label_wrap_width = 15
#' )
#'
#' # Control the order of patterns on the y-axis
#' plot_metrics(
#'   metrics,
#'   selected_metrics = c("ai", "lsi"),
#'   pattern_order = c("spots", "labyrinth")
#' )
#'
#' # Fix the jitter so that repeated runs produce an identical figure
#' plot_metrics(metrics, selected_metrics = c("ai", "lsi"), jitter_seed = 42)
#'
#' # Adjust point appearance for plots with many landscapes per pattern
#' plot_metrics(
#'   metrics,
#'   selected_metrics = c("ai", "lsi"),
#'   point_size = 0.5,
#'   point_alpha = 0.4
#' )
plot_metrics <- function(
  metrics,
  selected_metrics = NULL,
  force = FALSE,
  metric_labels = "abbreviation",
  label_wrap_width = NULL,
  pattern_order = NULL,
  jitter_seed = NA,
  jitter_width = 0.1,
  point_size = 1,
  point_alpha = 0.7
) {
  # Validate metric_labels
  if (
    !is.character(metric_labels) ||
      length(metric_labels) != 1 ||
      !metric_labels %in% c("abbreviation", "name")
  ) {
    cli::cli_abort(
      'metric_labels must be one of: "abbreviation" or "name"'
    )
  }

  # Validate label_wrap_width
  if (
    !is.null(label_wrap_width) &&
      (!is.numeric(label_wrap_width) ||
        length(label_wrap_width) != 1 ||
        label_wrap_width <= 0)
  ) {
    cli::cli_abort(
      "label_wrap_width must be NULL or a single positive number"
    )
  }

  # Validate pattern_order (type only; checked against the data further down)
  if (!is.null(pattern_order) && !is.character(pattern_order)) {
    cli::cli_abort(
      "pattern_order must be a character vector of pattern names"
    )
  }

  # Validate jitter_seed. NA (fresh jitter each render) and NULL (use the
  # current global stream) both mean something to position_jitter(), so both
  # are passed through untouched.
  if (
    !is.null(jitter_seed) &&
      !(length(jitter_seed) == 1 &&
        (identical(jitter_seed, NA) || is.numeric(jitter_seed)))
  ) {
    cli::cli_abort(
      "jitter_seed must be NA, NULL, or a single number"
    )
  }

  # Validate jitter_width (0 disables jitter)
  if (
    !is.numeric(jitter_width) ||
      length(jitter_width) != 1 ||
      is.na(jitter_width) ||
      jitter_width < 0
  ) {
    cli::cli_abort(
      "jitter_width must be a single non-negative number"
    )
  }

  # Validate point_size
  if (
    !is.numeric(point_size) ||
      length(point_size) != 1 ||
      is.na(point_size) ||
      point_size <= 0
  ) {
    cli::cli_abort(
      "point_size must be a single positive number"
    )
  }

  # Validate point_alpha
  if (
    !is.numeric(point_alpha) ||
      length(point_alpha) != 1 ||
      is.na(point_alpha) ||
      point_alpha < 0 ||
      point_alpha > 1
  ) {
    cli::cli_abort(
      "point_alpha must be a single number between 0 and 1"
    )
  }

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

  # Validate pattern_order against the patterns actually present in the data
  if (!is.null(pattern_order)) {
    available_patterns <- unique(metrics$pattern)
    missing_patterns <- setdiff(available_patterns, pattern_order)
    extra_patterns <- setdiff(pattern_order, available_patterns)
    if (length(missing_patterns) > 0 || length(extra_patterns) > 0) {
      cli::cli_abort(c(
        "pattern_order must contain exactly the patterns present in {.arg metrics}.",
        "i" = if (length(missing_patterns) > 0) {
          "Missing: {.val {missing_patterns}}"
        },
        "i" = if (length(extra_patterns) > 0) {
          "Not in data: {.val {extra_patterns}}"
        }
      ))
    }
  }

  # Validate selected_metrics
  selected_metrics <- selected_metric_names(selected_metrics)
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
    cli::cli_warn(
      "The following metrics are not in the data and will be ignored: {.val {invalid_metrics}}"
    )
    # Remove invalid metrics from selected_metrics
    selected_metrics <- setdiff(selected_metrics, invalid_metrics)

    # Check if any valid metrics remain
    if (length(selected_metrics) == 0) {
      cli::cli_abort(
        "No valid metrics remaining after filtering. Cannot create plot."
      )
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

  # Full names are looked up from the unsuffixed abbreviation, which only the
  # metric_name column carries (metric itself is suffixed with the class id)
  if (
    metric_labels == "name" &&
      level == "class" &&
      !"metric_name" %in% names(metrics)
  ) {
    cli::cli_abort(c(
      "metrics must contain a {.field metric_name} column to label class-level metrics by name.",
      "i" = "Use the metrics as returned by {.fn calculate_metrics}, or set {.code metric_labels = \"abbreviation\"}."
    ))
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
    cli::cli_warn(c(
      "With {n_patterns} pattern{?s}, limiting to {max_metrics} of {length(selected_metrics)} requested metrics for readability.",
      "i" = "Showing: {.val {selected_metrics[1:max_metrics]}}",
      "i" = "Use {.code force = TRUE} to show all metrics."
    ))
    selected_metrics <- selected_metrics[1:max_metrics]
  }

  # Warn if we still have many facets even with force
  total_facets <- length(selected_metrics)
  if (force && total_facets > 30) {
    cli::cli_warn(
      "Creating {total_facets} facets ({length(selected_metrics)} metrics x {n_patterns} patterns). Plot may be difficult to read."
    )
  }

  # Prepare plot data. Patterns are ordered alphabetically unless the caller
  # supplies pattern_order; the first level is drawn at the bottom of the
  # axis after coord_flip().
  pattern_levels <- if (!is.null(pattern_order)) {
    pattern_order
  } else {
    sort(unique(metrics$pattern))
  }
  plot_data <- metrics |>
    dplyr::filter(metric %in% selected_metrics) |>
    dplyr::mutate(
      metric = factor(metric, levels = selected_metrics),
      pattern = factor(pattern, levels = pattern_levels)
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

  # Determine facet labeller based on metric_labels. Full metric names can be
  # considerably longer than abbreviations, so (unless the user supplies
  # label_wrap_width explicitly) wrap width is approximated from the number
  # of columns facet_wrap() will actually use (more columns -> less
  # horizontal room per panel -> narrower wrap width). This is only a rough
  # approximation since it wraps by character count, not rendered text width.
  # The constants were chosen so the package's default metric selection
  # (10 metrics, i.e. a 4-column grid) wraps to at most 2 lines.
  facet_labeller <- if (metric_labels == "name") {
    wrap_width <- label_wrap_width
    if (is.null(wrap_width)) {
      # ggplot2:::wrap_dims() takes the *first* element of n2mfrow() as the
      # column count (it swaps them relative to n2mfrow's own nr/nc naming),
      # so [1] is deliberate here and matches what facet_wrap() will draw.
      ncol <- grDevices::n2mfrow(length(selected_metrics))[1]
      wrap_width <- max(15, round(90 / ncol))
    }
    metric_name_labeller(plot_data, level, wrap_width = wrap_width)
  } else {
    ggplot2::label_value
  }

  # Build complete plot
  p <- p +
    ggplot2::geom_boxplot() +
    ggplot2::geom_jitter(
      # height = 0 keeps the points at their true metric value; jitter only
      # ever spreads them across the pattern axis
      position = ggplot2::position_jitter(
        width = jitter_width,
        height = 0,
        seed = jitter_seed
      ),
      size = point_size,
      alpha = point_alpha
    ) +
    ggplot2::facet_wrap(~metric, scales = "free_x", labeller = facet_labeller) +
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

#' Build a facet labeller mapping metric abbreviations to full names
#'
#' Resolves the full names for the metrics present in \code{plot_data$metric}
#' (see \code{lookup_metric_names()}) and wraps them in a \code{ggplot2}
#' labeller suitable for \code{facet_wrap(labeller = )}.
#'
#' @param plot_data Data frame used to build the plot. Must contain a
#'   \code{metric} column, and for class-level metrics a \code{metric_name}
#'   column with the base (unsuffixed) metric abbreviation.
#' @param level Either "landscape" or "class".
#' @param wrap_width Integer. Character width at which to wrap long labels
#'   (passed to \code{\link[ggplot2]{label_wrap_gen}}). Should be chosen
#'   based on the number of facet columns; narrower grids need a smaller
#'   width.
#'
#' @return A function created by \code{\link[ggplot2]{as_labeller}}.
#' @noRd
#' @importFrom stats setNames
metric_name_labeller <- function(plot_data, level, wrap_width = 25) {
  metric <- as.character(plot_data$metric)
  base_metric <- if (level == "class") {
    as.character(plot_data$metric_name)
  } else {
    metric
  }

  # One label per facet, not per row of the plot data
  first <- !duplicated(metric)
  metric <- metric[first]
  base_metric <- base_metric[first]

  label_vec <- stats::setNames(
    lookup_metric_names(metric, base_metric, level),
    metric
  )
  ggplot2::as_labeller(
    label_vec,
    default = ggplot2::label_wrap_gen(width = wrap_width)
  )
}
