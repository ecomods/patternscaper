# Calculate Landscape Metrics

Calculates selected landscape metrics for one or more landscapes using
functions from the landscapemetrics package. Returns a standardized
tibble with results including landscape identifiers, metric values, and
any warnings.

## Usage

``` r
calculate_landscape_metrics(landscapes, metrics = NULL, level = "landscape")
```

## Arguments

- landscapes:

  A single landscape object (created with
  [`create_landscape`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md))
  or a list of landscape objects (e.g. created with
  [`create_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)).
  Each landscape object should contain a `data` element with a
  SpatRaster, plus `name` and `pattern` metadata.

- metrics:

  Character vector. Names of metrics to calculate (default: NULL for all
  available metrics at the specified level). Use `list_lsm()` from
  landscapemetrics to see available metrics.

- level:

  Character. Level(s) of metrics to calculate:"class", "landscape"
  (default: "landscape").

## Value

A tibble with the following columns:

- landscape_id:

  Numeric identifier for each landscape in the input list

- landscape_name:

  Name of the landscape from the landscape object

- pattern:

  Pattern type from the landscape object (e.g., "labyrinth", "spots")

- layer:

  Layer number (from landscapemetrics output)

- level:

  Metric level: "class", or "landscape"

- class:

  Class value (for class-level metrics, NA for landscape-level)

- metric:

  Name of the calculated metric

- value:

  Calculated metric value

- warnings:

  Any warnings generated during calculation (NA if none)

## References

Hesselbarth, M.H.K., Sciaini, M., With, K.A., Wiegand, K., & Nowosad, J.
(2019). landscapemetrics: an open-source R tool to calculate landscape
metrics. \*Ecography\*, 42(10), 1648-1657.
[doi:10.1111/ecog.04617](https://doi.org/10.1111/ecog.04617)

## See also

[`plot_metrics`](https://ecomods.github.io/spatPatClassifyR/reference/plot_metrics.md)

Other metrics:
[`evaluate_landscape_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/evaluate_landscape_metrics.md)

## Examples

``` r
# \donttest{
# Calculate all landscape-level metrics for a single landscape
landscape <- create_landscape(pattern = "labyrinth")
metrics <- calculate_landscape_metrics(landscape)

# Calculate specific metrics for multiple landscapes
landscapes <- create_landscapes(n = 10, patterns = "spots")
#> Warning: Regular spot placement requested 10 spots but only ~9 positions fit.
#> ℹ  Adjusting to maximum feasible spots. Consider decreasing `spot_radius`.
#> ✔ Successfully generated all 10 training landscapes
metrics <- calculate_landscape_metrics(
  landscapes,
  metrics = c("ai", "lsi"),
  level = "landscape"
)

# }
```
