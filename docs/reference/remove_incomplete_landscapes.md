# Remove landscapes with incomplete metrics

Removes missing data in three steps, from least to most consequential.
First drops any predictor columns that are NA for every landscape
(metrics that are undefined for the given landscapes carry no
information and would otherwise remove the entire dataset). Then drops
the row-wise counterpart: landscapes that are NA for every remaining
predictor, which carry no information either. Only then resolves values
missing from some, but not all, landscapes. Issues warnings listing
dropped metrics and removed landscapes, and aborts if no usable
predictors or landscapes remain.

## Usage

``` r
remove_incomplete_landscapes(
  metrics_wide,
  predictor_cols,
  na_action = "drop_metrics"
)
```

## Arguments

- metrics_wide:

  Data frame in wide format. Output from metrics_to_wide().

- predictor_cols:

  Character vector. Names of predictor columns to check for NAs.

- na_action:

  Character. How to resolve values that are missing for some but not all
  landscapes: `"drop_metrics"` removes the affected metrics and keeps
  every landscape; `"drop_landscapes"` removes the affected landscapes
  and keeps every metric.

## Value

Data frame after resolving incomplete predictors according to
`na_action`.
