# Tests for create_landscape_spots() -------------------------------------------

# Validation tests ------------------------------------------------------------

test_that("spots validates n_spots parameter", {
  expect_error(
    create_landscape_spots(n_spots = -5),
    "must be a positive integer",
    info = "Testing spots with negative n_spots"
  )

  expect_error(
    create_landscape_spots(n_spots = 0),
    "must be a positive integer",
    info = "Testing spots with zero n_spots"
  )
})

test_that("spots validates spot_radius parameter", {
  expect_error(
    create_landscape_spots(spot_radius = "5"),
    "must be a positive number",
    info = "Testing spots with non-numeric spot_radius"
  )

  expect_error(
    create_landscape_spots(spot_radius = -3),
    "must be a positive number",
    info = "Testing spots with negative spot_radius"
  )

  expect_error(
    create_landscape_spots(spot_radius = 0),
    "must be a positive number",
    info = "Testing spots with zero spot_radius"
  )

  expect_error(
    create_landscape_spots(width = 100, height = 100, spot_radius = 60),
    "too large for the landscape dimensions",
    info = "Testing spots with spot_radius >= min(width, height) / 2"
  )
})

test_that("spots validates spot_radius_sd parameter", {
  expect_error(
    create_landscape_spots(spot_radius_sd = "2"),
    "must be a non-negative number",
    info = "Testing spots with non-numeric spot_radius_sd"
  )

  expect_error(
    create_landscape_spots(spot_radius_sd = -1),
    "must be a non-negative number",
    info = "Testing spots with negative spot_radius_sd"
  )
})

test_that("spots validates radius_noise_fraction parameter", {
  expect_error(
    create_landscape_spots(radius_noise_fraction = "0.5"),
    "must be between 0 and 1",
    info = "Testing spots with non-numeric radius_noise_fraction"
  )

  expect_error(
    create_landscape_spots(radius_noise_fraction = -0.1),
    "must be between 0 and 1",
    info = "Testing spots with negative radius_noise_fraction"
  )

  expect_error(
    create_landscape_spots(radius_noise_fraction = 1.5),
    "must be between 0 and 1",
    info = "Testing spots with radius_noise_fraction > 1"
  )
})

test_that("spots validates invert_landscape parameter", {
  expect_error(
    create_landscape_spots(invert_landscape = "TRUE"),
    "must be a single logical value",
    info = "Testing spots with non-logical invert_landscape"
  )

  expect_error(
    create_landscape_spots(invert_landscape = c(TRUE, FALSE)),
    "must be a single logical value",
    info = "Testing spots with vector invert_landscape"
  )
})

test_that("spots validates regular_spots parameter", {
  expect_error(
    create_landscape_spots(regular_spots = "TRUE"),
    "must be a single logical value",
    info = "Testing spots with non-logical regular_spots"
  )

  expect_error(
    create_landscape_spots(regular_spots = c(TRUE, FALSE)),
    "must be a single logical value",
    info = "Testing spots with vector regular_spots"
  )
})

test_that("spots warns when n_spots exceeds grid capacity for regular placement", {
  expect_warning(
    create_landscape_spots(
      width = 50,
      height = 50,
      n_spots = 100,
      spot_radius = 10,
      regular_spots = TRUE
    ),
    "only ~.* positions fit",
    info = "Testing spots with too many spots for regular placement"
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_spots creates circular patterns", {
  set.seed(123)

  # Single large spot should create visible circular pattern
  l_spot <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 1,
    spot_radius = 5
  )

  expect_true(is_landscape(l_spot))

  # Should have some vegetation (1s)
  vals <- terra::values(l_spot$data)
  expect_true(sum(vals == 1) > 0)
})

test_that("create_landscape_spots regular_spots creates structured pattern", {
  set.seed(123)

  # Regular spots should create more uniform distribution
  l_regular <- create_landscape_spots(
    width = 50,
    height = 50,
    n_spots = 10,
    spot_radius = 5,
    regular_spots = TRUE
  )

  expect_true(is_landscape(l_regular))
  expect_equal(terra::ncol(l_regular$data), 50)
  expect_equal(terra::nrow(l_regular$data), 50)
})

test_that("create_landscape_spots spot_radius_sd adds variation", {
  set.seed(123)

  # With no variation
  l_no_var <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 5,
    spot_radius_sd = 0
  )

  # With variation
  l_with_var <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 5,
    spot_radius_sd = 2
  )

  # Landscapes should differ due to radius variation
  vals_no_var <- terra::values(l_no_var$data)
  vals_with_var <- terra::values(l_with_var$data)
  expect_false(identical(vals_no_var, vals_with_var))
})

test_that("create_landscape_spots radius_noise_fraction affects edges", {
  set.seed(123)

  # Sharp edges (no noise)
  l_sharp <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 3,
    spot_radius = 8,
    radius_noise_fraction = 0
  )

  # Gradual edges (with noise)
  l_gradual <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 3,
    spot_radius = 8,
    radius_noise_fraction = 0.3
  )

  expect_true(is_landscape(l_sharp))
  expect_true(is_landscape(l_gradual))

  # Different noise fractions should produce different patterns
  vals_sharp <- terra::values(l_sharp$data)
  vals_gradual <- terra::values(l_gradual$data)
  expect_false(identical(vals_sharp, vals_gradual))
})

