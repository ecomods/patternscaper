# Test individual landscape creation functions  -------------------------------

test_that("create_landscape_sharp_treeline creates valid landscape object", {
  l <- create_landscape_sharp_treeline(width = 50, height = 50)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "sharp")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_diffuse_treeline creates valid landscape object", {
  l <- create_landscape_diffuse_treeline(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "diffuse")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_curvy_treeline creates valid landscape object", {
  l <- create_landscape_curvy_treeline(width = 50, height = 50)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "curvy")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_random creates valid landscape object", {
  l <- create_landscape_random(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "random")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_scattered_trees creates valid landscape object", {
  l <- create_landscape_scattered_trees(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "scattered")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_clustered_trees creates valid landscape object", {
  l <- create_landscape_clustered_trees(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "clustered")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_fingers creates valid landscape object", {
  l <- create_landscape_fingers(width = 50, height = 50)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "fingers")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_sine_bands creates valid landscape object", {
  l <- create_landscape_sine_bands(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "sine_bands")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_spots creates valid landscape object", {
  l <- create_landscape_spots(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "spots")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_gaps creates valid landscape object", {
  l <- create_landscape_gaps(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "gaps")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_banded creates valid landscape object", {
  l <- create_landscape_banded(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "bands")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("create_landscape_labyrinth creates valid landscape object", {
  l <- create_landscape_labyrinth(width = 50, height = 50, seed = 123)

  expect_true(is_landscape(l))
  expect_s3_class(l, "landscape")
  expect_true(!is.null(l$data))
  expect_s4_class(l$data, "SpatRaster")
  expect_equal(l$class, "labyrinth")
  expect_true(!is.null(l$params))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

# Test that rotation works
test_that("rotation parameter works", {
  l <- create_landscape_sharp_treeline(width = 50, height = 50, rotation = 45)
  expect_true(is_landscape(l))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

# Test create_landscape wrapper function --------------------------------------

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

test_that("create_landscape handles partial matching correctly", {
  # Unambiguous partial match should work with warning
  expect_warning(
    l <- create_landscape("sha", width = 10, height = 10),
    "Partial pattern 'sha' matched to 'sharp'"
  )
  expect_equal(l$class, "sharp")

  # Ambiguous partial match should error
  expect_error(
    create_landscape("s", width = 10, height = 10),
    "Ambiguous pattern"
  )
})

test_that("create_landscape creates correct landscape types", {
  # Test each pattern creates the correct class
  expect_equal(
    create_landscape("random", width = 10, height = 10, seed = 123)$class,
    "random"
  )
  expect_equal(
    create_landscape("sharp", width = 10, height = 10)$class,
    "sharp"
  )
  expect_equal(
    create_landscape("diffuse", width = 10, height = 10, seed = 123)$class,
    "diffuse"
  )
  expect_equal(
    create_landscape("curvy", width = 10, height = 10)$class,
    "curvy"
  )
  expect_equal(
    create_landscape("fingers", width = 10, height = 10)$class,
    "fingers"
  )
  expect_equal(
    create_landscape("scattered", width = 10, height = 10, seed = 123)$class,
    "scattered"
  )
  expect_equal(
    create_landscape("clustered", width = 10, height = 10, seed = 123)$class,
    "clustered"
  )
  expect_equal(
    create_landscape("sine_bands", width = 10, height = 10, seed = 123)$class,
    "sine_bands"
  )
  expect_equal(
    create_landscape("spots", width = 10, height = 10, seed = 123)$class,
    "spots"
  )
  expect_equal(
    create_landscape("gaps", width = 10, height = 10, seed = 123)$class,
    "gaps"
  )
  expect_equal(
    create_landscape("banded", width = 10, height = 10, seed = 123)$class,
    "bands"
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
})

test_that("create_landscape returns valid landscape objects", {
  # Test a few different patterns
  patterns_to_test <- c("random", "sharp", "diffuse", "clustered")

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

test_that("create_landscape propagates errors from underlying functions", {
  # For example, invalid parameters should cause errors
  expect_error(
    create_landscape("sharp", width = -10, height = 50)
  )
})
