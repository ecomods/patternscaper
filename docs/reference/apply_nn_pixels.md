# Apply a Keras CNN Model for Landscape Classification

Applies a trained CNN model to classify new landscapes based on their
spatial patterns. Automatically resizes input landscapes to match the
model's expected dimensions.

## Usage

``` r
apply_nn_pixels(
  landscapes,
  nn_model,
  return_performance = FALSE,
  verbose = TRUE
)
```

## Arguments

- landscapes:

  landscape object, or list of landscape objects. Landscape(s) to
  classify. Landscapes will be automatically resized to match the
  model's input dimensions using nearest neighbor interpolation, which
  preserves categorical cell values. \*\*Note\*\*: Input landscapes must
  contain categorical/discrete habitat data (e.g., 0/1 for two habitat
  types, or 0/1/2 for three types). Continuous data (e.g., elevation,
  gradients) is not supported.

- nn_model:

  List. CNN model from train_nn_pixels().

- return_performance:

  Logical. Whether to return performance metrics when actual classes are
  available (default: FALSE).

- verbose:

  Logical. Show informational messages and performance summaries
  (default: TRUE). When TRUE, displays resize operations and performance
  evaluation results. When FALSE, runs silently. Warnings about unknown
  classes or invalid data always appear.

## Value

When actual classes unavailable or return_performance=FALSE: tibble with
columns:

- landscape_id:

  Numeric landscape identifier

- landscape_name:

  Character landscape name (if available)

- predicted_class:

  Predicted landscape pattern

- confidence:

  Prediction confidence (max probability)

- \<class_name\>:

  Probability for each trained class

When actual classes available and return_performance=TRUE: List
containing:

- predictions:

  Tibble as above, plus actual_class column

- performance:

  Performance metrics from evaluate_cv_performance()
