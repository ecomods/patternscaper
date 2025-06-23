#' Plot a Landscape
#'
#' Creates a visualization of a landscape using ggplot2.
#'
#' @param landscape SpatRaster or matrix. Landscape to plot.
#' @param title Character. Plot title (default: "Landscape").
#' @param color_scale Character vector. Colors for mapping values (default: NULL).
#' @param legend_title Character. Title for the legend (default: "Value").
#' @param show_legend Logical. Whether to show legend (default: TRUE).
#'
#' @return ggplot object. Plot of the landscape.
#' @export
plot_landscape <- function(
  landscape,
  title = "Landscape",
  color_scale = NULL,
  legend_title = "Value",
  show_legend = TRUE
) {
  # Use the ensure_spatraster function to handle matrix inputs
  landscape <- ensure_spatraster(landscape)

  # Convert raster to data frame for plotting
  df <- terra::as.data.frame(landscape, xy = TRUE)
  names(df)[3] <- "value" # Rename the value column

  # Determine if data is categorical/discrete
  unique_values <- unique(df$value[!is.na(df$value)])
  is_discrete <- length(unique_values) < 10 &&
    all(unique_values == round(unique_values))

  # If the values are discrete, convert to factor
  if (is_discrete) {
    df$value <- factor(df$value, levels = unique_values)
  }

  # Set up default color scale if not provided
  if (is.null(color_scale)) {
    # Define a standard palette of 10 distinct colors
    standard_palette <- c(
      "#005C29", # dark green (forest)
      "#E5E59F", # light yellow/beige (saltmarsh)
      "#8DA0CB", # periwinkle blue
      "#E78AC3", # pink
      "#A6D854", # lime green
      "#FFD92F", # yellow
      "#E5C494", # tan
      "#B3B3B3", # gray
      "#7570B3", # purple
      "#D95F02" # orange
    )

    if (is_discrete) {
      # For all categorical data, select the needed number of colors from the palette
      n_colors <- length(unique_values)
      color_scale <- standard_palette[1:min(n_colors, 10)]
    } else {
      # For continuous data, use a viridis gradient
      color_scale <- viridisLite::viridis(100)
    }
  }

  # Create base plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = y, fill = value)) +
    ggplot2::geom_raster() +
    ggplot2::coord_equal(expand = FALSE) +
    ggplot2::labs(title = title) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      legend.position = if (show_legend) "right" else "none"
    )

  # Apply appropriate color scale based on data type
  if (is_discrete) {
    p <- p +
      ggplot2::scale_fill_manual(
        values = color_scale,
        name = legend_title,
        na.value = "grey80"
      )
  } else {
    p <- p +
      ggplot2::scale_fill_gradientn(
        colours = color_scale,
        name = legend_title,
        na.value = "grey80"
      )
  }

  return(p)
}

#' Plot Multiple Landscapes
#'
#' Creates a grid of multiple landscape plots.
#'
#' @param landscape_list List. List of landscapes (SpatRaster or matrix) to plot.
#' @param titles Character vector. Vector of titles for each landscape (default: NULL).
#' @param color_scale Character vector. Colors for mapping values across all plots (default: NULL).
#' @param ncol Integer. Number of columns in the plot arrangement (default: NULL).
#' @param legend_title Character. Title for the legend (default: "Value").
#' @param show_legend Logical. Whether to show legend (default: TRUE).
#'
#' @return patchwork object. Combined plot of all landscapes.
#' @export
plot_landscape_list <- function(
  landscape_list,
  titles = NULL,
  color_scale = NULL,
  ncol = NULL,
  legend_title = "Value",
  show_legend = TRUE
) {
  # Function implementation will go here
}

#' Plot Landscape Metrics
#'
#' Creates a visualization of landscape metric values across landscape types.
#'
#' @param metrics Data frame. Metrics dataframe from calculate_landscape_metrics.
#' @param selected_metrics Character vector. Metrics to visualize.
#' @param title Character. Plot title (default: "Landscape Metrics").
#' @param facet Logical. Whether to create facet plot by metric (default: TRUE).
#' @param arrange_by_importance Logical. Whether to order metrics by importance (default: FALSE).
#' @param method Character. Method used for metric importance (default: "").
#'
#' @return ggplot object. Visualization of selected metrics across landscape types.
#' @export
plot_metrics <- function(
  metrics,
  selected_metrics,
  title = "Landscape Metrics",
  facet = TRUE,
  arrange_by_importance = FALSE,
  method = ""
) {
  # Function implementation will go here
}

#' Plot Classification Results
#'
#' Creates a visualization of neural network classification results.
#'
#' @param classification Data frame. Classification results from apply_nn.
#' @param show_probabilities Logical. Whether to include probability bars (default: TRUE).
#' @param confidence_threshold Numeric. Threshold for highlighting low confidence (default: 0.6).
#'
#' @return ggplot object. Visualization of classification results.
#' @export
plot_classification_results <- function(
  classification,
  show_probabilities = TRUE,
  confidence_threshold = 0.6
) {
  # Function implementation will go here
}
