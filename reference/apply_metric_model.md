# Apply Neural Network for Landscape Pattern Classification Based on their Landscape Metrics

Applies a trained neural network model to classify new landscapes
according to their spatial pattern type. The function automatically
calculates the required landscape metrics needed by the model and scales
them appropriately.

## Usage

``` r
apply_metric_model(landscapes, model, evaluate = "auto", verbose = TRUE)
```

## Arguments

- landscapes:

  Landscape object (single) or list of landscape objects to classify.
  Landscapes must have valid raster data that can be analyzed by
  landscapemetrics.

- model:

  List. Trained model object returned from train_metric_model(). Must
  contain elements: model, scaling, classes, features, and
  features_level.

- evaluate:

  Character. Whether to evaluate the predictions against the true known
  classes of the landscapes: `"auto"` (default) evaluates when true
  classes are available and classifies only otherwise, `"required"`
  evaluates them and raises an error if it cannot, and `"none"`
  classifies only without performance evaluation.

- verbose:

  Logical. Show performance summaries when the predictions are evaluated
  (default: TRUE). When FALSE, runs silently. Warnings about unknown
  classes or incomplete metrics always appear.

## Value

List with two elements:

- predictions:

  Tibble with one row per input landscape, in input order, and columns:

  landscape_id

  :   Numeric landscape identifier

  landscape_name

  :   Character landscape name (if available)

  actual_class

  :   True class (if available)

  predicted_class

  :   Predicted landscape pattern, or NA if the landscape could not be
      classified

  score

  :   Score of the predicted class, i.e. the largest of the class scores
      below (not a calibrated probability). See the "Interpreting the
      class scores" section.

  \<class_name\>

  :   Score for each class the model was trained on. The raw network
      outputs are projected onto the probability simplex, so each row is
      non-negative and sums to 1.

- performance:

  Performance metrics: confusion matrix, accuracy, and per-class
  recall/precision/F1. NULL if nothing was evaluated, which happens when
  `evaluate = "none"`, when no landscape has a known true class, or when
  some landscape's true known class was never seen during training.

Landscapes that could not be classified count as incorrect, and appear
in the confusion matrix under "no prediction".

## Interpreting the class scores

`predicted_class` is the class with the largest \*raw\* network output,
so it never depends on how those outputs are turned into the scores
below.

The class scores are non-negative and sum to 1, but they are \*\*not
calibrated probabilities\*\*: a score of 0.8 does not mean the
prediction is correct 80% of the time. Calibration would require a
separate step fitted on held-out data, which this package does not do
(the same caveat applies to
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)).
What the scores do support:

- \*\*Ranking classes within a landscape.\*\* A higher score means the
  network supported that class more.

- \*\*The gap between the leading classes within a landscape.\*\* A
  near-tie means the network was torn between them; a wide gap means it
  was decisive. The projection shifts every class in a row by the same
  amount, so gaps between classes that keep a non-zero score are
  unchanged.

- \*\*Ranking landscapes by `score`\*\* to decide which ones to inspect
  visually. This is a heuristic ordering, not a probability of being
  correct.

What they do not support: reading a score as a percentage, or comparing
\*ratios\* of scores ("twice as likely"). The shared shift preserves
differences but not ratios, and it differs from landscape to landscape.
Gaps involving a class that was pushed to exactly 0 are not meaningful
either: several weakly-supported classes collapse onto 0 together, and
the projection discards how far below the others they were.

## Landscapes that cannot be classified

The neural network requires a complete set of its features for every
landscape. If a required metric cannot be calculated for a landscape,
that landscape cannot be classified. This could happen for example when
a class is absent from a landscape that was used as a basis for one of
the training metrics. The result is still returned, with `NA` for
`predicted_class`, `score` and every class probability, and a warning
names the affected landscapes. The output therefore always has one row
per input landscape. Performance metrics, when requested, are calculated
from the classified landscapes only.

## Geometry checks

