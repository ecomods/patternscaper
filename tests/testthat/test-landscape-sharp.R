# Tests for sharp treeline landscape creation --------------------------------

# Validation tests ------------------------------------------------------------

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_sharp creates valid landscape objects", {
  l <- create_landscape_sharp(width = 50, height = 50)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$pattern, "sharp")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_sharp boundary_position creates correct patterns", {
  # Position = 0.5 should split approximately in half
  l_half <- create_landscape_sharp(
    width = 20,
    height = 20,
    boundary_position = 0.5
  )
  vals <- terra::values(l_half$data)
  prop_ones <- sum(vals == 1) / length(vals)
  expect_true(prop_ones > 0.4 && prop_ones < 0.6)
})

test_that("create_landscape_sharp stores all params correctly", {
  l <- create_landscape_sharp(
    width = 30,
    height = 40,
    boundary_position = 0.7,
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$boundary_position, 0.7)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_sharp supports rotation parameter", {
  l <- create_landscape_sharp(width = 50, height = 50, rotation = 45)

  expect_true(is_landscape(l))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
  expect_equal(l$params$rotation, 45)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_sharp handles extreme treeline positions", {
  # Treeline at bottom (position = 0)
  l_bottom <- create_landscape_sharp(
    width = 50,
    height = 50,
    boundary_position = 0
  )
  expect_true(is_landscape(l_bottom))

  # Treeline at top (position = 1)
  l_top <- create_landscape_sharp(
    width = 50,
    height = 50,
    boundary_position = 1
  )
  expect_true(is_landscape(l_top))
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_sharp handles multiple extreme parameters", {
  # Small landscape + extreme position + rotation
  l_extreme <- create_landscape_sharp(
    width = 5,
    height = 5,
    boundary_position = 0,
    rotation = 90
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 5)
  expect_equal(terra::nrow(l_extreme$data), 5)
})
