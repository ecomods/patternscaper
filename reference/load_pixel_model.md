# Load a Trained Pixel Model

Loads a model bundle written by
[`save_pixel_model`](https://ecomods.github.io/patternscaper/reference/save_pixel_model.md)
and reconstructs the complete object expected by
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md).

## Usage

``` r
load_pixel_model(path)
```

## Arguments

- path:

  Character. Directory containing a saved pixel model bundle.

## Value

A trained pixel model list with the Keras network and its R metadata.

## See also

[`save_pixel_model`](https://ecomods.github.io/patternscaper/reference/save_pixel_model.md),
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)

Other neural network application:
[`apply_metric_model()`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md),
[`apply_pixel_model()`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
