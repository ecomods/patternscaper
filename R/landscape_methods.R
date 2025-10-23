#' Print a landscape object
#'
#' Provides a concise summary of a landscape object, including its name,
#' class, dimensions, spatial properties, value range, and parameters.
#'
#' @param x A landscape object created by \code{\link{landscape}}.
#' @param ... Additional arguments (currently unused).
#'
#' @return The input landscape object \code{x}, returned invisibly.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Landscape name and class
#'   \item Dimensions (rows × columns and total cells)
#'   \item Resolution and spatial extent
#'   \item Value range (min/max) and count of NA values
#'   \item Parameters used to create the landscape (if available)
#' }
#'
#' @examples
#' # Create a landscape
#' mat <- matrix(1:100, 10, 10)
#' l <- landscape(mat, class = "test", name = "example")
#'
#' # Print it (calls print.landscape automatically)
#' l
#'
#' # Or explicitly
#' print(l)
#'
#' @importFrom terra dim res ext values
#' @export
print.landscape <- function(x, ...) {
  # Get basic properties of the landscape
  name_str <- if (is.na(x$name)) "unnamed" else paste0('"', x$name, '"')
  class_str <- if (is.na(x$class)) {
    "unclassified"
  } else {
    paste0("class: ", x$class)
  }

  # Print header
  cat("Landscape:", name_str, "[", class_str, "]\n")
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
#' @param x Landscape object
#' @param ... Additional arguments passed to plotting functions
#' @return Invisibly returns the input object
#' @export
plot.landscape <- function(x, ...) {
  # Extract raster data from landscape object
  # Set up plotting parameters (colors, legend, title)
  # Create plot using terra::plot or similar function
  # Return x invisibly
}
