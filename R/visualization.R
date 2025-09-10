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
  # Check if landscape has metadata structure
  has_metadata <- has_landscape_metadata(landscape)
  # extract the landscape data if it has metadata
  if (has_metadata) {
    landscape <- get_landscape(landscape)
  }
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
    # Always use sorted numeric values as factor levels for consistency
    df$value <- factor(df$value, levels = sort(unique_values))
  }

  # Set up default color scale if not provided
  if (is.null(color_scale)) {
    # Define a standard palette of 10 distinct colors
    standard_palette <- c(
      "#E5E59F", # light yellow/beige (saltmarsh)
      "#005C29", # dark green (forest)
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

      # If more than 10 colors are needed, use a color palette function
      if (n_colors > 10) {
        color_scale <- viridisLite::viridis(n_colors)
      }
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
      legend.position = if (show_legend) "right" else "none",
      plot.title = ggtext::element_markdown(size = 10),
      axis.text = ggplot2::element_blank()
    )

  # Apply appropriate color scale based on data type
  if (is_discrete) {
    p <- p +
      ggplot2::scale_fill_manual(
        values = color_scale,
        name = legend_title
      )
  } else {
    p <- p +
      ggplot2::scale_fill_gradientn(
        colors = color_scale,
        name = legend_title
      )
  }

  return(p)
}

#' Plot Multiple Landscapes
#'
#' Creates a grid of multiple landscape plots.
#'
#' @param landscape_list List. List of landscapes (SpatRaster, matrix) or list of landscape data with metadata
#'        (as returned by generate_training_landscapes).
#' @param titles Character vector. Vector of titles for each landscape (default: NULL).
#' @param color_scale Character vector. Colors for mapping values across all plots (default: NULL).
#' @param ncol Integer. Number of columns in the plot arrangement (default: NULL).
#' @param legend_title Character. Title for the legend (default: "Value").
#' @param show_legend Logical. Whether to show legend (default: TRUE).
#' @param show_type Logical. Whether to include landscape type in title when custom titles are provided (default: FALSE).
#'
#' @return patchwork object. Combined plot of all landscapes.
#' @export
plot_landscape_list <- function(
  landscape_list,
  titles = NULL,
  color_scale = NULL,
  ncol = NULL,
  legend_title = "Value",
  show_legend = TRUE,
  show_type = TRUE
) {
  # Validate input is a list
  if (!is.list(landscape_list)) {
    stop("landscape_list must be a list of landscapes (SpatRaster or matrix)")
  }

  # Check if the list contains only landscapes with metadata structures
  # (from generate_training_landscapes)
  has_metadata <- lapply(landscape_list, has_landscape_metadata) |>
    unlist() |>
    all()

  # If we have metadata structure, extract landscape types and the landscapes
  if (has_metadata) {
    # Extract landscape types for titles
    types <- sapply(landscape_list, function(x) x$type)

    # Extract just the landscapes
    landscape_list <- lapply(landscape_list, function(x) x$landscape)
  }

  # Generate titles
  if (is.null(titles)) {
    # if list is named, us the names as titles
    if (has_metadata) {
      # Use types as titles when available and no custom titles provided
      titles <- types
    } else if (!is.null(names(landscape_list))) {
      # Use list names if available
      titles <- names(landscape_list)
    } else {
      # Simple default titles as last resort
      titles <- paste("Landscape", 1:length(landscape_list))
    }
  } else if (length(titles) != length(landscape_list)) {
    warning(
      "Number of titles doesn't match number of landscapes. Using default titles."
    )
    if (has_metadata) {
      titles <- types
    } else {
      titles <- paste("Landscape", 1:length(landscape_list))
    }
  } else if (has_metadata && show_type) {
    # Append type information to user-provided titles if requested
    titles <- paste0(titles, " (", types, ")")
  }

  # Create a list of plots
  plot_list <- list()
  for (i in 1:length(landscape_list)) {
    # Pass all plotting decisions to plot_landscape
    plot_list[[i]] <- plot_landscape(
      landscape = landscape_list[[i]],
      title = titles[i],
      color_scale = color_scale,
      legend_title = legend_title,
      show_legend = show_legend
    )
  }

  # Combine all plots using patchwork
  combined_plot <- patchwork::wrap_plots(plot_list, ncol = ncol)

  # Use patchwork to handle legend collection if needed
  if (show_legend && length(landscape_list) > 1) {
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

plot_nn_classification_landscapes <- function(
  nn_model,
  landscape_list,
  only_misclassified = FALSE
) {
  # Check if nn_model has the required elements
  if (
    !is.list(nn_model) ||
      is.null(nn_model$validation_results) ||
      is.null(nn_model$classes)
  ) {
    stop("Invalid neural network model or missing validation results.")
  }

  # Validate input landscape_list
  if (!is.list(landscape_list)) {
    stop("landscape_list must be a list of landscapes (SpatRaster or matrix)")
  }

  # check if the landscape list has the same length as the validation results
  if (length(landscape_list) < nrow(nn_model$validation_results)) {
    stop(paste(
      "landscape_list has fewer entries (",
      length(landscape_list),
      ") than validation results (",
      nrow(nn_model$validation_results),
      "). Some landscapes may be missing."
    ))
  }

  # Extract validation results
  val_results <- nn_model$validation_results

  # If only_misclassified is TRUE, filter to only misclassified landscapes
  if (only_misclassified) {
    val_results <- val_results |>
      dplyr::filter(predicted_class != actual_class)
  }

  # Add plot titles as a column to the validation results
  val_results <- val_results |>
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
  landscapes_to_plot <- landscape_list[val_results$landscape_id]

  # Create plots for each landscape
  plots <- plot_landscape_list(
    landscape_list = landscapes_to_plot,
    titles = val_results$title
  )

  return(plots)
}
