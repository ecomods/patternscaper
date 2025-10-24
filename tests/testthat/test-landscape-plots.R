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

  p2 <- plot_landscape(l, title = "pattern")
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

# Test plot_landscape_list function --------------------------------------------

test_that("plot_landscape_list validates input", {
  # Empty list
  expect_error(
    plot_landscape_list(list()),
    "landscapes must contain at least one landscape"
  )

  # Not a list
  expect_error(
    plot_landscape_list(matrix(1:9, 3, 3)),
    "landscapes must be a list"
  )

  # List with non-landscape objects
  bad_list <- list(matrix(1:9, 3, 3), matrix(1:9, 3, 3))
  expect_error(
    plot_landscape_list(bad_list),
    "All elements must be landscape objects"
  )
})

test_that("plot_landscape_list handles titles correctly", {
  # Create test landscapes
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10)
  )

  # Test that we get a valid patchwork with 2 patches
  p1 <- plot_landscape_list(landscapes, titles = "pattern")
  expect_true(grepl("2 patches", capture_output(str(p1))))

  # Test title length validation
  expect_error(
    plot_landscape_list(landscapes, titles = c("One", "Two", "Three")),
    "length must match number of landscapes"
  )
})

test_that("plot_landscape_list respects max_landscapes", {
  # Create many landscapes
  landscapes <- replicate(
    10,
    create_landscape("sharp", width = 10, height = 10),
    simplify = FALSE
  )

  # Test max_landscapes warning and output
  expect_warning(
    p <- plot_landscape_list(landscapes, max_landscapes = 5),
    "Number of landscapes .* exceeds maximum"
  )
  expect_true(grepl("5 patches", capture_output(str(p))))

  # Test force override
  p2 <- plot_landscape_list(landscapes, max_landscapes = 5, force = TRUE)
  expect_true(grepl("10 patches", capture_output(str(p2))))
})

test_that("plot_landscape_list handles subset_index", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10),
    create_landscape("diffuse", width = 10, height = 10)
  )

  # Test subsetting produces correct number of patches
  p <- plot_landscape_list(landscapes, subset_index = c(1, 3))
  expect_true(grepl("2 patches", capture_output(str(p))))
})

test_that("plot_landscape_list returns patchwork object", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10)
  )

  p <- plot_landscape_list(landscapes)
  expect_s3_class(p, "patchwork")
})

test_that("plot_landscape_list respects ncol parameter", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10),
    create_landscape("diffuse", width = 10, height = 10),
    create_landscape("curvy", width = 10, height = 10)
  )

  p <- plot_landscape_list(landscapes, ncol = 2)
  expect_equal(p$patches$layout$ncol, 2)
})
