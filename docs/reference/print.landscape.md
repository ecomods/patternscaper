# Print a Landscape Object

Prints the landscape's name, pattern, dimensions, spatial properties,
value range, missing-value count, and generation parameters. Missing
name and pattern metadata are displayed as `<unnamed>` and
`<unknown pattern>`; the stored values remain `NA`.

## Usage

``` r
# S3 method for class 'landscape'
print(x, ...)
```

## Arguments

- x:

  A landscape object created by
  [`landscape`](https://ecomods.github.io/patternscaper/reference/landscape.md).

- ...:

  Unused.

## Value

The input landscape object `x`, returned invisibly.

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md),
[`plot.landscape()`](https://ecomods.github.io/patternscaper/reference/plot.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/patternscaper/reference/set_landscape_name.md),
[`set_landscape_pattern()`](https://ecomods.github.io/patternscaper/reference/set_landscape_pattern.md)

## Examples

``` r
# Create a landscape (0 = bare ground, 1 = vegetation)
mat <- matrix(rbinom(100, 1, 0.5), 10, 10)
l <- landscape(mat, pattern = "random", name = "example")

# Print it (calls print.landscape automatically)
l
#> Landscape: "example" [pattern: random]
#> -----------------------------------------
#> Dimensions: 10x10 (100 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0
#> Values    : min=0.0, max=1.0
#> Parameters: none

# Or explicitly
print(l)
#> Landscape: "example" [pattern: random]
#> -----------------------------------------
#> Dimensions: 10x10 (100 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0
#> Values    : min=0.0, max=1.0
#> Parameters: none
```
