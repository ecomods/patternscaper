# Test landscape creation: curvy treeline pattern

# Validation tests ------------------------------------------------------------

test_that("curvy treeline validates sine_length parameter", {
  expect_error(
    create_landscape_curvy_treeline(sine_length = "20"),
    "must be a positive numeric value",
    info = "Testing curvy with non-numeric sine_length"
  )

  expect_error(
    create_landscape_curvy_treeline(sine_length = -10),
    "must be a positive numeric value",
    info = "Testing curvy with negative sine_length"
  )

  expect_error(
    create_landscape_curvy_treeline(sine_length = 0),
    "must be a positive numeric value",
    info = "Testing curvy with zero sine_length"
  )
})

test_that("curvy treeline validates sine_height parameter", {
  expect_error(
    create_landscape_curvy_treeline(sine_height = "5"),
    "must be a non-negative numeric value",
    info = "Testing curvy with non-numeric sine_height"
  )

  expect_error(
    create_landscape_curvy_treeline(sine_height = -5),
    "must be a non-negative numeric value",
    info = "Testing curvy with negative sine_height"
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_curvy_treeline creates sinusoidal pattern", {
  # Zero amplitude should create straight line (like sharp)
  l_straight <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5,
    sine_height = 0
  )
  expect_true(is_landscape(l_straight))

  # With amplitude, pattern should vary across columns
  l_curvy <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5,
    sine_length = 10,
    sine_height = 3
  )
  expect_true(is_landscape(l_curvy))

  # Check that treeline position varies across columns
  vals <- terra::values(l_curvy$data)
  mat <- matrix(vals, nrow = 20, ncol = 20)
  # Count 1s in each column - should vary if pattern is curvy
  col_sums <- colSums(mat)
  expect_true(length(unique(col_sums)) > 1)
})

test_that("create_landscape_curvy_treeline stores all params correctly", {
  l <- create_landscape_curvy_treeline(
    width = 30,
    height = 40,
    treeline_position = 0.7,
    sine_length = 25,
    sine_height = 8,
    random_spots = c(0.1, 0.2),
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$treeline_position, 0.7)
  expect_equal(l$params$sine_length, 25)
  expect_equal(l$params$sine_height, 8)
  expect_equal(l$params$random_spots, c(0.1, 0.2))
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_curvy_treeline random_spots parameter works", {
  set.seed(123)
  # With no random spots
  l_no_random <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5,
    sine_height = 3,
    random_spots = c(0, 0)
  )

  # With random spots
  l_random <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    treeline_position = 0.5,
    sine_height = 3,
    random_spots = c(0.2, 0.2)
  )

  # Landscapes should differ due to randomness
  vals_no_random <- terra::values(l_no_random$data)
  vals_random <- terra::values(l_random$data)
  expect_false(identical(vals_no_random, vals_random))
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_curvy_treeline handles sine_length boundary values", {
  # Very small wavelength
  l_small_length <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    sine_length = 1
  )
  expect_true(is_landscape(l_small_length))

  # Very large wavelength (larger than landscape)
  l_large_length <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    sine_length = 1000
  )
  expect_true(is_landscape(l_large_length))

  # Wavelength equal to width
  l_equal_length <- create_landscape_curvy_treeline(
    width = 50,
    height = 50,
    sine_length = 50
  )
  expect_true(is_landscape(l_equal_length))
})

test_that("create_landscape_curvy_treeline handles sine_height boundary values", {
  # Zero amplitude (should be straight line)
  l_zero_height <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    sine_height = 0
  )
  expect_true(is_landscape(l_zero_height))

  # Very large amplitude
  l_large_height <- create_landscape_curvy_treeline(
    width = 20,
    height = 20,
    sine_height = 50
  )
  expect_true(is_landscape(l_large_height))

  # Amplitude larger than height (should trigger warning)
  expect_warning(
    l_extreme_height <- create_landscape_curvy_treeline(
      width = 20,
      height = 20,
      sine_height = 15
    ),
    "large relative to"
  )
  expect_true(is_landscape(l_extreme_height))
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_curvy_treeline handles multiple edge cases together", {
  # Small landscape + extreme treeline + extreme sine params + max random + rotation
  l_extreme <- create_landscape_curvy_treeline(
    width = 5,
    height = 5,
    treeline_position = 0.999,
    sine_length = 1,
    sine_height = 10,
    random_spots = c(0.5, 0.5),
    rotation = 45
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 5)
  expect_equal(terra::nrow(l_extreme$data), 5)
})
