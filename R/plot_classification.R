#' Plot Neural Network Classification Landscapes
#'
#' Plots landscapes with neural network classification results, highlighting
#' correct and misclassified cases. Optionally, only misclassified landscapes
#' can be shown.
#'
#' @param classification A data frame with columns: \code{landscape_id},
#'   \code{actual_class}, \code{predicted_class}, and \code{confidence}. Can be
#'   obtained from the CV-fold results of \code{\link{train_metrics_model}}/\code{\link{train_pixel_model}} or
#'   the output of \code{\link{apply_metrics_model}}/\code{\link{apply_pixel_model}}.
#' @param landscapes A list of landscape objects corresponding one-to-one and in the same order as the rows in `classification`.
#'   The easiest way to ensure this is to use the same list of landscapes for both training and plotting.
#' @param only_misclassified Logical; if \code{TRUE}, only misclassified
#'   landscapes are plotted. Default is \code{FALSE}.
#' @param ... Additional arguments passed to \code{\link{plot_landscape_list}},
#'   such as \code{show_legend}, \code{legend_title}, \code{ncol}, \code{max_landscapes},
#'   \code{force}, or \code{subset_index}.
#'
#' @return A patchwork object combining landscape plots with classification annotations.
#'
#' @examples
#' \donttest{
#' # Generate training landscapes
#' landscapes <- create_landscapes(n = 30, patterns = c("random", "sharp", "diffuse"))
#'
#' # Calculate landscape metrics
#' metrics <- calculate_metrics(landscapes, level = "landscape")
#'
#' # Find the best 10 metrics for classification
#' best_10 <- evaluate_metrics(metrics, metrics_number = 10)
#'
#' # Train model with cross-validation
#' model <- train_metrics_model(metrics, metrics_selected = best_10, cv_method = "k-fold")
#'
#' # Plot all classification results
#' plot_classified_landscapes(
#'   model$performance$validation_results,
#'   landscapes
#' )
#'
#' # Show only misclassifications without legend
#' plot_classified_landscapes(
#'   model$performance$validation_results,
#'   landscapes,
#'   only_misclassified = TRUE,
#'   show_legend = FALSE,
#'   ncol = 4
#' )
#' }
#' @seealso \code{\link{train_pixel_model}}, \code{\link{train_metrics_model}}
#' @family visualization
#' @export
plot_classified_landscapes <- function(
  classification,
  landscapes,
  only_misclassified = FALSE,
  ...
) {
  # Check if classification has the required elements
  if (
    !is.data.frame(classification) ||
      !all(
        c("landscape_id", "actual_class", "predicted_class", "confidence") %in%
          names(classification)
      )
  ) {
    cli::cli_abort(c(
      "Invalid classification results.",
      "x" = "Must be a data frame with columns: landscape_id, actual_class, predicted_class, confidence",
      "i" = "Instead got: {.cls {class(classification)}}"
    ))
  }

  # Validate input landscapes: must be a non-empty list of landscape objects
  # First check if it's a list at all
  if (!is.list(landscapes)) {
    cli::cli_abort("landscapes must be a list of landscape objects")
  }

  # Then check if it's a single landscape object (not a list of landscapes)
  if (is_landscape(landscapes)) {
    cli::cli_abort(
      "landscapes must be a list of landscape objects, not a single landscape"
    )
  }

  # Then check if list is empty
  if (length(landscapes) == 0) {
    cli::cli_abort("landscapes must contain at least one landscape to plot")
  }

  # Finally check if all elements are landscape objects
  if (any(!sapply(landscapes, is_landscape))) {
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    cli::cli_abort(c(
      "All elements must be landscape objects.",
      "x" = "Found {length(invalid_indices)} invalid element{?s} at {?index/indices}: {.val {invalid_indices}}"
    ))
  }

  # Validate landscape count matches classification results
  # Warn the user i this is not the case
  if (length(landscapes) != nrow(classification)) {
    cli::cli_warn(c(
      "Length mismatch between landscapes and classification results.",
      "x" = "landscapes has {length(landscapes)} element{?s}",
      "x" = "classification has {nrow(classification)} row{?s}",
      "i" = "Using landscape_id to index the landscapes"
    ))
  }

  # Validate all landscape_id values are valid indices
  invalid_ids <- classification$landscape_id[
    classification$landscape_id < 1 |
      classification$landscape_id > length(landscapes)
  ]

  if (length(invalid_ids) > 0) {
    cli::cli_abort(c(
      "Invalid landscape_id values detected.",
      "x" = "landscape_id must be between 1 and {length(landscapes)}",
      "i" = "Found {length(invalid_ids)} invalid ID{?s}: {.val {unique(invalid_ids)}}"
    ))
  }

  # If only_misclassified is TRUE, filter to only misclassified landscapes
  if (only_misclassified) {
    classification <- classification |>
      dplyr::filter(predicted_class != actual_class)
    if (nrow(classification) == 0) {
      cli::cli_abort(
        "No misclassified landscapes found. To plot all classified
       landscapes, set only_misclassified = FALSE."
      )
    }
  }

  # Add plot titles as a column to the validation results
  classification <- classification |>
    dplyr::mutate(
      title = dplyr::case_when(
        predicted_class == actual_class ~
          paste0(
            "<span style='color: #228B22;'>",
            predicted_class,
            "</span> (",
            round(confidence, 2),
            ")<br>",
            "Actual: ",
            actual_class
          ),
        predicted_class != actual_class ~
          paste0(
            "<span style='color: #FF6347;'>",
            predicted_class,
            "</span> (",
            round(confidence, 2),
            ")<br>",
            "Actual: ",
            actual_class
          ),
        .default = "no title"
      )
    )

  # Subset the landscapes that should be plotted using the index of the landscape
  # in the validation results
  landscapes_to_plot <- landscapes[classification$landscape_id]

  # Create plots for each landscape
  plots <- plot_landscape_list(
    landscapes = landscapes_to_plot,
    titles = classification$title,
    ...
  )

  return(plots)
}
