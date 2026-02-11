# Train a Convolutional Neural Network for Landscape Classification

Trains a CNN model using the Keras framework to classify landscapes
based on their spatial patterns. The function uses a multiscale CNN
architecture optimized for distinguishing different landscape patterns.

## Usage

``` r
train_nn_landscapes(
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
  callbacks = NULL,
  patience = 15,
  verbose = TRUE
)
```

## Arguments

- landscapes:

  List. List of landscape objects created by \`create_landscape()\` or
  \`create_training_landscapes()\`.

- cv_method:

  Character. Cross-validation method: "none", "k-fold", "loo" (default:
  "k-fold").

  - "k-fold" or "loo": Performs cross-validation and returns performance
    metrics

  - "none": Trains on ALL provided data without validation. Use
    apply_nn_landscapes() with a separate test set to evaluate
    performance.

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

  Character. CNN architecture: "multiscale" (default).

- dropout_rate:

  Numeric. Dropout rate for regularization (default: 0.3).

- dense_units:

  Integer. Units in dense layer (default: 128).

- model_path:

  Character. Path to save model (default: NULL means model is not
  saved).

- loss:

  Character. Loss function for training (default:
  "categorical_crossentropy"). Common alternatives:
  "sparse_categorical_crossentropy", "kullback_leibler_divergence".

- optimizer:

  Character. Optimizer to use: "adam" (default), "sgd", "rmsprop". Note:
  optimizer-specific parameters like momentum are currently not exposed.

- metrics:

  Character vector. Metrics to track during training (default:
  c("accuracy")). Common additions: "categorical_accuracy",
  "top_k_categorical_accuracy".

- callbacks:

  List. Optional keras callbacks for advanced training control (default:
  NULL). Examples: early stopping, learning rate scheduling, model
  checkpointing. Note: Only applies to final model training. CV folds
  always use patience-based early stopping if patience is specified.

- patience:

  Integer. Number of epochs with no improvement before early stopping
  (default: 15). Applied to both CV fold training (monitors validation
  loss) and final model training (monitors training loss). Only used
  when callbacks=NULL. Set to NULL to train for full epoch count without
  early stopping.

- verbose:

  Logical. Show training progress and performance summaries (default:
  TRUE). When TRUE, displays progress bar for final model training and
  prints performance metrics. When FALSE, runs silently. CV fold
  training always runs silently to reduce output clutter.

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

## Examples

``` r
if (FALSE) { # \dontrun{
# Create training data
training_landscapes <- create_training_landscapes(
  n = 200,
  patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
)

# Train with cross-validation
model <- train_nn_landscapes(
  landscapes = training_landscapes,
  cv_method = "k-fold",
  cv_folds = 5
)

# Train on all data for final deployment model
final_model <- train_nn_landscapes(
  landscapes = training_landscapes,
  cv_method = "none",
  epochs = 100
)

# Evaluate on separate test set
test_landscapes <- create_training_landscapes(
  n = 100,
  patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
)
results <- apply_nn_landscapes(
  landscapes = test_landscapes,
  nn_model = final_model,
  return_performance = TRUE
)
} # }
```
