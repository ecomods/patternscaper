#' Create a landscape with very dense vegetation
#'
#' Creates a landscape with dense vegetation cover using random distribution.
#' This is a specialized wrapper around \code{\link{create_landscape_random}}
#' with high vegetation proportions.
#'
#' Parameters are documented on \code{\link{pattern_dense}}.
#'
#' @return A landscape object with pattern "dense" containing
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "dense"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @noRd
#' @examples
#' \dontrun{
#' # Create default dense landscape (90% vegetation)
#' dense <- create_landscape_dense()
#'
#' # Create very dense landscape
#' very_dense <- create_landscape_dense(veg_prob = 0.95)
#' }
create_landscape_dense <- function(
  veg_prob = 0.9,
  width = 100,
  height = 100
) {
  landscape <- create_landscape_random(
    veg_prob = veg_prob,
    width = width,
    height = height
  )

  landscape <- set_landscape_pattern(landscape, "dense")

  landscape
}
