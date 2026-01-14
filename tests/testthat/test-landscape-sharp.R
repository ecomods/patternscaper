# Tests for sharp treeline landscape creation --------------------------------

# Validation tests ------------------------------------------------------------

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_sharp_treeline creates valid landscape objects", {
  l <- create_landscape_sharp_treeline(width = 50, height = 50)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$pattern, "sharp")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_sharp_treeline treeline_position creates correct patterns", {
  # Position = 0.5 should split approximately in half
  l_half <- create_landscape_sharp_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5
  )
  vals <- terra::values(l_half$data)
  prop_ones <- sum(vals == 1) / length(vals)
  expect_true(prop_ones > 0.4 && prop_ones < 0.6)
})

test_that("create_landscape_sharp_treeline stores all params correctly", {
  l <- create_landscape_sharp_treeline(
    width = 30,
    height = 40,
    treeline_position = 0.7,
    random_spots = c(0.1, 0.2),
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$treeline_position, 0.7)
  expect_equal(l$params$random_spots, c(0.1, 0.2))
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_sharp_treeline supports rotation parameter", {
  l <- create_landscape_sharp_treeline(width = 50, height = 50, rotation = 45)

  expect_true(is_landscape(l))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
  expect_equal(l$params$rotation, 45)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_sharp_treeline handles extreme treeline positions", {
  # Treeline at bottom (position = 0)
  l_bottom <- create_landscape_sharp_treeline(
    width = 50,
    height = 50,
    treeline_position = 0
  )
  expect_true(is_landscape(l_bottom))

  # Treeline at top (position = 1)
  l_top <- create_landscape_sharp_treeline(
    width = 50,
    height = 50,
    treeline_position = 1
  )
  expect_true(is_landscape(l_top))
})

test_that("create_landscape_sharp_treeline handles extreme random_spots values", {
  # No random spots
  l_no_spots <- create_landscape_sharp_treeline(
    width = 50,
    height = 50,
    random_spots = c(0, 0)
  )
  expect_true(is_landscape(l_no_spots))
  expect_equal(l_no_spots$params$random_spots, c(0, 0))

  # Maximum random spots
  l_max_spots <- create_landscape_sharp_treeline(
    width = 50,
    height = 50,
    random_spots = c(1, 1)
  )
  expect_true(is_landscape(l_max_spots))
  expect_equal(l_max_spots$params$random_spots, c(1, 1))
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_sharp_treeline handles multiple extreme parameters", {
  # Small landscape + extreme position + rotation
  l_extreme <- create_landscape_sharp_treeline(
    width = 5,
    height = 5,
    treeline_position = 0,
    rotation = 90,
    random_spots = c(0.5, 0.5)
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 5)
  expect_equal(terra::nrow(l_extreme$data), 5)
})
