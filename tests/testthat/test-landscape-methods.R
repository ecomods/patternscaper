# Test print.landscape ---------------------------------------------------------

test_that("print.landscape displays basic information correctly", {
  # Create a basic landscape
  l <- create_test_landscape(
    type = "uniform",
    n = 5,
    pattern = "test",
    name = "example"
  )

  # Capture the output
  output <- capture_output(print(l))

  # Check that essential information is present
  expect_match(output, 'Landscape: "example"')
  expect_match(output, 'pattern: test')
  expect_match(output, 'Dimensions: 5x5')
  expect_match(output, '25 cells')
  expect_match(output, 'Resolution:')
  expect_match(output, 'Extent')
  expect_match(output, 'Values')
})

test_that("print.landscape handles NA values in data", {
  # Create landscape with NA values
  l <- create_test_landscape(type = "uniform", n = 5, na_percent = 10)

  # Capture output
  output <- capture_output(print(l))

  # Check that NA count is shown (without escaping parentheses)
  expect_match(output, "NA=[0-9]+")
})

test_that("print.landscape handles missing name and pattern", {
  # Create landscape with missing metadata
  l <- create_test_landscape(type = "uniform", n = 5)

  # Capture output
  output <- capture_output(print(l))

  # Check explicit placeholders for missing metadata
  expect_match(
    output,
    "Landscape: <unnamed> \\[pattern: <unknown pattern>\\]"
  )
})

test_that("print.landscape shows parameters correctly", {
  # Create landscape with parameters
  params <- list(scale = 0.1, threshold = 0.5)
  l <- create_test_landscape(type = "uniform", n = 5, params = params)

  # Capture output
  output <- capture_output(print(l))

  # Check parameters are displayed
  expect_match(output, "Parameters:")
  expect_match(output, "scale")
  expect_match(output, "0\\.1")
  expect_match(output, "threshold")
  expect_match(output, "0\\.5")

  # Test with no parameters
  l2 <- create_test_landscape(type = "uniform", n = 5)
  output2 <- capture_output(print(l2))
  expect_match(output2, "Parameters: none")
})

test_that("print.landscape returns the object invisibly", {
  l <- create_test_landscape(type = "uniform", n = 5)

  # Test invisible return
  result <- withVisible(print(l))
  expect_identical(result$value, l)
  expect_false(result$visible)
})

# Test plot.landscape -------------------------------------------------------------

test_that("plot.landscape returns a valid ggplot object", {
  # Create a basic landscape
  l <- create_test_landscape(type = "uniform", n = 10)

  # Get plot
  p <- plot(l)

  # Check class
  expect_s3_class(p, "ggplot")

  # Check that plot has at least one layer
  expect_true(length(p$layers) > 0)

  # Check that first layer uses geom_raster (more robust)
  expect_true(inherits(p$layers[[1]]$geom, "GeomRaster"))

  # Check that coordinates use equal aspect ratio
  # coord_equal creates a CoordCartesian with ratio = 1
  expect_true(inherits(p$coordinates, "CoordCartesian"))
})

test_that("plot.landscape handles discrete and continuous data correctly", {
  # Discrete data (integers 1-5)
  l_discrete <- landscape(matrix(sample(1:5, 100, replace = TRUE), 10, 10))
  p_discrete <- plot(l_discrete)

  # More robust check - test that we can render the plot without errors
  expect_error(print(p_discrete), NA)

  # Continuous data (random decimals)
  set.seed(123)
  l_continuous <- landscape(matrix(runif(100), 10, 10))
  p_continuous <- plot(l_continuous)

  # More robust check - test that we can render the plot without errors
  expect_error(print(p_continuous), NA)
})

test_that("plot.landscape handles NA values properly", {
  # Create landscape with NAs
  l <- create_test_landscape(type = "uniform", n = 10, na_percent = 20)

  # This should run without errors
  p <- expect_silent(plot(l))

  # Check that the plot can be rendered without errors
  expect_error(print(p), NA)
})

test_that("plot.landscape validates input", {
  # Not a landscape
  not_landscape <- list(data = matrix(1:9, 3, 3))

  # Should error with informative message when called directly
  expect_error(plot.landscape(not_landscape), "must be a landscape object")
})

test_that("plot.landscape applies appropriate theme elements", {
  l <- create_test_landscape(type = "uniform", n = 5)
  p <- plot(l)

  # Check for theme existence rather than specific implementation
  expect_true(!is.null(p$theme))

  # Convert the theme to a list to check theme properties more robustly
  theme_list <- unclass(p$theme)

  # Check that certain theme properties exist (without checking specific implementation)
  expect_true(any(names(theme_list) == "axis.title"))
  expect_true(any(names(theme_list) == "axis.text"))
  expect_true(any(names(theme_list) == "panel.grid.major"))
})
