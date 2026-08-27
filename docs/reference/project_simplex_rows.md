# Row-wise projection onto the probability simplex

Applies
[`project_simplex`](https://ecomods.github.io/patternscaper/reference/project_simplex.md)
to each row of a matrix of raw network outputs, turning them into
per-row distributions for reporting.

## Usage

``` r
project_simplex_rows(x)
```

## Arguments

- x:

  Numeric matrix; each row is one landscape's raw class scores.

## Value

A matrix with the same dimensions and dimnames as \`x\`. Rows of finite
values are non-negative and sum to 1 up to floating-point error; a row
holding any non-finite value comes back as all \`NA_real\_\`.

## Details

The metric-based network has linear output units trained by squared
error against 0/1 class indicators (see
[`fit_nn_model`](https://ecomods.github.io/patternscaper/reference/fit_nn_model.md)),
so its outputs already sit close to a probability vector but are
unconstrained: they can fall below 0, rise above 1, and not sum to 1.
Projection is the smallest correction that fixes that, measured the same
way the training loss measures error.
