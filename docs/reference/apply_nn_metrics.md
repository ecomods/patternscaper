# Apply Neural Network for Landscape Pattern Classification Based on their Landscape Metrics

Applies a trained neural network model to classify new landscapes
according to their spatial pattern type. The function automatically
calculates the required landscape metrics needed by the model and scales
them appropriately.

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

  Probability for each class the model was trained on. Probabilities are
  derived from raw neural network outputs using softmax transformation.

When return_performance = TRUE and actual classes available: List
containing:

- predictions:

  Tibble as above, plus actual_class column

- performance:

  Performance metrics from evaluate_cv_performance(): confusion matrix,
  accuracy, and per-class recall/precision/F1

## See also

[`train_nn_metrics`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_metrics.md),
[`plot_classified_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/plot_classified_landscapes.md)

Other neural network application:
[`apply_nn_pixels()`](https://ecomods.github.io/spatPatClassifyR/reference/apply_nn_pixels.md)

## Examples

``` r
# \donttest{
# Train a model on reference landscapes
train_landscapes <- create_landscapes(n = 30, patterns = c("random", "sharp", "diffuse"))
#> ✔ Successfully generated all 30 training landscapes
metrics <- calculate_landscape_metrics(train_landscapes, level = "landscape")
#>  ■■■■■■■■                          23% |  ETA:  7s
#>  ■■■■■■■■■■■■■                     41% |  ETA:  7s
#>  ■■■■■■■■■■■■■■■■                  52% |  ETA:  8s
#>  ■■■■■■■■■■■■■■■■■■■■■■■■          76% |  ETA:  4s
# find the best 10 metrics for classification
best_10 <- evaluate_landscape_metrics(metrics, metrics_number = 10)
#> Warning: Excluded 180 rows containing 6 metrics with NA values. Metrics removed:
#> "enn_cv", "enn_mn", "enn_sd", "iji", "pafrac", and "rpr" Use
#> `exclude_NA_metrics = FALSE` to retain (not recommended for model training)
#> Warning: Excluded 3 metrics with zero variance: "pr", "prd", and "ta"
#> ! Only 6 uncorrelated metrics found. Filling to 10 with correlated metrics.
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
#>   diffuse      10      1     0
#>   random        0      9     0
#>   sharp         0      0    10
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <int>  <dbl>     <dbl>    <dbl>
#> 1 diffuse    10    1        0.91     0.95
#> 2 random     10    0.9      1        0.95
#> 3 sharp      10    1        1        1   

# Apply to new landscapes
new_landscapes <- create_landscapes(n = 5, patterns = c("random", "sharp"))
#> ✔ Successfully generated all 5 training landscapes
predictions <- apply_nn_metrics(new_landscapes, model)
predictions
#> # A tibble: 5 × 8
#>   landscape_id landscape_name actual_class predicted_class confidence diffuse
#>          <int> <chr>          <chr>        <chr>                <dbl>   <dbl>
#> 1            1 random_1       random       random               0.548   0.233
#> 2            2 random_2       random       random               0.571   0.216
#> 3            3 sharp_3_rot284 sharp        sharp                0.574   0.213
#> 4            4 random_4       random       random               0.580   0.209
#> 5            5 sharp_5_rot311 sharp        sharp                0.577   0.209
#> # ℹ 2 more variables: random <dbl>, sharp <dbl>

# Evaluate performance on labeled data
results <- apply_nn_metrics(new_landscapes, model, return_performance = TRUE)
#> Warning: Some classes were never correctly predicted during cross-validation: "diffuse".
#> Results for these classes are unreliable.
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 1-fold cross-validation
#> ℹ Overall accuracy: 100%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       0      0     0
#>   random        0      3     0
#>   sharp         0      0     2
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <int>  <dbl>     <dbl>    <dbl>
#> 1 diffuse    NA      0         0        0
#> 2 random      3      1         1        1
#> 3 sharp       2      1         1        1
results$predictions
#> # A tibble: 5 × 8
#>   landscape_id landscape_name actual_class predicted_class confidence diffuse
#>          <int> <chr>          <chr>        <chr>                <dbl>   <dbl>
#> 1            1 random_1       random       random               0.548   0.233
#> 2            2 random_2       random       random               0.571   0.216
#> 3            3 sharp_3_rot284 sharp        sharp                0.574   0.213
#> 4            4 random_4       random       random               0.580   0.209
#> 5            5 sharp_5_rot311 sharp        sharp                0.577   0.209
#> # ℹ 2 more variables: random <dbl>, sharp <dbl>
results$performance
#> $confusion_matrix
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       0      0     0
#>   random        0      3     0
#>   sharp         0      0     2
#> 
#> $accuracy
#> [1] 1
#> 
#> $per_class_metrics
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <int>  <dbl>     <dbl>    <dbl>
#> 1 diffuse    NA      0         0        0
#> 2 random      3      1         1        1
#> 3 sharp       2      1         1        1
#> 
#> $cv_method
#> [1] "none"
#> 
#> $cv_folds
#> [1] 1
#> 
#> $class_counts
#> [1] NA  3  2
#> 
# }

if (FALSE) { # \dontrun{
# Load a saved model
model <- readr::read_rds("models/landscape_classifier.rds")
predictions <- apply_nn_metrics(new_landscapes, model)
} # }
```
