# Tests for create_landscape() wrapper function -------------------------------

# Validation tests ------------------------------------------------------------

test_that("create_landscape validates pattern input", {
  # Invalid type - not a character
  expect_error(
    create_landscape(123),
    "'pattern' must be a single character string"
  )

  # Multiple patterns provided
  expect_error(
    create_landscape(c("sharp", "diffuse")),
    "'pattern' must be a single character string"
  )

  # Invalid pattern name
  expect_error(
    create_landscape("invalid_pattern"),
    "Invalid pattern"
  )
})

test_that("create_landscape propagates errors from underlying functions", {
  # For example, invalid parameters should cause errors
  expect_error(
    create_landscape("sharp", width = -10, height = 50)
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape creates correct landscape types", {
  set.seed(123)
  # Test each pattern creates the correct pattern
  expect_equal(
    create_landscape("random", width = 10, height = 10)$pattern,
    "random"
  )
  expect_equal(
    create_landscape("sharp", width = 10, height = 10)$pattern,
    "sharp"
  )
  expect_equal(
    create_landscape("diffuse", width = 10, height = 10)$pattern,
    "diffuse"
  )
  expect_equal(
    create_landscape("curvy", width = 10, height = 10)$pattern,
    "curvy"
  )
  expect_equal(
    create_landscape("fingers", width = 10, height = 10)$pattern,
    "fingers"
  )
  expect_equal(
    create_landscape(
      "clustered",
      width = 10,
      height = 10,
      cluster_radius = 1
    )$pattern,
    "clustered"
  )
  expect_equal(
    create_landscape("bands", width = 10, height = 10)$pattern,
    "bands"
  )
  expect_equal(
    create_landscape("spots", width = 10, height = 10, spot_radius = 1)$pattern,
    "spots"
  )
  expect_equal(
    create_landscape("gaps", width = 10, height = 10, spot_radius = 1)$pattern,
    "gaps"
  )
  expect_equal(
    create_landscape("stripes", width = 10, height = 10)$pattern,
    "stripes"
  )
  expect_equal(
    create_landscape("labyrinth", width = 10, height = 10)$pattern,
    "labyrinth"
  )
})

test_that("create_landscape passes parameters correctly", {
  # Test that custom parameters are passed through
  l <- create_landscape(
    "sharp",
    width = 30,
    height = 40,
    treeline_position = 0.7
  )

  expect_equal(terra::ncol(l$data), 30)
  expect_equal(terra::nrow(l$data), 40)
  expect_equal(l$params$treeline_position, 0.7)

  # Test that name parameter is set correctly
  l_named <- create_landscape(
    "sharp",
    width = 30,
    height = 40,
    name = "my_landscape"
  )

  expect_equal(l_named$name, "my_landscape")

  # Test that name is NULL when not provided
  expect_true(is.na(l$name) || is.null(l$name))
})

test_that("create_landscape returns valid landscape objects", {
  # Test a few different patterns
  patterns_to_test <- c("random", "sharp", "diffuse", "bands")

  for (pattern in patterns_to_test) {
    l <- create_landscape(pattern, width = 20, height = 20)

    expect_true(is_landscape(l), label = paste("Pattern:", pattern))
    expect_s3_class(l, "landscape")
    expect_s4_class(l$data, "SpatRaster")
    expect_true(!is.null(l$params))
  }
})

test_that("create_landscape handles rotation parameter", {
  l <- create_landscape("sharp", width = 50, height = 50, rotation = 45)

  expect_true(is_landscape(l))
  expect_equal(l$params$rotation, 45)
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})
