# Validation tests ------------------------------------------------------------

test_that("create_landscape_fingers validates sine_length_mean parameter", {
  expect_error(
    create_landscape_fingers(sine_length_mean = "20"),
    "must be a positive numeric value",
    info = "Testing fingers with non-numeric sine_length_mean"
  )

  expect_error(
    create_landscape_fingers(sine_length_mean = -10),
    "must be a positive numeric value",
    info = "Testing fingers with negative sine_length_mean"
  )

  expect_error(
    create_landscape_fingers(sine_length_mean = 0),
    "must be a positive numeric value",
    info = "Testing fingers with zero sine_length_mean"
  )
})

test_that("create_landscape_fingers validates sine_length_sd parameter", {
  expect_error(
    create_landscape_fingers(sine_length_sd = "5"),
    "must be a non-negative numeric value",
    info = "Testing fingers with non-numeric sine_length_sd"
  )

  expect_error(
    create_landscape_fingers(sine_length_sd = -5),
    "must be a non-negative numeric value",
    info = "Testing fingers with negative sine_length_sd"
  )
})

test_that("create_landscape_fingers validates sine_height_mean parameter", {
  expect_error(
    create_landscape_fingers(sine_height_mean = "5"),
    "must be a non-negative numeric value",
    info = "Testing fingers with non-numeric sine_height_mean"
  )

  expect_error(
    create_landscape_fingers(sine_height_mean = -5),
    "must be a non-negative numeric value",
    info = "Testing fingers with negative sine_height_mean"
  )
})

test_that("create_landscape_fingers validates sine_height_sd parameter", {
  expect_error(
    create_landscape_fingers(sine_height_sd = "3"),
    "must be a non-negative numeric value",
    info = "Testing fingers with non-numeric sine_height_sd"
  )

  expect_error(
    create_landscape_fingers(sine_height_sd = -3),
    "must be a non-negative numeric value",
    info = "Testing fingers with negative sine_height_sd"
  )
})

test_that("create_landscape_fingers warns about large sine_height_mean", {
  expect_warning(
    create_landscape_fingers(
      width = 20,
      height = 20,
      sine_height_mean = 15
    ),
    "large relative to",
    info = "Testing fingers with sine_height_mean > 50% of height"
  )
})

# Functionality tests ----------------------------------------------------------

test_that("create_landscape_fingers creates varying sinusoidal patterns", {
  set.seed(123)

  # Zero amplitude mean should create relatively straight line
  l_straight <- create_landscape_fingers(
    width = 20,
    height = 20,
    boundary_position = 0.5,
    sine_height_mean = 0,
    sine_height_sd = 0
  )
  expect_true(is_landscape(l_straight))

  # With amplitude, pattern should vary across columns
  l_curvy <- create_landscape_fingers(
    width = 20,
    height = 20,
    boundary_position = 0.5,
    sine_length_mean = 10,
    sine_length_sd = 3,
    sine_height_mean = 3,
    sine_height_sd = 1
  )
  expect_true(is_landscape(l_curvy))

  # Check that the boundary position varies across columns
  vals <- terra::values(l_curvy$data)
  mat <- matrix(vals, nrow = 20, ncol = 20)
  col_sums <- colSums(mat)
  expect_true(length(unique(col_sums)) > 1)
})

test_that("create_landscape_fingers stores all params correctly", {
  l <- create_landscape_fingers(
    width = 30,
    height = 40,
    boundary_position = 0.7,
    sine_length_mean = 25,
    sine_length_sd = 10,
    sine_height_mean = 8,
    sine_height_sd = 3,
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$boundary_position, 0.7)
  expect_equal(l$params$sine_length_mean, 25)
  expect_equal(l$params$sine_length_sd, 10)
  expect_equal(l$params$sine_height_mean, 8)
  expect_equal(l$params$sine_height_sd, 3)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_fingers produces variable patterns", {
  set.seed(123)

  # Generate two landscapes with same parameters
  l1 <- create_landscape_fingers(
    width = 30,
    height = 30,
    sine_length_mean = 15,
    sine_length_sd = 5,
    sine_height_mean = 5,
    sine_height_sd = 2
  )

  l2 <- create_landscape_fingers(
    width = 30,
    height = 30,
    sine_length_mean = 15,
    sine_length_sd = 5,
    sine_height_mean = 5,
    sine_height_sd = 2
  )

  # Different random seeds should produce different patterns
  vals1 <- terra::values(l1$data)
  vals2 <- terra::values(l2$data)
  expect_false(identical(vals1, vals2))
})

test_that("create_landscape_fingers handles zero standard deviations", {
  # Zero SDs should create constant wavelength and amplitude
  l_constant <- create_landscape_fingers(
    width = 20,
    height = 20,
    sine_length_mean = 20,
    sine_length_sd = 0,
    sine_height_mean = 5,
    sine_height_sd = 0
  )

  expect_true(is_landscape(l_constant))
  expect_equal(terra::ncol(l_constant$data), 20)
  expect_equal(terra::nrow(l_constant$data), 20)
})

