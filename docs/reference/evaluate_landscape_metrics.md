# Evaluate Landscape Metrics

Identifies the most informative metrics for discriminating between
landscape_name types.

## Usage

``` r
evaluate_landscape_metrics(
  metrics,
  metrics_number = 10,
  method = "coeffvar_all",
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

  Character. Selection method to use (default: "coeffvar_all"). See
  'Ranking Methods' section below for details.

- exclude_NA_metrics:

  Logical. Whether to exclude metrics with NA values (default: TRUE).
  This is recommended if data is later used for model training as this
  does not accept missing values.

- exclude_metrics:

  Character vector. Metrics to exclude (default: NULL).

- correlation_threshold:

  Numeric. Maximum allowed correlation between selected metrics
  (default: 0.7). If you don't want to filter based on correlation, set
  to 1.

- verbose:

  Logical. Whether to print detailed messages on excluded metrics or
  just a summary (default: FALSE).

## Value

Character vector. Names of most sensitive metrics.

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
