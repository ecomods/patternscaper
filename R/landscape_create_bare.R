#' Create Sparse Random Vegetation
#'
#' Uses the \code{\link{create_landscape_random}} and assigns the \code{"bare"} pattern label.
#'
#' Parameters are documented on \code{\link{pattern_bare}}.
#'
#' @return A landscape object with pattern \code{"bare"}.
#'
#' @noRd
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
