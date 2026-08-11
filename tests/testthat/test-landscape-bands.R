# Tests for sine bands landscape generation

# Validation tests ------------------------------------------------------------

test_that("bands validates band_zone_prop parameter", {
  expect_error(
    create_landscape_bands(band_zone_prop = "0.2"),
    "must be between 0 and 1",
    info = "Testing bands with non-numeric band_zone_prop"
  )

  expect_error(
    create_landscape_bands(band_zone_prop = -0.1),
    "must be between 0 and 1",
    info = "Testing bands with negative band_zone_prop"
  )

  expect_error(
    create_landscape_bands(band_zone_prop = 1.5),
    "must be between 0 and 1",
    info = "Testing bands with band_zone_prop > 1"
  )
})

test_that("bands validates band_thickness parameter", {
  expect_error(
    create_landscape_bands(band_thickness = "3"),
    "must be a positive number",
    info = "Testing bands with non-numeric band_thickness"
  )

  expect_error(
    create_landscape_bands(band_thickness = -2),
    "must be a positive number",
    info = "Testing bands with negative band_thickness"
  )

  expect_error(
    create_landscape_bands(band_thickness = 0),
    "must be a positive number",
    info = "Testing bands with zero band_thickness"
  )
})

test_that("bands validates band_spacing parameter", {
  expect_error(
    create_landscape_bands(band_spacing = "10"),
    "must be a positive number",
    info = "Testing bands with non-numeric band_spacing"
  )

  expect_error(
    create_landscape_bands(band_spacing = -5),
    "must be a positive number",
    info = "Testing bands with negative band_spacing"
  )

  expect_error(
    create_landscape_bands(band_spacing = 0),
    "must be a positive number",
    info = "Testing bands with zero band_spacing"
  )
})

test_that("bands validates frequency parameter", {
  expect_error(
    create_landscape_bands(frequency = "0.5"),
    "must be a non-negative number",
    info = "Testing bands with non-numeric frequency"
  )

  expect_error(
    create_landscape_bands(frequency = -1),
    "must be a non-negative number",
    info = "Testing bands with negative frequency"
  )
})

test_that("bands validates amplitude parameter", {
  expect_error(
    create_landscape_bands(amplitude = "5"),
    "must be a non-negative number",
    info = "Testing bands with non-numeric amplitude"
  )

  expect_error(
    create_landscape_bands(amplitude = -3),
    "must be a non-negative number",
    info = "Testing bands with negative amplitude"
  )
})

test_that("bands validates noise_sd parameter", {
  expect_error(
    create_landscape_bands(noise_sd = "1"),
    "must be a non-negative number",
    info = "Testing bands with non-numeric noise_sd"
  )

  expect_error(
    create_landscape_bands(noise_sd = -2),
    "must be a non-negative number",
    info = "Testing bands with negative noise_sd"
  )
})

