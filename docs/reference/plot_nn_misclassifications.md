# Plot Neural Network Misclassifications

Creates a visualization of common misclassification patterns from neural
network validation.

## Usage

``` r
plot_nn_misclassifications(nn_model, confidence_threshold = 0.6)
```

## Arguments

- nn_model:

  List. Neural network model from train_nn_metrics().

- confidence_threshold:

  Numeric. Threshold for highlighting low confidence (default: 0.6).

## Value

ggplot object. Visualization of misclassification patterns.
