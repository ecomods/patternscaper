#' Create a Dense Landscape
#'
#' Creates a landscape with dense tree coverage using random distribution.
#' This is a specialized wrapper around \code{\link{create_landscape_random}}
#' with high tree proportions.
#'
#' @param tree_prop Numeric. Proportion of cells with trees (0-1). Default: 0.9.
#' @param width Integer. Width of landscape in cells. Default: 100.
#' @param height Integer. Height of landscape in cells. Default: 100.
#'
#' @return A landscape object with pattern "dense".
#'
#' @seealso \code{\link{create_landscape_random}}, \code{\link{create_landscape_bare}}
#'
#' @examples
#' # Create default dense landscape (90% trees)
#' dense <- create_landscape_dense()
#'
#' # Create very dense landscape
#' very_dense <- create_landscape_dense(tree_prop = 0.95)
#' @export
create_landscape_dense <- function(
  tree_prop = 0.9,
  width = 100,
  height = 100
) {
  landscape <- create_landscape_random(
    tree_prop = tree_prop,
    width = width,
    height = height
  )

  landscape <- set_landscape_pattern(landscape, "dense")

  landscape
}
