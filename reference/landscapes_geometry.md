# Summarise the geometry of several landscapes

Internal helper mapping
[`landscape_geometry`](https://ecomods.github.io/patternscaper/reference/landscape_geometry.md)
over a list of landscapes and row-binding the results, one row per
landscape.

## Usage

``` r
landscapes_geometry(landscapes)
```

## Arguments

- landscapes:

  A list of landscape objects.

## Value

A tibble with one row per landscape (columns as in
[`landscape_geometry`](https://ecomods.github.io/patternscaper/reference/landscape_geometry.md)).
