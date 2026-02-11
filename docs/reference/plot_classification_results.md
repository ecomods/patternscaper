# Plot Neural Network Classification Results

Creates visualizations of neural network model results from
cross-validation.

## Usage

``` r
plot_classification_results(
  nn_model,
  plot_type = "confusion",
  confidence_threshold = 0.6,
  return_all = FALSE
)
```

## Arguments

- nn_model:

  List. Neural network model from train_nn_metrics().

- plot_type:

  Character. Type of plot to create: "confusion", "probabilities",
  "confidence", or "misclassifications" (default: "confusion").

- confidence_threshold:

  Numeric. Threshold for highlighting low confidence (default: 0.6).

- return_all:

  Logical. Whether to return all plot types as a list (default: FALSE).

## Value

ggplot object or list of ggplot objects. Visualization(s) of
classification results.
