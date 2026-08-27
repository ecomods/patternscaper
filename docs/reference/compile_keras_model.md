# Compile Keras Model

Compiles a keras model with specified loss function and optimizer.
Currently configured for multi-class classification problems.

## Usage

``` r
compile_keras_model(
  model,
  learning_rate = 0.001,
  loss = "categorical_crossentropy",
  optimizer = "adam"
)
```

## Arguments

- model:

  Keras model. Uncompiled model from create_keras_model().

- learning_rate:

  Numeric. Learning rate for optimizer (default: 0.001).

- loss:

  Character. Loss function (default: "categorical_crossentropy").

- optimizer:

  Character. Optimizer name: "adam", "sgd", "rmsprop" (default: "adam").

## Value

Compiled keras model.
