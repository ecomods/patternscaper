# Title: Scale-robust metric selection under extent mismatch
# Date: 2026-07-23
# Author: Selina Baldauf
# Purpose: Compare automatically selected metrics against normalised-only metrics
#   when the application landscapes are four times larger than the training ones.

# Background for this experiment is in
# ../spatPatClassifyR_paper/SCALE_AND_SHAPE.md, section 3.2. It is the
# publication-relevant counterpart to dev/scale_and_shape_demo.R: area-, edge-,
# density- and count-based metrics scale with extent, normalised configuration
# indices do not. Runtime is a few minutes.
#
# Single replicate, cv_method = "none" - indicative only. Promote to the analysis
# repo with replicates before citing any number.

pkgload::load_all(quiet = TRUE)
library(dplyr)

set_random_seed(42)
patterns <- c("sharp", "diffuse", "clustered", "fingers", "bands", "random")

# ta is deliberately left out of the pool: it is constant within a fixed training
# size and currently slips past the zero-variance filter (REVISIONS.md).
metric_pool <- c("ai", "contag", "cohesion", "lpi", "division",
                 "ed", "pd", "np", "area_mn", "lsi")
normalised <- c("ai", "contag", "cohesion", "lpi", "division")

train <- create_landscapes(n = 360, patterns = patterns, width = 50, height = 50)
test_matched <- create_landscapes(n = 120, patterns = patterns, width = 50, height = 50)
test_larger <- create_landscapes(n = 120, patterns = patterns, width = 100, height = 100)

# Train one model per metric set -----------------------------------------------

train_metrics <- calculate_metrics(train, metrics = metric_pool, level = "landscape")
auto_selected <- evaluate_metrics(train_metrics, metrics_number = 5, verbose = FALSE)
cat("\nautomatically selected:", auto_selected$selected, "\n")

fit_model <- function(metrics_selected) {
  train_metric_model(
    train_metrics,
    metrics_selected = metrics_selected,
    cv_method = "none",
    stepmax = 1e6,
    verbose = FALSE
  )
}

models <- list(auto = fit_model(auto_selected), normalised = fit_model(normalised))

# Evaluate ---------------------------------------------------------------------

accuracy_of <- function(model, landscapes) {
  result <- suppressWarnings(
    apply_metric_model(landscapes, model)
  )
  if (is.null(result$performance)) return(NA_real_)
  round(result$performance$accuracy, 3)
}

results <- tidyr::expand_grid(
  metrics_used = names(models),
  test_data = c("50x50 (matched)", "100x100 (4x extent)")
) |>
  mutate(accuracy = purrr::map2_dbl(metrics_used, test_data, \(m, d) {
    landscapes <- if (d == "50x50 (matched)") test_matched else test_larger
    accuracy_of(models[[m]], landscapes)
  }))

cat("\n=== accuracy (chance =", round(1 / length(patterns), 3), ") ===\n")
print(results, n = Inf)

# How far each metric moves with extent ----------------------------------------

shift <- bind_rows(
  calculate_metrics(test_matched, metrics = metric_pool, level = "landscape") |>
    mutate(extent = "50x50"),
  calculate_metrics(test_larger, metrics = metric_pool, level = "landscape") |>
    mutate(extent = "100x100")
) |>
  summarise(mean_value = mean(value, na.rm = TRUE), .by = c(metric, extent)) |>
  tidyr::pivot_wider(names_from = extent, values_from = mean_value) |>
  mutate(pct_change = round(100 * (`100x100` - `50x50`) / abs(`50x50`), 1)) |>
  arrange(abs(pct_change))

cat("\n=== metric shift with extent ===\n")
print(shift, n = Inf)
