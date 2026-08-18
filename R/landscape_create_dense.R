#' Create Dense Random Vegetation
#'
#' Uses the \code{\link{create_landscape_random}} and assigns the \code{"dense"} pattern label.
#'
#' Parameters are documented on \code{\link{pattern_dense}}.
#'
#' @return A landscape object with pattern \code{"dense"}.
#'
#' @noRd
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
