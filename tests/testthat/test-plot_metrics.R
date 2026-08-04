# Test Fixtures (created once) --------------------------------------------

# Create test landscapes (3 patterns for variety)
test_landscapes <- create_landscapes(
  n = 3,
  patterns = c("spots", "clustered", "labyrinth")
)

# Pre-calculate metrics to speed up tests
test_metrics_landscape <- calculate_metrics(
  test_landscapes,
  level = "landscape"
)

test_metrics_class <- calculate_metrics(
  test_landscapes,
  level = "class"
)

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


# Dynamic Limiting (Core Behavior) ----------------------------------------

test_that("plot_metrics limits metrics based on pattern count", {
  # Test with 2 patterns (should allow 12 metrics)
  landscapes_2 <- test_landscapes[1:2]
  metrics_2 <- calculate_metrics(landscapes_2, level = "landscape")

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

# metric_labels ------------------------------------------------------------

test_that("plot_metrics defaults to abbreviation labels", {
  p <- plot_metrics(test_metrics_landscape, selected_metrics = c("ai", "lsi"))

  labels <- p$facet$params$labeller(data.frame(metric = c("ai", "lsi")))
  expect_equal(labels$metric, c("ai", "lsi"))
})

test_that("plot_metrics stops on invalid metric_labels", {
  expect_error(
    plot_metrics(
      test_metrics_landscape,
      selected_metrics = "ai",
      metric_labels = "full"
    ),
    "metric_labels must be one of"
  )
})

test_that("plot_metrics uses full metric names for landscape level", {
  p <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = c("ai", "lsi"),
    metric_labels = "name"
  )

  labels <- p$facet$params$labeller(data.frame(metric = c("ai", "lsi")))
  expect_equal(labels$metric, c("Aggregation index", "Landscape shape index"))
})

test_that("plot_metrics distinguishes the cv/mn/sd triple in facet labels", {
  selected <- c("area_cv", "area_mn", "area_sd")
  p <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = selected,
    metric_labels = "name"
  )

  labels <- p$facet$params$labeller(data.frame(metric = selected))$metric
  expect_equal(
    labels,
    c("Patch area (CV)", "Patch area (mean)", "Patch area (SD)")
  )
})

test_that("plot_metrics uses full metric names with class disambiguation", {
  p <- plot_metrics(
    test_metrics_class,
    selected_metrics = c("ai_0", "ai_1"),
    metric_labels = "name"
  )

  labels <- p$facet$params$labeller(data.frame(metric = c("ai_0", "ai_1")))
  expect_equal(
    labels$metric,
    c("Aggregation index (class 0)", "Aggregation index (class 1)")
  )
})

test_that("plot_metrics warns and falls back to abbreviation for unmatched metrics", {
  # Construct data with a fabricated metric abbreviation not in list_lsm()
  fake_metrics <- test_metrics_landscape
  fake_metrics$metric[fake_metrics$metric == "ai"] <- "not_a_real_metric"
  fake_metrics$metric_name[
    fake_metrics$metric_name == "ai"
  ] <- "not_a_real_metric"

  expect_warning(
    p <- plot_metrics(
      fake_metrics,
      selected_metrics = c("not_a_real_metric", "lsi"),
      metric_labels = "name"
    ),
    "Could not find full name"
  )

  labels <- p$facet$params$labeller(
    data.frame(metric = c("not_a_real_metric", "lsi"))
  )
  expect_equal(labels$metric, c("not_a_real_metric", "Landscape shape index"))
})

test_that("plot_metrics stops when class-level data lacks metric_name", {
  no_metric_name <- test_metrics_class[
    ,
    setdiff(names(test_metrics_class), "metric_name")
  ]

  expect_error(
    plot_metrics(
      no_metric_name,
      selected_metrics = "ai_1",
      metric_labels = "name"
    ),
    "metric_name"
  )

  # Abbreviation labels do not need the column
  expect_no_error(
    plot_metrics(no_metric_name, selected_metrics = "ai_1")
  )
})

test_that("plot_metrics wraps long names automatically", {
  # Enough metrics to force a multi-column grid, so the automatic width applies.
  # "iji" has the longest full name (37 chars) and exceeds the width chosen here.
  p <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = c("ai", "lsi", "cohesion", "iji", "ed", "pd"),
    metric_labels = "name"
  )

  label <- p$facet$params$labeller(data.frame(metric = "iji"))$metric
  expect_true(grepl("\n", label))
})

test_that("plot_metrics stops on invalid label_wrap_width", {
  expect_error(
    plot_metrics(
      test_metrics_landscape,
      selected_metrics = "ai",
      metric_labels = "name",
      label_wrap_width = -1
    ),
    "label_wrap_width must be NULL or a single positive number"
  )

  expect_error(
    plot_metrics(
      test_metrics_landscape,
      selected_metrics = "ai",
      metric_labels = "name",
      label_wrap_width = c(10, 20)
    ),
    "label_wrap_width must be NULL or a single positive number"
  )
})

test_that("plot_metrics respects a user-supplied label_wrap_width", {
  p_narrow <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = "cohesion",
    metric_labels = "name",
    label_wrap_width = 5
  )
  p_wide <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = "cohesion",
    metric_labels = "name",
    label_wrap_width = 100
  )

  label_narrow <- p_narrow$facet$params$labeller(
    data.frame(metric = "cohesion")
  )$metric
  label_wide <- p_wide$facet$params$labeller(
    data.frame(metric = "cohesion")
  )$metric

  # A narrow wrap width should introduce line breaks that a wide one does not
  expect_true(grepl("\n", label_narrow))
  expect_false(grepl("\n", label_wide))
})

# pattern_order -------------------------------------------------------------

test_that("plot_metrics defaults to alphabetical pattern order", {
  p <- plot_metrics(test_metrics_landscape, selected_metrics = "ai")

  expect_equal(
    levels(p$data$pattern),
    sort(unique(test_metrics_landscape$pattern))
  )
})

test_that("plot_metrics respects a user-supplied pattern_order", {
  custom_order <- c("labyrinth", "spots", "clustered")
  p <- plot_metrics(
    test_metrics_landscape,
    selected_metrics = "ai",
    pattern_order = custom_order
  )

  expect_equal(levels(p$data$pattern), custom_order)
})

test_that("plot_metrics stops on non-character pattern_order", {
  expect_error(
    plot_metrics(
      test_metrics_landscape,
      selected_metrics = "ai",
      pattern_order = 1:3
    ),
    "pattern_order must be a character vector"
  )
})

test_that("plot_metrics stops when pattern_order omits a pattern", {
  expect_error(
    plot_metrics(
      test_metrics_landscape,
      selected_metrics = "ai",
      pattern_order = c("spots", "clustered")
    ),
    "pattern_order must contain exactly the patterns"
  )
})

test_that("plot_metrics stops when pattern_order has an unknown pattern", {
  expect_error(
    plot_metrics(
      test_metrics_landscape,
      selected_metrics = "ai",
      pattern_order = c("spots", "clustered", "labyrinth", "bands")
    ),
    "pattern_order must contain exactly the patterns"
  )
})
