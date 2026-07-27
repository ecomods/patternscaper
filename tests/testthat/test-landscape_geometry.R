test_that("landscape_geometry reports dimensions, resolution and aspect ratio", {
  # Matrix rows -> raster rows, matrix cols -> raster cols; res is 1x1
  l <- landscape(matrix(1, nrow = 10, ncol = 20))
  g <- landscape_geometry(l)

  expect_s3_class(g, "tbl_df")
  expect_equal(nrow(g), 1)
  expect_equal(g$n_row, 10)
  expect_equal(g$n_col, 20)
  expect_equal(g$cell_size_x, 1)
  expect_equal(g$cell_size_y, 1)
  expect_equal(g$aspect_ratio, 2)
  expect_equal(g$n_na, 0)
})

test_that("landscape_geometry counts NA cells", {
  m <- matrix(1, nrow = 5, ncol = 5)
  m[1, 1] <- NA
  m[2, 3] <- NA
  expect_equal(landscape_geometry(landscape(m))$n_na, 2)
})

test_that("landscape_geometry rejects non-landscape input", {
  expect_error(
    landscape_geometry(matrix(1, 3, 3)),
    "must be a landscape object"
  )
})

test_that("landscapes_geometry returns one row per landscape", {
  landscapes <- list(
    landscape(matrix(1, nrow = 10, ncol = 10)),
    landscape(matrix(1, nrow = 8, ncol = 12)),
    landscape(matrix(1, nrow = 20, ncol = 20))
  )
  g <- landscapes_geometry(landscapes)

  expect_equal(nrow(g), 3)
  expect_equal(g$n_row, c(10, 8, 20))
  expect_equal(g$n_col, c(10, 12, 20))
  expect_equal(g$aspect_ratio, c(1, 1.5, 1))
})

test_that("summarise_training_geometry condenses a homogeneous set", {
  landscapes <- rep(list(landscape(matrix(1, nrow = 40, ncol = 40))), 5)
  s <- summarise_training_geometry(landscapes)

  expect_equal(nrow(s), 1)
  expect_equal(s$n_landscapes, 5)
  expect_equal(s$n_row, 40)
  expect_equal(s$n_col, 40)
  expect_equal(s$cell_size_x, 1)
  expect_true(s$homogeneous)
})

test_that("summarise_training_geometry flags a heterogeneous set", {
  landscapes <- list(
    landscape(matrix(1, nrow = 40, ncol = 40)),
    landscape(matrix(1, nrow = 60, ncol = 60))
  )
  s <- summarise_training_geometry(landscapes)

  expect_false(s$homogeneous)
  expect_equal(s$n_landscapes, 2)
})

test_that("training_geometry_from_metrics summarises the geometry columns", {
  metrics <- tibble::tibble(
    landscape_id = c(1, 1, 2, 2),
    n_row = c(40, 40, 40, 40),
    n_col = c(40, 40, 40, 40),
    cell_size_x = 1,
    cell_size_y = 1,
    n_na = 0,
    metric = c("ai", "lsi", "ai", "lsi"),
    value = 1:4
  )
  s <- training_geometry_from_metrics(metrics)

  expect_equal(s$n_landscapes, 2)
  expect_equal(s$n_row, 40)
  expect_true(s$homogeneous)
})

test_that("training_geometry_from_metrics flags differing resolution", {
  metrics <- tibble::tibble(
    landscape_id = c(1, 2),
    n_row = c(40, 40),
    n_col = c(40, 40),
    cell_size_x = c(1, 30), # same dimensions, different resolution
    cell_size_y = c(1, 30),
    n_na = 0,
    metric = "ai",
    value = 1:2
  )
  expect_false(training_geometry_from_metrics(metrics)$homogeneous)
})

test_that("training_geometry_from_metrics returns NULL without geometry columns", {
  metrics <- tibble::tibble(
    landscape_id = c(1, 2),
    metric = "ai",
    value = 1:2
  )
  expect_null(training_geometry_from_metrics(metrics))
})
