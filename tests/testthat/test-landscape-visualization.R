test_that("plot_landscape validates input", {
  # Not a landscape object
  expect_error(
    plot_landscape(matrix(1:9, 3, 3)),
    "'landscape' must be a landscape object"
  )
})

test_that("plot_landscape creates correct title", {
  l <- create_landscape("sharp", width = 10, height = 10)

  # Test different title options
  p1 <- plot_landscape(l, title = "name")
  expect_equal(p1$labels$title, "Unnamed landscape")

  p2 <- plot_landscape(l, title = "class")
  expect_equal(p2$labels$title, "sharp")

  p3 <- plot_landscape(l, title = "both")
  expect_equal(p3$labels$title, "Unnamed landscape (sharp)")

  p4 <- plot_landscape(l, title = "Custom Title")
  expect_equal(p4$labels$title, "Custom Title")

  # Test with named landscape
  l$name <- "Test Landscape"
  p5 <- plot_landscape(l, title = "both")
  expect_equal(p5$labels$title, "Test Landscape (sharp)")
})

test_that("plot_landscape handles legend options", {
  l <- create_landscape("sharp", width = 10, height = 10)

  # Test legend visibility
  p1 <- plot_landscape(l, show_legend = FALSE)
  expect_equal(p1$theme$legend.position, "none")

  p2 <- plot_landscape(l, show_legend = TRUE)
  expect_equal(p2$theme$legend.position, "right")

  # Test legend title
  p3 <- plot_landscape(l, legend_title = "Custom Legend")
  expect_equal(p3$labels$fill, "Custom Legend")
})

test_that("plot_landscape uses correct color scales", {
  # For discrete data (e.g., binary landscape)
  l_discrete <- create_landscape("sharp", width = 10, height = 10)
  p1 <- plot_landscape(l_discrete)

  # Get the fill scale
  fill_scale <- p1$scales$get_scales("fill")
  expect_true(inherits(fill_scale, "ScaleDiscrete"))

  # Check legend title
  expect_equal(fill_scale$name, "Value")
})

test_that("plot_landscape returns a ggplot object", {
  l <- create_landscape("sharp", width = 10, height = 10)
  p <- plot_landscape(l)

  expect_s3_class(p, "ggplot")
})

test_that("plot_landscape preserves landscape dimensions", {
  l <- create_landscape("sharp", width = 15, height = 10)
  p <- plot_landscape(l)

  # Extract data from plot
  plot_data <- ggplot2::layer_data(p, 1)

  # Check unique x and y coordinates match original dimensions
  expect_equal(length(unique(plot_data$x)), 15) # width
  expect_equal(length(unique(plot_data$y)), 10) # height
})
