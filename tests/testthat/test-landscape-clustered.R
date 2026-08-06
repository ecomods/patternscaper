# Validation tests ------------------------------------------------------------

test_that("clustered trees validates n_clusters parameter", {
  expect_error(
    create_landscape_clustered(n_clusters = -5),
    "`n_clusters` must be a positive number",
    info = "Testing clustered with negative n_clusters"
  )

  expect_error(
    create_landscape_clustered(n_clusters = 0),
    "`n_clusters` must be a positive number",
    info = "Testing clustered with zero n_clusters"
  )
})

test_that("clustered trees validates cluster_radius parameter", {
  expect_error(
    create_landscape_clustered(cluster_radius = "5"),
    "must be a positive number",
    info = "Testing clustered with non-numeric cluster_radius"
  )

  expect_error(
    create_landscape_clustered(cluster_radius = -3),
    "must be a positive number",
    info = "Testing clustered with negative cluster_radius"
  )

  expect_error(
    create_landscape_clustered(cluster_radius = 0),
    "must be a positive number",
    info = "Testing clustered with zero cluster_radius"
  )
})

test_that("clustered trees validates scatter_zone_prop parameter", {
  expect_error(
    create_landscape_clustered(scatter_zone_prop = "0.3"),
    "must be between 0 and 1",
    info = "Testing clustered with non-numeric scatter_zone_prop"
  )

  expect_error(
    create_landscape_clustered(scatter_zone_prop = -0.1),
    "must be between 0 and 1",
    info = "Testing clustered with negative scatter_zone_prop"
  )

  expect_error(
    create_landscape_clustered(scatter_zone_prop = 0),
    "must be between 0 and 1",
    info = "Testing clustered with zero scatter_zone_prop"
  )

  expect_error(
    create_landscape_clustered(scatter_zone_prop = 1.5),
    "must be between 0 and 1",
    info = "Testing clustered with scatter_zone_prop > 1"
  )
})

test_that("clustered trees validates elongation_x parameter", {
  expect_error(
    create_landscape_clustered(elongation_x = "1.5"),
    "must be a positive number",
    info = "Testing clustered with non-numeric elongation_x"
  )

  expect_error(
    create_landscape_clustered(elongation_x = -2),
    "must be a positive number",
    info = "Testing clustered with negative elongation_x"
  )

  expect_error(
    create_landscape_clustered(elongation_x = 0),
    "must be a positive number",
    info = "Testing clustered with zero elongation_x"
  )
})

test_that("clustered trees validates elongation_y parameter", {
  expect_error(
    create_landscape_clustered(elongation_y = "1.5"),
    "must be a positive number",
    info = "Testing clustered with non-numeric elongation_y"
  )

  expect_error(
    create_landscape_clustered(elongation_y = -2),
    "must be a positive number",
    info = "Testing clustered with negative elongation_y"
  )

  expect_error(
    create_landscape_clustered(elongation_y = 0),
    "must be a positive number",
    info = "Testing clustered with zero elongation_y"
  )
})