test_that("create_landscape_spots invert_landscape parameter works", {
  set.seed(123)

  # Normal (bare spots in vegetation)
  l_normal <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 4,
    invert_landscape = FALSE
  )
  set.seed(123)
  # Inverted (vegetation spots in bare ground)
  l_inverted <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 4,
    invert_landscape = TRUE
  )

  vals_normal <- terra::values(l_normal$data)
  vals_inverted <- terra::values(l_inverted$data)

  # Inverted should have opposite values (approximately)
  # Sum of 1s in normal ≈ sum of 0s in inverted
  expect_true(abs(sum(vals_normal) - sum(1 - vals_inverted)) == 0)
})

test_that("create_landscape_spots stores all params correctly", {
  l <- create_landscape_spots(
    width = 30,
    height = 40,
    n_spots = 5,
    spot_radius = 6,
    spot_radius_sd = 1.5,
    radius_noise_fraction = 0.2,
    invert_landscape = TRUE,
    regular_spots = TRUE,
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$n_spots, 5)
  expect_equal(l$params$spot_radius, 6)
  expect_equal(l$params$spot_radius_sd, 1.5)
  expect_equal(l$params$invert_landscape, TRUE)
  expect_equal(l$params$regular_spots, TRUE)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_spots produces reproducible results with seed", {
  set.seed(789)
  l1 <- create_landscape_spots(
    width = 25,
    height = 25,
    n_spots = 8,
    spot_radius = 5,
    spot_radius_sd = 1
  )

  set.seed(789)
  l2 <- create_landscape_spots(
    width = 25,
    height = 25,
    n_spots = 8,
    spot_radius = 5,
    spot_radius_sd = 1
  )

  vals1 <- terra::values(l1$data)
  vals2 <- terra::values(l2$data)
  expect_identical(vals1, vals2)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_spots handles edge cases", {
  # Minimum spots
  l_min <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 1,
    spot_radius = 3
  )
  expect_true(is_landscape(l_min))

  # Very small radius
  l_small <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 1
  )
  expect_true(is_landscape(l_small))
})

test_that("create_landscape_spots handles n_spots boundary values", {
  # Minimum spots
  l_one_spot <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 1,
    spot_radius = 3
  )
  expect_true(is_landscape(l_one_spot))

  # Many spots
  l_many_spots <- create_landscape_spots(
    width = 50,
    height = 50,
    n_spots = 50,
    spot_radius = 3
  )
  expect_true(is_landscape(l_many_spots))
})

test_that("create_landscape_spots handles spot_radius boundary values", {
  # Very small radius
  l_tiny_radius <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 1
  )
  expect_true(is_landscape(l_tiny_radius))

  # Large radius (close to maximum allowed)
  l_large_radius <- create_landscape_spots(
    width = 50,
    height = 50,
    n_spots = 3,
    spot_radius = 24 # Just under min(50, 50) / 2
  )
  expect_true(is_landscape(l_large_radius))
})

test_that("create_landscape_spots handles spot_radius_sd boundary values", {
  set.seed(123)

  # Zero variation (default)
  l_no_variation <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 5,
    spot_radius_sd = 0
  )
  expect_true(is_landscape(l_no_variation))

  # Large variation relative to radius
  l_large_variation <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 5,
    spot_radius_sd = 10
  )
  expect_true(is_landscape(l_large_variation))
})

test_that("create_landscape_spots handles radius_noise_fraction boundary values", {
  set.seed(123)

  # Zero noise (sharp edges)
  l_sharp <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 8,
    radius_noise_fraction = 0
  )
  expect_true(is_landscape(l_sharp))

  # Maximum noise (full radius)
  l_full_noise <- create_landscape_spots(
    width = 30,
    height = 30,
    n_spots = 5,
    spot_radius = 8,
    radius_noise_fraction = 1
  )
  expect_true(is_landscape(l_full_noise))

  # Landscapes should differ
  vals_sharp <- terra::values(l_sharp$data)
  vals_noise <- terra::values(l_full_noise$data)
  expect_false(identical(vals_sharp, vals_noise))
})

test_that("create_landscape_spots handles invert_landscape boundary values", {
  set.seed(123)

  # Normal (bare spots in vegetation)
  l_normal <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 4,
    invert_landscape = FALSE
  )
  expect_true(is_landscape(l_normal))

  set.seed(123)
  # Inverted (vegetation spots in bare ground)
  l_inverted <- create_landscape_spots(
    width = 20,
    height = 20,
    n_spots = 5,
    spot_radius = 4,
    invert_landscape = TRUE
  )
  expect_true(is_landscape(l_inverted))

  # Values should be inverted
  vals_normal <- terra::values(l_normal$data)
  vals_inverted <- terra::values(l_inverted$data)
  expect_equal(sum(vals_normal), sum(1 - vals_inverted))
})

test_that("create_landscape_spots handles regular_spots with extreme parameters", {
  # Very small landscape with regular spots
  expect_warning(
    l_small_regular <- create_landscape_spots(
      width = 10,
      height = 10,
      n_spots = 20,
      spot_radius = 3,
      regular_spots = TRUE
    ),
    "only ~.* positions fit"
  )
  expect_true(is_landscape(l_small_regular))

  # Large landscape with few regular spots
  l_few_regular <- create_landscape_spots(
    width = 100,
    height = 100,
    n_spots = 3,
    spot_radius = 5,
    regular_spots = TRUE
  )
  expect_true(is_landscape(l_few_regular))
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_spots handles multiple edge cases together", {
  set.seed(456)

  # Small landscape + many spots + large radius + variation + noise + invert
  l_extreme <- create_landscape_spots(
    width = 15,
    height = 15,
    n_spots = 10,
    spot_radius = 3,
    spot_radius_sd = 1,
    radius_noise_fraction = 0.5,
    invert_landscape = TRUE,
    rotation = 45
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 15)
  expect_equal(terra::nrow(l_extreme$data), 15)
})
