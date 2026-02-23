#' Create a landscape with very dense vegetation
#'
#' Creates a landscape with dense vegetation cover using random distribution.
#' This is a specialized wrapper around \code{\link{create_landscape_random}}
#' with high vegetation proportions.
#'
#' @param veg_prop Numeric. Proportion of cells with vegetation (0-1). Default: 0.9.
#' @param width Integer. Width of landscape in cells. Default: 100.
#' @param height Integer. Height of landscape in cells. Default: 100.
#'
#' @return A landscape object with pattern "dense" containing
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "dense"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @family landscape creation
#' @examples
#' # Create default dense landscape (90% vegetation)
#' dense <- create_landscape_dense()
#'
#' # Create very dense landscape
#' very_dense <- create_landscape_dense(veg_prop = 0.95)
#' @export
create_landscape_dense <- function(
  veg_prop = 0.9,
  width = 100,
  height = 100
) {
  landscape <- create_landscape_random(
    veg_prop = veg_prop,
    width = width,
    height = height
  )

  landscape <- set_landscape_pattern(landscape, "dense")

  landscape
}
