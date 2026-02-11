# Remove landscapes with incomplete metrics

Checks for and removes landscapes that have NA values in any predictor
columns. Issues a warning listing removed landscapes and aborts if no
landscapes remain after removal.

## Usage

``` r
remove_incomplete_landscapes(metrics_wide, predictor_cols)
```

## Arguments

- metrics_wide:

  Data frame in wide format. Output from metrics_to_wide().

- predictor_cols:

  Character vector. Names of predictor columns to check for NAs.

## Value

Data frame with incomplete landscapes removed.
