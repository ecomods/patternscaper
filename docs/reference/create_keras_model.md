# Create Keras Model Architecture

Create Keras Model Architecture

## Usage

``` r
create_keras_model(
  architecture = "multiscale",
  input_shape,
  n_classes,
  dropout_rate = 0.3,
  dense_units = 128
)
```

## Arguments

- architecture:

  Character. Architecture type.

- input_shape:

  Integer vector. Input dimensions (height, width, channels).

- n_classes:

  Integer. Number of output classes.

- dropout_rate:

  Numeric. Dropout rate for regularization (default: 0.3).

- dense_units:

  Integer. Units in dense layer (default: 128).

## Value

Uncompiled keras model.
