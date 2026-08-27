# Calculate Landscape Metrics

Calculates selected landscape metrics for one or more landscapes using
functions from the landscapemetrics package. Returns a standardized
tibble with results including landscape identifiers, metric values, and
any warnings.

## Usage

``` r
calculate_metrics(landscapes, metrics = NULL, level = "landscape")
```

## Arguments

- landscapes:

  A single landscape object (created with
  [`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md))
  or a list of landscape objects (e.g. created with
  [`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)).
  Each landscape object should contain a `data` element with a
  SpatRaster, plus `name` and `pattern` metadata.

- metrics:

  Character vector. Abbreviations of the metrics to calculate (default:
  NULL for all available metrics at the specified level). Use
  [`list_lsm`](https://r-spatialecology.github.io/landscapemetrics/reference/list_lsm.html)
  to look up the available abbreviations and the full metric name each
  one stands for.

- level:

  Character. Metric level to calculate: "class" or "landscape"
  (default).

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

- metric_name:

  Metric abbreviation without the class suffix, e.g. "ai". Identical to
  `metric` for landscape-level metrics.

- metric:

  Metric abbreviation identifying the row, e.g. "ai". For class-level
  metrics the class is appended, e.g. "ai_1", so that each class gets
  its own identifier.

- value:

  Calculated metric value

- warnings:

  Any warnings generated during calculation (NA if none)

- n_row, n_col:

  Cell dimensions of the landscape the row was computed from

- cell_size_x, cell_size_y:

  Cell resolution (from
  [`res`](https://rspatial.github.io/terra/reference/dimensions.html))

- n_na:

  Number of NA cells in the landscape

Metrics are identified by their abbreviation throughout. To see what an
abbreviation stands for, look it up with
[`list_lsm`](https://r-spatialecology.github.io/landscapemetrics/reference/list_lsm.html);
[`evaluate_metrics`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md)
reports the full names in its ranking table, and
[`plot_metrics`](https://ecomods.github.io/patternscaper/reference/plot_metrics.md)
can use them as facet labels via `metric_labels = "name"`.

The last five columns record each landscape's geometry so it stays
attached to the metrics (e.g. through
[`write_csv`](https://readr.tidyverse.org/reference/write_delim.html));
they are used for geometry-mismatch checks and are never used as model
predictors.

## References

Hesselbarth, M.H.K., Sciaini, M., With, K.A., Wiegand, K., & Nowosad, J.
(2019). landscapemetrics: an open-source R tool to calculate landscape
metrics. \*Ecography\*, 42(10), 1648-1657.
[doi:10.1111/ecog.04617](https://doi.org/10.1111/ecog.04617)

## See also

[`plot_metrics`](https://ecomods.github.io/patternscaper/reference/plot_metrics.md),
[`list_lsm`](https://r-spatialecology.github.io/landscapemetrics/reference/list_lsm.html)
for the available metrics and their full names

Other metrics:
[`evaluate_metrics()`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md),
[`print.metrics_evaluation()`](https://ecomods.github.io/patternscaper/reference/print.metrics_evaluation.md)

## Examples

``` r
# Calculate all landscape-level metrics for a single landscape
landscape <- create_landscape(pattern = "labyrinth")
metrics <- calculate_metrics(landscape)

# Calculate specific metrics for multiple landscapes
landscapes <- create_landscapes(n = 10, patterns = "spots")
#> ✔ Successfully generated all 10 training landscapes
metrics <- calculate_metrics(
  landscapes,
  metrics = c("ai", "lsi"),
  level = "landscape"
)
```
