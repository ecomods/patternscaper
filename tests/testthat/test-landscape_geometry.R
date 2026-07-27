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
