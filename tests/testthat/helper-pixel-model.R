helper_pixel_stub_model <- function(
  height = 10,
  width = 10,
  habitat_values = c(0, 1)
) {
  list(
    model = NULL,
    classes = c("a", "b"),
    input_shape = c(height, width, length(habitat_values)),
    habitat_values = habitat_values
  )
}
