# Tests for gaps landscape generator
# Gaps are inverted spots (vegetation patches in bare ground)

# Validation tests --------------------------------------------------------

# Functionality tests -----------------------------------------------------

test_that("create_landscape_gaps inverts by default (vegetation in bare ground)", {
  set.seed(123)

  # Gaps should invert by default
  gaps <- create_landscape_gaps(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 4
  )

  set.seed(123)
  # Spots with invert=TRUE should match gaps
  spots_inverted <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 4,
    invert_landscape = TRUE
  )

  # Pattern labels differ
  expect_equal(gaps$pattern, "gaps")
  expect_equal(spots_inverted$pattern, "spots")

  # But data should be identical
  expect_identical(
    terra::values(gaps$data),
    terra::values(spots_inverted$data)
  )

  # Gaps should have invert_landscape = TRUE stored
  expect_true(gaps$params$invert_landscape)
})

test_that("create_landscape_gaps returns valid landscape object", {
  result <- create_landscape_gaps(width = 30, height = 30, n_spots = 5)

  expect_true(is_landscape(result))
  expect_equal(result$pattern, "gaps")
  expect_s4_class(result$data, "SpatRaster")
  expect_equal(terra::nrow(result$data), 30)
  expect_equal(terra::ncol(result$data), 30)
})

test_that("create_landscape_gaps stores all parameters correctly", {
  result <- create_landscape_gaps(
    width = 40,
    height = 50,
    n_spots = 8,
    spot_radius = 6,
    spot_radius_sd = 2,
    radius_noise_fraction = 0.3,
    regular_spots = TRUE,
    rotation = 45
  )

  expect_equal(result$params$width, 40)
  expect_equal(result$params$height, 50)
  expect_equal(result$params$n_spots, 8)
  expect_equal(result$params$spot_radius, 6)
  expect_equal(result$params$spot_radius_sd, 2)
  expect_equal(result$params$radius_noise_fraction, 0.3)
  expect_true(result$params$regular_spots)
  expect_equal(result$params$rotation, 45)
  expect_true(result$params$invert_landscape)
})

test_that("create_landscape_gaps is reproducible with seed", {
  set.seed(456)
  result1 <- create_landscape_gaps(width = 25, height = 25, n_spots = 4)

  set.seed(456)
  result2 <- create_landscape_gaps(width = 25, height = 25, n_spots = 4)

  expect_identical(
    terra::values(result1$data),
    terra::values(result2$data)
  )
})

test_that("create_landscape_gaps works with regular spots pattern", {
  result <- create_landscape_gaps(
    width = 30,
    height = 30,
    n_spots = 9,
    spot_radius = 3,
    regular_spots = TRUE
  )

  expect_true(is_landscape(result))
  expect_true(result$params$regular_spots)
})

test_that("create_landscape_gaps works with rotation", {
  result <- create_landscape_gaps(
    width = 40,
    height = 40,
    n_spots = 6,
    spot_radius = 5,
    rotation = 90
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$rotation, 90)
  # After 90 degree rotation, dimensions should swap
  expect_equal(terra::nrow(result$data), 40)
  expect_equal(terra::ncol(result$data), 40)
})


# Edge case tests ---------------------------------------------------------

test_that("create_landscape_gaps works with single spot", {
  result <- create_landscape_gaps(
    width = 20,
    height = 20,
    n_spots = 1,
    spot_radius = 5
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$n_spots, 1)
})

test_that("create_landscape_gaps works with many spots", {
  result <- create_landscape_gaps(
    width = 50,
    height = 50,
    n_spots = 50,
    spot_radius = 2
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$n_spots, 50)
})

test_that("create_landscape_gaps works with tiny spot radius", {
  result <- create_landscape_gaps(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 1
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$spot_radius, 1)
})

test_that("create_landscape_gaps works with large spot radius", {
  result <- create_landscape_gaps(
    width = 50,
    height = 50,
    n_spots = 3,
    spot_radius = 20
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$spot_radius, 20)
})

test_that("create_landscape_gaps works with zero noise", {
  result <- create_landscape_gaps(
    width = 30,
    height = 30,
    n_spots = 4,
    spot_radius = 5,
    radius_noise_fraction = 0
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$radius_noise_fraction, 0)
})

test_that("create_landscape_gaps works with maximum noise", {
  result <- create_landscape_gaps(
    width = 30,
    height = 30,
    n_spots = 4,
    spot_radius = 5,
    radius_noise_fraction = 1
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$radius_noise_fraction, 1)
})

test_that("create_landscape_gaps works with zero spot_radius_sd", {
  result <- create_landscape_gaps(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 5,
    spot_radius_sd = 0
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$spot_radius_sd, 0)
})

test_that("create_landscape_gaps works with large spot_radius_sd", {
  result <- create_landscape_gaps(
    width = 40,
    height = 40,
    n_spots = 6,
    spot_radius = 8,
    spot_radius_sd = 5
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$spot_radius_sd, 5)
})


# Integration tests -------------------------------------------------------

test_that("create_landscape_gaps works with multiple extreme parameters", {
  result <- create_landscape_gaps(
    width = 15,
    height = 15,
    n_spots = 20,
    spot_radius = 2,
    spot_radius_sd = 1,
    radius_noise_fraction = 1,
    regular_spots = FALSE,
    rotation = 45
  )

  expect_true(is_landscape(result))
  expect_true(result$params$invert_landscape)
})

test_that("create_landscape_gaps with small landscape and rotation", {
  result <- create_landscape_gaps(
    width = 10,
    height = 10,
    n_spots = 3,
    spot_radius = 2,
    rotation = 90
  )

  expect_true(is_landscape(result))
  expect_equal(result$params$rotation, 90)
})
