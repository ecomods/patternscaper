# Edge case tests for landscape creation functions ----------------------------

# Extreme dimensions ----------------------------------------------------------
test_that("landscape generators handle very small landscapes", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    l <- gen(width = 2, height = 2)

    expect_true(is_landscape(l), info = paste("Testing", name))
    expect_equal(terra::ncol(l$data), 2, info = paste("Testing", name))
    expect_equal(terra::nrow(l$data), 2, info = paste("Testing", name))
  }
})

test_that("landscape generators handle very large landscapes", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    l <- gen(width = 500, height = 500)

    expect_true(is_landscape(l), info = paste("Testing", name))
    expect_equal(terra::ncol(l$data), 500, info = paste("Testing", name))
    expect_equal(terra::nrow(l$data), 500, info = paste("Testing", name))
  }
})

test_that("landscape generators handle non-square landscapes", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    # Without rotation
    l_wide <- gen(width = 100, height = 20)
    l_tall <- gen(width = 20, height = 100)
    # With rotation
    l_wide_rotated <- gen(width = 100, height = 20, rotation = 45)
    l_tall_rotated <- gen(width = 20, height = 100, rotation = 45)

    # Not rotated
    expect_equal(
      terra::ncol(l_wide$data),
      100,
      info = paste("Testing", name, "wide not rotated")
    )
    expect_equal(
      terra::nrow(l_wide$data),
      20,
      info = paste("Testing", name, "wide not rotated")
    )
    expect_equal(
      terra::ncol(l_tall$data),
      20,
      info = paste("Testing", name, "tall not rotated")
    )
    expect_equal(
      terra::nrow(l_tall$data),
      100,
      info = paste("Testing", name, "tall not rotated")
    )
    # Rotated cases
    expect_equal(
      terra::ncol(l_wide_rotated$data),
      20,
      info = paste("Testing", name, "wide rotated")
    )
    expect_equal(
      terra::nrow(l_wide_rotated$data),
      100,
      info = paste("Testing", name, "wide rotated")
    )
    expect_equal(
      terra::ncol(l_tall_rotated$data),
      100,
      info = paste("Testing", name, "tall rotated")
    )
    expect_equal(
      terra::nrow(l_tall_rotated$data),
      20,
      info = paste("Testing", name, "tall rotated")
    )
  }
})

# Extreme rotation angles -----------------------------------------------------
test_that("landscape generators with rotation handle extreme angles", {
  generators_with_rotation <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers
  )

  for (name in names(generators_with_rotation)) {
    gen <- generators_with_rotation[[name]]

    l_0 <- gen(rotation = 0)

    l_360 <- gen(rotation = 360)

    expect_true(is_landscape(l_0), info = paste("Testing", name, "rotation 0"))
    expect_true(
      is_landscape(l_360),
      info = paste("Testing", name, "rotation 360")
    )

    # Dimensions should still match
    expect_equal(terra::ncol(l_360$data), 100, info = paste("Testing", name))
    expect_equal(terra::nrow(l_360$data), 100, info = paste("Testing", name))
  }
})

# Pattern-specific edge cases: Sharp treeline ---------------------------------

# Boundary values for treeline_position --------------------------------------
test_that("create_landscape_sharp_treeline handles treeline_position boundary values", {
  # Exactly 0 creates all 0s
  l_zero <- create_landscape_sharp_treeline(
    width = 20,
    height = 20,
    treeline_position = 0
  )
  vals <- terra::values(l_zero$data)
  expect_true(all(vals == 0))

  # Exactly 1 creates all 1s
  l_one <- create_landscape_sharp_treeline(
    width = 20,
    height = 20,
    treeline_position = 1
  )
  vals <- terra::values(l_one$data)
  expect_true(all(vals == 1))

  # Very close to boundaries
  l_near_zero <- create_landscape_sharp_treeline(treeline_position = 0.001)
  l_near_one <- create_landscape_sharp_treeline(treeline_position = 0.999)

  expect_true(is_landscape(l_near_zero))
  expect_true(is_landscape(l_near_one))
})

# Boundary values for random_spots -------------------------------------------
test_that("create_landscape_sharp_treeline handles random_spots boundary values", {
  # All zeros (no randomness)
  l_no_random <- create_landscape_sharp_treeline(random_spots = c(0, 0))
  expect_true(is_landscape(l_no_random))

  # Maximum randomness
  l_max_random <- create_landscape_sharp_treeline(
    width = 20,
    height = 20,
    random_spots = c(1, 1)
  )
  expect_true(is_landscape(l_max_random))

  # One direction only
  l_flip_1_to_0 <- create_landscape_sharp_treeline(random_spots = c(1, 0))
  l_flip_0_to_1 <- create_landscape_sharp_treeline(random_spots = c(0, 1))

  expect_true(is_landscape(l_flip_1_to_0))
  expect_true(is_landscape(l_flip_0_to_1))
})


