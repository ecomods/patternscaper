# Title:   Check facet labelling in plot_metrics()
# Date:    2026-08-03
# Author:  Selina Baldauf
# Purpose: Eyeball the new metric_labels / label_wrap_width arguments across the
#          cases that stress the automatic wrap width: few vs many panels,
#          landscape vs class level, and metrics with very long names.

devtools::load_all()

library(tidyverse)
library(patchwork)

# Data ------------------------------------------------------------------------

set.seed(42)
landscapes <- create_landscapes(
  n = 15,
  patterns = c("labyrinth", "spots", "gaps")
)

metrics_landscape <- calculate_metrics(landscapes, level = "landscape")
metrics_class <- calculate_metrics(landscapes, level = "class")

# The longest full names are the ones that expose a bad wrap width
long_names <- c("iji", "enn_mn", "msidi", "pafrac", "pladj", "circle_mn")

### Abbreviations vs full names

plot_metrics(metrics_landscape, selected_metrics = c("ai", "lsi", "ed")) +
  plot_metrics(
    metrics_landscape,
    selected_metrics = c("ai", "lsi", "ed"),
    metric_labels = "name"
  )

### Automatic wrap width across panel counts

# 2 metrics -> 2 columns, 6 -> 3 columns, 12 -> 4 columns. The strips should
# stay readable in all three without setting label_wrap_width by hand.
plot_metrics(
  metrics_landscape,
  selected_metrics = long_names[1:2],
  metric_labels = "name"
)

plot_metrics(
  metrics_landscape,
  selected_metrics = long_names,
  metric_labels = "name"
)

plot_metrics(
  metrics_landscape,
  selected_metrics = c(long_names, "ai", "lsi", "ed", "pd", "np", "contag"),
  metric_labels = "name"
)

### Where the automatic width gives up

# More than 12 metrics means 5+ columns and very little room per panel. This is
# the case the docs tell users to override.
many <- metrics_landscape |>
  distinct(metric) |>
  slice_head(n = 15) |>
  pull(metric)

plot_metrics(
  metrics_landscape,
  selected_metrics = many,
  metric_labels = "name",
  force = TRUE
)

plot_metrics(
  metrics_landscape,
  selected_metrics = many,
  metric_labels = "name",
  label_wrap_width = 12,
  force = TRUE
)

### Class level

# Names should be suffixed with "(class 0)" / "(class 1)" so the two classes are
# distinguishable, and the suffix should not push the label into an extra line
# unnecessarily.
plot_metrics(
  metrics_class,
  selected_metrics = c("ai_0", "ai_1", "pland_0", "pland_1"),
  metric_labels = "name"
)

### Fallback for unknown metrics

# A metric that list_lsm() does not know should warn once and fall back to the
# abbreviation, with the other panels still labelled properly.
fake <- metrics_landscape |>
  mutate(
    metric = if_else(metric == "ai", "made_up_metric", metric),
    metric_name = if_else(metric_name == "ai", "made_up_metric", metric_name)
  )

plot_metrics(
  fake,
  selected_metrics = c("made_up_metric", "lsi"),
  metric_labels = "name"
)

### Errors

# Both should abort with a clear message rather than a dplyr internal error
try(plot_metrics(metrics_landscape, metric_labels = "full"))
try(plot_metrics(
  metrics_class |> select(-metric_name),
  selected_metrics = "ai_1",
  metric_labels = "name"
))
