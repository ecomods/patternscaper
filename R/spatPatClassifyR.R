#' spatPatClassifyR: Classify Spatial Landscape Patterns Using Neural Networks
#'
#' @description
#' Classification of spatial landscape patterns using neural networks.
#' The package provides tools for generating artificial landscapes with
#' different spatial patterns, calculating landscape metrics, and training
#' neural network classifiers.
#'
#' Two classification approaches are supported:
#' \itemize{
#'   \item **Pixel-based classification** using convolutional neural networks
#'     via \pkg{keras3} (see \code{\link{train_pixel_model}})
#'   \item **Metrics-based classification** using landscape metrics computed
#'     with \pkg{landscapemetrics} as input features
#'     for a neural network (see \code{\link{train_metrics_model}})
#' }
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Generate training landscapes with \code{\link{create_landscapes}}
#'   \item Optionally calculate and evaluate landscape metrics with
#'     \code{\link{calculate_metrics}} and
#'     \code{\link{evaluate_landscape_metrics}}
#'   \item Train a classifier with \code{\link{train_pixel_model}} or
#'     \code{\link{train_metrics_model}}
#'   \item Apply the trained model to new landscapes with
#'     \code{\link{apply_pixel_model}} or \code{\link{apply_metrics_model}}
#'   \item Visualize results with \code{\link{plot_classified_landscapes}}
#' }
#'
#' @references
#' Baldauf, S., Tietjen, B., & Berger, U. (2025). spatPatClassifyR: An R
#' package for classifying spatial landscape patterns using neural networks.
#' *Methods in Ecology and Evolution*. In review.
#'
#' @docType package
#' @name spatPatClassifyR
"_PACKAGE"

utils::globalVariables(c(
  "level",
  "pattern",
  "metric",
  "value",
  "class",
  "landscape_id",
  "confidence",
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
  "mean_all"
))
