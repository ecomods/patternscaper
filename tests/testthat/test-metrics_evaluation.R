# Helper function to create test data
create_test_metrics <- function(
  n_landscapes = 10,
  n_metrics = 5,
  n_patterns = 2
) {
  patterns <- rep(
    c("pattern_A", "pattern_B")[1:n_patterns],
    length.out = n_landscapes
  )

  tibble::tibble(
    landscape_name = paste0(
      "landscape_",
      rep(1:n_landscapes, each = n_metrics)
    ),
    metric = rep(paste0("metric_", 1:n_metrics), times = n_landscapes),
    pattern = rep(patterns, each = n_metrics),
    value = rnorm(n_landscapes * n_metrics, mean = 10, sd = 2),
    level = "landscape"
  )
}

# Add helper for integration tests
create_real_test_metrics <- function(
  n_landscapes = 10,
  patterns = c("banded", "clustered", "labyrinth")
) {
  landscapes <- create_training_landscapes(
    n = n_landscapes,
    patterns = patterns,
    add_rotation = FALSE
  )

  calculate_landscape_metrics(
    landscapes,
    level = "landscape"
  )
}

# 1. INPUT VALIDATION TESTS ----
test_that("evaluate_landscape_metrics validates input correctly", {
  valid_metrics <- create_test_metrics()

  # Invalid data type
  expect_error(
    evaluate_landscape_metrics(metrics = "not_a_dataframe"),
    "metrics must be a data frame or tibble"
  )

  # Missing required columns
  expect_error(
    evaluate_landscape_metrics(metrics = tibble::tibble(a = 1, b = 2)),
    "metrics must contain columns"
  )

  # Invalid metrics_number
  expect_error(
    evaluate_landscape_metrics(valid_metrics, metrics_number = -1),
    "metrics_number must be a positive integer"
  )

  # Invalid method
  expect_error(
    evaluate_landscape_metrics(valid_metrics, method = "invalid_method"),
    "Invalid method"
  )

  # Invalid correlation_threshold
  expect_error(
    evaluate_landscape_metrics(valid_metrics, correlation_threshold = 1.5),
    "correlation_threshold must be a numeric value between 0 and 1"
  )
})

test_that("evaluate_landscape_metrics requires at least 2 patterns", {
  metrics_one_pattern <- create_test_metrics(n_patterns = 1)

  expect_error(
    evaluate_landscape_metrics(metrics_one_pattern),
    "At least two different landscape patterns are required"
  )
})

# 2. BASIC FUNCTIONALITY TESTS ----
test_that("evaluate_landscape_metrics returns expected output format", {
  metrics <- create_test_metrics(n_metrics = 10)

  result <- evaluate_landscape_metrics(metrics, metrics_number = 5)

  expect_type(result, "character")
  expect_length(result, 5)
  expect_true(all(result %in% unique(metrics$metric)))
})

test_that("evaluate_landscape_metrics works with all ranking methods", {
  metrics <- create_test_metrics(n_metrics = 10)

  methods <- c(
    "coeffvar_all",
    "lin_mod_r2",
    "mean_groups",
    "fisher_score",
    "kruskal_p"
  )

  for (method in methods) {
    result <- evaluate_landscape_metrics(
      metrics,
      method = method,
      metrics_number = 5,
      correlation_threshold = 1 # Disable correlation filtering
    )

    expect_type(result, "character")
    expect_length(result, 5)
  }
})

# 3. NA HANDLING TESTS ----
test_that("evaluate_landscape_metrics handles NA values correctly", {
  metrics <- create_test_metrics(n_metrics = 6)
  # Add NAs to two metrics
  metrics$value[metrics$metric == "metric_1"] <- NA
  metrics$value[metrics$metric == "metric_2"] <- NA

  # Should exclude NA metrics by default
  expect_warning(
    result <- evaluate_landscape_metrics(metrics, metrics_number = 5),
    "Excluded.*metrics with NA values"
  )
  expect_true(!any(c("metric_1", "metric_2") %in% result))

  # Should keep NA metrics if specified
  result_with_na <- evaluate_landscape_metrics(
    metrics,
    metrics_number = 5,
    exclude_NA_metrics = FALSE
  )
  expect_type(result_with_na, "character")
})

# 4. METRIC EXCLUSION TESTS ----
test_that("evaluate_landscape_metrics excludes specified metrics", {
  metrics <- create_test_metrics(n_metrics = 10)

  result <- evaluate_landscape_metrics(
    metrics,
    metrics_number = 5,
    exclude_metrics = c("metric_1", "metric_2"),
    correlation_threshold = 1
  )

  expect_true(!any(c("metric_1", "metric_2") %in% result))
})

test_that("evaluate_landscape_metrics fails when all metrics excluded", {
  metrics <- create_test_metrics(n_metrics = 3)

  expect_error(
    evaluate_landscape_metrics(
      metrics,
      exclude_metrics = c("metric_1", "metric_2", "metric_3")
    ),
    "No metrics left after exclusion"
  )
})

