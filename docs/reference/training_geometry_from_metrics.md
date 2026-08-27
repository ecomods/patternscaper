# Training-geometry summary from a metrics tibble

Internal helper: extracts the per-landscape geometry columns that
[`calculate_metrics`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md)
attaches to its output and condenses them via
[`summarise_geometry`](https://ecomods.github.io/patternscaper/reference/summarise_geometry.md).
Used by
[`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md),
which receives the metrics tibble rather than the landscapes. Returns
\`NULL\` when the geometry columns are absent (e.g. a metrics table
cached before geometry was recorded, or built by hand), so callers can
skip geometry checks gracefully.

## Usage

``` r
training_geometry_from_metrics(metrics)
```

## Arguments

- metrics:

  A metrics tibble from
  [`calculate_metrics`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md).

## Value

A one-row tibble (see
[`summarise_geometry`](https://ecomods.github.io/patternscaper/reference/summarise_geometry.md)),
or \`NULL\`.
