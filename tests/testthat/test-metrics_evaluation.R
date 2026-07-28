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
  patterns = c("spots", "clustered", "labyrinth")
) {
  landscapes <- create_landscapes(
    n = n_landscapes,
    patterns = patterns,
    rotation = 0
  )

  calculate_metrics(
    landscapes,
    level = "landscape"
  )
}

# 1. INPUT VALIDATION TESTS ----
test_that("evaluate_metrics validates input correctly", {
  valid_metrics <- create_test_metrics()

  # Invalid data type
  expect_error(
    evaluate_metrics(metrics = "not_a_dataframe"),
    "metrics must be a data frame or tibble"
  )

  # Missing required columns
  expect_error(
    evaluate_metrics(metrics = tibble::tibble(a = 1, b = 2)),
    "metrics must contain columns"
  )

  # Invalid metrics_number
  expect_error(
    evaluate_metrics(valid_metrics, metrics_number = -1),
    "metrics_number must be a positive integer"
  )

  # Invalid method
  expect_error(
    evaluate_metrics(valid_metrics, method = "invalid_method"),
    "Invalid method"
  )

  # Invalid correlation_threshold
  expect_error(
    evaluate_metrics(valid_metrics, correlation_threshold = 1.5),
    "correlation_threshold must be a numeric value between 0 and 1"
  )
})

test_that("evaluate_metrics validates the metrics level", {
  # A single unsupported level aborts, naming the offending level
  wrong_level <- create_test_metrics()
  wrong_level$level <- "patch"
  expect_error(
    evaluate_metrics(wrong_level),
    "Currently only metrics at the"
  )

  # Multiple levels abort cleanly, not with R's condition-length error (M4)
  mixed_level <- create_test_metrics()
  mixed_level$level <- rep(
    c("landscape", "class"),
    length.out = nrow(mixed_level)
  )
  expect_error(
    evaluate_metrics(mixed_level),
    "must contain a single"
  )
})

test_that("evaluate_metrics requires at least 2 patterns", {
  metrics_one_pattern <- create_test_metrics(n_patterns = 1)

  expect_error(
    evaluate_metrics(metrics_one_pattern),
    "At least two different landscape patterns are required"
  )
})

# 2. BASIC FUNCTIONALITY TESTS ----
test_that("evaluate_metrics returns expected output format", {
  metrics <- create_test_metrics(n_metrics = 10)

  result <- evaluate_metrics(metrics, metrics_number = 5)

  expect_type(result, "character")
  expect_length(result, 5)
  expect_true(all(result %in% unique(metrics$metric)))
})

test_that("evaluate_metrics works with all ranking methods", {
  metrics <- create_test_metrics(n_metrics = 10)

  methods <- c(
    "coeffvar_all",
    "lin_mod_r2",
    "mean_groups",
    "fisher_score",
    "kruskal_effsize"
  )

  for (method in methods) {
    result <- evaluate_metrics(
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
test_that("evaluate_metrics handles NA values correctly", {
  metrics <- create_test_metrics(n_metrics = 6)
  # Add NAs to two metrics
  metrics$value[metrics$metric == "metric_1"] <- NA
  metrics$value[metrics$metric == "metric_2"] <- NA

  # Should exclude NA metrics by default
  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 5),
    "NA value for at least one landscape"
  )
  expect_true(!any(c("metric_1", "metric_2") %in% result))

  # Should keep NA metrics if specified
  result_with_na <- evaluate_metrics(
    metrics,
    metrics_number = 5,
    exclude_incomplete_metrics = FALSE
  )
  expect_type(result_with_na, "character")
})

test_that("evaluate_metrics drops metrics that are constant across landscapes", {
  metrics <- create_test_metrics(n_metrics = 6)
  metrics$value[metrics$metric == "metric_1"] <- 1

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 5),
    "no variation across landscapes"
  )
  expect_false("metric_1" %in% result)
})

test_that("evaluate_metrics drops metrics that are constant only up to rounding", {
  # Total area behaves like this across equally sized landscapes: constant in
  # every meaningful sense, but floating-point summation leaves a variance
  # around 1e-34, which an exact `== 0` test does not catch. Left in, such a
  # metric is scaled by a near-zero sd and swamps every real predictor.
  metrics <- create_test_metrics(n_metrics = 6)
  constant_rows <- metrics$metric == "metric_1"
  metrics$value[constant_rows] <- 1
  metrics$value[which(constant_rows)[1]] <- 1 + 2e-16

  expect_gt(stats::var(metrics$value[constant_rows]), 0)

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 5),
    "no variation across landscapes"
  )
  expect_false("metric_1" %in% result)
})

test_that("evaluate_metrics excludes metrics missing for some landscapes", {
  metrics <- create_test_metrics(n_metrics = 6)
  # A metric that cannot be calculated for a landscape has no row at all, rather
  # than a row holding an NA value
  metrics <- metrics[
    !(metrics$metric == "metric_1" & metrics$landscape_name == "landscape_1"),
  ]

  expect_warning(
    result <- evaluate_metrics(
      metrics,
      metrics_number = 5,
      correlation_threshold = 1
    ),
    "Not available for all landscapes"
  )
  expect_false("metric_1" %in% result)

  # Should keep incomplete metrics if specified
  result_incomplete <- evaluate_metrics(
    metrics,
    metrics_number = 6,
    correlation_threshold = 1,
    exclude_incomplete_metrics = FALSE
  )
  expect_true("metric_1" %in% result_incomplete)
})

