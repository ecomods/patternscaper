# Create a Dense Landscape

Creates a landscape with dense tree coverage using random distribution.
This is a specialized wrapper around
[`create_landscape_random`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md)
with high tree proportions.

## Usage

``` r
create_landscape_dense(tree_prop = 0.9, width = 100, height = 100)
```

## Arguments

- tree_prop:

  Numeric. Proportion of cells with trees (0-1). Default: 0.9.

- width:

  Integer. Width of landscape in cells. Default: 100.

- height:

  Integer. Height of landscape in cells. Default: 100.

## Value

A landscape object with pattern "dense".

## See also

[`create_landscape_random`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md),
[`create_landscape_bare`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bare.md)

## Examples

``` r
# Create default dense landscape (90% trees)
dense <- create_landscape_dense()
#> Error in create_landscape_dense(): could not find function "create_landscape_dense"

# Create very dense landscape
very_dense <- create_landscape_dense(tree_prop = 0.95)
#> Error in create_landscape_dense(tree_prop = 0.95): could not find function "create_landscape_dense"
```
