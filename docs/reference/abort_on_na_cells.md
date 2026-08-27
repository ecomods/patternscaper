# Abort if any landscape contains NA cells

The CNN has no representation for a missing cell. How an NA reaches the
network depends on the raster's type: as \`NaN\` for a float raster, as
a corrupted integer for the integer rasters
[`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)
Neither raises an error on its own, so training or prediction runs to
completion on meaningless pixel values. Used by both
[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)
and
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
so the two refuse the same input.

## Usage

``` r
abort_on_na_cells(landscapes, action)
```

## Arguments

- landscapes:

  List of landscape objects.

- action:

  Character. Verb naming what the caller was about to do, used in the
  error message ("train on", "classify").

## Value

Invisibly \`NULL\`. Called for the error.
