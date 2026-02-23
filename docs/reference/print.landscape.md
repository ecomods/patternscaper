# Print a landscape object

Provides a concise summary of a landscape object, including its name,
pattern, dimensions, spatial properties, value range, and parameters.

## Usage

``` r
# S3 method for class 'landscape'
print(x, ...)
```

## Arguments

- x:

  A landscape object created by
  [`landscape`](https://ecomods.github.io/spatPatClassifyR/reference/landscape.md).

- ...:

  Additional arguments (currently unused).

## Value

The input landscape object `x`, returned invisibly.

## Details

The print method displays:

- Landscape name and pattern

- Dimensions (rows × columns and total cells)

- Resolution and spatial extent

- Value range (min/max) and count of NA values

- Parameters used to create the landscape (if available)

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/landscape.md),
[`plot.landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/plot.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_name.md),
[`set_landscape_pattern()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_pattern.md)

## Examples

``` r
# Create a landscape
mat <- matrix(1:100, 10, 10)
l <- landscape(mat, pattern = "test", name = "example")

# Print it (calls print.landscape automatically)
l
#> Landscape: "example" [ pattern: test ]
#> -----------------------------------------
#> Dimensions: 10x10 (100 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0
#> Values    : min=1.0, max=100.0
#> Parameters: none

# Or explicitly
print(l)
#> Landscape: "example" [ pattern: test ]
#> -----------------------------------------
#> Dimensions: 10x10 (100 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0
#> Values    : min=1.0, max=100.0
#> Parameters: none
```
