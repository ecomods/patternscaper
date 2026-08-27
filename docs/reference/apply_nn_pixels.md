# Apply a Keras CNN Model for Landscape Pattern Classification

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

  List. CNN model object from
  [`train_nn_pixels`](https://ecomods.github.io/patternscaper/reference/train_nn_pixels.md).

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

## See also

[`train_nn_pixels`](https://ecomods.github.io/patternscaper/reference/train_nn_pixels.md),
[`plot_classified_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_classified_landscapes.md)

Other neural network application:
[`apply_nn_metrics()`](https://ecomods.github.io/patternscaper/reference/apply_nn_metrics.md)

## Examples

``` r
# \donttest{
# Create training data
training_landscapes <- create_landscapes(
  n = 200,
  patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
)
#> ✔ Successfully generated all 200 training landscapes


# Train on all data for final deployment model
final_model <- train_nn_pixels(
  landscapes = training_landscapes,
  cv_method = "none",
  epochs = 100
)
#> 
#> ── Landscape type distribution: ──
#> 
#> training_labels
#>     bands clustered   diffuse   fingers    random     sharp 
#>        33        33        34        33        33        34 
#> ── Training final model on all data ──
#> 
#> ℹ Training on all data (validation split is 0)...
#> Epoch 1 - loss: 1.4320 - accuracy: 0.4100
#> Epoch 2 - loss: 0.8432 - accuracy: 0.6400
#> Epoch 3 - loss: 0.4490 - accuracy: 0.8300
#> Epoch 4 - loss: 0.2185 - accuracy: 0.9300
#> Epoch 5 - loss: 0.1319 - accuracy: 0.9450
#> Epoch 6 - loss: 0.0550 - accuracy: 0.9950
#> Epoch 7 - loss: 0.0299 - accuracy: 0.9900
#> Epoch 8 - loss: 0.0180 - accuracy: 0.9950
#> Epoch 9 - loss: 0.3721 - accuracy: 0.9000
#> Epoch 10 - loss: 0.7220 - accuracy: 0.7950
#> Epoch 11 - loss: 0.2506 - accuracy: 0.9350
#> Epoch 12 - loss: 0.0599 - accuracy: 0.9800
#> Epoch 13 - loss: 0.0106 - accuracy: 1.0000
#> Epoch 14 - loss: 0.0036 - accuracy: 1.0000
#> Epoch 15 - loss: 0.0013 - accuracy: 1.0000
#> Epoch 16 - loss: 0.0007 - accuracy: 1.0000
#> Epoch 17 - loss: 0.0005 - accuracy: 1.0000
#> Epoch 18 - loss: 0.0003 - accuracy: 1.0000
#> Epoch 19 - loss: 0.0003 - accuracy: 1.0000
#> Epoch 20 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 21 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 22 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 23 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 24 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 25 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 26 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 27 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 28 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 29 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 30 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 31 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 32 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 33 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 34 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 35 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 36 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 37 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 38 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 39 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 40 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 41 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 42 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 43 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 44 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 45 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 46 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 47 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 48 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 49 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 50 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 51 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 52 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 53 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 54 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 55 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 56 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 57 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 58 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 59 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 60 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 61 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 62 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 63 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 64 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 65 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 66 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 67 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 68 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 69 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 70 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 71 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 72 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 73 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 74 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 75 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 76 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 77 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 78 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 79 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 80 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 81 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 82 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 83 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 84 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 85 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 86 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 87 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 88 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 89 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 90 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 91 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 92 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 93 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 94 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 95 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 96 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 97 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 98 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 99 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 100 - loss: 0.0000 - accuracy: 1.0000

# Evaluate on separate test set
test_landscapes <- create_landscapes(
  n = 10,
  patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
)
#> ✔ Successfully generated all 10 training landscapes
results <- apply_nn_pixels(
  landscapes = test_landscapes,
  nn_model = final_model,
  return_performance = TRUE
)
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 1-fold cross-validation
#> ℹ Overall accuracy: 100%
#> 
#> ── Confusion matrix 
#>            Actual
#> Predicted   bands clustered diffuse fingers random sharp
#>   bands         1         0       0       0      0     0
#>   clustered     0         2       0       0      0     0
#>   diffuse       0         0       2       0      0     0
#>   fingers       0         0       0       2      0     0
#>   random        0         0       0       0      1     0
#>   sharp         0         0       0       0      0     2
#> 
#> ── Per-class performance 
#> # A tibble: 6 × 5
#>   class     count recall precision f1_score
#>   <chr>     <int>  <dbl>     <dbl>    <dbl>
#> 1 bands         1      1         1        1
#> 2 clustered     2      1         1        1
#> 3 diffuse       2      1         1        1
#> 4 fingers       2      1         1        1
#> 5 random        1      1         1        1
#> 6 sharp         2      1         1        1
# }
```
