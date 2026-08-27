# Centring and scaling statistics for a set of predictors

Computes the \`center\`/\`scale\` used to standardise predictors,
guarding columns that carry no variation (see
[`is_constant_sd`](https://ecomods.github.io/patternscaper/reference/is_constant_sd.md))
by giving them \`scale = 1\`. Those columns become all-zero after
centring instead of \`NaN\` or an enormous z-score.

## Usage

``` r
scaling_stats(predictors)
```

## Arguments

- predictors:

  Data frame or matrix of predictors.

## Value

List with \`center\` and \`scale\`, both named numeric vectors.
