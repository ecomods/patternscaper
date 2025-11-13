set.seed(123)
# Create test fixtures once, outside all tests
landscapes <- create_training_landscapes(
  n = 3,
  patterns = c("banded", "clustered", "labyrinth")
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

# Tests for calculate_landscape_metrics (main function) -----------------------
test_that("calculate_landscape_metrics produces correct output structure", {
  # Calculate once, test multiple aspects
  result <- calculate_landscape_metrics(
    landscapes,
    metrics = c("ai", "lsi"),
    level = "landscape"
  )

  # Test dimensions
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 6) # 3 landscapes × 2 metrics
  expect_equal(unique(result$landscape_id), 1:3)

  # Test column structure
  expected_cols <- c(
    "landscape_id",
    "landscape_name",
    "pattern",
    "level",
    "layer",
    "class",
    "id",
    "metric",
    "value",
    "warnings"
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

test_that("calculate_landscape_metrics handles single landscape", {
  single_landscape <- landscapes[[1]]

  result <- calculate_landscape_metrics(
    single_landscape,
    metrics = "ai",
    level = "landscape"
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$landscape_id, 1)
})

test_that("calculate_landscape_metrics works with different levels", {
  # Test landscape level
  result_landscape <- calculate_landscape_metrics(
    landscapes,
    metrics = "ai",
    level = "landscape"
  )

  expect_equal(unique(result_landscape$level), "landscape")
  expect_equal(nrow(result_landscape), 3)

  # Test class level
  result_class <- calculate_landscape_metrics(
    landscapes,
    metrics = "ai",
    level = "class"
  )

  expect_equal(unique(result_class$level), "class")
  expect_gt(nrow(result_class), 3) # Should have more rows due to multiple classes

  # Test patch level
  result_patch <- calculate_landscape_metrics(
    landscapes,
    level = "patch"
  )

  expect_equal(unique(result_patch$level), "patch")
  expect_gt(nrow(result_patch), nrow(result_class)) # Should have even more rows due to individual patches
})

test_that("calculate_landscape_metrics validates inputs correctly", {
  # Invalid level
  expect_error(
    calculate_landscape_metrics(landscapes, level = "invalid"),
    "Invalid level"
  )

  # Multiple levels should error (function only accepts single level)
  expect_error(
    calculate_landscape_metrics(landscapes, level = c("class", "landscape")),
    "Invalid level"
  )

  # Invalid metrics (should warn and continue with valid ones)
  expect_warning(
    calculate_landscape_metrics(
      landscapes,
      metrics = c("ai", "fake_metric"),
      level = "landscape"
    ),
    "not found and will be ignored"
  )

  # All invalid metrics
  expect_error(
    calculate_landscape_metrics(
      landscapes,
      metrics = c("fake1", "fake2"),
      level = "landscape"
    ),
    "No valid metrics selected"
  )
})

test_that("calculate_landscape_metrics validates landscape objects", {
  # Invalid landscape object
  not_a_landscape <- list(data = "not a raster")
  expect_error(
    calculate_landscape_metrics(not_a_landscape),
    "must be landscape objects"
  )

  # Mixed valid/invalid landscape list
  expect_error(
    calculate_landscape_metrics(list(landscapes[[1]], not_a_landscape)),
    "Invalid element\\(s\\) at index\\(es\\): 2"
  )
})

test_that("calculate_landscape_metrics handles NULL metrics parameter", {
  # Should calculate all available metrics at specified level
  result <- calculate_landscape_metrics(
    landscapes[[1]],
    metrics = NULL,
    level = "landscape"
  )

  expect_gt(nrow(result), 1) # Should have multiple metrics
  expect_true("warnings" %in% names(result))
})
