#' Plot Neural Network Classification Results
#'
#' Creates visualizations of neural network model results from cross-validation.
#'
#' @param nn_model List. Neural network model from train_nn_metrics().
#' @param plot_type Character. Type of plot to create: "confusion", "probabilities",
#'   "confidence", or "misclassifications" (default: "confusion").
#' @param confidence_threshold Numeric. Threshold for highlighting low confidence (default: 0.6).
#' @param return_all Logical. Whether to return all plot types as a list (default: FALSE).
#'
#' @return ggplot object or list of ggplot objects. Visualization(s) of classification results.
#' @export
plot_classification_results <- function(
  nn_model,
  plot_type = "confusion",
  confidence_threshold = 0.6,
  return_all = FALSE
) {
  # Check that nn_model is valid
  if (!is.list(nn_model)) {
    stop("Invalid neural network model. Must be a list.")
  }

  # Set up plot list for potential return_all
  plot_list <- list()

  # Try to generate each plot type as needed
  if (plot_type == "confusion" || return_all) {
    tryCatch(
      {
        plot_list[["confusion"]] <- plot_nn_confusion_matrix(nn_model)
      },
      error = function(e) {
        message("Could not create confusion matrix plot: ", e$message)
      }
    )
  }

  if (plot_type == "probabilities" || return_all) {
    tryCatch(
      {
        plot_list[["probabilities"]] <- plot_nn_probabilities(nn_model)
      },
      error = function(e) {
        message("Could not create probabilities plot: ", e$message)
      }
    )
  }

  if (plot_type == "confidence" || return_all) {
    tryCatch(
      {
        plot_list[["confidence"]] <- plot_nn_confidence(
          nn_model,
          confidence_threshold
        )
      },
      error = function(e) {
        message("Could not create confidence plot: ", e$message)
      }
    )
  }

  if (plot_type == "misclassifications" || return_all) {
    tryCatch(
      {
        plot_list[["misclassifications"]] <- plot_nn_misclassifications(
          nn_model,
          confidence_threshold
        )
      },
      error = function(e) {
        message("Could not create misclassifications plot: ", e$message)
      }
    )
  }

  # Return all plots if requested
  if (return_all) {
    return(plot_list)
  }

  # Return the requested plot type
  if (plot_type %in% names(plot_list)) {
    return(plot_list[[plot_type]])
  }

  # If we got here, the requested plot wasn't created
  stop(
    "Could not create plot of type '",
    plot_type,
    "'. Choose from: 'confusion', 'probabilities', 'confidence', or 'misclassifications'"
  )
}

#' Plot Neural Network Confusion Matrix
#'
#' Creates a visualization of the confusion matrix from neural network validation.
#'
#' @param nn_model List. Neural network model from train_nn_metrics().
#'
#' @return ggplot object. Visualization of the confusion matrix.
#' @export
plot_nn_confusion_matrix <- function(nn_model) {
  # Check if nn_model has the required elements
  if (
    !is.list(nn_model) ||
      is.null(nn_model$performance) ||
      is.null(nn_model$performance$confusion_matrix)
  ) {
    stop("Invalid neural network model or missing confusion matrix.")
  }

  # Convert confusion matrix to data frame for plotting
  conf_matrix <- nn_model$performance$confusion_matrix
  conf_df <- as.data.frame(as.table(conf_matrix))
  names(conf_df) <- c("Predicted", "Actual", "Count")

  # Calculate cell percentages (by actual class column)
  conf_df <- conf_df |>
    dplyr::mutate(Percent = Count / sum(Count) * 100, .by = Actual) |>
    dplyr::mutate(percent_color = ifelse(Percent > 50, "white", "black"))

  # Create plot
  p_confusion <- ggplot2::ggplot(
    conf_df,
    ggplot2::aes(x = Actual, y = Predicted, fill = Percent)
  ) +
    ggplot2::geom_tile(color = "lightgrey") +
    ggplot2::geom_text(
      ggplot2::aes(label = round(Percent, 1), color = percent_color)
    ) +
    ggplot2::scale_color_manual(
      values = c("black", "white"),
      guide = "none"
    ) +
    ggplot2::scale_fill_gradient2(
      low = "white",
      mid = "#828282",
      high = "#111111",
      midpoint = 50,
      limits = c(0, 100),
      name = "% of Actual Class"
    ) +
    ggplot2::coord_fixed(expand = FALSE) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      legend.position = "none"
    ) +
    ggplot2::labs(
      title = "Cross-Validation Confusion Matrix (% of actual class)",
      subtitle = sprintf(
        "Accuracy: %.1f%% (%s with %d folds)",
        nn_model$performance$accuracy * 100,
        nn_model$performance$cv_method,
        nn_model$performance$cv_folds
      ),
      x = "Actual Class",
      y = "Predicted Class"
    )

  return(p_confusion)
}

