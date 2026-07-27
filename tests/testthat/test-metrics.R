set.seed(123)
# Create test fixtures once, outside all tests
landscapes <- create_landscapes(
  n = 3,
  patterns = c("spots", "clustered", "labyrinth")
)

# Tests for calculate_single_metric (internal function) ----------------------
test_that("calculate_single_metric works correctly", {
  # Test that it returns expected structure
  result <- calculate_single_metric(landscapes, "lsm_l_ai")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(unique(result$landscape_id), 1:3)
  expect_true(all(
    c("landscape_id", "landscape_name", "pattern", "warnings") %in%
      names(result)
  ))
  expect_equal(result$metric, rep("ai", 3))
})

test_that("calculate_single_metric captures warnings correctly", {
  # Use a metric that might produce warnings
  result <- calculate_single_metric(landscapes, "lsm_l_iji")

  expect_type(result$warnings, "character")
})

test_that("calculate_single_metric propagates errors", {
  expect_error(
    calculate_single_metric(landscapes, "nonexistent_function"),
    "not found"
  )
})

# Tests for calculate_metrics (main function) -----------------------
test_that("calculate_metrics produces correct output structure", {
  # Calculate once, test multiple aspects
  result <- calculate_metrics(
    landscapes,
    metrics = c("ai", "lsi"),
    level = "landscape"
  )

  # Test dimensions
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 6) # 3 landscapes × 2 metrics
  expect_equal(unique(result$landscape_id), 1:3)

  # Test column structure (metric columns, then per-landscape geometry columns)
  expected_cols <- c(
    "landscape_id",
    "landscape_name",
    "pattern",
    "level",
    "layer",
    "class",
    "metric_name",
    "metric",
    "value",
    "warnings",
    "n_row",
    "n_col",
    "cell_size_x",
    "cell_size_y",
    "n_na"
  )
  expect_equal(names(result), expected_cols)

  # Test metric filtering
  expect_true(all(result$metric %in% c("ai", "lsi")))
  expect_equal(length(unique(result$metric)), 2)

  # Test metadata preservation
  expect_equal(
    sort(unique(result$landscape_name)),
    sort(vapply(
      landscapes,
      function(x) x$name,
      character(1),
      USE.NAMES = FALSE
    ))
  )
  expect_equal(
    sort(unique(result$pattern)),
    sort(vapply(
      landscapes,
      function(x) x$pattern,
      character(1),
      USE.NAMES = FALSE
    ))
  )
})

test_that("calculate_metrics attaches per-landscape geometry that survives write_csv", {
  m1 <- matrix(rbinom(10 * 20, 1, 0.5), nrow = 10, ncol = 20)
  m2 <- matrix(rbinom(15 * 15, 1, 0.5), nrow = 15, ncol = 15)
  m2[1, 1] <- NA
  geom_landscapes <- list(
    landscape(m1, pattern = "a", name = "a1"),
    landscape(m2, pattern = "b", name = "b1")
  )

  result <- calculate_metrics(geom_landscapes, metrics = "ai", level = "landscape")

  # One geometry record per landscape, with correct values
  geom <- dplyr::distinct(
    result,
    landscape_id,
    n_row,
    n_col,
    cell_size_x,
    cell_size_y,
    n_na
  )
  expect_equal(geom$n_row, c(10, 15))
  expect_equal(geom$n_col, c(20, 15))
  expect_equal(geom$cell_size_x, c(1, 1))
  expect_equal(geom$cell_size_y, c(1, 1))
  expect_equal(geom$n_na, c(0, 1))

  # Geometry must survive a CSV round-trip -- the reason it is columns, not an
  # attribute (attributes are lost by write_csv and by dplyr verbs).
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  readr::write_csv(result, path)
  restored <- readr::read_csv(path, show_col_types = FALSE)

  expect_true(all(
    c("n_row", "n_col", "cell_size_x", "cell_size_y", "n_na") %in%
      names(restored)
  ))
  expect_true(all(restored$n_row == result$n_row))
  expect_true(all(restored$n_col == result$n_col))
})

test_that("calculate_metrics handles single landscape", {
  single_landscape <- landscapes[[1]]

  result <- calculate_metrics(
    single_landscape,
    metrics = "ai",
    level = "landscape"
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$landscape_id, 1)
})

test_that("calculate_metrics works with different levels", {
  # Test landscape level
  result_landscape <- calculate_metrics(
    landscapes,
    metrics = "ai",
    level = "landscape"
  )

  expect_equal(unique(result_landscape$level), "landscape")
  expect_equal(nrow(result_landscape), 3)

  # Test class level
  result_class <- calculate_metrics(
    landscapes,
    metrics = "ai",
    level = "class"
  )

  expect_equal(unique(result_class$level), "class")
  expect_gt(nrow(result_class), 3) # Should have more rows due to multiple classes
})

test_that("calculate_metrics validates inputs correctly", {
  # Invalid level
  expect_error(
    calculate_metrics(landscapes, level = "invalid"),
    "Invalid level"
  )

  # Multiple levels should error (function only accepts single level)
  expect_error(
    calculate_metrics(landscapes, level = c("class", "landscape")),
    "Invalid level"
  )

  # Invalid metrics (should warn and continue with valid ones)
  expect_warning(
    calculate_metrics(
      landscapes,
      metrics = c("ai", "fake_metric"),
      level = "landscape"
    ),
    "not found and will be ignored"
  )

  # All invalid metrics
  expect_error(
    calculate_metrics(
      landscapes,
      metrics = c("fake1", "fake2"),
      level = "landscape"
    ),
    "No valid metrics selected"
  )
})

test_that("calculate_metrics validates landscape objects", {
  # Invalid landscape object
  not_a_landscape <- list(data = "not a raster")
  expect_error(
    calculate_metrics(not_a_landscape),
    "must be landscape objects"
  )

  # Mixed valid/invalid landscape list
  expect_error(
    calculate_metrics(list(landscapes[[1]], not_a_landscape)),
    "Invalid element\\(s\\) at index\\(es\\): 2"
  )
})

test_that("calculate_metrics handles NULL metrics parameter", {
  # Should calculate all available metrics at specified level
  result <- calculate_metrics(
    landscapes[[1]],
    metrics = NULL,
    level = "landscape"
  )

  expect_gt(nrow(result), 1) # Should have multiple metrics
  expect_true("warnings" %in% names(result))
})
