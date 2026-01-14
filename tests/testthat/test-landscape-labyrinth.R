# Validation tests --------------------------------------------------------

test_that("create_landscape_labyrinth validates band_fuzziness range", {
  # Should reject values > 0.5
  expect_error(
    create_landscape_labyrinth(
      width = 50,
      height = 50,
      band_fuzziness = 0.6
    ),
    "must be between 0 and 0.5"
  )

  # Should accept 0.5 (boundary)
  l <- create_landscape_labyrinth(
    width = 50,
    height = 50,
    band_fuzziness = 0.5
  )
  expect_true(is_landscape(l))
})

test_that("create_landscape_labyrinth rejects rotation parameter", {
  expect_error(
    create_landscape_labyrinth(
      width = 50,
      height = 50,
      rotation = 45
    ),
    "unused argument"
  )
})


# Functionality tests ------------------------------------------------------

test_that("create_landscape_labyrinth veg_threshold affects vegetation proportion", {
  set.seed(123)

  # Low threshold = more vegetation
  l_dense <- create_landscape_labyrinth(
    width = 100,
    height = 100,
    veg_threshold = 0.3,
    band_fuzziness = 0.1
  )

  # High threshold = less vegetation
  l_sparse <- create_landscape_labyrinth(
    width = 100,
    height = 100,
    veg_threshold = 0.6,
    band_fuzziness = 0.1
  )

  vals_dense <- terra::values(l_dense$data)
  vals_sparse <- terra::values(l_sparse$data)

  prop_dense <- sum(vals_dense == 1) / length(vals_dense)
  prop_sparse <- sum(vals_sparse == 1) / length(vals_sparse)

  # Dense should have more vegetation than sparse
  expect_true(prop_dense > prop_sparse)
  expect_true(prop_dense > 0.5)
  expect_true(prop_sparse < 0.5)
})

test_that("create_landscape_labyrinth band_fuzziness affects edges", {
  set.seed(123)

  # Sharp edges (no randomness in edges)
  l_sharp <- create_landscape_labyrinth(
    width = 50,
    height = 50,
    frequency = 5,
    veg_threshold = 0.5,
    band_fuzziness = 0
  )

  # Run again with same seed - should be identical when fuzziness = 0
  set.seed(123)
  l_sharp_repeat <- create_landscape_labyrinth(
    width = 50,
    height = 50,
    frequency = 5,
    veg_threshold = 0.5,
    band_fuzziness = 0
  )

  # With no fuzziness, results should be deterministic
  vals_sharp1 <- terra::values(l_sharp$data)
  vals_sharp2 <- terra::values(l_sharp_repeat$data)
  expect_identical(vals_sharp1, vals_sharp2)

  # Fuzzy edges (has randomness)
  set.seed(123)
  l_fuzzy <- create_landscape_labyrinth(
    width = 50,
    height = 50,
    frequency = 5,
    veg_threshold = 0.5,
    band_fuzziness = 0.2
  )

  expect_true(is_landscape(l_sharp))
  expect_true(is_landscape(l_fuzzy))

  # Different fuzziness should create different patterns
  vals_fuzzy <- terra::values(l_fuzzy$data)
  expect_false(identical(vals_sharp1, vals_fuzzy))

  # Check parameter storage
  expect_equal(l_sharp$params$band_fuzziness, 0)
  expect_equal(l_fuzzy$params$band_fuzziness, 0.2)
})

test_that("create_landscape_labyrinth stores all params correctly", {
  l <- create_landscape_labyrinth(
    width = 75,
    height = 60,
    frequency = 7,
    veg_threshold = 0.55,
    band_fuzziness = 0.15,
    octaves = 4
  )

  expect_equal(l$params$width, 75)
  expect_equal(l$params$height, 60)
  expect_equal(l$params$frequency, 7)
  expect_equal(l$params$veg_threshold, 0.55)
  expect_equal(l$params$band_fuzziness, 0.15)
  expect_equal(l$params$octaves, 4)

  # Should NOT have rotation parameter
  expect_null(l$params$rotation)
})

test_that("create_landscape_labyrinth produces reproducible results with seed", {
  set.seed(456)
  l1 <- create_landscape_labyrinth(
    width = 30,
    height = 30,
    frequency = 5,
    octaves = 3
  )

  set.seed(456)
  l2 <- create_landscape_labyrinth(
    width = 30,
    height = 30,
    frequency = 5,
    octaves = 3
  )

  vals1 <- terra::values(l1$data)
  vals2 <- terra::values(l2$data)
  expect_identical(vals1, vals2)
})

test_that("create_landscape_labyrinth handles octaves as decimal", {
  # Should convert 3.7 to 3
  l <- create_landscape_labyrinth(
    width = 50,
    height = 50,
    octaves = 3.7
  )

  expect_true(is_landscape(l))
  expect_equal(l$params$octaves, 3)
})


# Edge case tests ----------------------------------------------------------

test_that("create_landscape_labyrinth handles edge cases", {
  # Minimum octaves
  l_min_octaves <- create_landscape_labyrinth(
    width = 20,
    height = 20,
    octaves = 1
  )
  expect_true(is_landscape(l_min_octaves))

  # Very low frequency
  l_low_freq <- create_landscape_labyrinth(
    width = 20,
    height = 20,
    frequency = 0.5
  )
  expect_true(is_landscape(l_low_freq))

  # High frequency
  l_high_freq <- create_landscape_labyrinth(
    width = 20,
    height = 20,
    frequency = 20
  )
  expect_true(is_landscape(l_high_freq))
})


# Integration tests --------------------------------------------------------

# (No integration tests for labyrinth - doesn't support rotation or 
# complex parameter combinations that would be tested here)
