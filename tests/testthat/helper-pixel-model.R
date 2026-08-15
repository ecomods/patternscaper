helper_pixel_stub_model <- function(
  height = 10,
  width = 10,
  land_cover_values = c(0, 1)
) {
  list(
    model = NULL,
    classes = c("a", "b"),
    input_shape = c(height, width, length(land_cover_values)),
    land_cover_values = land_cover_values
  )
}
