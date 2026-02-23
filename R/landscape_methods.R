#' Print a landscape object
#'
#' Provides a concise summary of a landscape object, including its name,
#' pattern, dimensions, spatial properties, value range, and parameters.
#'
#' @param x A landscape object created by \code{\link{landscape}}.
#' @param ... Additional arguments (currently unused).
#'
#' @return The input landscape object \code{x}, returned invisibly.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Landscape name and pattern
#'   \item Dimensions (rows × columns and total cells)
#'   \item Resolution and spatial extent
#'   \item Value range (min/max) and count of NA values
#'   \item Parameters used to create the landscape (if available)
#' }
#'
#' @examples
#' # Create a landscape
#' mat <- matrix(1:100, 10, 10)
#' l <- landscape(mat, pattern = "test", name = "example")
#'
#' # Print it (calls print.landscape automatically)
#' l
#'
#' # Or explicitly
#' print(l)
#'
#' @importFrom terra res ext values
#' @export
print.landscape <- function(x, ...) {
  # Get basic properties of the landscape
  name_str <- if (is.na(x$name)) "unnamed" else paste0('"', x$name, '"')
  pattern_str <- if (is.na(x$pattern)) {
    "unclassified"
  } else {
    paste0("pattern: ", x$pattern)
  }

  # Print header
  cat("Landscape:", name_str, "[", pattern_str, "]\n")
  cat("-----------------------------------------\n")

  # Extract raster information
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

  # Print parameters if available
  if (!is.null(x$params) && length(x$params) > 0) {
    # Format parameters as a compact string
    params_str <- paste(names(x$params), "=", x$params, collapse = ", ")
    cat("Parameters:", params_str, "\n")
  } else {
    cat("Parameters: none\n")
  }

  # Return object invisibly
  invisible(x)
}

#' Plot method for landscape objects
#'
#' Creates a basic ggplot2 visualization of a landscape object.
#'
#' @param x A landscape object created by \code{\link{landscape}}.
#' @param ... Additional arguments passed to ggplot2 functions.
#'
#' @return A ggplot2 object representing the landscape data.
#'
#' @details
#' This function creates a minimal ggplot2 visualization of the landscape raster data.
#' The returned plot can be further customized by adding ggplot2 elements or by using
#' the \code{\link{plot_landscape}} function for higher-level customization.
#'
#' @examples
#' # Create a landscape
#' mat <- matrix(1:100, 10, 10)
#' l <- landscape(mat, pattern = "test", name = "example")
#'
#' # Get basic plot
#' p <- plot(l)
#'
#' # Add your own customization
#' p + ggplot2::ggtitle("My custom title") +
#'     ggplot2::theme_dark()
#'
#' @importFrom terra as.data.frame
#' @importFrom ggplot2 ggplot aes geom_raster coord_equal theme_minimal element_blank
#' @export
plot.landscape <- function(x, ...) {
  # Validate input
  if (!is_landscape(x)) {
    cli::cli_abort("'x' must be a landscape object")
  }

  # Convert raster to data frame for plotting
  df <- terra::as.data.frame(x$data, xy = TRUE)
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

  # Create base plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = y, fill = value)) +
    ggplot2::geom_raster() +
    ggplot2::coord_equal(expand = FALSE) +
    theme_landscape()

  # Return the ggplot object
  return(p)
}
