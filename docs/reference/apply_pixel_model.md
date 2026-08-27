# Apply a Keras CNN Model for Landscape Pattern Classification

Applies a trained CNN model to classify new landscapes based on their
spatial patterns. Automatically resamples input landscapes to match the
model's expected dimensions.

## Usage

``` r
apply_pixel_model(landscapes, model, evaluate = "auto", verbose = TRUE)
```

## Arguments

- landscapes:

  Landscape object, or list of landscape objects, to classify. Rows and
  columns are resampled to the model's input dimensions using nearest
  neighbor resampling, which preserves categorical cell values. Each
  landscape must contain exactly one raster layer with
  categorical/discrete land-cover data represented by numeric
  whole-number codes. The codes must match those used during training. A
  trained land-cover code may be absent, but a new code is rejected.
  Text labels, continuous data such as elevation or gradients, and NA
  cells are not supported. A landscape whose aspect ratio differs from
  the training grid is resized anisotropically (stretched), which raises
  a warning.

- model:

  List. CNN model object from
  [`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md).

- evaluate:

  Character. Whether to evaluate the predictions against the true known
  classes of the landscapes: `"auto"` (default) evaluates when true
  classes are available and classifies only otherwise, `"required"`
  evaluates them and raises an error if it cannot, and `"none"`
  classifies only without performance evaluation.

- verbose:

  Logical. Show informational messages and performance summaries
  (default: TRUE). When TRUE, displays resize operations and performance
  evaluation results. When FALSE, runs silently. Warnings about unknown
  classes or invalid data always appear.

## Value

List with two elements:

- predictions:

  Tibble with one row per input landscape, in input order, and columns:

  landscape_id

  :   Integer landscape identifier

  landscape_name

  :   Character landscape name (if available)

  actual_class

  :   True class (if available)

  predicted_class

  :   Predicted landscape pattern

  score

  :   Score of the predicted class, i.e. the largest of the class scores
      below (not a calibrated probability). See
      [`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md),
      section "Interpreting the class scores", which applies to both
      workflows.

  \<class_name\>

  :   Score for each trained class, straight from the network's softmax
      output layer, so each row sums to 1. These scores show the model's
      relative support among the available classes for that landscape.
      One dominant score indicates a more decisive output, while similar
      scores indicate ambiguity. They are not probabilities that the
      classification is correct.

- performance:

  Performance metrics: confusion matrix, accuracy, and per-class
  recall/precision/F1. NULL if nothing was evaluated, which happens when
  `evaluate = "none"`, when no landscape has a known true class, or when
  some landscape's true known class was never seen during training.

## See also

[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md),
[`plot_classified_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_classified_landscapes.md)

Other neural network application:
[`apply_metric_model()`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md),
[`load_pixel_model()`](https://ecomods.github.io/patternscaper/reference/load_pixel_model.md)

## Examples

``` r
# Create training data. Kept small so the example runs quickly; real
# training needs many more landscapes and epochs, see the vignette
# "Classify landscapes using Keras on landscape rasters".
training_landscapes <- create_landscapes(
  n = 12,
  patterns = c("sharp", "diffuse", "random")
)
#> ✔ Successfully generated all 12 training landscapes

# Train on all data for final deployment model
final_model <- train_pixel_model(
  landscapes = training_landscapes,
  cv_method = "none",
  epochs = 5
)
#> 
#> ── Landscape type distribution: ──
#> 
#> fit_labels
#> diffuse  random   sharp 
#>       4       4       4 
#> ── Training final model on all data ──
#> 
#> Epoch 1 - loss: 1.0736 - accuracy: 0.3333
#> Epoch 2 - loss: 1.1172 - accuracy: 0.6667
#> Epoch 3 - loss: 2.0093 - accuracy: 0.3333
#> Epoch 4 - loss: 0.7767 - accuracy: 0.5833
#> Epoch 5 - loss: 0.6337 - accuracy: 0.8333

# Evaluate on separate test set
test_landscapes <- create_landscapes(
  n = 6,
  patterns = c("sharp", "diffuse", "random")
)
#> ✔ Successfully generated all 6 training landscapes
results <- apply_pixel_model(
  landscapes = test_landscapes,
  model = final_model
)
#> Warning: Some classes were never correctly predicted during evaluation: "sharp". Results
#> for these classes are unreliable.
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 1-fold cross-validation
#> ℹ Overall accuracy: 50%
#> 
#> ── Confusion matrix 
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       1      0     0
#>   random        1      2     2
#>   sharp         0      0     0
#> 
#> ── Per-class performance 
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     2    0.5       1       0.67
#> 2 random      2    1         0.4     0.57
#> 3 sharp       2    0         0       0   
results$predictions
#> # A tibble: 6 × 8
#>   landscape_id landscape_name  actual_class predicted_class score diffuse random
#>          <int> <chr>           <chr>        <chr>           <dbl>   <dbl>  <dbl>
#> 1            1 diffuse_1       diffuse      random          0.541   0.358  0.541
#> 2            2 diffuse_2_rot2… diffuse      diffuse         0.599   0.599  0.371
#> 3            3 random_3        random       random          0.857   0.113  0.857
#> 4            4 sharp_4_rot11   sharp        random          0.402   0.319  0.402
#> 5            5 random_5        random       random          0.852   0.117  0.852
#> 6            6 sharp_6_rot53   sharp        random          0.442   0.144  0.442
#> # ℹ 1 more variable: sharp <dbl>
results$performance
#> $confusion_matrix
#>          Actual
#> Predicted diffuse random sharp
#>   diffuse       1      0     0
#>   random        1      2     2
#>   sharp         0      0     0
#> 
#> $accuracy
#> [1] 0.5
#> 
#> $per_class_metrics
#> # A tibble: 3 × 5
#>   class   count recall precision f1_score
#>   <chr>   <dbl>  <dbl>     <dbl>    <dbl>
#> 1 diffuse     2    0.5       1       0.67
#> 2 random      2    1         0.4     0.57
#> 3 sharp       2    0         0       0   
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
```
