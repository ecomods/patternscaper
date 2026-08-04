# Title: Unequal-size landscapes in both classification workflows
# Date: 2026-07-08
# Author: Selina Baldauf
# Purpose: Show that the metrics-based model is size-independent, while the
#   pixel-based model locks to one training size and resizes inputs on apply.

pkgload::load_all(quiet = TRUE)

set.seed(1)
patterns <- c("sharp", "diffuse", "bands", "random")

# Metrics-based: sizes may differ, even within the training pool ---------------

# Two extents mixed in one training pool - the model only sees metric values.
# Rename so the merged pool has unique names (each call numbers from 1).
train_landscapes <- create_landscapes(
  n = 20,
  patterns = patterns,
  width = 100,
  height = 100
)

test_landscapes <- create_landscapes(
  n = 4,
  patterns = patterns,
  width = 50,
  height = 52
)

train_metrics <- calculate_metrics(train_landscapes, level = "landscape")

# A few uncorrelated metrics so the small network converges.
selected <- evaluate_metrics(train_metrics, metrics_number = 5)

metrics_model <- train_metric_model(
  train_metrics,
  metrics_selected = selected,
  cv_method = "none",
  verbose = FALSE
)

# apply_metric_model() takes landscapes and computes their metrics internally.
metrics_pred <- apply_metric_model(test_landscapes, metrics_model)
metrics_pred

# Pixel-based: one size for training, auto-resize on apply ---------------------

pixel_model <- train_pixel_model(
  train_landscapes,
  cv_method = "none",
  epochs = 15,
  verbose = FALSE
)

# Test at two other extents - apply_pixel_model() resizes them to 48x48 first.
pixel_pred <- apply_pixel_model(test_landscapes, pixel_model)

pixel_pred
