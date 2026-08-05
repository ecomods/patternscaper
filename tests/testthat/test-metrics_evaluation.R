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

# Look up what the ranking table recorded for one metric. Asserting on this
# rather than on absence from `selected` is what actually pins down *why* a
# metric was dropped -- absence alone would also hold if it were silently lost.
outcome_of <- function(evaluation, metric_name) {
  as.character(
    evaluation$ranking$outcome[evaluation$ranking$metric == metric_name]
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

  expect_s3_class(result, "metrics_evaluation")
  expect_type(result$selected, "character")
  expect_length(result$selected, 5)
  expect_true(all(result$selected %in% unique(metrics$metric)))
  expect_equal(result$method, "kruskal_effsize")
})

test_that("evaluate_metrics works with all ranking methods", {
  metrics <- create_test_metrics(n_metrics = 10)

  methods <- c(
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

    expect_s3_class(result, "metrics_evaluation")
    expect_length(result$selected, 5)
    expect_equal(result$method, method)
    # The census holds under every method, not just the default
    expect_setequal(result$ranking$metric, unique(metrics$metric))
    expect_false(anyNA(result$ranking$outcome))
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
  expect_equal(outcome_of(result, "metric_1"), "excluded_incomplete")
  expect_equal(outcome_of(result, "metric_2"), "excluded_incomplete")
  expect_false(any(c("metric_1", "metric_2") %in% result$selected))

  # Should keep NA metrics if specified
  result_with_na <- evaluate_metrics(
    metrics,
    metrics_number = 5,
    exclude_incomplete_metrics = FALSE
  )
  expect_type(result_with_na$selected, "character")
})

test_that("evaluate_metrics drops metrics that are constant across landscapes", {
  metrics <- create_test_metrics(n_metrics = 6)
  metrics$value[metrics$metric == "metric_1"] <- 1

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 5),
    "no variation across landscapes"
  )
  expect_equal(outcome_of(result, "metric_1"), "excluded_zero_variance")
  expect_false("metric_1" %in% result$selected)
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
  expect_equal(outcome_of(result, "metric_1"), "excluded_zero_variance")
  expect_false("metric_1" %in% result$selected)
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
  expect_equal(outcome_of(result, "metric_1"), "excluded_incomplete")
  expect_false("metric_1" %in% result$selected)

  # Should keep incomplete metrics if specified
  result_incomplete <- evaluate_metrics(
    metrics,
    metrics_number = 6,
    correlation_threshold = 1,
    exclude_incomplete_metrics = FALSE
  )
  expect_true("metric_1" %in% result_incomplete$selected)
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
  expect_equal(outcome_of(result, "ai_0"), "excluded_incomplete")
  expect_equal(outcome_of(result, "pland_0"), "excluded_incomplete")
  expect_false(any(c("ai_0", "pland_0") %in% result$selected))
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

  expect_equal(outcome_of(result, "metric_1"), "excluded_user")
  expect_equal(outcome_of(result, "metric_2"), "excluded_user")
  expect_false(any(c("metric_1", "metric_2") %in% result$selected))
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
    method = "fisher_score"
  )

  # Should filter out highly correlated metrics
  expect_s3_class(result, "metrics_evaluation")
  expect_true(length(result$selected) <= 4)

  # metric_D duplicates metric_A, so one of the pair must be recorded as
  # correlated and must name the metric it clashed with
  pair <- result$ranking[result$ranking$metric %in% c("metric_A", "metric_D"), ]
  clashing <- pair[
    as.character(pair$outcome) %in%
      c("dropped_correlated", "selected_correlation_fill"),
  ]
  expect_equal(nrow(clashing), 1)
  expect_false(is.na(clashing$correlated_with))

  # If function is run with correlation_threshold = 1, all metrics should be kept
  result_no_filter <- evaluate_metrics(
    correlated_metrics,
    metrics_number = 4,
    correlation_threshold = 1,
    method = "fisher_score"
  )
  expect_length(result_no_filter$selected, 4)
  # No correlation filtering ran, so no correlation outcome is recorded
  expect_false(any(
    as.character(result_no_filter$ranking$outcome) %in%
      c("dropped_correlated", "selected_correlation_fill")
  ))
})

