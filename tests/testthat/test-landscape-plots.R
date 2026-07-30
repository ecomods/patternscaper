test_that("plot_landscapes validates a single landscape input", {
  # Not a landscape object
  expect_error(
    plot_landscapes(matrix(1:9, 3, 3)),
    "landscapes must be a landscape object or a list of landscape objects"
  )
})

test_that("plot_landscapes creates correct title for a single landscape", {
  l <- create_landscape("sharp", width = 10, height = 10)

  # Test different title options
  p1 <- plot_landscapes(l, titles = "name")
  expect_equal(p1$labels$title, "Unnamed landscape")

  p2 <- plot_landscapes(l, titles = "pattern")
  expect_equal(p2$labels$title, "sharp")

  p3 <- plot_landscapes(l, titles = "both")
  expect_equal(p3$labels$title, "Unnamed landscape (sharp)")

  p4 <- plot_landscapes(l, titles = "Custom Title")
  expect_equal(p4$labels$title, "Custom Title")

  # Test with named landscape
  l$name <- "Test Landscape"
  p5 <- plot_landscapes(l, titles = "both")
  expect_equal(p5$labels$title, "Test Landscape (sharp)")
})

test_that("plot_landscapes handles legend options for a single landscape", {
  l <- create_landscape("sharp", width = 10, height = 10)

  # Test legend visibility
  p1 <- plot_landscapes(l, show_legend = FALSE)
  expect_equal(p1$theme$legend.position, "none")

  p2 <- plot_landscapes(l, show_legend = TRUE)
  expect_equal(p2$theme$legend.position, "right")

  # Test legend title
  p3 <- plot_landscapes(l, legend_title = "Custom Legend")
  expect_equal(p3$labels$fill, "Custom Legend")
})

test_that("plot_landscapes uses correct color scales for a single landscape", {
  # For discrete data (e.g., binary landscape)
  l_discrete <- create_landscape("sharp", width = 10, height = 10)
  p1 <- plot_landscapes(l_discrete)

  # Get the fill scale
  fill_scale <- p1$scales$get_scales("fill")
  expect_true(inherits(fill_scale, "ScaleDiscrete"))

  # Check legend title
  expect_equal(fill_scale$name, "Value")
})

test_that("plot_landscapes returns a patchwork object for a single landscape", {
  l <- create_landscape("sharp", width = 10, height = 10)
  p <- plot_landscapes(l)

  expect_s3_class(p, "patchwork")
  # patchwork objects inherit from ggplot, so single-landscape plots can
  # still be extended like a regular ggplot object
  expect_s3_class(p, "ggplot")
})

test_that("& applies ggplot2 elements to every panel, unlike +", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10)
  )
  p <- plot_landscapes(landscapes)

  # `+` on a multi-panel patchwork only modifies the last panel
  p_plus <- p + ggplot2::theme_dark()
  expect_false(identical(
    p_plus$patches$plots[[1]]$theme$panel.background,
    ggplot2::theme_dark()$panel.background
  ))
  expect_identical(
    p_plus$theme$panel.background,
    ggplot2::theme_dark()$panel.background
  )

  # `&` applies to every panel
  p_and <- p & ggplot2::theme_dark()
  expect_identical(
    p_and$patches$plots[[1]]$theme$panel.background,
    ggplot2::theme_dark()$panel.background
  )
  expect_identical(
    p_and$theme$panel.background,
    ggplot2::theme_dark()$panel.background
  )
})

test_that("plot_landscapes preserves landscape dimensions for a single landscape", {
  l <- create_landscape("sharp", width = 15, height = 10)
  p <- plot_landscapes(l)

  # Extract data from plot
  plot_data <- ggplot2::layer_data(p, 1)

  # Check unique x and y coordinates match original dimensions
  expect_equal(length(unique(plot_data$x)), 15) # width
  expect_equal(length(unique(plot_data$y)), 10) # height
})

# Test plot_landscapes with multiple landscapes --------------------------

test_that("plot_landscapes validates list input", {
  # Empty list
  expect_error(
    plot_landscapes(list()),
    "landscapes must contain at least one landscape"
  )

  # Not a list
  expect_error(
    plot_landscapes(matrix(1:9, 3, 3)),
    "landscapes must be a landscape object or a list of landscape objects"
  )

  # List with non-landscape objects
  bad_list <- list(matrix(1:9, 3, 3), matrix(1:9, 3, 3))
  expect_error(
    plot_landscapes(bad_list),
    "All elements must be landscape objects"
  )
})

test_that("plot_landscapes handles titles correctly", {
  # Create test landscapes
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10)
  )

  # Test that we get a valid patchwork with 2 patches
  p1 <- plot_landscapes(landscapes, titles = "pattern")
  expect_true(grepl("2 patches", capture_output(str(p1))))

  # Test title length validation
  expect_error(
    plot_landscapes(landscapes, titles = c("One", "Two", "Three")),
    "length must match number of landscapes"
  )
})

test_that("plot_landscapes respects max_landscapes", {
  # Create many landscapes
  landscapes <- replicate(
    10,
    create_landscape("sharp", width = 10, height = 10),
    simplify = FALSE
  )

  # Test max_landscapes warning and output
  expect_warning(
    p <- plot_landscapes(landscapes, max_landscapes = 5),
    "Number of landscapes .* exceeds maximum"
  )
  expect_true(grepl("5 patches", capture_output(str(p))))

  # Test force override
  p2 <- plot_landscapes(landscapes, max_landscapes = 5, force = TRUE)
  expect_true(grepl("10 patches", capture_output(str(p2))))
})

test_that("plot_landscapes handles subset_index", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10),
    create_landscape("diffuse", width = 10, height = 10)
  )

  # Test subsetting produces correct number of patches
  p <- plot_landscapes(landscapes, subset_index = c(1, 3))
  expect_true(grepl("2 patches", capture_output(str(p))))
})

test_that("plot_landscapes returns patchwork object", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10)
  )

  p <- plot_landscapes(landscapes)
  expect_s3_class(p, "patchwork")
})

test_that("plot_landscapes respects ncol parameter", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10),
    create_landscape("diffuse", width = 10, height = 10)
  )

  p <- plot_landscapes(landscapes, ncol = 2)
  expect_equal(p$patches$layout$ncol, 2)
})
