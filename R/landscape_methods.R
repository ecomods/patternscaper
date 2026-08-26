#' Print a Landscape Object
#'
#' Prints the landscape's name, pattern, dimensions, spatial properties, value
#' range, missing-value count, and generation parameters. Missing name and
#' pattern metadata are displayed as \code{<unnamed>} and
#' \code{<unknown pattern>}; the stored values remain \code{NA}.
#'
#' @param x A landscape object created by \code{\link{landscape}}.
#' @param ... Unused.
#'
#' @return The input landscape object \code{x}, returned invisibly.
#'
#' @examples
#' # Create a landscape (0 = bare ground, 1 = vegetation)
#' mat <- matrix(rbinom(100, 1, 0.5), 10, 10)
#' l <- landscape(mat, pattern = "random", name = "example")
#'
#' # Print it (calls print.landscape automatically)
#' l
#'
#' # Or explicitly
#' print(l)
#'
#' @family landscape objects
#' @importFrom terra res ext values
#' @export
print.landscape <- function(x, ...) {
  # Display labels
  name_str <- if (is.na(x$name)) "<unnamed>" else paste0('"', x$name, '"')
  pattern_str <- if (is.na(x$pattern)) {
    "<unknown pattern>"
  } else {
    x$pattern
  }

  cat("Landscape: ", name_str, " [pattern: ", pattern_str, "]\n", sep = "")
  cat("-----------------------------------------\n")

  # Raster summary
  dims <- dim(x$data)
  res <- terra::res(x$data)
  ext <- terra::ext(x$data)
  vals <- terra::values(x$data)

  # Print dimensions and spatial properties
  cat(sprintf(
    "Dimensions: %dx%d (%d cells)\n",
    dims[1],
    dims[2],
    dims[1] * dims[2]
  ))
  cat(sprintf("Resolution: %.1fx%.1f\n", res[1], res[2]))
  cat(sprintf(
    "Extent    : xmin=%.1f, xmax=%.1f, ymin=%.1f, ymax=%.1f\n",
    ext[1],
    ext[2],
    ext[3],
    ext[4]
  ))

  # Print value range and NA count
  na_count <- sum(is.na(vals))
  cat(sprintf(
    "Values    : min=%.1f, max=%.1f",
    min(vals, na.rm = TRUE),
    max(vals, na.rm = TRUE)
  ))
  if (na_count > 0) {
    cat(sprintf(" (NA=%d)", na_count))
  }
  cat("\n")

  # Generation parameters
  if (!is.null(x$params) && length(x$params) > 0) {
    params_str <- paste(names(x$params), "=", x$params, collapse = ", ")
    cat("Parameters:", params_str, "\n")
  } else {
    cat("Parameters: none\n")
  }

  invisible(x)
}

#' Plot a Landscape Object
#'
#' Plots a landscape object as a ggplot2.
#'
#' @param x A landscape object created by \code{\link{landscape}}.
#' @param ... Must be empty.
#'
#' @return A ggplot2 object.
#'
#' @details
#' Add ggplot2 layers directly to the result, or use
#' \code{\link{plot_landscapes}} for titles, legends, and multi-panel layouts.
#'
#' @examples
#' # Create a landscape (0 = bare ground, 1 = vegetation)
#' mat <- matrix(rbinom(100, 1, 0.5), 10, 10)
#' l <- landscape(mat, pattern = "random", name = "example")
#'
#' # Get basic plot
#' p <- plot(l)
#'
#' # Add your own customization
#' p + ggplot2::ggtitle("My custom title") +
#'     ggplot2::theme_dark()
#'
#' @family landscape objects
#' @importFrom terra as.data.frame
#' @importFrom ggplot2 ggplot aes geom_raster coord_equal theme_minimal element_blank
#' @export
plot.landscape <- function(x, ...) {
  if (!is_landscape(x)) {
    cli::cli_abort("'x' must be a landscape object")
  }

  # Convert raster cells to plotting data
  df <- terra::as.data.frame(x$data, xy = TRUE)
  names(df)[3] <- "value" # Rename the value column

  # Treat small integer sets as categorical
  unique_values <- unique(df$value[!is.na(df$value)])
  is_discrete <- length(unique_values) < 10 &&
    all(unique_values == round(unique_values))

  if (is_discrete) {
    # Keep factor levels in numeric order
    df$value <- factor(df$value, levels = sort(unique_values))
  }

  # Base plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = y, fill = value)) +
    ggplot2::geom_raster() +
    ggplot2::coord_equal(expand = FALSE) +
    theme_landscape()

  return(p)
}
