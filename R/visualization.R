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
  # Function implementation will go here
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
