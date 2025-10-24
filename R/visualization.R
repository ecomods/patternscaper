#' Plot a Landscape
#'
#' A wrapper function for the S3 method \code{plot.landscape} with additional customization options.
#'
#' @param landscape A landscape object to plot.
#' @param title Character. Controls the plot title:
#'        - "name": uses only the landscape name
#'        - "class": uses only the landscape class
#'        - "both": uses "name (class)" format
#'        - Any other string: used as a custom title
#'        Default: "both"
#' @param show_legend Logical. Whether to show legend (default: TRUE).
#' @param legend_title Character. Title for the legend (default: "Value").
#'
#' @return ggplot object. Plot of the landscape.
#' @importFrom ggplot2 ggplot aes geom_raster coord_equal labs theme_minimal theme
#'             element_blank scale_fill_manual scale_fill_viridis_c
#' @importFrom ggtext element_markdown
#' @examples
#'
#' # Create a basic landscape
#' l <- create_landscape("sharp", width = 50, height = 50)
#'
#' # Default plot (shows both name and class)
#' plot_landscape(l)
#'
#' # Show only class name
#' plot_landscape(l, title = "class")
#'
#' # Custom title and legend
#' plot_landscape(l,
#'               title = "My Sharp Treeline",
#'               legend_title = "Vegetation",
#'               show_legend = TRUE)
#' @export
plot_landscape <- function(
  landscape,
  title = "both",
  show_legend = TRUE,
  legend_title = "Value"
) {
  # Validate landscape is a landscape object
  if (!is_landscape(landscape)) {
    stop("'landscape' must be a landscape object", call. = FALSE)
  }

  # Generate the base plot using plot.landscape
  p <- plot(landscape)

  # Build the title based on the options
  plot_title <- switch(
    title,
    name = if (!is.na(landscape$name)) landscape$name else "Unnamed landscape",
    class = if (!is.na(landscape$class)) {
      landscape$class
    } else {
      "Unclassified landscape"
    },
    both = paste0(
      if (!is.na(landscape$name)) landscape$name else "Unnamed landscape",
      " (",
      if (!is.na(landscape$class)) landscape$class else "unclassified",
      ")"
    ),
    title # Use custom title as provided if not one of the special keywords
  )

  # Check if data is discrete by examining the plot's fill scale
  is_discrete <- is.factor(p$data$value)

  # Update plot with appropriate scale and customizations
  if (is_discrete) {
    # Define standard palette for discrete data
    standard_palette <- c(
      "#E5E59F",
      "#005C29",
      "#8DA0CB",
      "#E78AC3",
      "#A6D854",
      "#FFD92F",
      "#E5C494",
      "#B3B3B3",
      "#7570B3",
      "#D95F02"
    )

    p <- p +
      ggplot2::scale_fill_manual(
        values = standard_palette,
        name = legend_title
      )
  } else {
    p <- p +
      ggplot2::scale_fill_viridis_c(name = legend_title)
  }

  # Add title and legend customization
  p <- p +
    ggplot2::labs(title = plot_title, fill = legend_title) +
    ggplot2::theme(
      legend.position = if (show_legend) "right" else "none",
      plot.title = ggtext::element_markdown(size = 10)
    )

  return(p)
}

