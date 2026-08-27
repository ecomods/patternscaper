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
if (FALSE) { # requireNamespace("reticulate", quietly = TRUE) && reticulate::virtualenv_exists("r-keras")
# Create training data. Kept small so the example runs quickly; real
# training needs many more landscapes and epochs, see the vignette
# "Classify landscapes using Keras on landscape rasters".
training_landscapes <- create_landscapes(
  n = 12,
  patterns = c("sharp", "diffuse", "random")
)

# Train on all data for final deployment model
final_model <- train_pixel_model(
  landscapes = training_landscapes,
  cv_method = "none",
  epochs = 5
)

# Evaluate on separate test set
test_landscapes <- create_landscapes(
  n = 6,
  patterns = c("sharp", "diffuse", "random")
)
results <- apply_pixel_model(
  landscapes = test_landscapes,
  model = final_model
)
results$predictions
results$performance
}
```
