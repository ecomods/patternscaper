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
      print(titles)
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
  # Check if nn_model has the required elements
  if (!is.list(nn_model) || is.null(nn_model$performance)) {
    stop(
      "Invalid neural network model. Must be a list with performance element."
    )
  }

  # Extract key data from model
  class_names <- nn_model$classes

  # Set up plot list for potential return_all
  plot_list <- list()

  # 1. Confusion Matrix Plot --------------------------------------------------
  if (plot_type == "confusion" || return_all) {
    if (is.null(nn_model$performance$confusion_matrix)) {
      message("No confusion matrix available. Skipping confusion plot.")
    } else {
      # Convert confusion matrix to data frame for plotting
      conf_matrix <- nn_model$performance$confusion_matrix
      conf_df <- as.data.frame(as.table(conf_matrix))
      names(conf_df) <- c("Predicted", "Actual", "Count")

      # Calculate cell percentages (by actual class column)
      conf_df <- conf_df |>
        dplyr::mutate(Percent = Count / sum(Count) * 100, .by = Actual)

      # Create plot
      p_confusion <- ggplot2::ggplot(
        conf_df,
        ggplot2::aes(x = Actual, y = Predicted, fill = Percent)
      ) +
        ggplot2::geom_tile() +
        ggplot2::geom_text(
          ggplot2::aes(label = sprintf("%.1f%%", Percent)),
          color = "black"
        ) +
        ggplot2::scale_fill_gradient2(
          low = "white",
          mid = "#6baed6",
          high = "#084594",
          midpoint = 50,
          limits = c(0, 100),
          name = "% of Actual Class"
        ) +
        ggplot2::coord_fixed() +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          panel.grid = ggplot2::element_blank(),
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
        ) +
        ggplot2::labs(
          title = "Cross-Validation Confusion Matrix",
          subtitle = sprintf(
            "Accuracy: %.1f%% (%s with %d folds)",
            nn_model$performance$accuracy * 100,
            nn_model$performance$cv_method,
            nn_model$performance$cv_folds
          ),
          fill = "% of Actual Class"
        )

      plot_list[["confusion"]] <- p_confusion
      if (plot_type == "confusion" && !return_all) {
        return(p_confusion)
      }
    }
  }

  # 2. Validation Probabilities Plot ------------------------------------------
  if (plot_type == "probabilities" || return_all) {
    if (is.null(nn_model$validation_results)) {
      message(
        "No validation results available. Add code to store cross-validation probabilities in train_nn()."
      )
    } else {
      # Extract class probabilities from validation results
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
        ggplot2::geom_tile() +
        ggplot2::geom_text(
          ggplot2::aes(label = sprintf("%.2f", MeanProbability)),
          color = ifelse(
            prob_matrix_data$MeanProbability > 0.7,
            "white",
            "black"
          )
        ) +
        ggplot2::scale_fill_gradient2(
          low = "white",
          mid = "#6baed6",
          high = "#084594",
          midpoint = 0.5,
          limits = c(0, 1),
          name = "Mean Probability"
        ) +
        ggplot2::coord_fixed() +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          panel.grid = ggplot2::element_blank(),
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
        ) +
        ggplot2::labs(
          title = "Cross-Validation Mean Probabilities",
          subtitle = "Average probability that landscapes of class X are classified as class Y",
          x = "Actual Class",
          y = "Predicted Class",
          fill = "Mean Probability"
        )

      plot_list[["probabilities"]] <- p_probabilities
      if (plot_type == "probabilities" && !return_all) {
        return(p_probabilities)
      }
    }
  }

  # 3. Confidence by Class ----------------------------------------------------
  if (plot_type == "confidence" || return_all) {
    if (is.null(nn_model$validation_results)) {
      message(
        "No validation results available. Add code to store cross-validation results in train_nn()."
      )
    } else {
      # Create data for confidence plot
      confidence_data <- nn_model$validation_results

      # Create plot
      p_confidence <- ggplot2::ggplot(
        confidence_data,
        ggplot2::aes(
          x = factor(actual_class),
          y = confidence,
          color = factor(predicted_class == actual_class)
        )
      ) +
        ggplot2::geom_boxplot(outlier.shape = NA) +
        ggplot2::geom_point(
          position = ggplot2::position_jitterdodge(
            jitter.width = 0.1,
            dodge.width = 0.75
          ),
          alpha = 0.5
        ) +
        ggplot2::geom_hline(
          yintercept = confidence_threshold,
          linetype = "dashed",
          color = "red"
        ) +
        ggplot2::scale_color_manual(
          values = c("tomato", "forestgreen"),
          name = "Prediction",
          labels = c("Incorrect", "Correct")
        ) +
        ggplot2::theme_bw() +
        ggplot2::theme(
          panel.grid.minor = ggplot2::element_blank(),
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
        ) +
        ggplot2::labs(
          title = "Cross-Validation Confidence by Class",
          subtitle = sprintf(
            "Dashed line shows confidence threshold (%.1f)",
            confidence_threshold
          ),
          x = "Actual Class",
          y = "Confidence Score"
        )

      plot_list[["confidence"]] <- p_confidence
      if (plot_type == "confidence" && !return_all) {
        return(p_confidence)
      }
    }
  }

  # 4. Misclassification Analysis ----------------------------------------------
  if (plot_type == "misclassifications" || return_all) {
    if (is.null(nn_model$validation_results)) {
      message(
        "No validation results available. Add code to store cross-validation results in train_nn()."
      )
    } else {
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
          count = n(),
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
            mid = "#6baed6",
            high = "#084594",
            midpoint = 0.5,
            limits = c(0, 1),
            name = "Avg. Confidence"
          ) +
          ggplot2::coord_flip() +
          ggplot2::theme_bw() +
          ggplot2::theme(
            panel.grid.minor = ggplot2::element_blank()
          ) +
          ggplot2::labs(
            title = "Common Cross-Validation Misclassifications",
            subtitle = "Frequency of specific misclassification patterns",
            y = "Count",
            x = "Misclassification (Actual - Predicted)"
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

      plot_list[["misclassifications"]] <- p_misclass
      if (plot_type == "misclassifications" && !return_all) {
        return(p_misclass)
      }
    }
  }

  # Return all plots if requested
  if (return_all) {
    return(plot_list)
  }

  # Default return if plot_type wasn't valid
  stop(
    "Invalid plot_type. Choose from: 'confusion', 'probabilities', 'confidence', or 'misclassifications'"
  )
}
