# Basic functionality tests ---------------------------------------------------
test_that("create_landscape_clusters creates matrix with correct dimensions", {
  # Default parameters
  landscape <- create_landscape_clusters()
  expect_equal(dim(landscape), c(100, 100))

  # Custom dimensions
  landscape_custom <- create_landscape_clusters(width = 50, height = 75)
  expect_equal(dim(landscape_custom), c(75, 50))
})

test_that("create_landscape_clusters creates binary matrix", {
  landscape <- create_landscape_clusters()
  expect_true(all(landscape %in% c(0, 1)))
})

# Parameter validation tests ------------------------------------------------
test_that("create_landscape_clusters validates input parameters", {
  # Invalid width
  expect_error(create_landscape_clusters(width = -10), "width")
  expect_error(create_landscape_clusters(width = "invalid"), "width")

  # Invalid height
  expect_error(create_landscape_clusters(height = 0), "height")

  # Invalid treeline position
  expect_error(
    create_landscape_clusters(treeline_position = -0.1),
    "treeline_position"
  )
  expect_error(
    create_landscape_clusters(treeline_position = 1.2),
    "treeline_position"
  )

  # Invalid cluster parameters
  expect_error(create_landscape_clusters(num_clusters = 0), "num_clusters")
  expect_error(create_landscape_clusters(cluster_radius = -5), "cluster_radius")

  # Invalid elongation
  expect_error(create_landscape_clusters(elongation_x = 0), "elongation_x")
  expect_error(create_landscape_clusters(elongation_y = -1), "elongation_y")

  # Invalid seed
  expect_error(create_landscape_clusters(seed = 1.5), "seed")
})

# Rotation tests ------------------------------------------------
test_that("rotation preserves matrix dimensions", {
  # With rotation
  landscape_rotated <- create_landscape_clusters(
    width = 60,
    height = 80,
    rotation = 45,
    seed = 123
  )
  expect_equal(dim(landscape_rotated), c(80, 60))

  # Different rotation angle
  landscape_rotated2 <- create_landscape_clusters(
    width = 60,
    height = 80,
    rotation = 30,
    seed = 123
  )
  expect_equal(dim(landscape_rotated2), c(80, 60))
})

# Cluster property tests ------------------------------------------------
test_that("clusters are created with requested parameters", {
  # Many small clusters
  landscape_many <- create_landscape_clusters(
    num_clusters = 20,
    cluster_radius = 3,
    seed = 123
  )

  # Few large clusters
  landscape_few <- create_landscape_clusters(
    num_clusters = 3,
    cluster_radius = 15,
    seed = 123
  )

  # The many small clusters should have more distinct clumps
  # and fewer total cells than few large clusters
  expect_true(
    sum(landscape_many) < sum(landscape_few),
    info = "Expected fewer total forest cells with many small clusters"
  )
})

test_that("elongation parameters affect cluster shape", {
  # Create elongated clusters in x direction
  landscape_x <- create_landscape_clusters(
    num_clusters = 5,
    cluster_radius = 10,
    elongation_x = 2.0,
    elongation_y = 0.5,
    seed = 123
  )

  # Create elongated clusters in y direction
  landscape_y <- create_landscape_clusters(
    num_clusters = 5,
    cluster_radius = 10,
    elongation_x = 0.5,
    elongation_y = 2.0,
    seed = 123
  )

  # Different distributions should produce different landscapes
  expect_false(identical(landscape_x, landscape_y))
})

# Reproducibility tests ------------------------------------------------
test_that("seed parameter ensures reproducibility", {
  # Create two landscapes with same seed
  landscape1 <- create_landscape_clusters(seed = 42)
  landscape2 <- create_landscape_clusters(seed = 42)

  # Create landscape with different seed
  landscape3 <- create_landscape_clusters(seed = 123)

  # Same seed should produce identical landscapes
  expect_identical(landscape1, landscape2)

  # Different seeds should produce different landscapes
  expect_false(identical(landscape1, landscape3))
})

# Edge-case tests ------------------------------------------------
test_that("edge case handling works correctly", {
  # Very high treeline position with small scatter zone
  expect_warning(
    create_landscape_clusters(
      treeline_position = 0.95,
      scatter_zone_prop = 0.05
    ),
    "Scatter zone too small"
  )

  # Single cluster
  landscape_single <- create_landscape_clusters(num_clusters = 1)
  expect_true(sum(landscape_single) > 0)

  # Very large cluster radius
  landscape_large <- create_landscape_clusters(cluster_radius = 40)
  expect_true(sum(landscape_large) > 0)
})
