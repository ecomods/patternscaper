# Create a Binary Landscape with Randomly Distributed Vegetation

Create a Binary Landscape with Randomly Distributed Vegetation

## Usage

``` r
create_landscape_random(width = 100, height = 100, veg_prop = 0.5)
```

## Arguments

- width:

  Integer. Width of the landscape in pixels (default: 100).

- height:

  Integer. Height of the landscape in pixels (default: 100).

- veg_prop:

  Numeric. Probability of vegetation presence (0-1) (default: 0.5).
  Higher values result in a denser vegetation cover.

## Value

A landscape object with random pattern containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "random"

- params:

  List of all input parameters used to generate the landscape

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscape_bands()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/patternscaper/reference/create_landscape_clustered.md),
[`create_landscape_dense()`](https://ecomods.github.io/patternscaper/reference/create_landscape_dense.md),
[`create_landscape_diffuse()`](https://ecomods.github.io/patternscaper/reference/create_landscape_diffuse.md),
[`create_landscape_fingers()`](https://ecomods.github.io/patternscaper/reference/create_landscape_fingers.md),
[`create_landscape_gaps()`](https://ecomods.github.io/patternscaper/reference/create_landscape_gaps.md),
[`create_landscape_labyrinth()`](https://ecomods.github.io/patternscaper/reference/create_landscape_labyrinth.md),
[`create_landscape_sharp()`](https://ecomods.github.io/patternscaper/reference/create_landscape_sharp.md),
[`create_landscape_spots()`](https://ecomods.github.io/patternscaper/reference/create_landscape_spots.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

## Examples

``` r
# Default randomly distributed trees
random_default <- create_landscape_random()

# Higher tree density
random_dense <- create_landscape_random(veg_prop = 0.7)

# Custom dimensions
random_large <- create_landscape_random(width = 200, height = 150)
```
