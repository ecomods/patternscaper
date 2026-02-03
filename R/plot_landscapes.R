#' Plot a Landscape
#'
#' A wrapper function for the S3 method \code{plot.landscape} with additional customization options.
#'
#' @param landscape A landscape object to plot.
#' @param title Character. Controls the plot title:
#'        - "name": uses only the landscape name
#'        - "pattern": uses only the landscape pattern
#'        - "both": uses "name (pattern)" format
#'        - "none": no title
#'        - Any other string: used as a custom title
#'        Default: "pattern"
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
#' # Default plot (shows both name and pattern)
#' plot_landscape(l)
#'
#' # Show only pattern name
#' plot_landscape(l, title = "pattern")
#'
#' # Custom title and legend
#' plot_landscape(l,
#'               title = "My Sharp Treeline",
#'               legend_title = "Vegetation",
#'               show_legend = TRUE)
#' @export
plot_landscape <- function(
  landscape,
  title = "pattern",
  show_legend = TRUE,
  legend_title = "Value"
) {
  # Validate landscape is a landscape object
  if (!is_landscape(landscape)) {
    cli::cli_abort("'landscape' must be a landscape object")
  }

  # Generate the base plot using plot.landscape
  p <- plot(landscape)

  # Build the title based on the options
  plot_title <- switch(
    title,
    name = if (!is.na(landscape$name)) landscape$name else "Unnamed landscape",
    pattern = if (!is.na(landscape$pattern)) {
      landscape$pattern
    } else {
      "Unclassified landscape"
    },
    both = paste0(
      if (!is.na(landscape$name)) landscape$name else "Unnamed landscape",
      " (",
      if (!is.na(landscape$pattern)) landscape$pattern else "unclassified",
      ")"
    ),
    none = NULL, # No title
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
#'     \code{\link{create_landscapes}}.
#' @param titles Character. Controls the plot titles:
#'        - "name": uses only the landscape name
#'        - "pattern": uses only the landscape pattern
#'        - "both": uses "name (pattern)" format
#'        - "none": no title
#'        - A character vector with custom titles for each landscape. If providing
#'        `subset_index`, ensure titles match the subset length.
#'        Default is "pattern"
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
#' many_landscapes <- create_landscapes(n = 50)
#' plot_landscape_list(many_landscapes,
#'                    max_landscapes = 9,  # Show first 9 only
#'                    ncol = 3)            # In 3x3 grid
#' @export
plot_landscape_list <- function(
  landscapes,
  titles = "pattern",
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
    if (!titles %in% c("name", "pattern", "both", "none")) {
      cli::cli_alert_warning(
        "Using a single custom title for multiple landscapes. All plots will have the same title."
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
