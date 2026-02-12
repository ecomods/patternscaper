#' Create a Bare Landscape
#'
#' Creates a landscape with sparse tree coverage using random distribution.
#' This is a specialized wrapper around \code{\link{create_landscape_random}}
#' with low tree proportions.
#'
#' @param tree_prop Numeric. Proportion of cells with trees (0-1). Default: 0.1.
#' @param width Integer. Width of landscape in cells. Default: 100.
#' @param height Integer. Height of landscape in cells. Default: 100.
#'
#' @return A landscape object with pattern "bare" containing.
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "bare"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#' @seealso \code{\link{create_landscape_random}}, \code{\link{create_landscape_dense}}
#'
#' @examples
#' # Create default bare landscape (10% trees)
#' bare <- create_landscape_bare()
#'
#' # Create very sparse landscape
#' very_bare <- create_landscape_bare(tree_prop = 0.05)
create_landscape_bare <- function(
  tree_prop = 0.1,
  width = 100,
  height = 100
) {
  landscape <- create_landscape_random(
    tree_prop = tree_prop,
    width = width,
    height = height
  )

  landscape <- set_landscape_pattern(landscape, "bare")

  landscape
}
