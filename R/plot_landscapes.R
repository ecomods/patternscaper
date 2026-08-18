# Plot one landscape for plot_landscapes()
#
# `title` accepts "name", "pattern", "both", "none", or a custom string
plot_single_landscape <- function(
  landscape,
  title = "pattern",
  show_legend = TRUE,
  legend_title = "Value"
) {
  # Validate input
  if (!is_landscape(landscape)) {
    cli::cli_abort("'landscape' must be a landscape object")
  }

  p <- plot(landscape)

  # Resolve the requested title
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

  # Match the fill scale to categorical or continuous values
  is_discrete <- is.factor(p$data$value)

  if (is_discrete) {
    # Standard categorical palette
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
#' Plots one landscape or arranges several landscape plots in a grid.
#'
#' @param landscapes A landscape object or a list of landscape objects, such as
#'     those returned by \code{\link{create_landscape}},
#'     \code{\link{create_landscapes}}, or \code{\link{landscape}}.
#' @param titles Character. One of "name", "pattern", "both", "none", a single
#'     custom title, or one custom title per landscape (default:
#'     "pattern"). A single custom title is repeated with a warning when several
#'     landscapes are plotted. With \code{subset_index}, a vector of custom
#'     titles must match the subset length.
#' @param show_legend Logical. Show one combined legend (default: TRUE).
#' @param legend_title Character. Legend title (default: "Value").
#' @param ncol Integer. Number of grid columns (default: NULL).
#' @param max_landscapes Positive integer. Maximum number of landscapes shown
#'     (default: 36). Use \code{Inf} to show all landscapes.
#' @param subset_index Integer vector. Indices of the \code{landscapes} to plot,
#'      in the requested order (default: NULL for plotting all landscapes).
#'
#' @return A patchwork object combining one or more landscape plots.
#' @details
#' Use \code{&} to add \pkg{ggplot2} elements to every panel, for example
#' \code{plot_landscapes(landscapes) & ggplot2::theme_dark()}. With multiple
#' landscapes, \code{+} modifies only the last panel.
#' @family visualization
#' @seealso \code{\link{create_landscape}}, \code{\link{create_landscapes}},
#'     \code{\link{landscape}}
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
  subset_index = NULL
) {
  # Normalize a single landscape to the list form used below
  if (is_landscape(landscapes)) {
    landscapes <- list(landscapes)
  }

  # Validate inputs
  if (!is.list(landscapes)) {
    cli::cli_abort(
      "landscapes must be a landscape object or a list of landscape objects"
    )
  }

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

  if (
    !is.numeric(max_landscapes) ||
      length(max_landscapes) != 1 ||
      is.na(max_landscapes) ||
      max_landscapes <= 0 ||
      (!is.infinite(max_landscapes) && max_landscapes != floor(max_landscapes))
  ) {
    cli::cli_abort(
      "{.arg max_landscapes} must be a positive integer or {.code Inf}"
    )
  }

  # Apply the subset before validating title count
  if (!is.null(subset_index)) {
    landscapes <- landscapes[subset_index]
  }

  # Check if enough titles are provided for the subset
  if (length(titles) > 1 && length(titles) != length(landscapes)) {
    cli::cli_abort(
      "If providing multiple titles, length must match number of landscapes ({length(landscapes)}). Got {length(titles)} titles instead."
    )
  }

  # Limit oversized grids
  if (length(landscapes) > max_landscapes) {
    cli::cli_warn(
      "Showing the first {max_landscapes} of {length(landscapes)} landscapes. Increase {.arg max_landscapes} to show more, or use {.arg subset_index} to select landscapes."
    )
    landscapes <- landscapes[1:max_landscapes]
  }

  # Resolve one title per landscape
  if (length(titles) == 1) {
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

  # Build the panels
  plot_list <- list()
  for (i in seq_along(landscapes)) {
    plot_list[[i]] <- plot_single_landscape(
      landscape = landscapes[[i]],
      title = titles[i],
      show_legend = show_legend,
      legend_title = legend_title
    )
  }

  # Combine panels and collect a shared legend when requested
  combined_plot <- patchwork::wrap_plots(plot_list, ncol = ncol)

  if (show_legend && length(landscapes) > 1) {
    combined_plot <- combined_plot +
      patchwork::plot_layout(guides = "collect")
  }

  return(combined_plot)
}
