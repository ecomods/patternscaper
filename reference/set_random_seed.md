# Set Random Seeds for Neural Network Training

Sets random seeds for R and Keras to support reproducible neural network
training. This is a convenience wrapper around
[`set.seed`](https://rdrr.io/r/base/Random.html) and
[`set_random_seed`](https://keras3.posit.co/reference/set_random_seed.html).

## Usage

``` r
set_random_seed(seed)
```

## Arguments

- seed:

  Integer seed value.

## Value

Invisibly returns `NULL`. Called for side effects.

## Details

Neural network training involves randomness from R (data shuffling and
CV fold creation) and Keras/TensorFlow (weight initialization and
dropout).

Seed both to reproduce a training run as closely as possible. Call this
function immediately before each training call because landscape
generation and other R operations advance R's random-number stream.
Minor variations may still occur across different hardware and software
configurations.

## See also

Other neural network training:
[`save_pixel_model()`](https://ecomods.github.io/patternscaper/reference/save_pixel_model.md),
[`train_metric_model()`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md),
[`train_pixel_model()`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)

## Examples

``` r
if (FALSE) { # requireNamespace("reticulate", quietly = TRUE) && reticulate::virtualenv_exists("r-keras")
# Generate reproducible training data
set.seed(42)
landscapes <- create_landscapes(n = 6, patterns = c("sharp", "random"))

# Reset both random-number generators immediately before training
set_random_seed(42)
model <- train_pixel_model(landscapes, cv_method = "none", epochs = 5)
}
```