test_that("bands warns when no bands can fit", {
  expect_warning(
    create_landscape_bands(
      boundary_position = 0.7,
      band_zone_prop = 0.15,
      band_spacing = 20
    ),
    "No bands can fit in available space",
    info = "Testing bands with band_spacing too large for available space"
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_bands creates a vegetation boundary with bands below", {
  set.seed(123)

  l <- create_landscape_bands(
    width = 30,
    height = 30,
    boundary_position = 0.4,
    band_zone_prop = 0.3,
    band_spacing = 5,
    band_thickness = 2
  )

  expect_true(is_landscape(l))

  # Should have vegetation (1s) both from the boundary and the bands
  vals <- terra::values(l$data)
  expect_true(sum(vals == 1) > 0)

  # Check that bands exist below the boundary
  mat <- matrix(vals, nrow = 30, ncol = 30)
  # Lower rows (below the boundary) should have some 1s (bands)
  lower_half <- mat[20:30, ]
  expect_true(sum(lower_half == 1) > 0)
})

test_that("create_landscape_bands handles zero amplitude (straight boundary)", {
  l <- create_landscape_bands(
    width = 20,
    height = 20,
    boundary_position = 0.5,
    amplitude = 0,
    band_spacing = 5
  )

  expect_true(is_landscape(l))
})

test_that("create_landscape_bands noise_sd adds variation to bands", {
  set.seed(123)

  # Without noise
  l_no_noise <- create_landscape_bands(
    width = 25,
    height = 25,
    band_spacing = 5,
    band_thickness = 2,
    noise_sd = 0
  )

  set.seed(123)
  # With noise
  l_with_noise <- create_landscape_bands(
    width = 25,
    height = 25,
    band_spacing = 5,
    band_thickness = 2,
    noise_sd = 2
  )

  vals_no_noise <- terra::values(l_no_noise$data)
  vals_with_noise <- terra::values(l_with_noise$data)

  # Patterns should differ due to noise
  expect_false(identical(vals_no_noise, vals_with_noise))
})

test_that("create_landscape_bands frequency affects wave pattern", {
  set.seed(123)

  # Low frequency (long waves)
  l_low_freq <- create_landscape_bands(
    width = 30,
    height = 30,
    frequency = 0.1,
    amplitude = 5
  )

  # High frequency (short waves)
  l_high_freq <- create_landscape_bands(
    width = 30,
    height = 30,
    frequency = 0.5,
    amplitude = 5
  )

  expect_true(is_landscape(l_low_freq))
  expect_true(is_landscape(l_high_freq))

  # Different frequencies should create different patterns
  vals_low <- terra::values(l_low_freq$data)
  vals_high <- terra::values(l_high_freq$data)
  expect_false(identical(vals_low, vals_high))
})

test_that("create_landscape_bands stores all params correctly", {
  l <- create_landscape_bands(
    width = 30,
    height = 40,
    boundary_position = 0.6,
    band_zone_prop = 0.3,
    band_thickness = 4,
    band_spacing = 8,
    frequency = 0.2,
    amplitude = 6,
    noise_sd = 1.5,
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$boundary_position, 0.6)
  expect_equal(l$params$band_zone_prop, 0.3)
  expect_equal(l$params$band_thickness, 4)
  expect_equal(l$params$band_spacing, 8)
  expect_equal(l$params$frequency, 0.2)
  expect_equal(l$params$amplitude, 6)
  expect_equal(l$params$noise_sd, 1.5)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_bands produces reproducible results with seed", {
  set.seed(789)
  l1 <- create_landscape_bands(
    width = 25,
    height = 25,
    band_spacing = 6,
    noise_sd = 1
  )

  set.seed(789)
  l2 <- create_landscape_bands(
    width = 25,
    height = 25,
    band_spacing = 6,
    noise_sd = 1
  )

  vals1 <- terra::values(l1$data)
  vals2 <- terra::values(l2$data)
  expect_identical(vals1, vals2)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_bands warns when bands cannot fit", {
  expect_warning(
    l <- create_landscape_bands(
      width = 20,
      height = 20,
      boundary_position = 0.7,
      band_zone_prop = 0.15,
      band_spacing = 20
    ),
    "No bands can fit in available space"
  )
})

test_that("create_landscape_bands handles edge cases", {
  # Very small band zone
  l_small_zone <- create_landscape_bands(
    width = 20,
    height = 20,
    band_zone_prop = 0.05,
    band_spacing = 3
  )
  expect_true(is_landscape(l_small_zone))

  # Very thick bands
  l_thick <- create_landscape_bands(
    width = 20,
    height = 20,
    band_thickness = 8,
    band_spacing = 10
  )
  expect_true(is_landscape(l_thick))
})

# Integration tests -----------------------------------------------------------

test_that("bands handles rotation correctly", {
  set.seed(123)

  l_no_rotation <- create_landscape_bands(
    width = 30,
    height = 30,
    rotation = 0,
    band_spacing = 5
  )

  l_with_rotation <- create_landscape_bands(
    width = 30,
    height = 30,
    rotation = 45,
    band_spacing = 5
  )

  expect_true(is_landscape(l_no_rotation))
  expect_true(is_landscape(l_with_rotation))

  # Rotation should change the pattern
  vals_no_rot <- terra::values(l_no_rotation$data)
  vals_rot <- terra::values(l_with_rotation$data)
  expect_false(identical(vals_no_rot, vals_rot))
})
