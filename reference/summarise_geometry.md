# Compact geometry summary from a per-landscape geometry table

Internal core that condenses a per-landscape geometry table (columns
\`n_row\`, \`n_col\`, \`cell_size_x\`, \`cell_size_y\`) into a one-row
record stored in a trained model. It records the representative
dimensions and resolution (the median, which equals the common value
when all landscapes match) plus whether the set is homogeneous in
dimensions \*and\* resolution, so that
[`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md)
and
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
can warn when application landscapes differ from the data the model was
trained on.

## Usage

``` r
summarise_geometry(geometry)
```

## Arguments

- geometry:

  A per-landscape geometry tibble (see
  [`landscapes_geometry`](https://ecomods.github.io/patternscaper/reference/landscapes_geometry.md)).

## Value

A one-row tibble with columns \`n_landscapes\`, \`n_row\`, \`n_col\`,
\`cell_size_x\`, \`cell_size_y\` and \`homogeneous\`.
