# Evaluate cross-validation performance

Calculates performance metrics from cross-validation results including
confusion matrix, accuracy, and per-class metrics (recall, precision,
F1).

## Usage

``` r
evaluate_cv_performance(
  cv_predictions,
  cv_probabilities,
  cv_actual,
  cv_landscape_ids,
  class_names,
  cv_method,
  cv_folds,
  verbose = TRUE,
  return_predictions = TRUE
)
```

## Arguments

- cv_predictions:

  List. Predicted class labels for each fold.

- cv_probabilities:

  List. Prediction probabilities for each fold. Each element should be a
  matrix or data frame with class probabilities.

- cv_actual:

  List. Actual class labels for each fold.

- cv_landscape_ids:

  List. Landscape IDs for each fold. Needed to map predictions back to
  original landscapes.

- class_names:

  Character vector. Names of all classes in the dataset.

- cv_method:

  Character. Cross-validation method used ("none", "k-fold", or "loo").

- cv_folds:

  Integer. Number of folds used.

- verbose:

  Logical. Whether to print detailed results (default: TRUE).

- return_predictions:

  Logical. Whether to include validation_results tibble with detailed
  per-landscape predictions (default: TRUE).

## Value

List with performance metrics:

- confusion_matrix:

  Confusion matrix table

- accuracy:

  Overall accuracy (numeric)

- per_class_metrics:

  Tibble with per-class recall, precision, and F1 scores

- cv_method:

  CV method used (character)

- cv_folds:

  Number of folds used (integer)

- class_counts:

  Sample counts per class (integer vector)

- validation_results:

  Tibble with detailed predictions per landscape (only included if
  return_predictions = TRUE)