test_that("gap-filled metrics are appended to the end of the selection", {
  # Two correlated pairs: metric_b duplicates metric_a (shifted, so the
  # correlation is 1 but mean_groups differs, since it divides by the group
  # mean), and metric_d duplicates metric_c. Only two metrics can be mutually
  # uncorrelated, so asking for three forces the fill path.
  set.seed(20260730)
  base_a <- rnorm(12, mean = 10, sd = 3)
  base_c <- rnorm(12, mean = 100, sd = 10)

  pairs <- tibble::tibble(
    landscape_name = paste0("landscape_", 1:12),
    pattern = rep(c("A", "B"), each = 6),
    level = "landscape",
    metric_a = base_a,
    metric_b = base_a + 10, # cor 1 with metric_a, lower score
    metric_c = base_c,
    metric_d = base_c + 100 # cor 1 with metric_c, lower score
  ) |>
    tidyr::pivot_longer(
      cols = starts_with("metric_"),
      names_to = "metric",
      values_to = "value"
    )

  expect_warning(
    result <- evaluate_metrics(
      pairs,
      metrics_number = 3,
      method = "mean_groups",
      correlation_threshold = 0.7
    ),
    "Filling to 3 with correlated metrics"
  )

  # metric_d ranks second overall but is only added once the filter runs out
  # of uncorrelated candidates, so it is returned last rather than in rank
  # order. Callers have always seen this order; changing it would silently
  # reorder plot_metrics() facets and the stored golden selection.
  expect_identical(result$selected, c("metric_c", "metric_a", "metric_d"))

  # ...and the ranking records why it was added, and what it clashed with
  expect_equal(outcome_of(result, "metric_d"), "selected_correlation_fill")
  expect_equal(
    result$ranking$correlated_with[result$ranking$metric == "metric_d"],
    "metric_c"
  )
})

# 6. EDGE CASES ----
test_that("evaluate_metrics handles fewer metrics than requested", {
  metrics <- create_test_metrics(n_metrics = 3)

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 10),
    "Only 3 metric.*available"
  )

  expect_length(result$selected, 3)
})

test_that("evaluate_metrics handles single metric", {
  metrics <- create_test_metrics(n_metrics = 1)

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 5),
    "Only 1 metric available"
  )

  expect_length(result$selected, 1)
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

# 9. THE RETURNED OBJECT ----
test_that("the ranking table is a complete census of the input metrics", {
  metrics <- create_test_metrics(n_metrics = 8)
  metrics$value[metrics$metric == "metric_1"] <- NA
  metrics$value[metrics$metric == "metric_2"] <- 1

  suppressWarnings(
    result <- evaluate_metrics(
      metrics,
      metrics_number = 3,
      exclude_metrics = "metric_3"
    )
  )

  # Every metric that went in comes back out, exactly once, with an outcome
  expect_setequal(result$ranking$metric, unique(metrics$metric))
  expect_equal(nrow(result$ranking), dplyr::n_distinct(metrics$metric))
  expect_false(anyNA(result$ranking$outcome))

  # The three pre-ranking exclusion routes stay distinguishable
  expect_equal(outcome_of(result, "metric_1"), "excluded_incomplete")
  expect_equal(outcome_of(result, "metric_2"), "excluded_zero_variance")
  expect_equal(outcome_of(result, "metric_3"), "excluded_user")
})

