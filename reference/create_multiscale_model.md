# Create Multiscale CNN Architecture

Create Multiscale CNN Architecture

## Usage

``` r
create_multiscale_model(
  input_shape,
  n_classes,
  dropout_rate = 0.3,
  dense_units = 128
)
```

## Arguments

- input_shape:

  Integer vector. Input dimensions.

- n_classes:

  Integer. Number of output classes.

- dropout_rate:

  Numeric. Dropout rate for regularization.

- dense_units:

  Integer. Units in dense layer.

## Value

Uncompiled keras model.