#' Plot Multiple Landscapes
#'
#' Creates a grid of multiple landscape plots.
#'
#' @param landscapes List. List of landscape objects to plot. E.g. created by
#'     \code{\link{create_training_landscapes}}.
#' @param titles Character. Controls the plot titles:
#'        - "name": uses only the landscape name
#'        - "class": uses only the landscape class
#'        - "both": uses "name (class)" format
#'        - A character vector with custom titles for each landscape. If providing
#'        `subset_index`, ensure titles match the subset length.
#'        Default is "both"
#' @param show_legend Logical. Whether to show a single combined legend (default: TRUE).
#' @param legend_title Character. Title for the legend (default: "Value").
#' @param ncol Integer. Number of columns in the plot grid (default: NULL).
#' @param max_landscapes Integer. Maximum number of landscapes to plot (default: 36).
#'     Plotting more than 36 landscapes (6x6 grid) is not recommended.
#' @param force Logical. Override max_landscapes limit (default: FALSE).
#' @param subset_index Integer vector. Indices of landscapes to plot.
#'     Can be used to plot specific landscapes or change plot order (default: NULL).
#'
#' @return A ggplot object combining all landscape plots.
#' @importFrom patchwork wrap_plots plot_layout
#' @examples
#' # Create a list of different landscapes
#' landscapes <- list(
#'   create_landscape("sharp", width = 50, height = 50),
#'   create_landscape("random", width = 50, height = 50),
#'   create_landscape("diffuse", width = 50, height = 50)
#' )
#'
#' # Default plot (3x1 grid)
#' plot_landscape_list(landscapes)
#'
#' # 2-column grid with custom titles
#' plot_landscape_list(landscapes,
#'                    titles = c("Sharp", "Random", "Diffuse"),
#'                    ncol = 2)
#'
#' # Plot only first two landscapes
#' plot_landscape_list(landscapes,
#'                    subset_index = 1:2,
#'                    legend_title = "Vegetation")
#'
#' # Create many landscapes and handle overflow
#' many_landscapes <- create_training_landscapes(n = 50)
#' plot_landscape_list(many_landscapes,
#'                    max_landscapes = 9,  # Show first 9 only
#'                    ncol = 3)            # In 3x3 grid
#' @export
plot_landscape_list <- function(
  landscapes,
  titles = "both",
  show_legend = TRUE,
  legend_title = "Value",
  ncol = NULL,
  max_landscapes = 36,
  force = FALSE,
  subset_index = NULL
) {
  # Validate inputs

  # First validate that input is a list
  if (!is.list(landscapes)) {
    stop("landscapes must be a list", call. = FALSE)
  }

  # Then check if list is empty
  if (length(landscapes) == 0) {
    stop(
      "landscapes must contain at least one landscape to plot",
      call. = FALSE
    )
  }

  if (any(!sapply(landscapes, is_landscape))) {
    # find out which element is not a landscape
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    stop(
      "All elements must be landscape objects. Invalid element(s) at index(es): ",
      paste(invalid_indices, collapse = ", ")
    )
  }

  # Subset the landscape list if subset_index is provided
  if (!is.null(subset_index)) {
    landscapes <- landscapes[subset_index]
  }

  # Check if enough titles are provided for the subset
  if (length(titles) > 1 && length(titles) != length(landscapes)) {
    stop(
      sprintf(
        "If providing multiple titles, length must match number of landscapes (%d). Got %d titles instead.",
        length(landscapes),
        length(titles)
      ),
      call. = FALSE
    )
  }

  # If number of landscapes exceeds max_landscapes, limit it (only if force is FALSE)
  if (length(landscapes) > max_landscapes && !force) {
    warning(
      sprintf(
        "Number of landscapes (%d) exceeds maximum (%d). Showing first %d. Use force=TRUE to override or subset_index to select a subset of landscapes to plot.",
        length(landscapes),
        max_landscapes,
        max_landscapes
      ),
      call. = FALSE
    )
    landscapes <- landscapes[1:max_landscapes]
  }

  # Generate title strings to pass to plot_landscape for each landscape
  if (length(titles) == 1) {
    # check that titles is one of the special keywords
    if (!titles %in% c("name", "class", "both")) {
      warning(
        "Using a single custom title for multiple landscapes. All plots will have the same title.",
        call. = FALSE
      )
    }
    titles <- rep(titles, length(landscapes))
  }

  # Create a list of plots
  plot_list <- list()
  for (i in seq_along(landscapes)) {
    # Pass all plotting decisions to plot_landscape
    plot_list[[i]] <- plot_landscape(
      landscape = landscapes[[i]],
      title = titles[i],
      show_legend = show_legend,
      legend_title = legend_title
    )
  }

  # Combine all plots using patchwork
  combined_plot <- patchwork::wrap_plots(plot_list, ncol = ncol)

  # Use patchwork to collect legend if it's shown
  if (show_legend && length(landscapes) > 1) {
    combined_plot <- combined_plot +
      patchwork::plot_layout(guides = "collect")
  }

  return(combined_plot)
}

