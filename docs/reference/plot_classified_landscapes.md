# Plot Neural Network Classification Landscapes

Plots landscapes with neural network classification results,
highlighting correct and misclassified cases. Optionally, only
misclassified landscapes can be shown.

## Usage

``` r
plot_classified_landscapes(
  classification,
  landscapes,
  only_misclassified = FALSE,
  score_note = TRUE,
  subset_index = NULL,
  ...
)
```

## Arguments

- classification:

  A data frame with columns: `landscape_id`, `actual_class`,
  `predicted_class`, and `score`. Can be obtained from the CV-fold
  results of
  [`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)/[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)
  or the output of
  [`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md)/[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md).

- landscapes:

  A list of landscape objects corresponding one-to-one and in the same
  order as the rows in \`classification\`. The easiest way to ensure
  this is to use the same list of landscapes for both training and
  plotting.

- only_misclassified:

  Logical; if `TRUE`, only misclassified landscapes are plotted. Default
  is `FALSE`. If every landscape was classified correctly there is
  nothing to plot: the function reports this with a message and returns
  an empty placeholder plot. Landscapes whose true class is unknown are
  not counted as misclassified.

- score_note:

  Logical; if `TRUE` (default), a one-line caption is added under the
  whole figure stating that the bracketed number is the score of the
  predicted class and not a calibrated probability. Set to `FALSE` when
  the surrounding figure caption already says so.

- subset_index:

  Integer vector. Which of the plotted landscapes to show, e.g. to keep
  a large figure readable. Indexes the rows of `classification` that
  would otherwise be plotted, so with `only_misclassified = TRUE` it
  selects among the misclassified ones. Default `NULL` plots all of
  them.

- ...:

  Additional arguments passed to
  [`plot_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md),
  such as `show_legend`, `legend_title`, `ncol`, `max_landscapes`, or
  `force`.

## Value

A patchwork object combining landscape plots with classification
annotations. With `only_misclassified = TRUE` and no misclassified
landscape, an empty placeholder plot carrying that message.

## See also

[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md),
[`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)

Other visualization:
[`plot_landscapes()`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md),
[`plot_metrics()`](https://ecomods.github.io/patternscaper/reference/plot_metrics.md)

## Examples

``` r
# \donttest{
# Generate training landscapes
landscapes <- create_landscapes(
  n = 18,
  patterns = c("random", "sharp", "diffuse")
)
#> ✔ Successfully generated all 18 training landscapes

# Calculate landscape metrics
metrics <- calculate_metrics(landscapes, level = "landscape")
#>  ■■■■■■■                           21% |  ETA:  5s
#>  ■■■■■■■■■■■■■■■■                  50% |  ETA:  4s
#>  ■■■■■■■■■■■■■■■■■■■■■■■■          76% |  ETA:  2s

# Find the best 5 metrics for classification
best_5 <- evaluate_metrics(metrics, metrics_number = 5)
#> Warning: Excluded 6 metrics with missing values (108 rows removed).
#> ✖ NA value for at least one landscape: "enn_cv", "enn_mn", "enn_sd", "iji",
#>   "pafrac", and "rpr"
#> ℹ Use `exclude_incomplete_metrics = FALSE` to retain them (not recommended for
#>   model training).
#> Warning: Excluded 3 metrics with no variation across landscapes: "pr", "prd", and "ta"

# Cross-validation produces the held-out predictions this plot needs.
# Only 2 folds, as each fold needs at least 3 landscapes per pattern.
model <- train_metric_model(
  metrics,
  metrics_selected = best_5,
  cv_method = "k-fold",
  cv_folds = 2
)
#> ℹ Low sample-to-predictor ratio (3.6:1). Consider LOO CV or reducing features.
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 2-fold cross-validation
#> ℹ Overall accuracy: 77.78%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       6      1     2
#>   random        0      5     1
#>   sharp         0      0     3
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     6   1         0.67     0.8 
#> 2 random      6   0.83      0.83     0.83
#> 3 sharp       6   0.5       1        0.67

# Plot all classification results
plot_classified_landscapes(
  model$performance$validation_results,
  landscapes
)


# Show only misclassifications without legend
plot_classified_landscapes(
  model$performance$validation_results,
  landscapes,
  only_misclassified = TRUE,
  show_legend = FALSE,
  ncol = 4
)

# }
```
