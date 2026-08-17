# Plot a Single Landscape (internal)
#
# Create a customizable plot of a single landscape object with options for
# titles, legends, and display preferences. Used internally by
# \code{\link{plot_landscapes}} to render each landscape in the grid; not
# exported since \code{plot_landscapes()} also accepts a single landscape
# directly.
#
# @param landscape A landscape object to plot.
# @param title Character. Controls the plot title:
#        - "name": uses only the landscape name
#        - "pattern": uses only the landscape pattern
#        - "both": uses "name (pattern)" format
#        - "none": no title
#        - Any other string: used as-is as a custom title
#        Default: "pattern"
# @param show_legend Logical. Whether to show legend (default: TRUE).
# @param legend_title Character. Title for the legend (default: "Value").
#
# @return ggplot object. Plot of the landscape.
# @keywords internal
# @noRd
plot_single_landscape <- function(
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
      "#56B4E9",
      "#D55E00",
      "#0072B2",
      "#CC79A7",
      "#E69F00",
      "#009E73"
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

#' Plot One or More Landscapes
#'
#' Creates a plot of a single landscape, or a grid of multiple landscape
#' plots.
#'
#' @param landscapes A single landscape object, or a list of landscape
#'     objects to plot. E.g. created by \code{\link{create_landscape}} or
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
#' @return A patchwork object combining one or more landscape plots.
#' @details
#' To add \pkg{ggplot2} elements (themes, scales, etc.) to every panel of the
#' result, use \code{&} rather than \code{+} (e.g.
#' \code{plot_landscapes(landscapes) & ggplot2::theme_dark()}): with more than
#' one landscape, \code{+} only modifies the last panel, while \code{&}
#' applies to all of them. For a single landscape the two operators happen to
#' give the same result, but using \code{&} consistently avoids surprises if
#' more landscapes are added later.
#' @family visualization
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}}
#' @importFrom patchwork wrap_plots plot_layout
#' @examples
#' # Plot a single landscape
#' l <- create_landscape("sharp", width = 50, height = 50)
#' plot_landscapes(l)
#'
#' # Custom title and legend for a single landscape
#' plot_landscapes(l,
#'                 titles = "My Sharp Treeline",
#'                 legend_title = "Vegetation")
#'
#' # Use & (not +) to add ggplot2 elements to every panel
#' plot_landscapes(l) & ggplot2::theme_dark()
#'
#' # Create a list of different landscapes
#' landscapes <- list(
#'   create_landscape("sharp", width = 50, height = 50),
#'   create_landscape("random", width = 50, height = 50),
#'   create_landscape("diffuse", width = 50, height = 50)
#' )
#'
#' # Default plot (3x1 grid)
#' plot_landscapes(landscapes)
#'
#' # & applies to all three panels; + would only affect the last one
#' plot_landscapes(landscapes) & ggplot2::theme_dark()
#'
#' # 2-column grid with custom titles
#' plot_landscapes(landscapes,
#'                 titles = c("Sharp", "Random", "Diffuse"),
#'                 ncol = 2)
#'
#' # Plot only first two landscapes
#' plot_landscapes(landscapes,
#'                 subset_index = 1:2,
#'                 legend_title = "Vegetation")
#'
#' # Create many landscapes and handle overflow
#' many_landscapes <- create_landscapes(n = 12, width = 50, height = 50)
#' plot_landscapes(many_landscapes,
#'                 max_landscapes = 4,  # Show first 4 only
#'                 ncol = 2)            # In 2x2 grid
#' @export
plot_landscapes <- function(
  landscapes,
  titles = "pattern",
  show_legend = TRUE,
  legend_title = "Value",
  ncol = NULL,
  max_landscapes = 36,
  force = FALSE,
  subset_index = NULL
) {
  # Allow a single landscape object to be passed directly, without wrapping
  # it in a list
  if (is_landscape(landscapes)) {
    landscapes <- list(landscapes)
  }

  # Validate inputs

  # First validate that input is a list
  if (!is.list(landscapes)) {
    cli::cli_abort(
      "landscapes must be a landscape object or a list of landscape objects"
    )
  }

  # Then check if list is empty
  if (length(landscapes) == 0) {
    cli::cli_abort(
      "landscapes must contain at least one landscape to plot"
    )
  }

  if (any(!vapply(landscapes, is_landscape, logical(1)))) {
    # find out which element is not a landscape
    invalid_indices <- which(!vapply(landscapes, is_landscape, logical(1)))
    cli::cli_abort(
      "All elements must be landscape objects. Invalid element(s) at index(es): {paste(invalid_indices, collapse = ', ')}"
    )
  }

  # Subset the landscape list if subset_index is provided
  if (!is.null(subset_index)) {
    landscapes <- landscapes[subset_index]
  }

  # Check if enough titles are provided for the subset
  if (length(titles) > 1 && length(titles) != length(landscapes)) {
    cli::cli_abort(
      "If providing multiple titles, length must match number of landscapes ({length(landscapes)}). Got {length(titles)} titles instead."
    )
  }

  # If number of landscapes exceeds max_landscapes, limit it (only if force is FALSE)
  if (length(landscapes) > max_landscapes && !force) {
    cli::cli_warn(
      "Number of landscapes ({length(landscapes)}) exceeds maximum ({max_landscapes}). Showing first {max_landscapes}. Use {.code force = TRUE} to override or {.arg subset_index} to select a subset of landscapes to plot."
    )
    landscapes <- landscapes[1:max_landscapes]
  }

  # Generate title strings to pass to plot_single_landscape for each landscape
  if (length(titles) == 1) {
    # check that titles is one of the special keywords
    if (
      length(landscapes) > 1 &&
        !titles %in% c("name", "pattern", "both", "none")
    ) {
      cli::cli_alert_warning(
        "Using a single custom title for multiple landscapes. All plots will have the same title."
      )
    }
    titles <- rep(titles, length(landscapes))
  }

  # Create a list of plots
  plot_list <- list()
  for (i in seq_along(landscapes)) {
    # Pass all plotting decisions to plot_single_landscape
    plot_list[[i]] <- plot_single_landscape(
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
