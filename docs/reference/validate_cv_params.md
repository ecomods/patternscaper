# Validate and adjust cross-validation parameters

Checks if the dataset is suitable for the requested cross-validation
method and adjusts parameters if needed. Issues warnings or errors for
problematic configurations.

## Usage

``` r
validate_cv_params(
  patterns,
  cv_method,
  cv_folds,
  n_predictors = NULL,
  min_samples_per_fold = 3
)
```

## Arguments

- patterns:

  Factor or character vector. Class labels for training data.

- cv_method:

  Character. Cross-validation method: "none", "k-fold", or "loo".
  Already validated by calling function.

- cv_folds:

  Integer. Number of folds for k-fold CV. Already validated by calling
  function when cv_method = "k-fold".

- n_predictors:

  Integer. Number of predictor variables (optional, for
  sample-to-predictor ratio check).

- min_samples_per_fold:

  Integer. Minimum samples per class per fold for k-fold CV (default:
  3).

## Value

List with validated/adjusted CV parameters:

- cv_method:

  Adjusted CV method (may switch from k-fold to loo)

- cv_folds:

  Integer number of folds, or 1L for "none"

- class_counts:

  Named vector of sample counts per class

- total_samples:

  Total number of samples
