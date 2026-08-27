# Convert Landscape Metrics from Long to Wide Format

Reshapes landscape metrics to one row per landscape and one column per
metric for neural-network training.

## Usage

``` r
metrics_to_wide(metrics, return_only_metrics = FALSE)
```

## Arguments

- metrics:

  A data frame containing landscape metrics in long format. Expected
  columns include: \`metric\`, \`class\`, \`value\`, \`pattern\`. Must
  include either \`landscape_id\` or \`landscape_name\` for
  identification.

- return_only_metrics:

  Logical. Whether to return only the metric columns or retain the
  identification columns (default: FALSE).

## Value

A data frame in wide format where each metric becomes a column and each
row is a landscape. Metric names already include class IDs when
applicable (format: \`metric_class_id\`); that folding is done upstream
in
[`calculate_metrics`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md),
not here.
