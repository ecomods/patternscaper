# Train a multi-layer Neural Network for Landscape Classification

Trains a multi-layer neural network model to classify landscapes based
on landscape metrics. Uses the neuralnet package.

## Usage

``` r
train_nn_metrics(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_layers = 6,
  threshold = 0.01,
  stepmax = 1e+05,
  model_path = NULL,
  verbose = TRUE
)
```

## Arguments

- metrics:

  Tibble or data frame. Output from calculate_landscape_metrics()
  containing landscape metrics in long format with required columns:
  landscape_id, landscape_name, pattern, level, class, id, metric,
  value.

- metrics_selected:

  Character vector of metric names to use as features, or NULL to use
  all available metrics. Default: NULL.

- cv_method:

  Character. Cross-validation method: "none", "k-fold", or "loo". May be
  automatically adjusted based on dataset size via validate_cv_params().
  Default: "k-fold".

- cv_folds:

  Integer. Number of folds for k-fold cross-validation. May be
  automatically reduced if dataset is too small. Default: 5.

- hidden_layers:

  Integer vector. Number of neurons in each hidden layer. Length
  determines number of hidden layers. Default: 6 (single hidden layer
  with 6 neurons).

- threshold:

  Numeric. Threshold for partial derivatives as stopping criteria.
  Smaller values = more training iterations. Default: 0.01.

- stepmax:

  Integer. Maximum number of training steps. Default: 1e+05.

- model_path:

  Character. Optional file path (must end in .rds) to save the trained
  model. Default: NULL (no saving).

- verbose:

  Logical. Print training details and cross-validation results. Default:
  TRUE.

## Value

List containing:

- model:

  Trained neuralnet model object

- features:

  Character vector of metric names used as features

- features_level:

  Character. Metric aggregation level ("landscape" or "class")

- scaling:

  List with 'center' and 'scale' parameters for normalization

- classes:

  Character vector of class names in alphabetical order

- performance:

  List from evaluate_cv_performance() with confusion matrix, accuracy,
  per-class metrics, and validation results. NULL if cv_method = "none".
