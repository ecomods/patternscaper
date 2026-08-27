# Create a Landscape with a Sharp Vegetation Boundary

Create a Landscape with a Sharp Vegetation Boundary

## Usage

``` r
create_landscape_sharp(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  random_spots = c(0, 0),
  rotation = 0
)
```

## Arguments

- width:

  Integer. Width of the landscape in pixels (default: 100).

- height:

  Integer. Height of the landscape in pixels (default: 100).

- boundary_position:

  Numeric. Relative position of vegetation boundary from top (0-1)
  (default: 0.5).

- random_spots:

  Numeric vector of length 2. Probabilities for flipping cells: \[1→0,
  0→1\] (default: c(0,0)).

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "sharp" containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "sharp"

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
[`create_landscape_random()`](https://ecomods.github.io/patternscaper/reference/create_landscape_random.md),
[`create_landscape_spots()`](https://ecomods.github.io/patternscaper/reference/create_landscape_spots.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

## Examples

``` r
# Default sharp vegetation boundary
sharp_default <- create_landscape_sharp()

# Modified sharp vegetation boundary with higher boundary position
sharp_modified <- create_landscape_sharp(
  boundary_position = 0.7
)

# Landscape with rotation and some spots
sharp_rotated <- create_landscape_sharp(
  boundary_position = 0.3,
  random_spots = c(0, 0.1),
  rotation = 45
)
```
