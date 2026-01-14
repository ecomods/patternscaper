# Tests for stripes landscape pattern ---------------------------------------

# Validation tests ------------------------------------------------------------

# Note: create_landscape_stripes currently has no specific parameters beyond
# width and height, which are tested in test-landscape-creation-shared.R

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_stripes creates valid landscape object", {
  result <- create_landscape_stripes(width = 50, height = 50)

  expect_s3_class(result, "landscape")
  expect_equal(result$pattern, "stripes")
  expect_true(terra::is.raster(result$data))
})

test_that("create_landscape_stripes respects width and height", {
  result <- create_landscape_stripes(width = 30, height = 40)

  expect_equal(terra::ncol(result$data), 30)
  expect_equal(terra::nrow(result$data), 40)
})

test_that("create_landscape_stripes creates valid raster values", {
  result <- create_landscape_stripes(width = 50, height = 50)

  values <- terra::values(result$data)
  expect_true(all(values %in% c(0, 1)))
  expect_true(any(values == 0))
  expect_true(any(values == 1))
})

test_that("create_landscape_stripes stores parameters", {
  result <- create_landscape_stripes(width = 50, height = 50)

  expect_type(result$params, "list")
  expect_equal(result$params$width, 50)
  expect_equal(result$params$height, 50)
})

test_that("create_landscape_stripes is reproducible with set seed", {
  set.seed(123)
  result1 <- create_landscape_stripes(width = 50, height = 50)

  set.seed(123)
  result2 <- create_landscape_stripes(width = 50, height = 50)

  expect_equal(terra::values(result1$data), terra::values(result2$data))
})

test_that("create_landscape_stripes produces different patterns with different seeds", {
  set.seed(123)
  result1 <- create_landscape_stripes(width = 50, height = 50)

  set.seed(456)
  result2 <- create_landscape_stripes(width = 50, height = 50)

  expect_false(identical(terra::values(result1$data), terra::values(result2$data)))
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_stripes works with very small landscapes", {
  result <- create_landscape_stripes(width = 5, height = 5)

  expect_s3_class(result, "landscape")
  expect_equal(terra::ncol(result$data), 5)
  expect_equal(terra::nrow(result$data), 5)
})

test_that("create_landscape_stripes works with very large landscapes", {
  result <- create_landscape_stripes(width = 500, height = 500)

  expect_s3_class(result, "landscape")
  expect_equal(terra::ncol(result$data), 500)
  expect_equal(terra::nrow(result$data), 500)
})

test_that("create_landscape_stripes works with non-square landscapes", {
  result_wide <- create_landscape_stripes(width = 100, height = 50)
  expect_equal(terra::ncol(result_wide$data), 100)
  expect_equal(terra::nrow(result_wide$data), 50)

  result_tall <- create_landscape_stripes(width = 50, height = 100)
  expect_equal(terra::ncol(result_tall$data), 50)
  expect_equal(terra::nrow(result_tall$data), 100)
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_stripes works through create_landscape wrapper", {
  result <- create_landscape("stripes", width = 50, height = 50)

  expect_s3_class(result, "landscape")
  expect_equal(result$pattern, "stripes")
})
