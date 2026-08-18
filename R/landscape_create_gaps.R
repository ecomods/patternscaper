#' Create Circular Bare Gaps
#'
#' Reuses the spots algorithm with inverted cell values and gap-specific names.
#'
#' Parameters are documented on \code{\link{pattern_gaps}}.
#'
#' @return A landscape object with pattern "gaps".
#'
#' @noRd
create_landscape_gaps <- function(
  width = 100,
  height = 100,
  n_gaps = 5,
  gap_radius = 10,
  gap_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_gaps = FALSE
) {
  # Call create_landscape_spots with invert_landscape = TRUE. The shared
  # implementation speaks in spots, so the gap names are translated here
  result <- create_landscape_spots(
    width = width,
    height = height,
    n_spots = n_gaps,
    spot_radius = gap_radius,
    spot_radius_sd = gap_radius_sd,
    radius_noise_fraction = radius_noise_fraction,
    invert_landscape = TRUE,
    regular_spots = regular_gaps
  )

  # Apply the gaps label
  result$pattern <- "gaps"

  # Report parameter names in gap terminology
  gap_names <- c(
    n_spots = "n_gaps",
    spot_radius = "gap_radius",
    spot_radius_sd = "gap_radius_sd",
    regular_spots = "regular_gaps"
  )
  renamed <- names(result$params) %in% names(gap_names)
  names(result$params)[renamed] <- gap_names[names(result$params)[renamed]]

  return(result)
}
