# Create a landscape object

Converts a matrix or SpatRaster into a landscape object that can be used
with landscape analysis functions.

## Usage

``` r
landscape(data, pattern = NA_character_, name = NA_character_, params = NULL)
```

## Arguments

- data:

  Matrix or SpatRaster containing landscape data

- pattern:

  Character string specifying the landscape pattern if known (default
  NA).

- name:

  Character string specifying the landscape name to distinguish it from
  other landscapes (default NA).

- params:

  List of parameters used to create the landscape. Can be empty but will
  be filled if landscapes are created automatically by the
  [`create_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)
  or the
  [`create_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)
  function. Default is NULL.

## Value

A landscape object

## See also

[`create_landscape`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md),
[`create_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)

Other landscape objects:
[`plot.landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/plot.landscape.md),
[`print.landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/print.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_name.md),
[`set_landscape_pattern()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_pattern.md)

## Examples

``` r
# Create from a matrix
mat <- matrix(runif(100), nrow = 10, ncol = 10)
l <- landscape(mat)

# Create with pattern and name
l <- landscape(mat, pattern = "random", name = "test_landscape")

# Create with parameters
l <- landscape(
  mat,
  pattern = "sharp",
  name = "alpine_treeline",
  params = list(boundary_position = 0.5, rotation = 0)
)

# Create from SpatRaster
rast <- terra::rast(mat)
l <- landscape(rast, name = "my_raster")
```
