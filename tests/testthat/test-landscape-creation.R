# Test each landscape creation function individually

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

# Test that rotation works
test_that("rotation parameter works", {
  l <- create_landscape_sharp_treeline(width = 50, height = 50, rotation = 45)
  expect_true(is_landscape(l))
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})