# Edge case tests --------------------------------------------------------------

test_that("create_landscape_fingers handles sine_length boundary values", {
  # Very small mean wavelength
  l_small_length <- create_landscape_fingers(
    width = 20,
    height = 20,
    sine_length_mean = 1,
    sine_length_sd = 0
  )
  expect_true(is_landscape(l_small_length))

  # Very large mean wavelength (larger than landscape)
  l_large_length <- create_landscape_fingers(
    width = 20,
    height = 20,
    sine_length_mean = 1000,
    sine_length_sd = 0
  )
  expect_true(is_landscape(l_large_length))

  # Wavelength equal to width
  l_equal_length <- create_landscape_fingers(
    width = 50,
    height = 50,
    sine_length_mean = 50,
    sine_length_sd = 0
  )
  expect_true(is_landscape(l_equal_length))

  # Zero standard deviation (constant wavelength)
  l_zero_sd <- create_landscape_fingers(
    sine_length_mean = 20,
    sine_length_sd = 0
  )
  expect_true(is_landscape(l_zero_sd))

  # Large standard deviation
  l_large_sd <- create_landscape_fingers(
    sine_length_mean = 20,
    sine_length_sd = 50
  )
  expect_true(is_landscape(l_large_sd))
})

test_that("create_landscape_fingers handles sine_height boundary values", {
  # Zero mean amplitude (should be straight line)
  l_zero_height <- create_landscape_fingers(
    width = 20,
    height = 20,
    sine_height_mean = 0,
    sine_height_sd = 0
  )
  expect_true(is_landscape(l_zero_height))

  # Very large mean amplitude
  l_large_height <- create_landscape_fingers(
    width = 20,
    height = 20,
    sine_height_mean = 50,
    sine_height_sd = 0
  )
  expect_true(is_landscape(l_large_height))

  # Amplitude larger than height (should trigger warning)
  expect_warning(
    l_extreme_height <- create_landscape_fingers(
      width = 20,
      height = 20,
      sine_height_mean = 15,
      sine_height_sd = 0
    ),
    "large relative to"
  )
  expect_true(is_landscape(l_extreme_height))

  # Zero standard deviation (constant amplitude)
  l_zero_sd <- create_landscape_fingers(
    sine_height_mean = 5,
    sine_height_sd = 0
  )
  expect_true(is_landscape(l_zero_sd))

  # Large standard deviation relative to mean
  l_large_sd <- create_landscape_fingers(
    sine_height_mean = 5,
    sine_height_sd = 20
  )
  expect_true(is_landscape(l_large_sd))
})

test_that("create_landscape_fingers handles boundary_position boundary values", {
  # Exactly 0 - transition at top
  l_zero <- create_landscape_fingers(
    width = 20,
    height = 20,
    boundary_position = 0,
    sine_height_mean = 2
  )
  expect_true(is_landscape(l_zero))

  # Exactly 1 - transition at bottom
  l_one <- create_landscape_fingers(
    width = 20,
    height = 20,
    boundary_position = 1,
    sine_height_mean = 2
  )
  expect_true(is_landscape(l_one))

  # Very close to boundaries
  l_near_zero <- create_landscape_fingers(boundary_position = 0.001)
  l_near_one <- create_landscape_fingers(boundary_position = 0.999)

  expect_true(is_landscape(l_near_zero))
  expect_true(is_landscape(l_near_one))
})

# Integration tests ------------------------------------------------------------

test_that("create_landscape_fingers handles multiple edge cases together", {
  # Small landscape + extreme boundary + extreme sine params + rotation
  l_extreme <- create_landscape_fingers(
    width = 30,
    height = 30,
    boundary_position = 0.999,
    sine_length_mean = 1,
    sine_length_sd = 2,
    sine_height_mean = 10,
    sine_height_sd = 5,
    rotation = 45
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 30)
  expect_equal(terra::nrow(l_extreme$data), 30)
})

test_that("create_landscape_fingers produces varying patterns across replications", {
  set.seed(123)

  # Generate multiple landscapes with same parameters
  landscapes <- replicate(
    5,
    {
      create_landscape_fingers(
        width = 50,
        height = 50,
        sine_length_mean = 15,
        sine_length_sd = 5,
        sine_height_mean = 8,
        sine_height_sd = 3
      )
    },
    simplify = FALSE
  )

  # Extract values from each
  vals_list <- lapply(landscapes, function(l) terra::values(l$data))

  # Check that landscapes are not identical (due to randomness)
  expect_false(all(sapply(2:5, function(i) {
    identical(vals_list[[1]], vals_list[[i]])
  })))
})
