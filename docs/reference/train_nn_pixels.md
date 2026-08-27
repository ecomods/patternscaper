# Train a Convolutional Neural Network for Landscape Pattern Classification

Trains a CNN model using the Keras framework via keras3 to classify
landscapes based on their spatial patterns (pixel data). The function
uses a multiscale CNN architecture optimized for distinguishing
different landscape patterns.

## Usage

``` r
train_nn_pixels(
  landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 50,
  batch_size = 16,
  learning_rate = 0.001,
  architecture = "multiscale",
  dropout_rate = 0.3,
  dense_units = 128,
  model_path = NULL,
  loss = "categorical_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy"),
  validation_split = 0,
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
  \*\*Note\*\*: Input landscapes must contain categorical/discrete
  habitat data (e.g., 0/1 for two habitat types, or 0/1/2 for three
  types). Continuous data (e.g., elevation, gradients) is not supported.
  All landscapes used for training are required to have the same spatial
  extent.

- cv_method:

  Character. Cross-validation method: "none", "k-fold", "loo" (default:
  "k-fold").

  - "k-fold" or "loo": Performs cross-validation and returns performance
    metrics

  - "none": Trains on ALL provided data without validation. Use
    [`apply_nn_pixels`](https://ecomods.github.io/patternscaper/reference/apply_nn_pixels.md)
    with a separate test set to evaluate performance.

- cv_folds:

  Integer. Number of cross-validation folds when cv_method="k-fold"
  (default: 5). Note: May be automatically reduced to ensure adequate
  samples per fold.

- epochs:

  Integer. Number of training epochs (default: 50).

- batch_size:

  Integer. Batch size for training (default: 16).

- learning_rate:

  Numeric. Learning rate for Adam optimizer (default: 0.001).

- architecture:

  Character. CNN architecture (default: "multiscale"). Currently only
  "multiscale" is supported, which uses multiple kernel sizes (3x3 and
  5x5) to capture patterns at different spatial scales.

- dropout_rate:

  Numeric. Dropout rate for regularization (0-1, default: 0.3). Higher
  values reduce overfitting but may decrease model capacity. Applied
  between convolutional and dense layers.

- dense_units:

  Integer. Number of units in the final dense layer before output
  (default: 128). Controls model capacity for learning complex pattern
  combinations.

- model_path:

  Character. Path to save model. Models are saved as \`.keras\` files.
  (default: NULL means model is not saved).

- loss:

  Character. Loss function for training (default:
  "categorical_crossentropy"). Use "sparse_categorical_crossentropy" if
  labels are integers rather than one-hot encoded. See
  [`loss_categorical_crossentropy`](https://keras3.posit.co/reference/loss_categorical_crossentropy.html)
  for details.

- optimizer:

  Character. Optimizer algorithm: "adam" (default), "sgd", "rmsprop".
  Adam is recommended for most cases. See
  [`optimizer_adam`](https://keras3.posit.co/reference/optimizer_adam.html).
  Note: Advanced optimizer parameters (e.g., momentum, beta values) are
  not currently exposed.

- metrics:

  Character vector. Metrics to track during training (default:
  c("accuracy")). Additional options: "categorical_accuracy",
  "top_k_categorical_accuracy". Does not affect training, only
  monitoring. See
  [`compile`](https://generics.r-lib.org/reference/compile.html).

- validation_split:

  Numeric. Fraction of training data to use as validation set during
  final model training and passed to
  [`fit`](https://generics.r-lib.org/reference/fit.html)(0-1, default:
  0). When \> 0, enables monitoring and early stopping on validation
  loss. Particularly useful when cv_method="none" to prevent
  overfitting. Ignored during CV fold training (which uses its own
  validation splits).

- callbacks:

  List. Optional keras callbacks for advanced training control (default:
  NULL). Examples: early stopping, learning rate scheduling, model
  checkpointing. Note: Only applies to final model training. CV folds
  always use patience-based early stopping if patience is specified. For
  an overview of available callbacks, see
  [`callback_early_stopping`](https://keras3.posit.co/reference/callback_early_stopping.html)
  (the callback used by default) and related \`callback\_\` functions.

- patience:

  Integer. Number of epochs with no improvement before early stopping
  (default: 15). Applied to both CV fold training (monitors validation
  loss) and final model training (monitors validation loss if
  \`validation_split\` \> 0). Only used when callbacks=NULL. Set to NULL
  to train for full epoch count without early stopping. Is passed to
  [`callback_early_stopping`](https://keras3.posit.co/reference/callback_early_stopping.html).

- verbose:

  Logical. Show training progress and performance summaries (default:
  TRUE). When TRUE, displays epoch-by-epoch training/validation metrics
  during final model training, plus CV fold accuracies and final
  performance summaries. CV fold epoch details are not shown. When
  FALSE, runs silently.

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

- architecture:

  Character, architecture type used ("multiscale")

- performance:

  Performance metrics. When cv_method != "none", contains results from
  evaluate_cv_performance() including confusion matrix, per-class
  metrics, and overall accuracy. When cv_method = "none", contains
  training metadata only (see note field for evaluation instructions).

## See also

[`apply_nn_pixels`](https://ecomods.github.io/patternscaper/reference/apply_nn_pixels.md)

Other neural network training:
[`set_random_seed()`](https://ecomods.github.io/patternscaper/reference/set_random_seed.md),
[`train_nn_metrics()`](https://ecomods.github.io/patternscaper/reference/train_nn_metrics.md)

## Examples

``` r
# \donttest{
# Create training data
training_landscapes <- create_landscapes(
  n = 200,
  patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
)
#> ✔ Successfully generated all 200 training landscapes