#' Plot Neural Network Class Probabilities
#'
#' Creates a visualization of class probabilities from neural network validation.
#'
#' @param nn_model List. Neural network model from train_nn_metrics().
#'
#' @return ggplot object. Visualization of mean class probabilities.
#' @export
plot_nn_probabilities <- function(nn_model) {
  # Check if nn_model has the required elements
  if (
    !is.list(nn_model) ||
      is.null(nn_model$validation_results) ||
      is.null(nn_model$classes)
  ) {
    stop("Invalid neural network model or missing validation results.")
  }

  # Extract class names and probabilities
  class_names <- nn_model$classes
  prob_data <- nn_model$validation_results

  # Calculate mean probability for each actual-predicted class combination
  prob_matrix_data <- data.frame()
  for (actual in class_names) {
    for (pred in class_names) {
      # Subset data for this actual class
      actual_class_data <- prob_data[prob_data$actual_class == actual, ]
      # Get mean probability for this prediction class
      mean_prob <- mean(actual_class_data[[pred]], na.rm = TRUE)

      # Add to data frame
      prob_matrix_data <- rbind(
        prob_matrix_data,
        data.frame(
          Actual = actual,
          Predicted = pred,
          MeanProbability = mean_prob
        )
      )
    }
  }

  # Create the probability confusion matrix plot
  p_probabilities <- ggplot2::ggplot(
    prob_matrix_data,
    ggplot2::aes(x = Actual, y = Predicted, fill = MeanProbability)
  ) +
    ggplot2::geom_tile(color = "lightgrey") +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.2f", MeanProbability)),
      color = ifelse(
        prob_matrix_data$MeanProbability > 0.5,
        "white",
        "black"
      )
    ) +
    ggplot2::scale_fill_gradient2(
      low = "white",
      mid = "#828282",
      high = "#111111",
      midpoint = 0.5,
      limits = c(0, 1),
      name = "Mean Probability"
    ) +
    ggplot2::coord_fixed(expand = FALSE) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      legend.position = "none"
    ) +
    ggplot2::labs(
      title = "Cross-Validation Mean Probabilities",
      subtitle = "Average probability that landscapes of class X are classified as class Y",
      x = "Actual Class",
      y = "Predicted Class"
    )

  return(p_probabilities)
}

#' Plot Neural Network Prediction Confidence
#'
#' Creates a visualization of prediction confidence by class from neural network validation.
#'
#' @param nn_model List. Neural network model from train_nn_metrics().
#' @param confidence_threshold Numeric. Threshold for highlighting low confidence (default: 0.6).
#' @param add_raw_data Logical. Whether to overlay raw data points (default: TRUE).
#'
#' @return ggplot object. Visualization of confidence by class.
#' @export
plot_nn_confidence <- function(
  nn_model,
  confidence_threshold = 0.6,
  add_raw_data = TRUE
) {
  # Check if nn_model has the required elements
  if (!is.list(nn_model) || is.null(nn_model$validation_results)) {
    stop("Invalid neural network model or missing validation results.")
  }

  # Create data for confidence plot
  confidence_data <- nn_model$validation_results

  # Create plot
  p_confidence <- ggplot2::ggplot(
    confidence_data,
    ggplot2::aes(
      x = factor(actual_class),
      y = confidence,
      fill = factor(predicted_class == actual_class)
    )
  ) +
    ggdist::stat_slabinterval(
      slab_linewidth = NA
    )

  if (add_raw_data) {
    p_confidence <- p_confidence +
      ggplot2::geom_jitter(
        ggplot2::aes(
          color = factor(predicted_class == actual_class)
        ),
        width = 0.1,
        alpha = 0.3,
        size = 1
      )
  }

  p_confidence <- p_confidence +
    ggplot2::coord_flip() +
    ggplot2::geom_hline(
      yintercept = confidence_threshold,
      linetype = "dashed"
    ) +
    ggplot2::scale_fill_manual(
      values = c("#FF6347", "#228B22"),
      name = "Prediction",
      labels = c("Incorrect", "Correct")
    ) +
    ggplot2::scale_color_manual(
      values = c("#ff6347", "#228B22"),
      name = "Prediction",
      labels = c("Incorrect", "Correct")
    ) +
    ggplot2::labs(
      title = "Cross-Validation Confidence by Class",
      subtitle = "<span style = 'color: #228B22;'>Correct</span> and <span style = 'color: #FF6347;'>incorrect</span> predictions",
      x = "Actual Class",
      y = "Confidence Score"
    ) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.subtitle = ggtext::element_markdown(),
      legend.position = "none"
    )

  return(p_confidence)
}

