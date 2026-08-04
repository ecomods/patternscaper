#' Plot Neural Network Classification Landscapes
#'
#' Plots landscapes with neural network classification results, highlighting
#' correct and misclassified cases. Optionally, only misclassified landscapes
#' can be shown.
#'
#' @param classification A data frame with columns: \code{landscape_id},
#'   \code{actual_class}, \code{predicted_class}, and \code{score}. Can be
#'   obtained from the CV-fold results of \code{\link{train_metric_model}}/\code{\link{train_pixel_model}} or
#'   the output of \code{\link{apply_metric_model}}/\code{\link{apply_pixel_model}}.
#' @param landscapes A list of landscape objects corresponding one-to-one and in the same order as the rows in `classification`.
#'   The easiest way to ensure this is to use the same list of landscapes for both training and plotting.
#' @param only_misclassified Logical; if \code{TRUE}, only misclassified
#'   landscapes are plotted. Default is \code{FALSE}.
#' @param score_note Logical; if \code{TRUE} (default), a one-line caption is
#'   added under the whole figure stating that the bracketed number is the score
#'   of the predicted class and not a calibrated probability. Set to
#'   \code{FALSE} when the surrounding figure caption already says so.
#' @param ... Additional arguments passed to \code{\link{plot_landscapes}},
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
#' model <- train_metric_model(metrics, metrics_selected = best_10, cv_method = "k-fold")
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
#' @seealso \code{\link{train_pixel_model}}, \code{\link{train_metric_model}}
#' @family visualization
#' @export
#' @importFrom patchwork plot_annotation
plot_classified_landscapes <- function(
  classification,
  landscapes,
  only_misclassified = FALSE,
  score_note = TRUE,
  ...
) {
  if (!is.logical(score_note) || length(score_note) != 1) {
    cli::cli_abort("{.arg score_note} must be a single logical value")
  }

  # Check if classification has the required elements
  if (
    !is.data.frame(classification) ||
      !all(
        c("landscape_id", "actual_class", "predicted_class", "score") %in%
          names(classification)
      )
  ) {
    cli::cli_abort(c(
      "Invalid classification results.",
      "x" = "Must be a data frame with columns: landscape_id, actual_class, predicted_class, score",
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
      # Unclassified landscapes are not misclassifications, so they are excluded
      # here.
      dplyr::filter(!is.na(predicted_class) & predicted_class != actual_class)
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
        # Landscape could not be classified: apply_metric_model() returns NA
        # when a required metric was unavailable for it. Must be matched before
        # the equality branches, which would both give NA and fall through.
        is.na(predicted_class) ~ dplyr::if_else(
          is.na(actual_class) | actual_class == "unclassified",
          "Unclassified",
          paste0("Unclassified<br>Actual: ", actual_class)
        ),
        # Unlabeled input (true class unknown, i.e. NA or "unclassified"):
        # show a predicted-only title.
        is.na(actual_class) | actual_class == "unclassified" ~
          paste0(
            predicted_class,
            " (",
            round(score, 2),
            ")"
          ),
        predicted_class == actual_class ~
          paste0(
            "<span style='color: #228B22;'>",
            predicted_class,
            "</span> (",
            round(score, 2),
            ")<br>",
            "Actual: ",
            actual_class
          ),
        predicted_class != actual_class ~
          paste0(
            "<span style='color: #FF6347;'>",
            predicted_class,
            "</span> (",
            round(score, 2),
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
  plots <- plot_landscapes(
    landscapes = landscapes_to_plot,
    titles = classification$title,
    ...
  )

  # One caption for the whole composite rather than a word in every panel
  # title, which does not scale to a multi-panel figure. The bracketed number
  # is easily misread as a calibrated probability; see the "Interpreting the
  # class scores" section of `apply_metric_model()`.
  if (score_note) {
    plots <- plots +
      patchwork::plot_annotation(
        caption = "Number in brackets: score of the predicted class (not a calibrated probability)"
      )
  }

  return(plots)
}
