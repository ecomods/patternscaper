# Apply Neural Network for Landscape Classification

Applies a trained neural network model to classify new landscapes. The
function automatically calculates the required landscape metrics needed
by the model and scales them appropriately.

## Usage

``` r
apply_nn_metrics(landscapes, nn_model, return_performance = FALSE)
```

## Arguments

- landscapes:

  Landscape object (single) or list of landscape objects to classify.
  Landscapes must have valid raster data that can be analyzed by
  landscapemetrics.

- nn_model:

  List. Trained model object returned from train_nn_metrics(). Must
  contain elements: model, scaling, classes, features, and
  features_level.

- return_performance:

  Logical. If TRUE and landscapes contain known classes (pattern
  attribute), calculate and return performance metrics. If FALSE or
  classes unknown, only return predictions. Default: FALSE.

## Value

When return_performance = FALSE or actual classes unavailable: Tibble
with columns:

- landscape_id:

  Numeric landscape identifier

- landscape_name:

  Character landscape name (if available)

- predicted_class:

  Predicted landscape pattern

- confidence:

  Prediction confidence (maximum probability across classes)

- \<class_name\>:

  Probability for each class the model was trained on

When return_performance = TRUE and actual classes available: List
containing:

- predictions:

  Tibble as above, plus actual_class column

- performance:

  Performance metrics from evaluate_cv_performance(): confusion matrix,
  accuracy, and per-class recall/precision/F1
