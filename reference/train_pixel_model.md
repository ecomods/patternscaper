# Train a Convolutional Neural Network for Landscape Pattern Classification

Trains a CNN model using the Keras framework via keras3 to classify
landscapes from their raster cell values. By default, the function uses
the built-in multiscale CNN architecture.

## Usage

``` r
train_pixel_model(
  landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 50,
  batch_size = 16,
  learning_rate = 0.001,
  architecture = "multiscale",
  dropout_rate = 0.3,
  dense_units = 128,
  loss = "categorical_crossentropy",
  optimizer = "adam",
  validation_split = 0,
  validation_landscapes = NULL,
  callbacks = NULL,
  patience = 15,
  verbose = TRUE
)
```

## Arguments

- landscapes:

  List. List of landscape objects created by
  [`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md)
  or
  [`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md).
  Input landscapes must contain categorical/discrete land-cover data
  represented by numeric whole-number codes, such as 0/1 for two
  land-cover categories or 0/1/2 for three categories. Text labels,
  continuous data such as elevation or gradients, and NA cells are not
  supported. Each landscape must contain exactly one raster layer and
  have the same number of rows and columns. At least two labelled
  pattern classes are required. Each land-cover code is converted to a
  separate binary input channel.

- cv_method:

  Character. Cross-validation method: "none", "k-fold", "loo" (default:
  "k-fold").

  - "k-fold" or "loo": Performs cross-validation and returns performance
    metrics

  - "none": Trains one final model, optionally with separate validation
    data for early stopping. Use
    [`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
    with an untouched test set for final performance evaluation.

- cv_folds:

  Integer. Number of cross-validation folds when cv_method="k-fold"
  (default: 5). Note: May be automatically reduced to ensure adequate
  samples per fold.

- epochs:

  Integer. Number of training epochs (default: 50).

- batch_size:

  Integer. Batch size for training (default: 16).

- learning_rate:

  Numeric. Learning rate for the optimizer (default: 0.001).

- architecture:

  Either "multiscale" for the built-in CNN architecture or a
  model-building function. A custom function must accept the arguments
  `input_shape`, `n_classes`, `dropout_rate`, and `dense_units`, and
  return a new uncompiled Keras model each time it is called. The model
  must have one two-dimensional output with `n_classes` units and an
  explicitly configured softmax activation in its final layer.

- dropout_rate:

  Numeric. Dropout rate for regularization (0-1, default: 0.3). Higher
  values reduce overfitting but may decrease model capacity. Applied
  between convolutional and dense layers.

- dense_units:

  Integer. Number of units in the final dense layer before output
  (default: 128). Controls model capacity for learning complex pattern
  combinations.

- loss:

  Character. Loss function for training (default:
  "categorical_crossentropy"). Labels are one-hot encoded internally, so
  the loss must accept one-hot targets. "categorical_focal_crossentropy"
  is a useful alternative when classes are strongly imbalanced. See
  [`loss_categorical_crossentropy`](https://keras3.posit.co/reference/loss_categorical_crossentropy.html)
  for details.

- optimizer:

  Character. Optimizer algorithm: "adam" (default), "sgd", "rmsprop".
  Adam is recommended for most cases. See
  [`optimizer_adam`](https://keras3.posit.co/reference/optimizer_adam.html).
  Note: Advanced optimizer parameters (e.g., momentum, beta values) are
  not currently exposed.

- validation_split:

  Numeric. Fraction of training data to use as validation set during
  final model training (0-1, default: 0). The split is stratified so
  every pattern class remains in the training data and is also
  represented in the validation data. The realized fraction may differ
  slightly from the request. Use only with `cv_method = "none"` and do
  not combine with `validation_landscapes`.

- validation_landscapes:

  Optional list of independently prepared, labelled landscapes used to
  monitor validation loss during final model training. They must have
  the same dimensions, pattern classes, and numeric coding as
  `landscapes`. Use only with `cv_method = "none"` and
  `validation_split = 0`.

- callbacks:

  List. Optional keras callbacks for advanced training control (default:
  NULL). Examples: early stopping, learning rate scheduling, model
  checkpointing. Only applies to final model training. CV folds always
  train for the full requested number of epochs without callbacks. For
  an overview of available callbacks, see
  [`callback_early_stopping`](https://keras3.posit.co/reference/callback_early_stopping.html)
  (the callback used by default) and related callback functions.

- patience:

  Integer. Number of epochs with no improvement before early stopping
  (default: 15). Applied only to final model training, where it monitors
  validation loss if validation data are supplied. CV folds always train
  for the full requested number of epochs. Only used when
  `callbacks = NULL`. Set to NULL to train the final model for the full
  epoch count while still recording validation metrics. Is passed to
  [`callback_early_stopping`](https://keras3.posit.co/reference/callback_early_stopping.html).

- verbose:

  Logical. Show training progress and performance summaries (default:
  TRUE). When TRUE, displays epoch-by-epoch training/validation metrics
  during final model training, plus CV fold accuracies and final
  performance summaries. CV fold epoch details are not shown. When
  FALSE, most output is silenced, but warnings about the requested CV
  configuration being adjusted (e.g. folds reduced, switched to LOO) are
  always shown.

## Value

List containing:

- model:

  Trained keras model object

- history:

  Training history object from keras3::fit()

- classes:

  Character vector of class names used during training

- input_shape:

  Integer vector of input dimensions (height, width, channels)

- land_cover_values:

  Numeric vector of fitted land-cover codes in input-channel order

- architecture:

  Character, either "multiscale" or "custom"

- performance:

  Performance metrics. When cv_method != "none", contains results from
  evaluate_cv_performance() including confusion matrix, per-class
  metrics, overall accuracy, and the number of epochs completed by each
  fold. When cv_method = "none" and validation data are used, contains
  validation predictions, loss, accuracy, per-class metrics, and
  stopping metadata. Otherwise it contains training metadata only.

- training_geometry:

  One-row tibble summarising the geometry of the landscapes used to fit
  model weights (cell dimensions and resolution), recorded for
  reference.

## See also

[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)

Other neural network training:
[`save_pixel_model()`](https://ecomods.github.io/patternscaper/reference/save_pixel_model.md),
[`set_random_seed()`](https://ecomods.github.io/patternscaper/reference/set_random_seed.md),
[`train_metric_model()`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)

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

# Train with cross-validation
model <- train_pixel_model(
  landscapes = training_landscapes,
  cv_method = "k-fold",
  cv_folds = 2,
  epochs = 5
)

# Train without cross validation on all data
final_model <- train_pixel_model(
  landscapes = training_landscapes,
  cv_method = "none",
  epochs = 5
)
}
```