# Combined edge cases ---------------------------------------------------------
test_that("create_landscape_sharp_treeline handles multiple edge cases together", {
  # Small landscape + extreme treeline + max random + rotation
  l_extreme <- create_landscape_sharp_treeline(
    width = 5,
    height = 5,
    treeline_position = 0.999,
    random_spots = c(0.5, 0.5),
    rotation = 45
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 5)
  expect_equal(terra::nrow(l_extreme$data), 5)
})

# Pattern-specific edge cases: Diffuse treeline -------------------------------

# Boundary values for treeline_position --------------------------------------
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

# Boundary values for steepness -----------------------------------------------
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

# Combined edge cases ---------------------------------------------------------
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

# Pattern-specific edge cases: Curvy treeline ---------------------------------

# Boundary values for sine_length ---------------------------------------------
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

# Boundary values for sine_height ---------------------------------------------
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

# Combined edge cases ---------------------------------------------------------
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

# Boundary values for sine_length ---------------------------------------------
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

# Boundary values for sine_height ---------------------------------------------
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

# Combined edge cases ---------------------------------------------------------
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

# Pattern-specific edge cases: Curvy fingers treeline -------------------------

# Boundary values for sine_length_mean and sine_length_sd ---------------------
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

# Boundary values for sine_height_mean and sine_height_sd --------------------
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

# Boundary values for treeline_position --------------------------------------
test_that("create_landscape_fingers handles treeline_position boundary values", {
  # Exactly 0 - transition at top
  l_zero <- create_landscape_fingers(
    width = 20,
    height = 20,
    treeline_position = 0,
    sine_height_mean = 2
  )
  expect_true(is_landscape(l_zero))

  # Exactly 1 - transition at bottom
  l_one <- create_landscape_fingers(
    width = 20,
    height = 20,
    treeline_position = 1,
    sine_height_mean = 2
  )
  expect_true(is_landscape(l_one))

  # Very close to boundaries
  l_near_zero <- create_landscape_fingers(treeline_position = 0.001)
  l_near_one <- create_landscape_fingers(treeline_position = 0.999)

  expect_true(is_landscape(l_near_zero))
  expect_true(is_landscape(l_near_one))
})

# Boundary values for random_spots -------------------------------------------
test_that("create_landscape_fingers handles random_spots boundary values", {
  # All zeros (no randomness)
  l_no_random <- create_landscape_fingers(random_spots = c(0, 0))
  expect_true(is_landscape(l_no_random))

  # Maximum randomness
  l_max_random <- create_landscape_fingers(
    width = 20,
    height = 20,
    random_spots = c(1, 1)
  )
  expect_true(is_landscape(l_max_random))

  # One direction only
  l_flip_1_to_0 <- create_landscape_fingers(random_spots = c(1, 0))
  l_flip_0_to_1 <- create_landscape_fingers(random_spots = c(0, 1))

  expect_true(is_landscape(l_flip_1_to_0))
  expect_true(is_landscape(l_flip_0_to_1))
})

# Combined edge cases ---------------------------------------------------------
test_that("create_landscape_fingers handles multiple edge cases together", {
  # Small landscape + extreme treeline + extreme sine params + max random + rotation
  l_extreme <- create_landscape_fingers(
    width = 5,
    height = 5,
    treeline_position = 0.999,
    sine_length_mean = 1,
    sine_length_sd = 2,
    sine_height_mean = 10,
    sine_height_sd = 5,
    random_spots = c(0.5, 0.5),
    rotation = 45
  )

  expect_true(is_landscape(l_extreme))
  expect_equal(terra::ncol(l_extreme$data), 5)
  expect_equal(terra::nrow(l_extreme$data), 5)
})

# Test variability in patterns ------------------------------------------------
test_that("create_landscape_fingers produces varying patterns", {
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

# Edge cases for create_training_landscapes ----------------------------------
test_that("create_training_landscapes handles errors gracefully", {
  set.seed(123)
  # Use parameters that might cause errors in some cases
  # The function should handle errors and continue
  landscapes <- create_training_landscapes(
    n = 20,
    width = 20,
    height = 20
  )

  # Should still return landscapes (possibly fewer than n if some failed)
  expect_true(length(landscapes) > 0)
  expect_true(length(landscapes) <= 20)
})

test_that("create_training_landscapes works with all default landscape patterns", {
  # Test that all types can be generated without errors
  landscapes <- create_training_landscapes(
    n = 24, # 12 types * 2 = 24 for balanced distribution
    width = 20,
    height = 20,
    balance_patterns = TRUE
  )

  expect_true(length(landscapes) > 0)

  # Check variety of types
  patterns <- sapply(landscapes, function(x) x$pattern)
  unique_patterns <- unique(patterns)

  # Should have multiple types
  expect_true(length(unique_patterns) > 5)
})