#' Plot Neural Network Misclassifications
#'
#' Creates a visualization of common misclassification patterns from neural network validation.
#'
#' @param nn_model List. Neural network model from train_nn_metrics().
#' @param confidence_threshold Numeric. Threshold for highlighting low confidence (default: 0.6).
#'
#' @return ggplot object. Visualization of misclassification patterns.
#' @export
plot_nn_misclassifications <- function(nn_model, confidence_threshold = 0.6) {
  # Check if nn_model has the required elements
  if (!is.list(nn_model) || is.null(nn_model$validation_results)) {
    stop("Invalid neural network model or missing validation results.")
  }

  # Create data for misclassification analysis
  misclass_data <- nn_model$validation_results |>
    dplyr::mutate(
      correct = predicted_class == actual_class,
      low_confidence = confidence < confidence_threshold
    )

  # Count occurrences of each type of misclassification
  misclass_counts <- misclass_data |>
    dplyr::filter(!correct) |>
    dplyr::group_by(actual_class, predicted_class) |>
    dplyr::summarize(
      count = dplyr::n(),
      avg_confidence = mean(confidence),
      .groups = "drop"
    ) |>
    dplyr::arrange(desc(count))

  # Create plot
  if (nrow(misclass_counts) > 0) {
    p_misclass <- ggplot2::ggplot(
      misclass_counts,
      ggplot2::aes(
        x = reorder(paste(actual_class, "-", predicted_class), count),
        y = count,
        fill = avg_confidence
      )
    ) +
      ggplot2::geom_col(color = "grey") +
      ggplot2::scale_fill_gradient2(
        low = "white",
        mid = "#828282",
        high = "#111111",
        midpoint = 0.5,
        limits = c(0, 1),
        name = "Avg. Confidence"
      ) +
      ggplot2::geom_text(
        ggplot2::aes(
          label = round(avg_confidence, 1),
          y = count - 0.5,
          color = ifelse(avg_confidence > 0.5, "white", "black")
        ),
      ) +
      ggplot2::scale_color_manual(
        values = c("black", "white"),
        guide = "none"
      ) +
      ggplot2::coord_flip(expand = FALSE) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major.y = ggplot2::element_blank(),
        axis.title.y = ggplot2::element_blank(),
        legend.position = "none"
      ) +
      ggplot2::labs(
        title = "Cross-Validation Misclassifications (Actual - Predicted)",
        subtitle = "Color and number indicate average confidence of misclassifications",
        y = "Count"
      )
  } else {
    p_misclass <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No misclassifications found"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Cross-Validation Misclassification Analysis")
  }
  return(p_misclass)
}

#' Plot Neural Network Classification Landscapes
#'
#' Plots landscapes with neural network classification results, highlighting
#' correct and misclassified cases. Optionally, only misclassified landscapes
#' can be shown.
#'
#' @param classification A data frame with columns: \code{landscape_id},
#'   \code{actual_class}, \code{predicted_class}, and \code{confidence}.
#' @param landscapes A list of landscape objects
#'   corresponding to the classification results.
#' @param only_misclassified Logical; if \code{TRUE}, only misclassified
#'   landscapes are plotted. Default is \code{FALSE}.
#'
#' @return A list of ggplot objects, one for each landscape.
#'
#' @details The function checks input validity, filters misclassified
#'   landscapes if requested, and generates annotated plots for each landscape.
#'
#' @examples
#' # Example usage:
#' # plots <- plot_classified_landscapes(classification, landscape_list)
#'
#' @export
plot_classified_landscapes <- function(
  classification,
  landscapes,
  only_misclassified = FALSE
) {
  # Check if classification has the required elements
  if (
    !is.data.frame(classification) ||
      !all(
        c("landscape_id", "actual_class", "predicted_class", "confidence") %in%
          names(classification)
      )
  ) {
    stop(
      paste(
        "Invalid classification results. Must be a data frame with at least columns: landscape_id, actual_class, predicted_class, confidence.
       Instead it is",
        class(classification)
      )
    )
  }

  # Validate input landscape_list: must be a list of landscape objects
  # First validate that input is a list
  if (!is.list(landscapes)) {
    stop("landscapes must be a list", call. = FALSE)
  }
  # Check if it's a list of landscape objects
  if (any(!sapply(landscapes, is_landscape))) {
    # find out which element is not a landscape
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    stop(
      "All elements must be landscape objects. Invalid element(s) at index(es): ",
      paste(invalid_indices, collapse = ", ")
    )
  }

  # check if the landscape list has the same length as the validation results
  if (length(landscapes) < nrow(classification)) {
    stop(paste(
      "landscapes has fewer entries (",
      length(landscapes),
      ") than validation results (",
      nrow(classification),
      "). Some landscapes may be missing."
    ))
  }

  # If only_misclassified is TRUE, filter to only misclassified landscapes
  if (only_misclassified) {
    classification <- classification |>
      dplyr::filter(predicted_class != actual_class)
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
    titles = classification$title
  )

  return(plots)
}
