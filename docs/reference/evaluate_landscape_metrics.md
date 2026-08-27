# Evaluate Landscape Metrics

Identifies the metrics most suitable for discriminating between
different pattern types based on a specified selection method. The
choice of method affects the ranking: parametric methods assume linear
relationships and normally distributed residuals, while non-parametric
methods are more robust to outliers and deviations from normality. This
function is useful for selecting informative metrics to train the
metric-based neural network.

## Usage

``` r
evaluate_landscape_metrics(
  metrics,
  metrics_number = 10,
  method = "kruskal_effsize",
  exclude_NA_metrics = TRUE,
  exclude_metrics = NULL,
  correlation_threshold = 0.7,
  verbose = FALSE
)
```

## Arguments

- metrics:

  tibble. Metrics from calculate_landscape_metrics().

- metrics_number:

  Integer. Number of top metrics to return (default: 10).

- method:

  Character. Selection method to use (default: "kruskal_effsize"). See
  'Ranking Methods' section below for details.

- exclude_NA_metrics:

  Logical. Whether to exclude metrics with NA values (default: TRUE).
  This is recommended if data is later used for model training as this
  does not accept missing values.

- exclude_metrics:

  Character vector. Metrics to exclude (default: NULL).

- correlation_threshold:

  Numeric. Maximum allowed correlation between selected metrics
  (default: 0.7). If you do not want to filter based on correlation, set
  to 1.

- verbose:

  Logical. Whether to print detailed messages on excluded metrics or
  just a summary (default: FALSE).

## Value

Character vector. Names of metrics that best discriminate between
pattern types.

## Ranking Methods

- `coeffvar_all`:

  Coefficient of Variation (CV = SD/mean). Ranks metrics by their
  relative variability across landscapes. Higher CV indicates greater
  spread. Best for identifying metrics with high variability regardless
  of pattern type.

- `lin_mod_r2`:

  Linear Model R-squared. Fits `value ~ pattern` for each metric and
  ranks by R². Higher values indicate better ability to predict pattern
  types. Assumes linear relationships and normally distributed
  residuals.

- `mean_groups`:

  Mean Differences. Calculates relative differences between
  pattern-specific means and overall mean, then sums across patterns.
  Higher scores indicate better discrimination between pattern types.

- `fisher_score`:

  Fisher Score (ratio of between-group to within-group variance). Higher
  scores indicate better separation between pattern types. Assumes
  normally distributed data within groups.

- `kruskal_effsize`:

  Kruskal-Wallis H test effect sizes. Non-parametric test for
  differences between groups. Higher effect sizes indicate better
  discrimination between pattern types.

## See also

[`train_nn_metrics`](https://ecomods.github.io/patternscaper/reference/train_nn_metrics.md)

Other metrics:
[`calculate_landscape_metrics()`](https://ecomods.github.io/patternscaper/reference/calculate_landscape_metrics.md)

## Examples

``` r
# Calculate most suitable metrics to discriminate between spots and random landscapes
landscapes <- create_landscapes(n = 50, patterns = c("spots","random"))
#> Warning: Regular spot placement requested 10 spots but only ~8 positions fit.
#> ℹ  Adjusting to maximum feasible spots. Consider decreasing `spot_radius`.
#> ✔ Successfully generated all 50 training landscapes
metrics <- calculate_landscape_metrics(
  landscapes,
  level = "landscape"
)
#>  ■■■■■■                            17% |  ETA: 13s
#>  ■■■■■■■■■■■                       32% |  ETA: 12s
#>  ■■■■■■■■■■■■■                     41% |  ETA: 13s
#>  ■■■■■■■■■■■■■■■■                  50% |  ETA: 13s
#>  ■■■■■■■■■■■■■■■■■                 53% |  ETA: 14s
#>  ■■■■■■■■■■■■■■■■■■■■■■            70% |  ETA:  8s
#>  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■      89% |  ETA:  2s
metric_list <- evaluate_landscape_metrics(
  metrics = metrics,
  metrics_number = 5,
  method = "coeffvar_all"
)
#> Warning: Excluded 300 rows containing 6 metrics with NA values. Metrics removed:
#> "enn_cv", "enn_mn", "enn_sd", "iji", "pafrac", and "rpr" Use
#> `exclude_NA_metrics = FALSE` to retain (not recommended for model training)
#> Warning: Excluded 3 metrics with zero variance: "pr", "prd", and "ta"
```