test_that("clustered trees validates cluster placement", {
  # Cluster radius too large for scatter zone
  expect_error(
    create_landscape_clustered(
      width = 20,
      height = 20,
      boundary_position = 0.8,
      scatter_zone_prop = 0.1,
      cluster_radius = 10
    ),
    "Scatter zone too small for cluster size"
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_clustered creates clusters in scatter zone", {
  set.seed(123)

  l <- create_landscape_clustered(
    width = 30,
    height = 30,
    boundary_position = 0.4,
    n_clusters = 10,
    cluster_radius = 3,
    scatter_zone_prop = 0.4
  )

  expect_true(is_landscape(l))

  # Should have vegetation (1s) in clusters
  vals <- terra::values(l$data)
  expect_true(sum(vals == 1) > 0)

  # Clusters should be below treeline
  mat <- matrix(vals, nrow = 30, ncol = 30)
  treeline_row <- round(30 * 0.4)
  # Check scatter zone has clusters
  scatter_zone <- mat[(treeline_row + 1):30, ]
  expect_true(sum(scatter_zone == 1) > 0)
})

test_that("create_landscape_clustered elongation affects cluster shape", {
  set.seed(123)

  # Horizontal elongation - clusters should be wider than tall
  l_horizontal <- create_landscape_clustered(
    width = 80,
    height = 80,
    boundary_position = 0.2,
    n_clusters = 1,
    cluster_radius = 5,
    elongation_x = 3,
    elongation_y = 1,
    scatter_zone_prop = 0.6
  )

  # Get cluster dimensions (excluding the treeline area)
  mat_h <- terra::as.matrix(l_horizontal$data, wide = TRUE)
  treeline_row_h <- round(80 * 0.2)

  # Only look at vegetation below the treeline (where cluster is)
  cluster_area_h <- mat_h[(treeline_row_h + 1):80, ]
  veg_coords_h <- which(cluster_area_h == 1, arr.ind = TRUE)

  # Measure spread in each dimension
  width_spread <- diff(range(veg_coords_h[, "col"]))
  height_spread <- diff(range(veg_coords_h[, "row"]))

  # Horizontal elongation: width should be > height
  expect_true(width_spread > height_spread)

  # Vertical elongation - clusters should be taller than wide
  set.seed(456)
  l_vertical <- create_landscape_clustered(
    width = 80,
    height = 80,
    boundary_position = 0.2,
    n_clusters = 1,
    cluster_radius = 5,
    elongation_x = 1,
    elongation_y = 3,
    scatter_zone_prop = 0.8
  )

  # Get cluster dimensions (excluding treeline area)
  mat_v <- terra::as.matrix(l_vertical$data, wide = TRUE)
  treeline_row_v <- round(80 * 0.2)

  # Only look at vegetation below the treeline (where cluster is)
  cluster_area_v <- mat_v[(treeline_row_v + 1):80, ]
  veg_coords_v <- which(cluster_area_v == 1, arr.ind = TRUE)

  width_spread_v <- diff(range(veg_coords_v[, "col"]))
  height_spread_v <- diff(range(veg_coords_v[, "row"]))

  # Vertical elongation: height should be > width
  expect_true(height_spread_v > width_spread_v)
})

test_that("create_landscape_clustered stores all params correctly", {
  l <- create_landscape_clustered(
    width = 30,
    height = 40,
    boundary_position = 0.6,
    noise_veg_to_bare = 0.1,
    noise_bare_to_veg = 0.05,
    n_clusters = 15,
    cluster_radius = 4,
    scatter_zone_prop = 0.35,
    elongation_x = 1.5,
    elongation_y = 2.0,
    rotation = 45
  )

  expect_equal(l$params$width, 30)
  expect_equal(l$params$height, 40)
  expect_equal(l$params$boundary_position, 0.6)
  expect_equal(l$params$noise_veg_to_bare, 0.1)
  expect_equal(l$params$noise_bare_to_veg, 0.05)
  expect_equal(l$params$n_clusters, 15)
  expect_equal(l$params$cluster_radius, 4)
  expect_equal(l$params$scatter_zone_prop, 0.35)
  expect_equal(l$params$elongation_x, 1.5)
  expect_equal(l$params$elongation_y, 2.0)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape_clustered handles n_clusters as decimal", {
  # Should convert 2.7 to 2
  l <- create_landscape_clustered(
    width = 50,
    height = 50,
    n_clusters = 2.7
  )

  expect_true(is_landscape(l))
  expect_equal(l$params$n_clusters, 2)
})

test_that("create_landscape_clustered produces reproducible results with seed", {
  set.seed(456)
  l1 <- create_landscape_clustered(
    width = 25,
    height = 25,
    n_clusters = 2,
    cluster_radius = 2
  )

  set.seed(456)
  l2 <- create_landscape_clustered(
    width = 25,
    height = 25,
    n_clusters = 2,
    cluster_radius = 2
  )

  vals1 <- terra::values(l1$data)
  vals2 <- terra::values(l2$data)
  expect_identical(vals1, vals2)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_clustered handles single cluster", {
  l_single <- create_landscape_clustered(
    width = 50,
    height = 50,
    n_clusters = 1,
    cluster_radius = 5
  )
  expect_true(is_landscape(l_single))
})

test_that("create_landscape_clustered handles very small radius", {
  l_small <- create_landscape_clustered(
    width = 20,
    height = 20,
    n_clusters = 5,
    cluster_radius = 1
  )
  expect_true(is_landscape(l_small))
})

test_that("create_landscape_clustered handles large number of clusters", {
  l_many <- create_landscape_clustered(
    width = 100,
    height = 100,
    n_clusters = 50,
    cluster_radius = 2,
    scatter_zone_prop = 0.8
  )
  expect_true(is_landscape(l_many))
})

test_that("create_landscape_clustered handles large cluster radius", {
  l_large <- create_landscape_clustered(
    width = 100,
    height = 100,
    n_clusters = 2,
    cluster_radius = 15,
    scatter_zone_prop = 0.7
  )
  expect_true(is_landscape(l_large))
})

test_that("create_landscape_clustered handles extreme elongation", {
  # Very horizontal
  l_horizontal <- create_landscape_clustered(
    width = 100,
    height = 100,
    n_clusters = 3,
    cluster_radius = 5,
    elongation_x = 10,
    elongation_y = 1
  )
  expect_true(is_landscape(l_horizontal))

  # Very vertical
  l_vertical <- create_landscape_clustered(
    width = 150,
    height = 150,
    n_clusters = 3,
    scatter_zone_prop = 0.9,
    cluster_radius = 5,
    elongation_x = 1,
    elongation_y = 10
  )
  expect_true(is_landscape(l_vertical))
})

test_that("create_landscape_clustered handles very small scatter zone", {
  l_small_zone <- create_landscape_clustered(
    width = 100,
    height = 100,
    boundary_position = 0.9,
    scatter_zone_prop = 0.05,
    n_clusters = 2,
    cluster_radius = 2
  )
  expect_true(is_landscape(l_small_zone))
})

test_that("create_landscape_clustered handles very large scatter zone", {
  l_large_zone <- create_landscape_clustered(
    width = 100,
    height = 100,
    boundary_position = 0.1,
    scatter_zone_prop = 0.99,
    n_clusters = 10,
    cluster_radius = 5
  )
  expect_true(is_landscape(l_large_zone))
})