test_that("the ranking table holds its invariants", {
  metrics <- create_test_metrics(n_metrics = 8)
  metrics$value[metrics$metric == "metric_1"] <- NA

  suppressWarnings(
    result <- evaluate_metrics(metrics, metrics_number = 3)
  )

  ranking <- result$ranking
  outcomes <- as.character(ranking$outcome)

  # the selected flag agrees with $selected
  expect_setequal(ranking$metric[ranking$selected], result$selected)

  # metrics excluded before ranking have no rank; everything else has one
  expect_identical(is.na(ranking$rank), grepl("^excluded_", outcomes))

  # correlated_with is populated for exactly the two correlation outcomes
  expect_identical(
    !is.na(ranking$correlated_with),
    outcomes %in% c("dropped_correlated", "selected_correlation_fill")
  )

  # the selection is capped by the pool that actually got scored
  expect_equal(
    length(result$selected),
    min(3, sum(!is.na(ranking$rank)))
  )
})

test_that("the ranking table reports full metric names", {
  metrics <- create_real_test_metrics(n_landscapes = 6)

  suppressWarnings(
    result <- evaluate_metrics(metrics, metrics_number = 3)
  )

  ranking <- result$ranking
  expect_true("name" %in% names(ranking))
  expect_false(anyNA(ranking$name))

  # Names come from list_lsm(), sentence-cased
  expect_equal(ranking$name[ranking$metric == "ai"], "Aggregation index")
  expect_equal(ranking$name[ranking$metric == "lsi"], "Landscape shape index")

  # list_lsm() gives the _cv/_mn/_sd triple one shared name, so the statistic
  # has to be added or half the ranking would be ambiguous
  expect_equal(ranking$name[ranking$metric == "area_mn"], "Patch area (mean)")
  expect_equal(ranking$name[ranking$metric == "area_sd"], "Patch area (SD)")
  expect_equal(ranking$name[ranking$metric == "area_cv"], "Patch area (CV)")

  # No two metrics may share a label
  expect_equal(length(unique(ranking$name)), nrow(ranking))
})

test_that("the ranking table disambiguates class-level names by class", {
  landscapes <- create_landscapes(
    n = 6,
    patterns = c("spots", "labyrinth"),
    rotation = 0
  )
  metrics <- calculate_metrics(
    landscapes,
    level = "class",
    metrics = c("ai", "pland")
  )

  suppressWarnings(
    result <- evaluate_metrics(metrics, metrics_number = 2)
  )

  ranking <- result$ranking
  expect_equal(
    ranking$name[ranking$metric == "ai_1"],
    "Aggregation index (class 1)"
  )
  expect_equal(
    ranking$name[ranking$metric == "ai_0"],
    "Aggregation index (class 0)"
  )
})

test_that("the ranking table combines statistic and class in one bracket", {
  landscapes <- create_landscapes(
    n = 6,
    patterns = c("spots", "labyrinth"),
    rotation = 0
  )
  metrics <- calculate_metrics(
    landscapes,
    level = "class",
    metrics = c("area_mn", "area_cv")
  )

  suppressWarnings(
    result <- evaluate_metrics(metrics, metrics_number = 2)
  )

  ranking <- result$ranking
  expect_equal(
    ranking$name[ranking$metric == "area_mn_1"],
    "Patch area (mean, class 1)"
  )
  expect_equal(
    ranking$name[ranking$metric == "area_cv_0"],
    "Patch area (CV, class 0)"
  )
})

test_that("the ranking table falls back to the abbreviation without warning", {
  # Synthetic metric names are not in list_lsm(); the name column is supplied
  # unasked, so an unresolvable name must not warn
  metrics <- create_test_metrics(n_metrics = 4)

  expect_no_warning(
    result <- evaluate_metrics(metrics, metrics_number = 2)
  )
  expect_identical(result$ranking$name, result$ranking$metric)
})