#' Plot Landscape Metrics
#'
#' Creates a visualization of landscape metric values across landscape types.
#'
#' @param metrics Data frame. Metrics dataframe from calculate_landscape_metrics.
#'    Needs to contain columns: "level", "type", "metric", "value", and optionally "class".
#' @param selected_metrics Character vector. Metrics to visualize.
#'
#' @return ggplot object. Visualization of selected metrics across landscape types.
#' @export
plot_metrics <- function(
  calculated_metrics,
  selected_metrics,
  title = "Landscape Metrics"
) {
  # Validate input data
  if (!is.data.frame(calculated_metrics)) {
    stop("metrics must be a data frame from calculate_landscape_metrics()")
  }
  if (!is.character(selected_metrics)) {
    stop("selected_metrics must be a character vector of metric names")
  }
  # check if metrics data has columns we need
  required_cols <- c("level", "type", "metric", "value")
  if (!all(required_cols %in% names(calculated_metrics))) {
    stop(paste(
      "metrics data frame must contain the following columns:",
      paste(required_cols, collapse = ", ")
    ))
  }
  if (length(selected_metrics) == 0) {
    stop("selected_metrics must contain at least one metric to plot")
  }

  # extract level at which metrics were calculated
  level <- unique(calculated_metrics$level)

  # Prepare the data for plotting
  plot_data <- calculated_metrics |>
    dplyr::filter(metric %in% selected_metrics) |>
    # Order metrics by their order in selected_metrics
    dplyr::mutate(
      metric = factor(metric, levels = selected_metrics),
      type = as.factor(type)
    )

  # Create the base plot (depends on the level at which metrics were calculated)
  if (level == "landscape") {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = type, y = value))
  } else if (level == "class") {
    p <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = type, y = value, fill = class)
    )
  } else {
    stop("Plotting for patch-level metrics is not implemented yet.")
  }

  p <- p +
    ggplot2::geom_boxplot() +
    ggplot2::geom_jitter(
      position = ggplot2::position_jitter(width = 0.1),
      size = 1,
      alpha = 0.7
    ) +
    ggplot2::facet_wrap(~metric, scales = "free_x") +
    ggplot2::coord_flip() +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
    ) +
    ggplot2::labs(
      x = "Landscape Type",
      y = "Metric Value"
    )
  return(p)
}

#' Plot Neural Network Classification Results
#'
#' Creates visualizations of neural network model results from cross-validation.
#'
#' @param nn_model List. Neural network model from train_nn().
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
#' @param nn_model List. Neural network model from train_nn().
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
#' @param nn_model List. Neural network model from train_nn().
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
#' @param nn_model List. Neural network model from train_nn().
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
#' @param nn_model List. Neural network model from train_nn().
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
#' @param landscape_list A list of landscapes (e.g., SpatRaster or matrix)
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
#' # plots <- plot_nn_classification_landscapes(classification, landscape_list)
#'
#' @export
plot_nn_classification_landscapes <- function(
  classification,
  landscape_list,
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

  # Validate input landscape_list
  if (!is.list(landscape_list)) {
    stop("landscape_list must be a list of landscapes (SpatRaster or matrix)")
  }

  # check if the landscape list has the same length as the validation results
  if (length(landscape_list) < nrow(classification)) {
    stop(paste(
      "landscape_list has fewer entries (",
      length(landscape_list),
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
  landscapes_to_plot <- landscape_list[classification$landscape_id]

  # Create plots for each landscape
  plots <- plot_landscape_list(
    landscape_list = landscapes_to_plot,
    titles = classification$title
  )

  return(plots)
}
