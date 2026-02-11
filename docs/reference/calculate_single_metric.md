# Calculate a Single Landscape Metric

Internal function to calculate a specific landscape metric for a single
landscape. This function handles both plain SpatRaster lists and lists
with metadata structure.

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
