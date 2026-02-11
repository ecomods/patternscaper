# Plot Neural Network Prediction Confidence

Creates a visualization of prediction confidence by class from neural
network validation.

## Usage

``` r
plot_nn_confidence(nn_model, confidence_threshold = 0.6, add_raw_data = TRUE)
```

## Arguments

- nn_model:

  List. Neural network model from train_nn_metrics().

- confidence_threshold:

  Numeric. Threshold for highlighting low confidence (default: 0.6).

- add_raw_data:

  Logical. Whether to overlay raw data points (default: TRUE).

## Value

ggplot object. Visualization of confidence by class.
