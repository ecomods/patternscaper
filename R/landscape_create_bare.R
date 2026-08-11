#' Create a bare landscape with very sparse vegetation
#'
#' Creates a landscape with sparse vegetation cover using random distribution.
#' This is a specialized wrapper around \code{\link{create_landscape_random}}
#' with low vegetation proportions.
#'
#' Parameters are documented on \code{\link{pattern_bare}}.
#'
#' @return A landscape object with pattern "bare" containing.
#'   \item{data}{SpatRaster with binary values (0 = bare ground, 1 = vegetation)}
#'   \item{pattern}{Character string "bare"}
#'   \item{params}{List of all input parameters used to generate the landscape}
#'
#' @noRd
#' @examples
#' \dontrun{
#' # Create default bare landscape (10% vegetation)
#' bare <- create_landscape_bare()
#'
#' # Create very sparse landscape
#' very_bare <- create_landscape_bare(veg_prob = 0.05)
#' }
create_landscape_bare <- function(
  veg_prob = 0.1,
  width = 100,
  height = 100
) {
  landscape <- create_landscape_random(
    veg_prob = veg_prob,
    width = width,
    height = height
  )

  landscape <- set_landscape_pattern(landscape, "bare")

  landscape
}
