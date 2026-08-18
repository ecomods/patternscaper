#' Create Randomly Distributed Vegetation
#'
#' Parameters are documented on \code{\link{pattern_random}}.
#'
#' @return A landscape object with pattern \code{"random"}.
#'
#' @noRd
#' @importFrom stats rbinom
create_landscape_random <- function(
  width = 100,
  height = 100,
  veg_prob = 0.5
) {
  # Validate inputs.
  validate_dimensions(width = width, height = height)

  if (!is.numeric(veg_prob) || veg_prob < 0 || veg_prob > 1) {
    cli::cli_abort(c(
      "{.arg veg_prob} must be between 0 and 1.",
      "x" = "You supplied {.val {veg_prob}}"
    ))
  }

  # Get landscape with random distribution of vegetation
  mat <- matrix(
    stats::rbinom(width * height, size = 1, prob = veg_prob),
    nrow = height,
    ncol = width
  )

  # Store the raster and its generation metadata.
  landscape(
    data = mat,
    pattern = "random",
    params = list(
      width = width,
      height = height,
      veg_prob = veg_prob
    )
  )
}
