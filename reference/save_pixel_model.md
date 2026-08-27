# Save a Trained Pixel Model

Saves a complete pixel classifier as one model-bundle directory. The
bundle contains the trained Keras network and the R metadata needed by
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md),
including class names, input dimensions, and the fitted land-cover
codes. Move or archive the complete folder rather than the single files
inside it.

## Usage

``` r
save_pixel_model(model, path, overwrite = FALSE)
```

## Arguments

- model:

  List. Trained pixel model returned by
  [`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md).

- path:

  Character. Directory in which to save the complete model bundle. The
  path must not end in `.keras` or `.rds`; those files are managed
  inside the directory.

- overwrite:

  Logical. Whether to replace the model files in an existing directory
  (default: FALSE). Other files in that directory are not removed.

## Value

The normalized bundle path, invisibly.

## See also

[`load_pixel_model`](https://ecomods.github.io/patternscaper/reference/load_pixel_model.md),
[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)

Other neural network training:
[`set_random_seed()`](https://ecomods.github.io/patternscaper/reference/set_random_seed.md),
[`train_metric_model()`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md),
[`train_pixel_model()`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)

## Examples

``` r
if (FALSE) { # requireNamespace("reticulate", quietly = TRUE) && reticulate::virtualenv_exists("r-keras")
training_landscapes <- create_landscapes(
  n = 6,
  patterns = c("sharp", "random"),
  width = 20,
  height = 20
)
set_random_seed(42)
model <- train_pixel_model(
  training_landscapes,
  cv_method = "none",
  epochs = 1,
  verbose = FALSE
)

model_bundle <- tempfile("pixel-model-")
save_pixel_model(model, model_bundle)
reloaded_model <- load_pixel_model(model_bundle)
# Clean up the temporary bundle created for this example.
unlink(model_bundle, recursive = TRUE)
}
```
