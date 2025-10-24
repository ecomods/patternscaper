test_that("new_landscape constructor works with valid input", {
  # Setup
  rast_data <- terra::rast(create_uniform_matrix(5))

  # Test basic creation
  l <- new_landscape(rast_data)
  expect_s3_class(l, "landscape")
  expect_identical(l$data, rast_data)
  expect_true(is.na(l$pattern))
  expect_true(is.na(l$name))
  expect_null(l$params)

  # Test with all parameters
  params <- list(value1 = 10, value2 = "test")
  l2 <- new_landscape(
    rast_data,
    pattern = "spots",
    name = "test_landscape",
    params = params
  )
  expect_equal(l2$pattern, "spots")
  expect_equal(l2$name, "test_landscape")
  expect_equal(l2$params, params)
})

test_that("new_landscape constructor validates input", {
  # Should error with non-SpatRaster
  mat <- create_uniform_matrix(5)
  expect_error(new_landscape(mat), "SpatRaster")
})

test_that("landscape function works with matrix input", {
  mat <- create_gradient_matrix(5)
  l <- landscape(mat, pattern = "spots", name = "test")

  expect_s3_class(l, "landscape")
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$pattern, "spots")
  expect_equal(l$name, "test")
})

test_that("landscape function works with SpatRaster input", {
  rast_data <- terra::rast(create_uniform_matrix(5))
  l <- landscape(rast_data)

  expect_s3_class(l, "landscape")
  expect_identical(l$data, rast_data)
})

test_that("landscape function works with different matrix types", {
  # Test uniform matrix
  l_uniform <- create_test_landscape(type = "uniform", n = 10, pattern = "test")
  expect_s3_class(l_uniform, "landscape")
  expect_equal(l_uniform$pattern, "test")

  # Test gradient matrix
  l_gradient <- create_test_landscape(type = "gradient", n = 10)
  expect_s3_class(l_gradient, "landscape")

  # Test random matrix
  l_random <- create_test_landscape(type = "random", n = 10)
  expect_s3_class(l_random, "landscape")
})

test_that("landscape function handles matrices with NAs", {
  # Test with 10% NAs
  l_na <- create_test_landscape(type = "uniform", n = 10, na_percent = 10)
  expect_s3_class(l_na, "landscape")

  # Check that NAs are present in the data
  mat_values <- terra::values(l_na$data)
  expect_true(any(is.na(mat_values)))
})

test_that("landscape function validates parameters", {
  mat <- create_uniform_matrix(5)

  # Test invalid data type
  expect_error(landscape(list()), "'data' must be")

  # Test invalid pattern
  expect_error(landscape(mat, pattern = 123), "'pattern' must be")

  # Test invalid name
  expect_error(landscape(mat, name = 123), "'name' must be")

  # Test invalid params
  expect_error(landscape(mat, params = "not a list"), "'params' must be")
})

test_that("landscape function stores params correctly", {
  mat <- create_random_matrix(5)
  params <- list(scale = 0.1, threshold = 0.5, pattern = "spots")

  l <- landscape(mat, params = params)
  expect_equal(l$params, params)
})

test_that("is_landscape correctly identifies landscape objects", {
  # Create test objects using fixtures
  l <- create_test_landscape(type = "uniform", n = 5)
  not_l <- list(data = terra::rast(create_uniform_matrix(5)))

  # Test identification
  expect_true(is_landscape(l))
  expect_false(is_landscape(not_l))
  expect_false(is_landscape(NULL))
  expect_false(is_landscape(create_uniform_matrix(5)))
})
