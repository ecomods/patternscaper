# Summarise the geometry of a landscape

Internal helper returning the spatial geometry of a single landscape
object: its cell dimensions, resolution, aspect ratio and number of
missing cells. Used to compare training and application landscapes so
that mismatches in extent, resolution, aspect ratio or missing data can
be reported.

## Usage

``` r
landscape_geometry(landscape)
```

## Arguments

- landscape:

  A landscape object.

## Value

A one-row tibble with columns \`n_row\`, \`n_col\`, \`cell_size_x\`,
\`cell_size_y\`, \`aspect_ratio\` (\`n_col / n_row\`) and \`n_na\`.
