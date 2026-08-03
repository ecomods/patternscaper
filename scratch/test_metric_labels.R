## Manual testing script for plot_metrics(metric_labels = ...)
## Run interactively in the console; inspect plots in the Plots pane
## or via ggsave() at different sizes to see how element_textbox_simple()
## adapts to the rendered facet width.

library(ggplot2)

# --- 1. Baseline: default (abbreviation) behaviour is unchanged ------------
p_abbrev <- plot_metrics(
  test_metrics_landscape,
  selected_metrics = c("ai", "lsi")
)
p_abbrev

# --- 2. Full names, wide panels (few metrics -> plenty of horizontal room) -
p_name_wide <- plot_metrics(
  test_metrics_landscape,
  selected_metrics = c("enn_mn", "cohesion"),
  metric_labels = "name"
)
p_name_wide

# --- 3. Full names, narrow panels (many metrics -> 4 columns) --------------
p_name_narrow <- plot_metrics(
  test_metrics_landscape,
  selected_metrics = many_metrics,
  metric_labels = "name",
  force = TRUE
)
p_name_narrow

# --- 4. Class-level metrics: full names + "(class N)" disambiguation -------
p_name_class <- plot_metrics(
  test_metrics_class,
  selected_metrics = c("ai_0", "ai_1", "lsi_0", "lsi_1"),
  metric_labels = "name"
)
p_name_class

# --- 5. Compare small vs large render sizes for the narrow-panel case ------
# At small sizes, wrapped 2-line strip labels can visually clip into the
# panel below (ggplot2's facet_wrap() strip row height doesn't auto-grow).
# At larger, more realistic figure sizes this resolves itself.
ggsave("scratch/narrow_small.png", p_name_narrow, width = 6, height = 5, dpi = 120)
ggsave("scratch/narrow_large.png", p_name_narrow, width = 10, height = 9, dpi = 120)

# --- 6. Invalid metric_labels value raises a clear error -------------------
tryCatch(
  plot_metrics(test_metrics_landscape, selected_metrics = "ai", metric_labels = "full"),
  error = function(e) message("Caught expected error: ", conditionMessage(e))
)

# --- 7. Metric with no match in list_lsm() falls back to abbreviation ------
fake_metrics <- test_metrics_landscape
fake_metrics$metric[fake_metrics$metric == "ai"] <- "not_a_real_metric"
fake_metrics$metric_name[fake_metrics$metric_name == "ai"] <- "not_a_real_metric"

p_fallback <- plot_metrics(
  fake_metrics,
  selected_metrics = c("not_a_real_metric", "lsi"),
  metric_labels = "name"
)
p_fallback
