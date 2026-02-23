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
landscapes <- create_landscapes(n=5)
#> ✔ Successfully generated all 5 training landscapes
model <- train_nn_pixels(landscapes, cv_method = "none", epochs = 10)
#> 
#> ── Landscape type distribution: ──
#> 
#> training_labels
#>    bare   dense diffuse  random   sharp 
#>       1       1       1       1       1 
#> ── Training final model on all data ──
#> 
#> ℹ Training on all data (validation split is 0)...
#> Epoch 1 - loss: 1.6097 - accuracy: 0.2000
#> Epoch 2 - loss: 1.4949 - accuracy: 0.2000
#> Epoch 3 - loss: 1.3860 - accuracy: 0.4000
#> Epoch 4 - loss: 1.0473 - accuracy: 0.8000
#> Epoch 5 - loss: 0.6227 - accuracy: 0.8000
#> Epoch 6 - loss: 0.2356 - accuracy: 1.0000
#> Epoch 7 - loss: 0.0701 - accuracy: 1.0000
#> Epoch 8 - loss: 0.0277 - accuracy: 1.0000
#> Epoch 9 - loss: 0.0006 - accuracy: 1.0000
#> Epoch 10 - loss: 0.0005 - accuracy: 1.0000
# }
```
