# Create a landscape with very dense vegetation

Creates a landscape with dense vegetation cover using random
distribution. This is a specialized wrapper around
[`create_landscape_random`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md)
with high vegetation proportions.

## Usage

``` r
create_landscape_dense(veg_prop = 0.9, width = 100, height = 100)
```

## Arguments

- veg_prop:

  Numeric. Proportion of cells with vegetation (0-1). Default: 0.9.

- width:

  Integer. Width of landscape in cells. Default: 100.

- height:

  Integer. Height of landscape in cells. Default: 100.

## Value

A landscape object with pattern "dense" containing

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "dense"

- params:

  List of all input parameters used to generate the landscape

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md),
[`create_landscape_bands()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_clustered.md),
[`create_landscape_diffuse()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_diffuse.md),
[`create_landscape_fingers()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_fingers.md),
[`create_landscape_gaps()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_gaps.md),
[`create_landscape_labyrinth()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_labyrinth.md),
[`create_landscape_random()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md),
[`create_landscape_sharp()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_sharp.md),
[`create_landscape_spots()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md),
[`create_landscapes()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)

## Examples

``` r
# Create default dense landscape (90% vegetation)
dense <- create_landscape_dense()

# Create very dense landscape
very_dense <- create_landscape_dense(veg_prop = 0.95)
```
