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
    df$value <- factor(df$value, levels = unique_values)
  }

  # Set up default color scale if not provided
  if (is.null(color_scale)) {
    # Define a standard palette of 10 distinct colors
    standard_palette <- c(
      "#005C29", # dark green (forest)
      "#E5E59F", # light yellow/beige (saltmarsh)
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
      legend.position = if (show_legend) "right" else "none"
    )

  # Apply appropriate color scale based on data type
  if (is_discrete) {
    p <- p +
      ggplot2::scale_fill_manual(
        values = color_scale,
        name = legend_title,
        na.value = "grey80"
      )
  } else {
    p <- p +
      ggplot2::scale_fill_gradientn(
        colours = color_scale,
        name = legend_title,
        na.value = "grey80"
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

  # Check if the list contains metadata structures (from generate_training_landscapes)
  has_metadata <- has_landscape_metadata(landscape_list)

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

#' Plot Raw Landscape Metrics
#'
#' Creates visualizations of raw landscape metrics data to help users
#' understand their metrics before selecting an evaluation method.
#'
#' @param metrics Data frame. Metrics dataframe from calculate_landscape_metrics.
#' @param plot_type Character. Type of plot to create: "boxplot", "heatmap", "variability", or "parallel" (default: "boxplot").
#' @param title Character. Plot title (default: "Raw Landscape Metrics").
#' @param scale_values Logical. Whether to scale metric values for better comparison (default: FALSE).
#' @param top_n Integer. Number of metrics to highlight in variability plot (default: 10).
#' @param return_all Logical. Whether to return all plot types as a list (default: FALSE).
#'
#' @return ggplot object or list of ggplot objects. Visualization(s) of raw metrics.
#' @export
plot_raw_metrics <- function(
  metrics,
  plot_type = "boxplot",
  title = "Raw Landscape Metrics",
  scale_values = FALSE,
  top_n = 10,
  return_all = FALSE
) {
  # Check input dataframe structure
  if (!all(c("metric", "value", "type") %in% names(metrics))) {
    stop(
      "Metrics dataframe must contain columns: 'metric', 'value', and 'type'"
    )
  }

  # Scale values if requested
  if (scale_values) {
    metrics <- metrics %>%
      dplyr::group_by(metric) %>%
      dplyr::mutate(value = scale(value)[, 1]) %>%
      dplyr::ungroup()
  }

  # Create boxplot
  p_boxplot <- ggplot2::ggplot(
    metrics,
    ggplot2::aes(x = type, y = value, fill = type)
  ) +
    ggplot2::geom_boxplot() +
    ggplot2::facet_wrap(~metric, scales = "free_y") +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "bottom",
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold")
    ) +
    ggplot2::labs(
      title = paste0(title, " - Distribution"),
      x = "Landscape Type",
      y = "Metric Value"
    )

  # Create heatmap
  # Calculate mean values for each metric by type
  means <- metrics %>%
    dplyr::group_by(metric, type) %>%
    dplyr::summarize(mean_value = mean(value, na.rm = TRUE), .groups = "drop")

  # Standardize values for the heatmap using base R scale function
  means_wide <- tidyr::pivot_wider(
    means,
    names_from = type,
    values_from = mean_value
  )

  # Apply scale() to each row (metric) and convert back to long format
  metric_names <- means_wide$metric
  scaled_values <- t(scale(t(as.matrix(means_wide[, -1]))))

  means_scaled <- data.frame(
    metric = rep(metric_names, ncol(scaled_values)),
    type = rep(colnames(scaled_values), each = nrow(scaled_values)),
    mean_value_scaled = as.vector(scaled_values)
  )

  p_heatmap <- ggplot2::ggplot(
    means_scaled,
    ggplot2::aes(x = type, y = metric, fill = mean_value_scaled)
  ) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient2(
      low = "blue",
      mid = "white",
      high = "red",
      midpoint = 0,
      name = "Standardized\nValue"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid = ggplot2::element_blank()
    ) +
    ggplot2::labs(title = paste0(title, " - Heatmap"))

  # Create metric variability plot
  # Calculate coefficient of variation for each metric
  cv_data <- metrics %>%
    dplyr::group_by(metric) %>%
    dplyr::summarize(
      mean = mean(value, na.rm = TRUE),
      sd = sd(value, na.rm = TRUE),
      cv = sd / abs(mean),
      .groups = "drop"
    ) %>%
    dplyr::arrange(desc(cv))

  # Highlight top metrics by CV
  cv_data$highlight <- cv_data$metric %in%
    cv_data$metric[1:min(top_n, nrow(cv_data))]

  p_variability <- ggplot2::ggplot(
    cv_data,
    ggplot2::aes(x = reorder(metric, cv), y = cv, fill = highlight)
  ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(
      values = c("FALSE" = "gray80", "TRUE" = "steelblue")
    ) +
    ggplot2::coord_flip() +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(
      title = paste0(title, " - Variability"),
      x = "Metric",
      y = "Coefficient of Variation"
    )

  # Create parallel coordinate plot
  # Create a scaled version of the data for parallel plot
  parallel_data <- metrics %>%
    dplyr::group_by(metric) %>%
    dplyr::mutate(scaled_value = scale(value)[, 1]) %>%
    dplyr::ungroup()

  p_parallel <- ggplot2::ggplot(
    parallel_data,
    ggplot2::aes(
      x = metric,
      y = scaled_value,
      group = interaction(id, type),
      color = type
    )
  ) +
    ggplot2::geom_line(alpha = 0.5) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5),
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::labs(
      title = paste0(title, " - Parallel Coordinates"),
      x = "Metric",
      y = "Scaled Value"
    )

  # Return either a single plot or all plots based on parameters
  if (return_all) {
    return(list(
      boxplot = p_boxplot,
      heatmap = p_heatmap,
      variability = p_variability,
      parallel = p_parallel
    ))
  } else {
    # Return the requested plot type
    switch(
      plot_type,
      "boxplot" = return(p_boxplot),
      "heatmap" = return(p_heatmap),
      "variability" = return(p_variability),
      "parallel" = return(p_parallel),
      stop(
        "Invalid plot_type. Choose from: 'boxplot', 'heatmap', 'variability', or 'parallel'"
      )
    )
  }
}
