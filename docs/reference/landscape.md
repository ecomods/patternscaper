# Create a Landscape Object

Wraps a matrix or SpatRaster with pattern, name, and
generation-parameter metadata into a landscape object that can be used
by other patternscaper functions.

## Usage

``` r
landscape(data, pattern = NA_character_, name = NA_character_, params = NULL)
```

## Arguments

- data:

  Matrix or `SpatRaster` containing landscape data.

- pattern:

  Character. Known pattern label, or `NA` if unknown (default).

- name:

  Character. Landscape name, or `NA` if unnamed (default).

- params:

  List. Parameters used to generate the landscape (default: NULL).
  [`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md)
  and
  [`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)
  fill this automatically.

## Value

A landscape object containing the data and metadata.

## See also

[`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

Other landscape objects:
[`plot.landscape()`](https://ecomods.github.io/patternscaper/reference/plot.landscape.md),
[`print.landscape()`](https://ecomods.github.io/patternscaper/reference/print.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/patternscaper/reference/set_landscape_name.md),
[`set_landscape_pattern()`](https://ecomods.github.io/patternscaper/reference/set_landscape_pattern.md)

## Examples

``` r
# Create from a binary matrix (0 = bare ground, 1 = vegetation)
mat <- matrix(rbinom(100, 1, 0.5), nrow = 10, ncol = 10)
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