# 5. CORRELATION FILTERING TESTS ----
test_that("correlation filtering reduces to uncorrelated metrics if threshold not 1", {
  # Create a table with 4 metrics for 10 landscapes where 2 metrics are exactly the same
  correlated_metrics <- tibble::tibble(
    landscape_name = paste0("landscape_", 1:10),
    pattern = rep(c("A", "B"), each = 5),
    level = "landscape",
    metric_A = rnorm(10),
    metric_B = rnorm(10),
    metric_C = rnorm(10),
    metric_D = metric_A
  )
  # Bring to long format which is expected by the function
  correlated_metrics <- tidyr::pivot_longer(
    correlated_metrics,
    cols = starts_with("metric_"),
    names_to = "metric",
    values_to = "value"
  )

  result <- evaluate_landscape_metrics(
    correlated_metrics,
    metrics_number = 4,
    correlation_threshold = 0.5,
    method = "coeffvar_all"
  )

  # Should filter out highly correlated metrics
  expect_type(result, "character")
  expect_true(length(result) <= 4)

  # If function is run with correlation_threshold = 1, all metrics should be kept
  result_no_filter <- evaluate_landscape_metrics(
    correlated_metrics,
    metrics_number = 4,
    correlation_threshold = 1,
    method = "coeffvar_all"
  )
  expect_length(result_no_filter, 4)
})

# 6. EDGE CASES ----
test_that("evaluate_landscape_metrics handles fewer metrics than requested", {
  metrics <- create_test_metrics(n_metrics = 3)

  expect_warning(
    result <- evaluate_landscape_metrics(metrics, metrics_number = 10),
    "Only 3 metric.*available"
  )

  expect_length(result, 3)
})

test_that("evaluate_landscape_metrics handles single metric", {
  metrics <- create_test_metrics(n_metrics = 1)

  expect_warning(
    result <- evaluate_landscape_metrics(metrics, metrics_number = 5),
    "Only 1 metric available"
  )

  expect_length(result, 1)
})

# 7. RANKING METHOD SPECIFIC TESTS ----
test_that("coefficient of variation ranks high-variance metrics first", {
  # Create wide format first, then pivot
  metrics_wide <- tibble::tibble(
    landscape_name = paste0("landscape_", 1:10),
    pattern = rep(c("A", "B"), each = 5),
    level = "landscape",
    low_var = rep(10, 10), # Very stable
    high_var = seq(1, 20, length.out = 10) # Wide range
  )

  metrics <- tidyr::pivot_longer(
    metrics_wide,
    cols = c(low_var, high_var),
    names_to = "metric",
    values_to = "value"
  )

  result <- evaluate_landscape_metrics(
    metrics,
    metrics_number = 1,
    method = "coeffvar_all",
    correlation_threshold = 1
  )

  expect_equal(result[1], "high_var")
})

test_that("linear model R² ranks discriminative metrics first", {
  # Create wide format with clear pattern separation
  metrics_wide <- tibble::tibble(
    landscape_name = paste0("landscape_", 1:20),
    pattern = rep(c("A", "B"), each = 10),
    level = "landscape",
    discriminative = rep(c(10, 20), each = 10), # Clear pattern difference
    non_discriminative = rnorm(20, mean = 15, sd = 5) # Random noise
  )

  metrics <- tidyr::pivot_longer(
    metrics_wide,
    cols = c(discriminative, non_discriminative),
    names_to = "metric",
    values_to = "value"
  )

  result <- evaluate_landscape_metrics(
    metrics,
    metrics_number = 1,
    method = "lin_mod_r2",
    correlation_threshold = 1
  )

  expect_equal(result[1], "discriminative")
})

# 8. VERBOSE OUTPUT TEST ----
test_that("verbose parameter controls messaging", {
  metrics <- create_test_metrics(n_metrics = 5)

  # With verbose = TRUE, should see info messages
  expect_message(
    evaluate_landscape_metrics(metrics, verbose = TRUE),
    "Ranked metrics"
  )

  # With verbose = FALSE, should not see info messages (except warnings)
  expect_silent(
    suppressWarnings(evaluate_landscape_metrics(metrics, verbose = FALSE))
  )
})

# Integration tests with real data
test_that("evaluate_landscape_metrics works with real landscape data", {
  skip_if_not_installed("landscapemetrics")

  # This is slower but tests real workflow
  real_metrics <- create_real_test_metrics(n_landscapes = 10)

  result <- evaluate_landscape_metrics(
    real_metrics,
    metrics_number = 5,
    method = "coeffvar_all"
  )

  expect_type(result, "character")
  expect_length(result, 5)
  expect_true(all(result %in% unique(real_metrics$metric)))
})

test_that("evaluate_landscape_metrics handles real metric NA patterns", {
  skip_if_not_installed("landscapemetrics")

  real_metrics <- create_real_test_metrics(n_landscapes = 15)

  # Real metrics may have NAs - this tests actual behavior
  result <- evaluate_landscape_metrics(
    real_metrics,
    metrics_number = 10,
    exclude_NA_metrics = TRUE
  )

  expect_type(result, "character")
})
