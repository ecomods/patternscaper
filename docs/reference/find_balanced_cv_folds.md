# Create balanced fold indices for cross-validation

Creates stratified fold assignments ensuring each class is represented
proportionally in each fold.

## Usage

``` r
find_balanced_cv_folds(patterns, cv_folds)
```

## Arguments

- patterns:

  Factor or character vector. Class labels for training data.

- cv_folds:

  Integer. Number of folds for k-fold CV.

## Value

Integer vector of fold assignments (length = length(patterns)). Each
element indicates which fold that sample belongs to (1 to cv_folds).
