#' patternscaper: Classify Spatial Landscape Patterns Using Neural Networks
#'
#' @description
#' Generates artificial landscapes with defined spatial patterns, calculates
#' landscape metrics, and trains neural networks to classify landscape
#' patterns.
#'
#' The package supports two classification workflows:
#' \itemize{
#'   \item Pixel-based classification with convolutional neural networks using
#'     \pkg{keras3} (see \code{\link{train_pixel_model}})
#'   \item Metrics-based classification with landscape metrics from
#'     \pkg{landscapemetrics} as neural-network inputs (see
#'     \code{\link{train_metric_model}})
#' }
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Generate training landscapes with \code{\link{create_landscapes}}
#'   \item Optionally calculate and evaluate landscape metrics with
#'     \code{\link{calculate_metrics}} and
#'     \code{\link{evaluate_metrics}}
#'   \item Train a classifier with \code{\link{train_pixel_model}} or
#'     \code{\link{train_metric_model}}
#'   \item Apply the trained model to new landscapes with
#'     \code{\link{apply_pixel_model}} or \code{\link{apply_metric_model}}
#'   \item Visualize results with \code{\link{plot_classified_landscapes}}
#' }
#'
#' @references
#' Baldauf, S., Tietjen, B., & Berger, U. (2025). patternscaper: An R
#' package for classifying spatial landscape patterns using neural networks.
#' *Methods in Ecology and Evolution*. In review.
#'
#' @name patternscaper
"_PACKAGE"

utils::globalVariables(c(
  "level",
  "pattern",
  "metric",
  "value",
  "class",
  "landscape_id",
  "score",
  "fold",
  "y",
  "x",
  "r2",
  "mean_type",
  "rel_mean_diff",
  "importance_score",
  "landscape_name",
  "metric_name",
  "layer",
  "actual_class",
  "predicted_class",
  "var",
  "id",
  "var_value",
  "sd",
  "cv",
  "fisher_score",
  "data",
  "kruskal_effsize",
  "mean_all",
  "n_row",
  "n_col",
  "cell_size_x",
  "cell_size_y",
  "n_na",
  "n_present",
  "sd_value",
  "mean_value",
  "outcome",
  "name",
  "selected",
  "correlated_with"
))
