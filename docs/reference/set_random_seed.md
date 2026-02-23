# Set Random Seeds for Reproducible Neural Network Training

Sets random seeds for R and Keras to ensure reproducible results when
training neural networks. This is a convenience wrapper around
\[base::set.seed()\] and \[keras3::set_random_seed()\].

## Usage

``` r
set_random_seed(seed)
```

## Arguments

- seed:

  Integer seed value.

## Value

Invisibly returns \`NULL\`. Called for side effects.

## Details

Neural network training involves randomness from: - R's RNG (data
shuffling, CV fold creation) - Keras/TensorFlow's RNG (weight
initialization, dropout)

Both must be seeded for reproducible results. Note that minor variations
may still occur across different hardware/software configurations.

## See also

Other neural network training:
[`train_nn_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_metrics.md),
[`train_nn_pixels()`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_pixels.md)

## Examples

``` r
# \donttest{
# Ensure reproducible training
set_random_seed(42)
model <- train_nn_pixels(landscapes, cv_folds = 5)
#> Error: object 'landscapes' not found
# }
```