test_that("evaluate_metrics excludes class-level metrics of an absent class", {
  skip_if_not_installed("landscapemetrics")

  set.seed(1)
  size <- 20
  landscapes <- c(
    lapply(1:4, \(i) {
      landscape(
        matrix(rbinom(size^2, 1, 0.4), size, size),
        pattern = "mixed",
        name = paste0("mixed_", i)
      )
    }),
    lapply(1:4, \(i) {
      landscape(
        matrix(1L, size, size),
        pattern = "vegetated",
        name = paste0("vegetated_", i)
      )
    })
  )

  metrics <- calculate_metrics(
    landscapes,
    metrics = c("ai", "pland"),
    level = "class"
  )

  # Class 0 is absent from the vegetated landscapes, so landscapemetrics returns
  # no row for its metrics instead of an NA value
  expect_equal(sum(is.na(metrics$value)), 0)

  expect_warning(
    result <- evaluate_metrics(
      metrics,
      metrics_number = 2,
      correlation_threshold = 1
    ),
    "Not available for all landscapes"
  )
  expect_false(any(c("ai_0", "pland_0") %in% result))
})

# 4. METRIC EXCLUSION TESTS ----
test_that("evaluate_metrics excludes specified metrics", {
  metrics <- create_test_metrics(n_metrics = 10)

  result <- evaluate_metrics(
    metrics,
    metrics_number = 5,
    exclude_metrics = c("metric_1", "metric_2"),
    correlation_threshold = 1
  )

  expect_true(!any(c("metric_1", "metric_2") %in% result))
})

test_that("evaluate_metrics fails when all metrics excluded", {
  metrics <- create_test_metrics(n_metrics = 3)

  expect_error(
    evaluate_metrics(
      metrics,
      exclude_metrics = c("metric_1", "metric_2", "metric_3")
    ),
    "No metrics left after exclusion"
  )
})

# 5. CORRELATION FILTERING TESTS ----
test_that("correlation filtering reduces to uncorrelated metrics if threshold not 1", {
  # Create a table with 4 metrics for 10 landscapes where 2 metrics are exactly the same.
  # Values are positive so that they are on a ratio scale, which "coeffvar_all"
  # requires. Shifting the mean does not change the correlations under test.
  correlated_metrics <- tibble::tibble(
    landscape_name = paste0("landscape_", 1:10),
    pattern = rep(c("A", "B"), each = 5),
    level = "landscape",
    metric_A = rnorm(10, mean = 10, sd = 2),
    metric_B = rnorm(10, mean = 10, sd = 2),
    metric_C = rnorm(10, mean = 10, sd = 2),
    metric_D = metric_A
  )
  # Bring to long format which is expected by the function
  correlated_metrics <- tidyr::pivot_longer(
    correlated_metrics,
    cols = starts_with("metric_"),
    names_to = "metric",
    values_to = "value"
  )

  result <- evaluate_metrics(
    correlated_metrics,
    metrics_number = 4,
    correlation_threshold = 0.5,
    method = "coeffvar_all"
  )

  # Should filter out highly correlated metrics
  expect_type(result, "character")
  expect_true(length(result) <= 4)

  # If function is run with correlation_threshold = 1, all metrics should be kept
  result_no_filter <- evaluate_metrics(
    correlated_metrics,
    metrics_number = 4,
    correlation_threshold = 1,
    method = "coeffvar_all"
  )
  expect_length(result_no_filter, 4)
})

# 6. EDGE CASES ----
test_that("evaluate_metrics handles fewer metrics than requested", {
  metrics <- create_test_metrics(n_metrics = 3)

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 10),
    "Only 3 metric.*available"
  )

  expect_length(result, 3)
})

test_that("evaluate_metrics handles single metric", {
  metrics <- create_test_metrics(n_metrics = 1)

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 5),
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

  result <- evaluate_metrics(
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

  result <- evaluate_metrics(
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
    evaluate_metrics(metrics, verbose = TRUE),
    "Ranked metrics"
  )

  # With verbose = FALSE, should not see info messages (except warnings)
  expect_silent(
    suppressWarnings(evaluate_metrics(metrics, verbose = FALSE))
  )
})

# Integration tests with real data
test_that("evaluate_metrics works with real landscape data", {
  skip_if_not_installed("landscapemetrics")

  # This is slower but tests real workflow
  real_metrics <- create_real_test_metrics(n_landscapes = 10)

  result <- evaluate_metrics(
    real_metrics,
    metrics_number = 5,
    method = "coeffvar_all"
  )

  expect_type(result, "character")
  expect_length(result, 5)
  expect_true(all(result %in% unique(real_metrics$metric)))
})

test_that("evaluate_metrics handles real metric NA patterns", {
  skip_if_not_installed("landscapemetrics")

  real_metrics <- create_real_test_metrics(n_landscapes = 15)

  # Real metrics may have NAs - this tests actual behavior
  result <- evaluate_metrics(
    real_metrics,
    metrics_number = 10,
    exclude_incomplete_metrics = TRUE
  )

  expect_type(result, "character")
})
