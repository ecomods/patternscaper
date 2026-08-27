# Compact geometry summary of a set of landscapes

Internal helper: computes the per-landscape geometry of a list of
landscapes and condenses it via
[`summarise_geometry`](https://ecomods.github.io/patternscaper/reference/summarise_geometry.md).
Used by
[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md),
which receives landscape objects directly.

## Usage

``` r
summarise_training_geometry(landscapes)
```

## Arguments

- landscapes:

  A list of landscape objects.

## Value

A one-row tibble (see
[`summarise_geometry`](https://ecomods.github.io/patternscaper/reference/summarise_geometry.md)).
