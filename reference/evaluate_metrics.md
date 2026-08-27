# Evaluate Landscape Metrics

Ranks metrics by how well they distinguish pattern types. Each method
emphasizes a different aspect of separation among patterns and has
different sensitivities to distribution, within-pattern variation, and
outliers.

## Usage

``` r
evaluate_metrics(
  metrics,
  metrics_number = 10,
  method = "kruskal_effsize",
  exclude_incomplete_metrics = TRUE,
  exclude_metrics = NULL,
  correlation_threshold = 0.7,
  verbose = FALSE,
  fill_correlated = TRUE
)
```

## Arguments

- metrics:

  tibble. Metrics from calculate_metrics().

- metrics_number:

  Integer. Number of top metrics to return (default: 10).

- method:

  Character. Selection method to use (default: "kruskal_effsize"). See
  'Ranking Methods' section below for details.

- exclude_incomplete_metrics:

  Logical. Whether to exclude metrics with missing values (default:
  TRUE). This covers both metrics that are calculated as NA and metrics
  that are not available for every landscape. For example, at the class
  level a metric cannot be calculated for a class that is absent from a
  landscape. Keep this enabled if the data is later used for model
  training, which requires a complete predictor matrix.

- exclude_metrics:

  Character vector. Metric abbreviations to exclude, as they appear in
  the \`metric\` column (default: NULL). Use
  [`list_lsm`](https://r-spatialecology.github.io/landscapemetrics/reference/list_lsm.html)
  to look up what an abbreviation stands for.

- correlation_threshold:

  Numeric. Maximum allowed absolute Pearson correlation between selected
  metrics (default: 0.7). Correlations are calculated across all
  landscapes and pattern types. Candidate metrics are considered in
  ranking order. A candidate passes the filter only if its absolute
  correlation with every already selected metric does not exceed the
  threshold. Set to 1 to disable correlation filtering.

- verbose:

  Logical. Whether to print detailed messages on excluded metrics or
  just a summary (default: FALSE).

- fill_correlated:

  Logical. If \`TRUE\` (default), fills any difference between the
  number of metrics that pass the correlation filter and the requested
  \`metrics_number\` with the highest-ranked correlated metrics, and
  warn. If \`FALSE\`, returns only uncorrelated metrics, which then may
  be fewer than the requested \`metric_number\`.

## Value

An object of class \`metrics_evaluation\`, a list with elements:

- `selected`:

  Character vector. Names of metrics that best discriminate between
  pattern types. With \`fill_correlated = TRUE\`, metrics added to fill
  a correlation gap come last rather than at their rank position. With
  \`fill_correlated = FALSE\`, the vector may contain fewer than
  \`metrics_number\` names.

- `ranking`:

  tibble. One row per metric passed in, with its score and outcome. See
  'The ranking table' below.

- `method`:

  Character. The ranking method used.

- `params`:

  List. The arguments that affect the result.

[`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)
and
[`plot_metrics`](https://ecomods.github.io/patternscaper/reference/plot_metrics.md)
accept this object directly, so it can be passed straight on.

## Ranking Methods

Within each method, higher scores indicate stronger separation. Score
values use different scales and should not be compared across methods.

- `mean_groups`:

  Mean Differences. Calculates relative differences between
  pattern-specific means and the overall mean, then sums across
  patterns. It does not account for within-pattern spread and works most
  reliably when within-pattern variation is low relative to differences
  between patterns.

- `fisher_score`:

  Fisher Score (ratio of between-group to within-group variance).
  Assumes approximately normally distributed values within patterns and
  is sensitive to outliers.

- `kruskal_effsize`:

  Kruskal-Wallis H test effect sizes (default). Uses ranks, so it is
  robust to outliers and does not require normally distributed values.
  It does not describe the magnitude of differences on the original
  metric scale.

## The ranking table

\`ranking\` gives an overview of all metrics ranked: one row per metric,
whatever happened to it. Columns:

- `metric`:

  Metric abbreviation, e.g. "ai". For class-level metrics the class is
  appended, e.g. "ai_1".

- `name`:

  Full metric name from
  [`list_lsm`](https://r-spatialecology.github.io/landscapemetrics/reference/list_lsm.html),
  e.g. "Aggregation index". Metrics that summarise per-patch values get
  the statistic in brackets, because \`list_lsm()\` gives the
  \`\_cv\`/\`\_mn\`/\`\_sd\` triple a single name: \`area_mn\` is "Patch
  area (mean)". For class-level metrics the class is added too, e.g.
  "Patch area (mean, class 1)". Falls back to the abbreviation for
  metrics \`landscapemetrics\` does not document.

- `score`:

  Score from the ranking \`method\`, or \`NA\` for metrics that were
  excluded before ranking.

- `rank`:

  Position in the full ranking, best first, or \`NA\` for metrics that
  were excluded before ranking.

- `selected`:

  Whether the metric is in \`selected\`.

- `outcome`:

  Factor recording what happened to the metric, with levels ordered by
  pipeline stage: \`selected\`, \`selected_correlation_fill\` (added
  despite correlation because too few uncorrelated metrics existed),
  \`dropped_correlated\`, \`dropped_below_cutoff\` (scored, but ranked
  below \`metrics_number\`), \`excluded_user\` (via
  \`exclude_metrics\`), \`excluded_incomplete\` (\`NA\` values, or
  absent for some landscapes), and \`excluded_zero_variance\`.

- `correlated_with`:

  For the two correlation outcomes, the already selected metrics the
  metric clashed with. \`NA\` otherwise.

Ties in \`score\` are broken by metric name, so the ranking is
deterministic for given data regardless of its row order.

## See also

[`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md),
[`list_lsm`](https://r-spatialecology.github.io/landscapemetrics/reference/list_lsm.html)
for the available metrics and their full names

Other metrics:
[`calculate_metrics()`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md),
[`print.metrics_evaluation()`](https://ecomods.github.io/patternscaper/reference/print.metrics_evaluation.md)

## Examples

``` r
# Most suitable metrics to tell spots and random landscapes apart
landscapes <- create_landscapes(n = 10, patterns = c("spots", "random"))
#> ✔ Successfully generated all 10 training landscapes
metrics <- calculate_metrics(
  landscapes,
  level = "landscape"
)
#>  ■■■■■■■■■■■■■■■■■■                56% |  ETA:  2s
evaluation <- evaluate_metrics(
  metrics = metrics,
  metrics_number = 5
)
#> Warning: Excluded 6 metrics with missing values (60 rows removed).
#> ✖ NA value for at least one landscape: "enn_cv", "enn_mn", "enn_sd", "iji",
#>   "pafrac", and "rpr"
#> ℹ Use `exclude_incomplete_metrics = FALSE` to retain them (not recommended for
#>   model training).
#> Warning: Excluded 3 metrics with no variation across landscapes: "pr", "prd", and "ta"

# The selected metric names, to pass on to a model or a plot
evaluation$selected
#> [1] "dcad"      "dcore_cv"  "circle_cv" "para_cv"   "division" 

# What happened to every candidate metric
evaluation$ranking
#> # A tibble: 66 × 7
#>    metric   name                    score  rank selected outcome correlated_with
#>    <chr>    <chr>                   <dbl> <int> <lgl>    <fct>   <chr>          
#>  1 dcad     Disjunct core area den… 0.776     1 TRUE     select… NA             
#>  2 ndca     Number of disjunct cor… 0.776     2 FALSE    droppe… dcad           
#>  3 dcore_cv Disjunct core area (CV) 0.762     3 TRUE     select… NA             
#>  4 dcore_sd Disjunct core area (SD) 0.762     4 FALSE    droppe… dcad           
#>  5 ai       Aggregation index       0.758     5 FALSE    droppe… dcad           
#>  6 area_cv  Patch area (CV)         0.758     6 FALSE    droppe… dcore_cv       
#>  7 area_mn  Patch area (mean)       0.758     7 FALSE    droppe… dcore_cv       
#>  8 area_sd  Patch area (SD)         0.758     8 FALSE    droppe… dcore_cv       
#>  9 cai_cv   Core area index (CV)    0.758     9 FALSE    droppe… dcore_cv       
#> 10 cai_mn   Core area index (mean)  0.758    10 FALSE    droppe… dcore_cv       
#> # ℹ 56 more rows
dplyr::count(evaluation$ranking, outcome)
#> # A tibble: 5 × 2
#>   outcome                    n
#>   <fct>                  <int>
#> 1 selected                   5
#> 2 dropped_correlated        37
#> 3 dropped_below_cutoff      15
#> 4 excluded_incomplete        6
#> 5 excluded_zero_variance     3
```
