# Scale a validation fold using only the training fold's statistics

Fits centering/scaling on the training-fold predictors alone and applies
the same statistics to both the training and validation predictors. This
keeps the validation rows from contributing to the \`center\`/\`scale\`
used on them, avoiding the optimistic leakage that arises when the whole
dataset is scaled before cross-validation. Columns that are constant
within the training fold are given \`scale = 1\` so they become all-zero
after centering instead of \`NaN\` (see
[`scaling_stats`](https://ecomods.github.io/patternscaper/reference/scaling_stats.md)).

## Usage

``` r
scale_fold(train_predictors, val_predictors)
```

## Arguments

- train_predictors:

  Data frame or matrix of training-fold predictors.

- val_predictors:

  Data frame or matrix of validation-fold predictors.

## Value

List with \`train\` and \`val\`: numeric matrices scaled with the
training-fold center/scale.
