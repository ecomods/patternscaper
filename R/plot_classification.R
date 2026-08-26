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
#'   landscapes are plotted. Default is \code{FALSE}. If every landscape was
#'   classified correctly there is nothing to plot: the function reports this
#'   with a message and returns an empty placeholder plot. Landscapes whose
#'   true class is unknown are not counted as misclassified.
#' @param score_note Logical; if \code{TRUE} (default), a one-line caption is
#'   added under the whole figure stating that the bracketed number is the score
#'   of the predicted class and not a calibrated probability. Set to
#'   \code{FALSE} when the surrounding figure caption already says so.
#' @param subset_index Integer vector. Which of the plotted landscapes to show,
#'   e.g. to keep a large figure readable. Indexes the rows of
#'   \code{classification} that would otherwise be plotted, so with
#'   \code{only_misclassified = TRUE} it selects among the misclassified ones.
#'   Default \code{NULL} plots all of them.
#' @param ... Additional arguments passed to \code{\link{plot_landscapes}},
#'   such as \code{show_legend}, \code{legend_title}, \code{ncol},
#'   \code{max_landscapes}, or \code{force}.
#'
#' @return A patchwork object combining landscape plots with classification
#'   annotations. With \code{only_misclassified = TRUE} and no misclassified
#'   landscape, an empty placeholder plot carrying that message.
#'
#' @examples
#' \donttest{
#' # Generate training landscapes
#' landscapes <- create_landscapes(
#'   n = 18,
#'   patterns = c("random", "sharp", "diffuse")
#' )
#'
#' # Calculate landscape metrics
#' metrics <- calculate_metrics(landscapes, level = "landscape")
#'
#' # Find the best 5 metrics for classification
#' best_5 <- evaluate_metrics(metrics, metrics_number = 5)
#'
#' # Cross-validation produces the held-out predictions this plot needs.
#' # Only 2 folds, as each fold needs at least 3 landscapes per pattern.
#' model <- train_metric_model(
#'   metrics,
#'   metrics_selected = best_5,
#'   cv_method = "k-fold",
#'   cv_folds = 2
#' )
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
  subset_index = NULL,
  ...
) {
  if (!is.logical(only_misclassified) || length(only_misclassified) != 1) {
    cli::cli_abort("{.arg only_misclassified} must be a single logical value")
  }

  if (!is.logical(score_note) || length(score_note) != 1) {
    cli::cli_abort("{.arg score_note} must be a single logical value")
  }

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

  if (!is.list(landscapes)) {
    cli::cli_abort("landscapes must be a list of landscape objects")
  }

  if (is_landscape(landscapes)) {
    cli::cli_abort(
      "landscapes must be a list of landscape objects, not a single landscape"
    )
  }

  if (length(landscapes) == 0) {
    cli::cli_abort("landscapes must contain at least one landscape to plot")
  }

  valid_landscapes <- vapply(landscapes, is_landscape, logical(1))
  if (any(!valid_landscapes)) {
    invalid_indices <- which(!valid_landscapes)
    cli::cli_abort(c(
      "All elements must be landscape objects.",
      "x" = "Found {length(invalid_indices)} invalid element{?s} at {?index/indices}: {.val {invalid_indices}}"
    ))
  }

  if (length(landscapes) != nrow(classification)) {
    cli::cli_warn(c(
      "Length mismatch between landscapes and classification results.",
      "x" = "landscapes has {length(landscapes)} element{?s}",
      "x" = "classification has {nrow(classification)} row{?s}",
      "i" = "Using landscape_id to index the landscapes"
    ))
  }

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

  if (only_misclassified) {
    classification <- classification |>
      # Missing predictions are not misclassifications, and misclassification
      # is undefined without a true class, matching the rows apply_*() scores
      dplyr::filter(
        !is.na(predicted_class) &
          !is.na(actual_class) &
          predicted_class != actual_class
      )
    if (nrow(classification) == 0) {
      cli::cli_inform(c(
        "i" = "All landscapes classified correctly - nothing to plot.",
        "i" = "Set {.code only_misclassified = FALSE} to plot all landscapes."
      ))

      placeholder <- ggplot2::ggplot() +
        ggplot2::annotate(
          "text",
          x = 0,
          y = 0,
          label = "All landscapes classified correctly"
        ) +
        ggplot2::theme_void()

      # Preserve the patchwork return type; the score caption does not apply to
      # an empty plot
      return(patchwork::wrap_plots(placeholder))
    }
  }

  # Apply after filtering so the index refers to the landscapes being plotted
  if (!is.null(subset_index)) {
    if (!is.numeric(subset_index) || anyNA(subset_index)) {
      cli::cli_abort(
        "{.arg subset_index} must be a numeric vector without missing values"
      )
    }

    invalid_index <- subset_index[
      subset_index < 1 | subset_index > nrow(classification)
    ]

    if (length(invalid_index) > 0) {
      cli::cli_abort(c(
        "Invalid {.arg subset_index} values detected.",
        "x" = "{.arg subset_index} must be between 1 and {nrow(classification)}",
        "i" = "Found {length(invalid_index)} invalid value{?s}: {.val {unique(invalid_index)}}"
      ))
    }

    classification <- classification[subset_index, , drop = FALSE]
  }

  classification <- classification |>
    dplyr::mutate(
      title = dplyr::case_when(
        # Match missing predictions before equality branches where NA falls
        # through
        is.na(predicted_class) ~ dplyr::if_else(
          is.na(actual_class),
          "No prediction",
          paste0("No prediction<br>Actual: ", actual_class)
        ),
        # Unknown true classes get a predicted-only title
        is.na(actual_class) ~
          paste0(
            predicted_class,
            " (",
            sprintf("%.2f", score),
            ")"
          ),
        predicted_class == actual_class ~
          paste0(
            "<span style='color: #0072B2;'>",
            predicted_class,
            "</span> (",
            sprintf("%.2f", score),
            ")<br>",
            "Actual: ",
            actual_class
          ),
        predicted_class != actual_class ~
          paste0(
            "<span style='color: #D55E00;'><b>",
            predicted_class,
            "</b></span> (",
            sprintf("%.2f", score),
            ")<br>",
            "Actual: ",
            actual_class
          ),
        .default = "no title"
      )
    )

  landscapes_to_plot <- landscapes[classification$landscape_id]

  plots <- plot_landscapes(
    landscapes = landscapes_to_plot,
    titles = classification$title,
    ...
  )

  # A single caption scales better than repeating the note in every panel and
  # prevents the bracketed score being read as a calibrated probability
  if (score_note) {
    plots <- plots +
      patchwork::plot_annotation(
        caption = "Number in brackets: score of the predicted class (not a calibrated probability)",
        theme = ggplot2::theme(
          plot.caption = ggplot2::element_text(hjust = 0)
        )
      )
  }

  return(plots)
}
