# Edge case tests for landscape creation functions ----------------------------

# Extreme dimensions ----------------------------------------------------------
test_that("landscape generators handle very small landscapes", {
  generators <- list(
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
# Add diffuse-specific edge cases here when needed

# Pattern-specific edge cases: Curvy treeline ---------------------------------
# Add curvy-specific edge cases here when needed

# Pattern-specific edge cases: Other patterns ---------------------------------
# Add pattern-specific edge cases as needed

# Edge cases for create_training_landscapes ----------------------------------
test_that("create_training_landscapes handles errors gracefully", {
  # Use parameters that might cause errors in some cases
  # The function should handle errors and continue
  landscapes <- create_training_landscapes(
    n = 20,
    width = 20,
    height = 20,
    seed = 123
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
    balance_patterns = TRUE,
    seed = 123
  )

  expect_true(length(landscapes) > 0)

  # Check variety of types
  patterns <- sapply(landscapes, function(x) x$pattern)
  unique_patterns <- unique(patterns)

  # Should have multiple types
  expect_true(length(unique_patterns) > 5)
})
