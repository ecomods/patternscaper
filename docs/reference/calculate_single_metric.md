# Calculate a Single Landscape Metric

Calculates a specific metric for each landscape object and captures any
warnings.

## Usage

``` r
calculate_single_metric(landscapes, function_name)
```

## Arguments

- landscapes:

  A list of landscape objects

- function_name:

  Character. The name of the landscapemetrics function to call.

## Value

tibble. Results from the metric calculation including any warnings.
