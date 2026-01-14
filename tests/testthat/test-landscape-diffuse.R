# Tests for diffuse treeline landscape creation ------------------------------

# Validation tests ------------------------------------------------------------
test_that("create_landscape_diffuse_treeline validates steepness parameter", {
  expect_error(
    create_landscape_diffuse_treeline(steepness = -0.1),
    "between 0 and 1"
  )
  expect_error(
    create_landscape_diffuse_treeline(steepness = 1.1),
    "between 0 and 1"
  )
  expect_error(
    create_landscape_diffuse_treeline(steepness = "invalid"),
    "must be numeric"
  )
  # Valid boundary values
  expect_no_error(create_landscape_diffuse_treeline(steepness = 0))
  expect_no_error(create_landscape_diffuse_treeline(steepness = 1))
})

test_that("create_landscape_diffuse_treeline validates rotation parameter", {
  expect_error(
    create_landscape_diffuse_treeline(rotation = -1),
    "between 0 and 360"
  )
  expect_error(
    create_landscape_diffuse_treeline(rotation = 361),
    "between 0 and 360"
  )
  expect_error(
    create_landscape_diffuse_treeline(rotation = "invalid"),
    "must be numeric"
  )
  # Valid boundary values
  expect_no_error(create_landscape_diffuse_treeline(rotation = 0))
  expect_no_error(create_landscape_diffuse_treeline(rotation = 360))
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_diffuse_treeline creates valid landscape object", {
  l <- create_landscape_diffuse_treeline(width = 50, height = 50)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$pattern, "diffuse")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_diffuse_treeline steepness creates gradual transition", {
  # Low steepness should create sharp-ish transition
  l_sharp <- create_landscape_diffuse_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5,
    steepness = 0.1
  )

  # High steepness should create gradual transition
  l_gradual <- create_landscape_diffuse_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5,
    steepness = 0.9
  )

  expect_true(is_landscape(l_sharp))
  expect_true(is_landscape(l_gradual))

  # Both should have values between 0 and 1 (gradual transition)
  vals_sharp <- terra::values(l_sharp$data)
  vals_gradual <- terra::values(l_gradual$data)

  expect_true(all(vals_sharp >= 0 & vals_sharp <= 1))
  expect_true(all(vals_gradual >= 0 & vals_gradual <= 1))
})

test_that("create_landscape_diffuse_treeline stores all params correctly", {
  l <- create_landscape_diffuse_treeline(
    width = 30,
    height = 40,
    treeline_position = 0.7,
    steepness = 0.6,
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$treeline_position, 0.7)
  expect_equal(l$params$steepness, 0.6)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_diffuse_treeline supports rotation", {
  l <- create_landscape_diffuse_treeline(
    width = 50,
    height = 50,
    rotation = 45
  )

  expect_true(is_landscape(l))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
  expect_equal(l$params$rotation, 45)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_diffuse_treeline handles very small landscapes", {
  l_small <- create_landscape_diffuse_treeline(width = 5, height = 5)

  expect_true(is_landscape(l_small))
  expect_equal(terra::ncol(l_small$data), 5)
  expect_equal(terra::nrow(l_small$data), 5)
})

test_that("create_landscape_diffuse_treeline handles very large landscapes", {
  l_large <- create_landscape_diffuse_treeline(width = 500, height = 500)

  expect_true(is_landscape(l_large))
  expect_equal(terra::ncol(l_large$data), 500)
  expect_equal(terra::nrow(l_large$data), 500)
})

test_that("create_landscape_diffuse_treeline handles non-square landscapes", {
  l_wide <- create_landscape_diffuse_treeline(width = 100, height = 50)
  l_tall <- create_landscape_diffuse_treeline(width = 50, height = 100)

  expect_true(is_landscape(l_wide))
  expect_equal(terra::ncol(l_wide$data), 100)
  expect_equal(terra::nrow(l_wide$data), 50)

  expect_true(is_landscape(l_tall))
  expect_equal(terra::ncol(l_tall$data), 50)
  expect_equal(terra::nrow(l_tall$data), 100)
})

test_that("create_landscape_diffuse_treeline handles extreme rotation angles", {
  l_zero <- create_landscape_diffuse_treeline(rotation = 0)
  l_max <- create_landscape_diffuse_treeline(rotation = 360)
  l_mid <- create_landscape_diffuse_treeline(rotation = 180)

  expect_true(is_landscape(l_zero))
  expect_true(is_landscape(l_max))
  expect_true(is_landscape(l_mid))
})

test_that("create_landscape_diffuse_treeline handles treeline_position boundary values", {
  # Exactly 0 - transition at top
  l_zero <- create_landscape_diffuse_treeline(
    width = 20,
    height = 20,
    treeline_position = 0,
    steepness = 0.5
  )
  expect_true(is_landscape(l_zero))

  # Exactly 1 - transition at bottom
  l_one <- create_landscape_diffuse_treeline(
    width = 20,
    height = 20,
    treeline_position = 1,
    steepness = 0.5
  )
  expect_true(is_landscape(l_one))

  # Very close to boundaries
  l_near_zero <- create_landscape_diffuse_treeline(treeline_position = 0.001)
  l_near_one <- create_landscape_diffuse_treeline(treeline_position = 0.999)

  expect_true(is_landscape(l_near_zero))
  expect_true(is_landscape(l_near_one))
})

test_that("create_landscape_diffuse_treeline handles steepness boundary values", {
  # Minimum steepness (sharp transition)
  l_min_steep <- create_landscape_diffuse_treeline(
    width = 20,
    height = 20,
    steepness = 0
  )
  expect_true(is_landscape(l_min_steep))

  # Maximum steepness (very gradual)
  l_max_steep <- create_landscape_diffuse_treeline(
    width = 20,
    height = 20,
    steepness = 1
  )
  expect_true(is_landscape(l_max_steep))

  # Very close to boundaries
  l_near_zero <- create_landscape_diffuse_treeline(steepness = 0.001)
  l_near_one <- create_landscape_diffuse_treeline(steepness = 0.999)

  expect_true(is_landscape(l_near_zero))
  expect_true(is_landscape(l_near_one))
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_diffuse_treeline handles multiple edge cases together", {
  # Small landscape + extreme treeline + extreme steepness + rotation
  l_extreme <- create_landscape_diffuse_treeline(
    width = 5,
    height = 5,
    treeline_position = 0.999,
    steepness = 0.001,
    rotation = 45
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 5)
  expect_equal(terra::nrow(l_extreme$data), 5)
})

test_that("create_landscape_diffuse_treeline produces consistent results with same seed", {
  set.seed(123)
  l1 <- create_landscape_diffuse_treeline(width = 30, height = 30)

  set.seed(123)
  l2 <- create_landscape_diffuse_treeline(width = 30, height = 30)

  expect_equal(terra::values(l1$data), terra::values(l2$data))
})
