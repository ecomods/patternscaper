# Test print.landscape ---------------------------------------------------------

test_that("print.landscape displays basic information correctly", {
  # Create a basic landscape
  l <- create_test_landscape(
    type = "uniform",
    n = 5,
    class = "test",
    name = "example"
  )

  # Capture the output
  output <- capture_output(print(l))

  # Check that essential information is present
  expect_match(output, 'Landscape: "example"')
  expect_match(output, 'class: test')
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

test_that("print.landscape handles missing name and class", {
  # Create landscape with missing metadata
  l <- create_test_landscape(type = "uniform", n = 5)

  # Capture output
  output <- capture_output(print(l))

  # Check fallback text
  expect_match(output, "Landscape: unnamed")
  expect_match(output, "unclassified")
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
