# Print a metrics evaluation

Summarises which metrics were selected and what happened to the rest.
Prints a summary rather than the ranking table itself, which has one row
per metric passed in and is usually too long to read in the console; use
\`x\$ranking\` to see it.

## Usage

``` r
# S3 method for class 'metrics_evaluation'
print(x, ...)
```

## Arguments

- x:

  A \`metrics_evaluation\` object from
  [`evaluate_metrics`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md).

- ...:

  Ignored, for compatibility with the generic.

## Value

\`x\`, invisibly.

## See also

Other metrics:
[`calculate_metrics()`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md),
[`evaluate_metrics()`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md)

## Examples

``` r
landscapes <- create_landscapes(n = 10, patterns = c("spots", "random"))
#> ✔ Successfully generated all 10 training landscapes
metrics <- calculate_metrics(landscapes, level = "landscape")
#>  ■■■■■■■■■■■■■                     39% |  ETA:  2s
evaluate_metrics(metrics, metrics_number = 5)
#> Warning: Excluded 6 metrics with missing values (60 rows removed).
#> ✖ NA value for at least one landscape: "enn_cv", "enn_mn", "enn_sd", "iji",
#>   "pafrac", and "rpr"
#> ℹ Use `exclude_incomplete_metrics = FALSE` to retain them (not recommended for
#>   model training).
#> Warning: Excluded 3 metrics with no variation across landscapes: "pr", "prd", and "ta"
#> Metrics evaluation: kruskal_effsize [66 candidate metrics]
#> -----------------------------------------
#> Selected (5): area_mn, dcore_sd, cai_sd, circle_cv, dcore_mn
#> 
#> Outcomes:
#>   selected                   5
#>   dropped_correlated         40
#>   dropped_below_cutoff       12
#>   excluded_incomplete        6
#>   excluded_zero_variance     3
#> 
#> Use $ranking for scores and per-metric outcomes.
```
