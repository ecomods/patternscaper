# Create a Bare Landscape

Creates a landscape with sparse tree coverage using random distribution.
This is a specialized wrapper around
[`create_landscape_random`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md)
with low tree proportions.

## Usage

``` r
create_landscape_bare(tree_prop = 0.1, width = 100, height = 100)
```

## Arguments

- tree_prop:

  Numeric. Proportion of cells with trees (0-1). Default: 0.1.

- width:

  Integer. Width of landscape in cells. Default: 100.

- height:

  Integer. Height of landscape in cells. Default: 100.

## Value

A landscape object with pattern "bare".

## See also

[`create_landscape_random`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md),
[`create_landscape_dense`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_dense.md)

## Examples

``` r
# Create default bare landscape (10% trees)
bare <- create_landscape_bare()
#> Error in create_landscape_bare(): could not find function "create_landscape_bare"

# Create very sparse landscape
very_bare <- create_landscape_bare(tree_prop = 0.05)
#> Error in create_landscape_bare(tree_prop = 0.05): could not find function "create_landscape_bare"
```
