#' Plot a landscape matrix with automatic detection of discrete or continuous data
#'
#' Visualizes a landscape matrix using ggplot2, automatically selecting an appropriate
#' color scale based on whether the data is discrete (binary/categorical) or continuous.
#'
#' @param landscape A matrix representing the landscape to plot
#' @param title Character string for the plot title (default: "Landscape Pattern")
#' @param discrete_colors Vector of colors to use for discrete values (default: c("#E5E59F", "#005C29"))
#' @param discrete_labels Vector of labels for discrete values (default: c("Saltmarsh", "Mangrove"))
#' @param continuous_colors Vector of colors for gradient (default: c("#E5E59F", "#005C29"))
#' @param legend_title Character string for the legend title (default: "Land Cover")
#'
#' @return A ggplot object
#' @export
plot_landscape <- function(
  landscape,
  title = "",
  discrete_colors = c("#E5E59F", "#005C29"),
  discrete_labels = c("Saltmarsh", "Mangrove"),
  continuous_colors = c("#E5E59F", "#005C29"),
  legend_title = "Land Cover"
) {
  # Check if landscape is discrete or continuous
  # Detect if the data appears to be discrete (binary or categorical)
  unique_values <- unique(as.vector(landscape))
  # Consider it discrete if fewer than 10 unique values or all values are integers
  is_discrete <- length(unique_values) < 10 &&
    all(unique_values == round(unique_values))

  # Convert matrix to data frame for ggplot
  df <- as.data.frame(landscape) |>
    dplyr::mutate(y = dplyr::row_number()) |>
    tidyr::pivot_longer(-y, names_to = "x", values_to = "value") |>
    dplyr::mutate(x = as.numeric(stringr::str_replace(x, "V", "")))

  # Create base plot
  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = x, y = y, fill = if (is_discrete) factor(value) else value)
  ) +
    ggplot2::geom_tile() +
    ggplot2::scale_y_reverse() + # Reverse y-axis to have origin at top-left
    ggplot2::labs(title = title, x = "Column", y = "Row") +
    ggplot2::coord_equal(expand = FALSE) + # Ensure square cells
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.title = ggplot2::element_blank()
    )

  # Apply appropriate color scale based on data type
  if (is_discrete) {
    # For discrete data, create named vector of colors
    color_map <- stats::setNames(
      discrete_colors[1:min(length(discrete_colors), length(unique_values))],
      sort(as.character(unique_values))
    )

    # Create named vector of labels if available
    if (length(discrete_labels) >= length(unique_values)) {
      label_map <- stats::setNames(
        discrete_labels[1:length(unique_values)],
        sort(as.character(unique_values))
      )
      p <- p +
        ggplot2::scale_fill_manual(
          values = color_map,
          labels = label_map,
          name = legend_title
        )
    } else {
      p <- p +
        ggplot2::scale_fill_manual(values = color_map, name = legend_title)
    }
  } else {
    # For continuous data
    p <- p +
      ggplot2::scale_fill_gradientn(
        colours = continuous_colors,
        na.value = "grey98",
        name = legend_title
      )
  }

  return(p)
}
