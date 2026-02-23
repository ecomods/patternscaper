# Train a Multi-Layer Neural Network for Landscape Pattern Classification

Trains a multi-layer neural network model to classify landscapes using
landscape metrics as features and using the neuralnet package. The
network's input layer has one neuron per metric, and the output layer
represents the pattern classes.

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
  landscape_id, landscape_name, pattern, level, class, metric, value.

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

  Integer vector. Number of neurons in each hidden layer passed to
  [`neuralnet`](https://rdrr.io/pkg/neuralnet/man/neuralnet.html).
  Length determines number of hidden layers. Default: 6 (single hidden
  layer with 6 neurons).

- threshold:

  Numeric. Threshold for partial derivatives as stopping criteria passed
  to [`neuralnet`](https://rdrr.io/pkg/neuralnet/man/neuralnet.html).
  Smaller values = more training iterations. Default: 0.01.

- stepmax:

  Integer. Maximum number of training steps passed to
  [`neuralnet`](https://rdrr.io/pkg/neuralnet/man/neuralnet.html).
  Default: 1e+05.

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

## See also

[`apply_nn_metrics`](https://ecomods.github.io/spatPatClassifyR/reference/apply_nn_metrics.md),
[`evaluate_landscape_metrics`](https://ecomods.github.io/spatPatClassifyR/reference/evaluate_landscape_metrics.md)

Other neural network training:
[`set_random_seed()`](https://ecomods.github.io/spatPatClassifyR/reference/set_random_seed.md),
[`train_nn_pixels()`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_pixels.md)

## Examples

``` r
# \donttest{
# Generate training landscapes
landscapes <- create_landscapes(n = 30, patterns = c("random", "sharp", "diffuse"))
#> ✔ Successfully generated all 30 training landscapes

# Calculate landscape metrics
metrics <- calculate_landscape_metrics(landscapes, level = "landscape")
#>  ■■■■■■■■■■                        30% |  ETA:  7s
#>  ■■■■■■■■■■■■■■■                   45% |  ETA:  7s
#>  ■■■■■■■■■■■■■■■■■                 53% |  ETA:  8s
#>  ■■■■■■■■■■■■■■■■■■■■■■■■■■        82% |  ETA:  3s

# Find the best 10 metrics for classification
best_10 <- evaluate_landscape_metrics(metrics, metrics_number = 10)
#> Warning: Excluded 180 rows containing 6 metrics with NA values. Metrics removed:
#> "enn_cv", "enn_mn", "enn_sd", "iji", "pafrac", and "rpr" Use
#> `exclude_NA_metrics = FALSE` to retain (not recommended for model training)
#> Warning: Excluded 3 metrics with zero variance: "pr", "prd", and "ta"
#> ! Only 4 uncorrelated metrics found. Filling to 10 with correlated metrics.

# Train model with cross-validation
model <- train_nn_metrics(metrics, metrics_selected = best_10, cv_method = "k-fold", cv_folds = 3)
#> ℹ Low sample-to-predictor ratio (3:1). Consider LOO CV or reducing features.
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 3-fold cross-validation
#> ℹ Overall accuracy: 96.67%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       9      0     0
#>   random        0     10     0
#>   sharp         1      0    10
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <int>  <dbl>     <dbl>    <dbl>
#> 1 diffuse    10    0.9      1        0.95
#> 2 random     10    1        1        1   
#> 3 sharp      10    1        0.91     0.95

# Train with specific metrics
selected <- c("ai", "lsi", "ed", "np")
model <- train_nn_metrics(
  metrics,
  metrics_selected = selected,
  hidden_layers = c(8, 4)
)
#> ℹ Reducing CV folds from 5 to 3 to maintain 3 samples per class per fold.
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 3-fold cross-validation
#> ℹ Overall accuracy: 100%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse      10      0     0
#>   random        0     10     0
#>   sharp         0      0    10
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <int>  <dbl>     <dbl>    <dbl>
#> 1 diffuse    10      1         1        1
#> 2 random     10      1         1        1
#> 3 sharp      10      1         1        1
# }

if (FALSE) { # \dontrun{
# Save model to file
model <- train_nn_metrics(
  metrics,
  model_path = "models/landscape_classifier.rds"
)
} # }
```
