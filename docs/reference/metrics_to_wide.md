# Convert landscape metrics from long to wide format

This function transforms landscape metrics from a long format to a wide
format that is needed to train nn models

## Usage

``` r
metrics_to_wide(metrics, return_only_metrics = FALSE)
```

## Arguments

- metrics:

  A data frame containing landscape metrics in long format. Expected
  columns include: \`metric\`, \`class\`, \`id\`, \`value\`,
  \`pattern\`. Must include either \`landscape_id\` or
  \`landscape_name\` for identification.

- return_only_metrics:

  Logical. Whether to return only the metrics or also the the
  identification columns in output (default: FALSE).

## Value

A data frame in wide format where each metric becomes a column and each
row is a landscape. Metric names are modified to include class and patch
IDs when applicable (format: \`metric_class_id\`).
