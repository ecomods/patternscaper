# Test Fixtures (created once) --------------------------------------------

# Create test landscapes (3 patterns for variety)
test_landscapes <- create_training_landscapes(
  n = 3,
  patterns = c("spots", "clustered", "labyrinth")
)

# Pre-calculate metrics to speed up tests
test_metrics_landscape <- calculate_landscape_metrics(
  test_landscapes,
  level = "landscape"
)

test_metrics_class <- calculate_landscape_metrics(
  test_landscapes,
  level = "class"
)

test_metrics_patch <- calculate_landscape_metrics(
  test_landscapes,
  level = "patch"
)

# Core Functionality Tests ------------------------------------------------

test_that("plot_metrics returns a ggplot object", {
  p_landscape <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = c("ai", "lsi")
  )
  p_class <- plot_metrics(test_metrics_class, selected_metrics = c("ai", "lsi"))

  expect_s3_class(p_landscape, "ggplot")
  expect_s3_class(p_class, "ggplot")
})

# Critical Error Handling -------------------------------------------------

test_that("plot_metrics stops on non-data.frame input", {
  expect_error(
    plot_metrics(list(a = 1), selected_metrics = "ai"),
    "metrics must be a data frame"
  )
})

test_that("plot_metrics stops on missing required columns", {
  bad_df <- data.frame(
    pattern = c("labyrinth", "spots"),
    value = c(1, 2)
  )

  expect_error(
    plot_metrics(bad_df, selected_metrics = "ai"),
    "metrics is missing required columns"
  )
})

test_that("plot_metrics stops on multiple levels in data", {
  mixed_metrics <- rbind(test_metrics_landscape, test_metrics_class)

  expect_error(
    plot_metrics(mixed_metrics, selected_metrics = "ai"),
    "metrics contains multiple levels"
  )
})

test_that("plot_metrics stops on patch-level metrics", {
  expect_error(
    plot_metrics(test_metrics_patch, selected_metrics = "area"),
    "Plotting patch-level metrics is not supported"
  )
})

# Dynamic Limiting (Core Behavior) ----------------------------------------

test_that("plot_metrics limits metrics based on pattern count", {
  # Test with 2 patterns (should allow 12 metrics)
  landscapes_2 <- test_landscapes[1:2]
  metrics_2 <- calculate_landscape_metrics(landscapes_2, level = "landscape")

  all_metrics <- unique(metrics_2$metric)
  many_metrics <- all_metrics[1:min(15, length(all_metrics))]

  expect_warning(
    p <- plot_metrics(metrics_2, selected_metrics = many_metrics),
    "limiting to 12"
  )

  expect_equal(length(unique(p$data$metric)), 12)
})

test_that("plot_metrics force = TRUE overrides limits", {
  all_metrics <- unique(test_metrics_landscape$metric)
  many_metrics <- all_metrics[1:min(15, length(all_metrics))]

  p <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = many_metrics,
    force = TRUE
  )

  # Should plot all requested metrics
  expect_equal(length(unique(p$data$metric)), length(many_metrics))
})

# Optional Tests ----------------------------------------------------------

test_that("plot_metrics handles NULL selected_metrics", {
  # Should plot all available metrics (subject to limits)
  p <- plot_metrics(test_metrics_landscape, selected_metrics = NULL)

  expect_s3_class(p, "ggplot")
  expect_true(length(unique(p$data$metric)) > 0)
})

test_that("plot_metrics warns and filters invalid metrics", {
  expect_warning(
    p <- plot_metrics(
      test_metrics_landscape,
      selected_metrics = c("ai", "fake_metric", "lsi")
    ),
    "The following metrics are not in the data and will be ignored"
  )

  # Should still create plot with valid metrics
  expect_s3_class(p, "ggplot")
  expect_equal(length(unique(p$data$metric)), 2)
})

test_that("plot_metrics stops when all selected_metrics are invalid", {
  expect_error(
    suppressWarnings(
      plot_metrics(
        test_metrics_landscape,
        selected_metrics = c("fake1", "fake2")
      )
    ),
    "No valid metrics remaining"
  )
})

test_that("plot_metrics respects selected_metrics parameter", {
  selected <- c("ai", "lsi", "ed")
  p <- plot_metrics(test_metrics_landscape, selected_metrics = selected)

  # Check that plot has correct number of metrics
  expect_equal(length(unique(p$data$metric)), length(selected))
})
