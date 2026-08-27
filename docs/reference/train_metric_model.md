# Train a Multi-Layer Neural Network for Landscape Pattern Classification

Trains a multi-layer neural network model to classify landscapes using
landscape metrics as features and using the neuralnet package. The
network's input layer has one neuron per metric, and the output layer
represents the pattern classes.

## Usage

``` r
train_metric_model(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_layers = 6,
  threshold = 0.01,
  stepmax = 1e+05,
  na_action = "drop_metrics",
  verbose = TRUE
)
```

## Arguments

- metrics:

  Tibble or data frame. Output from calculate_metrics() containing
  landscape metrics in long format with required columns: landscape_id,
  landscape_name, pattern, level, class, metric, value.

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

- na_action:

  Character. How to obtain the complete predictor matrix the network
  requires when a metric is missing for some but not all landscapes.
  `"drop_metrics"` (default) drops the affected metrics and keeps every
  landscape; `"drop_landscapes"` keeps every metric and drops the
  affected landscapes. Either way the cost of both options is reported.
  Metrics that are NA for every landscape, and landscapes that are NA
  for every metric, are always removed first as they do not carry any
  information.

- verbose:

  Logical. Print training details and cross-validation results. Default:
  TRUE. When FALSE, most output is silenced, but warnings about the
  requested CV configuration being adjusted (e.g. folds reduced,
  switched to LOO) are always shown.

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

- training_geometry:

  One-row tibble summarising the geometry of the training landscapes,
  used by
  [`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md)
  to warn on geometry mismatch. NULL if the metrics table carries no
  geometry columns.

## See also

[`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md),
[`evaluate_metrics`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md)

Other neural network training:
[`save_pixel_model()`](https://ecomods.github.io/patternscaper/reference/save_pixel_model.md),
[`set_random_seed()`](https://ecomods.github.io/patternscaper/reference/set_random_seed.md),
[`train_pixel_model()`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)

## Examples

``` r
# \donttest{
# Generate training landscapes
landscapes <- create_landscapes(
  n = 18,
  patterns = c("random", "sharp", "diffuse")
)
#> ✔ Successfully generated all 18 training landscapes

# Calculate landscape metrics
metrics <- calculate_metrics(landscapes, level = "landscape")
#>  ■■■■■■■■■■■                       35% |  ETA:  5s
#>  ■■■■■■■■■■■■■■■■■                 53% |  ETA:  5s
#>  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■     92% |  ETA:  1s

# Find the best 5 metrics for classification
best_5 <- evaluate_metrics(metrics, metrics_number = 5)
#> Warning: Excluded 6 metrics with missing values (108 rows removed).
#> ✖ NA value for at least one landscape: "enn_cv", "enn_mn", "enn_sd", "iji",
#>   "pafrac", and "rpr"
#> ℹ Use `exclude_incomplete_metrics = FALSE` to retain them (not recommended for
#>   model training).
#> Warning: Excluded 3 metrics with no variation across landscapes: "pr", "prd", and "ta"

# Train model with cross-validation. Only 2 folds, as each fold needs at
# least 3 landscapes per pattern.
model <- train_metric_model(
  metrics,
  metrics_selected = best_5,
  cv_method = "k-fold",
  cv_folds = 2
)
#> ℹ Low sample-to-predictor ratio (3.6:1). Consider LOO CV or reducing features.
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 2-fold cross-validation
#> ℹ Overall accuracy: 94.44%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       6      1     0
#>   random        0      5     0
#>   sharp         0      0     6
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     6   1         0.86     0.92
#> 2 random      6   0.83      1        0.91
#> 3 sharp       6   1         1        1   

# Train with specific metrics, on all data and without cross-validation
selected <- c("ai", "lsi", "ed", "np")
model <- train_metric_model(
  metrics,
  metrics_selected = selected,
  cv_method = "none",
  hidden_layers = c(8, 4)
)
#> ℹ Low sample-to-predictor ratio (4.5:1). Consider LOO CV or reducing features.

# Save the model, to apply it later without retraining
model_file <- tempfile(fileext = ".rds")
saveRDS(model, model_file)
model <- readRDS(model_file)
# }
```