test_that("both correlation paths produce a complete census", {
  metrics <- create_test_metrics(n_metrics = 8)

  filtered <- evaluate_metrics(metrics, metrics_number = 3)
  unfiltered <- evaluate_metrics(
    metrics,
    metrics_number = 3,
    correlation_threshold = 1
  )

  # The threshold >= 1 path skips the correlation filter entirely, so it has to
  # record its own outcomes rather than inheriting them
  expect_setequal(filtered$ranking$metric, unique(metrics$metric))
  expect_setequal(unfiltered$ranking$metric, unique(metrics$metric))
  expect_false(anyNA(unfiltered$ranking$outcome))
  expect_setequal(
    as.character(unfiltered$ranking$outcome),
    c("selected", "dropped_below_cutoff")
  )
})

test_that("evaluate_metrics records the parameters that shaped the result", {
  metrics <- create_test_metrics(n_metrics = 6)

  result <- evaluate_metrics(
    metrics,
    metrics_number = 3,
    method = "fisher_score",
    correlation_threshold = 0.9
  )

  expect_equal(result$method, "fisher_score")
  expect_equal(result$params$metrics_number, 3)
  expect_equal(result$params$correlation_threshold, 0.9)
  expect_equal(result$params$level, "landscape")
})

test_that("params records the requested metrics_number, not the achieved one", {
  # Only 3 metrics exist, so the selection is capped at 3 -- but the object
  # should still report that 10 were asked for
  metrics <- create_test_metrics(n_metrics = 3)

  expect_warning(
    result <- evaluate_metrics(metrics, metrics_number = 10),
    "Only 3 metric.*available"
  )

  expect_equal(result$params$metrics_number, 10)
  expect_length(result$selected, 3)
})

test_that("evaluate_metrics is deterministic under row reordering", {
  metrics <- create_test_metrics(n_metrics = 8)

  result <- evaluate_metrics(metrics, metrics_number = 4)
  shuffled <- evaluate_metrics(
    metrics[sample(nrow(metrics)), ],
    metrics_number = 4
  )

  expect_identical(result$selected, shuffled$selected)
  expect_identical(result$ranking$metric, shuffled$ranking$metric)
})

test_that("print.metrics_evaluation summarises to stdout", {
  metrics <- create_test_metrics(n_metrics = 6)
  result <- evaluate_metrics(metrics, metrics_number = 3)

  # expect_output captures stdout, so this also pins that the method does not
  # print via cli, which would go to the message stream instead
  expect_output(print(result), "Metrics evaluation: kruskal_effsize")
  expect_output(print(result), "Selected \\(3\\)")
  expect_output(print(result), "Outcomes:")
  expect_output(print(result), "Use \\$ranking")
  expect_invisible(print(result))
})

test_that("print shows a summary, not the ranking table", {
  metrics <- create_test_metrics(n_metrics = 15)
  result <- evaluate_metrics(
    metrics,
    metrics_number = 14,
    correlation_threshold = 1
  )

  printed <- capture.output(print(result))

  # The whole point is not to dump one line per metric
  expect_false(any(grepl("# A tibble", printed, fixed = TRUE)))
  expect_lt(length(printed), nrow(result$ranking))

  # Long selections are truncated rather than filling the console
  expect_true(any(grepl("and 4 more", printed, fixed = TRUE)))
})

test_that("downstream functions accept the object or a name vector", {
  metrics <- create_test_metrics(n_metrics = 6)
  result <- evaluate_metrics(metrics, metrics_number = 3)

  expect_s3_class(
    plot_metrics(metrics, selected_metrics = result),
    "ggplot"
  )
  expect_s3_class(
    plot_metrics(metrics, selected_metrics = result$selected),
    "ggplot"
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
    method = "fisher_score"
  )

  expect_type(result$selected, "character")
  expect_length(result$selected, 5)
  expect_true(all(result$selected %in% unique(real_metrics$metric)))
  expect_setequal(result$ranking$metric, unique(real_metrics$metric))
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

  expect_type(result$selected, "character")
  expect_setequal(result$ranking$metric, unique(real_metrics$metric))
})