If the model stores the geometry of its training landscapes (see
[`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)),
the application landscapes are compared against it and a warning is
issued when they differ substantially in extent, resolution or aspect
ratio, since scale-dependent metrics are then unreliable. If the model
has no stored training geometry, the checks are skipped with an
informative note (suppressed when `verbose = FALSE`).

## References

Wang, W., & Carreira-Perpinan, M. A. (2013). Projection onto the
probability simplex: an efficient algorithm with a simple proof, and an
application. arXiv:1309.1541.

## See also

[`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md),
[`plot_classified_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_classified_landscapes.md)

Other neural network application:
[`apply_pixel_model()`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md),
[`load_pixel_model()`](https://ecomods.github.io/patternscaper/reference/load_pixel_model.md)

## Examples

``` r
# \donttest{
# Train a model on reference landscapes
train_landscapes <- create_landscapes(
  n = 18,
  patterns = c("random", "sharp", "diffuse")
)
#> ✔ Successfully generated all 18 training landscapes
metrics <- calculate_metrics(train_landscapes, level = "landscape")
#>  ■■■■■■■■■                         26% |  ETA:  8s
#>  ■■■■■■■■■■■■■                     41% |  ETA:  8s
#>  ■■■■■■■■■■■■■■■■■                 53% |  ETA:  9s
#>  ■■■■■■■■■■■■■■■■■■■■■■■           73% |  ETA:  4s
# find the best 5 metrics for classification
best_5 <- evaluate_metrics(metrics, metrics_number = 5)
#> Warning: Excluded 6 metrics with missing values (108 rows removed).
#> ✖ NA value for at least one landscape: "enn_cv", "enn_mn", "enn_sd", "iji",
#>   "pafrac", and "rpr"
#> ℹ Use `exclude_incomplete_metrics = FALSE` to retain them (not recommended for
#>   model training).
#> Warning: Excluded 3 metrics with no variation across landscapes: "pr", "prd", and "ta"
# Train on all data, then evaluate below on a separate test set.
model <- train_metric_model(
  metrics,
  metrics_selected = best_5,
  cv_method = "none"
)
#> ℹ Low sample-to-predictor ratio (3.6:1). Consider LOO CV or reducing features.
model_file <- tempfile(fileext = ".rds")
saveRDS(model, model_file)
model <- readRDS(model_file)

# Apply to new landscapes
new_landscapes <- create_landscapes(
  n = 6,
  patterns = c("random", "sharp", "diffuse")
)
#> ✔ Successfully generated all 6 training landscapes
results <- apply_metric_model(new_landscapes, model)
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 1-fold cross-validation
#> ℹ Overall accuracy: 100%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       2      0     0
#>   random        0      2     0
#>   sharp         0      0     2
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     2      1         1        1
#> 2 random      2      1         1        1
#> 3 sharp       2      1         1        1
results$predictions
#> # A tibble: 6 × 8
#>   landscape_id landscape_name actual_class predicted_class score diffuse  random
#>          <int> <chr>          <chr>        <chr>           <dbl>   <dbl>   <dbl>
#> 1            1 random_1       random       random          1      0      1      
#> 2            2 random_2       random       random          0.907  0.0884 0.907  
#> 3            3 diffuse_3_rot… diffuse      diffuse         1      1      0      
#> 4            4 sharp_4_rot260 sharp        sharp           0.986  0.0139 0      
#> 5            5 diffuse_5_rot… diffuse      diffuse         0.985  0.985  0.00687
#> 6            6 sharp_6_rot250 sharp        sharp           0.983  0.0170 0      
#> # ℹ 1 more variable: sharp <dbl>

# The true classes are known here, so performance is scored automatically
results$performance
#> $confusion_matrix
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       2      0     0
#>   random        0      2     0
#>   sharp         0      0     2
#> 
#> $accuracy
#> [1] 1
#> 
#> $per_class_metrics
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     2      1         1        1
#> 2 random      2      1         1        1
#> 3 sharp       2      1         1        1
#> 
#> $cv_method
#> [1] "none"
#> 
#> $cv_folds
#> [1] 1
#> 
#> $class_counts
#> [1] 2 2 2
#> 

# Classify without scoring, even though the landscapes carry true classes
apply_metric_model(new_landscapes, model, evaluate = "none")$predictions
#> # A tibble: 6 × 8
#>   landscape_id landscape_name actual_class predicted_class score diffuse  random
#>          <int> <chr>          <chr>        <chr>           <dbl>   <dbl>   <dbl>
#> 1            1 random_1       random       random          1      0      1      
#> 2            2 random_2       random       random          0.907  0.0884 0.907  
#> 3            3 diffuse_3_rot… diffuse      diffuse         1      1      0      
#> 4            4 sharp_4_rot260 sharp        sharp           0.986  0.0139 0      
#> 5            5 diffuse_5_rot… diffuse      diffuse         0.985  0.985  0.00687
#> 6            6 sharp_6_rot250 sharp        sharp           0.983  0.0170 0      
#> # ℹ 1 more variable: sharp <dbl>

# A model saved earlier is read back with readRDS()
saved_model <- readRDS(model_file)
apply_metric_model(new_landscapes, saved_model)
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 1-fold cross-validation
#> ℹ Overall accuracy: 100%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       2      0     0
#>   random        0      2     0
#>   sharp         0      0     2
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     2      1         1        1
#> 2 random      2      1         1        1
#> 3 sharp       2      1         1        1
#> $predictions
#> # A tibble: 6 × 8
#>   landscape_id landscape_name actual_class predicted_class score diffuse  random
#>          <int> <chr>          <chr>        <chr>           <dbl>   <dbl>   <dbl>
#> 1            1 random_1       random       random          1      0      1      
#> 2            2 random_2       random       random          0.907  0.0884 0.907  
#> 3            3 diffuse_3_rot… diffuse      diffuse         1      1      0      
#> 4            4 sharp_4_rot260 sharp        sharp           0.986  0.0139 0      
#> 5            5 diffuse_5_rot… diffuse      diffuse         0.985  0.985  0.00687
#> 6            6 sharp_6_rot250 sharp        sharp           0.983  0.0170 0      
#> # ℹ 1 more variable: sharp <dbl>
#> 
#> $performance
#> $performance$confusion_matrix
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       2      0     0
#>   random        0      2     0
#>   sharp         0      0     2
#> 
#> $performance$accuracy
#> [1] 1
#> 
#> $performance$per_class_metrics
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     2      1         1        1
#> 2 random      2      1         1        1
#> 3 sharp       2      1         1        1
#> 
#> $performance$cv_method
#> [1] "none"
#> 
#> $performance$cv_folds
#> [1] 1
#> 
#> $performance$class_counts
#> [1] 2 2 2
#> 
#> 
# }
```