# Train with cross-validation
model <- train_nn_pixels(
  landscapes = training_landscapes,
  cv_method = "k-fold",
  cv_folds = 5
)
#> 
#> ── Landscape type distribution: ──
#> 
#> training_labels
#>     bands clustered   diffuse   fingers    random     sharp 
#>        33        33        34        33        33        34 
#> ── Cross-validation (k-fold, 5 folds) ──
#> 
#> ✔ Fold 1/5 accuracy: 0.8333
#> ✔ Fold 2/5 accuracy: 0.8333
#> ✔ Fold 3/5 accuracy: 0.8095
#> ✔ Fold 4/5 accuracy: 0.7895
#> ✔ Fold 5/5 accuracy: 0.7222
#> 
#> ── Cross-validation results ──
#> 
#> ℹ Method: 5-fold cross-validation
#> ℹ Overall accuracy: 80%
#> 
#> ── Confusion matrix 
#>            Actual
#> Predicted   bands clustered diffuse fingers random sharp
#>   bands        26         2       1       2      0     0
#>   clustered     1        19       0       7      0     0
#>   diffuse       4         0      32       0      0     0
#>   fingers       2         9       0      20      0     4
#>   random        0         0       1       0     33     0
#>   sharp         0         3       0       4      0    30
#> 
#> ── Per-class performance 
#> # A tibble: 6 × 5
#>   class     count recall precision f1_score
#>   <chr>     <int>  <dbl>     <dbl>    <dbl>
#> 1 bands        33   0.79      0.84     0.81
#> 2 clustered    33   0.58      0.7      0.63
#> 3 diffuse      34   0.94      0.89     0.91
#> 4 fingers      33   0.61      0.57     0.59
#> 5 random       33   1         0.97     0.99
#> 6 sharp        34   0.88      0.81     0.85
#> 
#> ── Accuracy and loss across folds ──
#> 
#> Mean accuracy: 0.7976 +- 0.0459
#> Mean loss: 0.5956 +- 0.1579
#> 
#> 
#> ── Training final model on all data (validation split: 0) ──
#> 
#> Epoch 1 - loss: 1.9607 - accuracy: 0.1950
#> Epoch 2 - loss: 1.3769 - accuracy: 0.4950
#> Epoch 3 - loss: 0.5326 - accuracy: 0.8250
#> Epoch 4 - loss: 0.2971 - accuracy: 0.8950
#> Epoch 5 - loss: 0.1829 - accuracy: 0.9450
#> Epoch 6 - loss: 0.1632 - accuracy: 0.9650
#> Epoch 7 - loss: 0.1692 - accuracy: 0.9550
#> Epoch 8 - loss: 0.0680 - accuracy: 0.9800
#> Epoch 9 - loss: 0.0101 - accuracy: 1.0000
#> Epoch 10 - loss: 0.0019 - accuracy: 1.0000
#> Epoch 11 - loss: 0.0010 - accuracy: 1.0000
#> Epoch 12 - loss: 0.0010 - accuracy: 1.0000
#> Epoch 13 - loss: 0.0004 - accuracy: 1.0000
#> Epoch 14 - loss: 0.0004 - accuracy: 1.0000
#> Epoch 15 - loss: 0.0003 - accuracy: 1.0000
#> Epoch 16 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 17 - loss: 0.0003 - accuracy: 1.0000
#> Epoch 18 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 19 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 20 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 21 - loss: 0.0002 - accuracy: 1.0000
#> Epoch 22 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 23 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 24 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 25 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 26 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 27 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 28 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 29 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 30 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 31 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 32 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 33 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 34 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 35 - loss: 0.0000 - accuracy: 1.0000
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

# Train without cross validation on all data
final_model <- train_nn_pixels(
  landscapes = training_landscapes,
  cv_method = "none",
  epochs = 100
)
#> ── Landscape type distribution: ──
#> 
#> training_labels
#>     bands clustered   diffuse   fingers    random     sharp 
#>        33        33        34        33        33        34 
#> ── Training final model on all data ──
#> 
#> ℹ Training on all data (validation split is 0)...
#> Epoch 1 - loss: 1.5645 - accuracy: 0.3450
#> Epoch 2 - loss: 1.0592 - accuracy: 0.5200
#> Epoch 3 - loss: 0.6512 - accuracy: 0.7200
#> Epoch 4 - loss: 0.4895 - accuracy: 0.7850
#> Epoch 5 - loss: 0.3321 - accuracy: 0.8700
#> Epoch 6 - loss: 0.1418 - accuracy: 0.9650
#> Epoch 7 - loss: 0.1040 - accuracy: 0.9600
#> Epoch 8 - loss: 0.0261 - accuracy: 0.9850
#> Epoch 9 - loss: 0.0285 - accuracy: 0.9950
#> Epoch 10 - loss: 0.3093 - accuracy: 0.9500
#> Epoch 11 - loss: 0.1795 - accuracy: 0.9350
#> Epoch 12 - loss: 0.0480 - accuracy: 0.9900
#> Epoch 13 - loss: 0.0136 - accuracy: 0.9950
#> Epoch 14 - loss: 0.0083 - accuracy: 1.0000
#> Epoch 15 - loss: 0.0014 - accuracy: 1.0000
#> Epoch 16 - loss: 0.0004 - accuracy: 1.0000
#> Epoch 17 - loss: 0.0004 - accuracy: 1.0000
#> Epoch 18 - loss: 0.0002 - accuracy: 1.0000
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
#> Epoch 34 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 35 - loss: 0.0000 - accuracy: 1.0000
#> Epoch 36 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 37 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 38 - loss: 0.0001 - accuracy: 1.0000
#> Epoch 39 - loss: 0.0001 - accuracy: 1.0000
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
# }
```
