# Fit a neural network with a helpful error on training failure

Wraps
[`neuralnet::neuralnet()`](https://rdrr.io/pkg/neuralnet/man/neuralnet.html)
and converts its cryptic "the error derivative contains a NA" failure
into an actionable error. That failure typically means the network is
over-parameterized for the data (e.g. far more metrics than landscapes),
so the message points the user at metric selection. Any other error is
re-raised unchanged.

## Usage

``` r
fit_nn_model(data, hidden, threshold, stepmax)
```

## Arguments

- data:

  Data frame with predictor columns and a `pattern` factor.

- hidden:

  Numeric vector. Hidden layer sizes.

- threshold:

  Numeric. Passed to
  [`neuralnet::neuralnet()`](https://rdrr.io/pkg/neuralnet/man/neuralnet.html).

- stepmax:

  Numeric. Passed to
  [`neuralnet::neuralnet()`](https://rdrr.io/pkg/neuralnet/man/neuralnet.html).

## Value

A trained `nn` object.
