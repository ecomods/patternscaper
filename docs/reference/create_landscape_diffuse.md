# Create a Landscape with Diffuse Vegetation Boundary

Generates a binary landscape with a diffuse vegetation boundary where
vegetation probability decreases with distance.

## Usage

``` r
create_landscape_diffuse(
  width = 100,
  height = 100,
  boundary_position = 0.2,
  steepness = 0.5,
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

- steepness:

  Numeric. Controls the transition gradient (0-1). Lower values (e.g.,
  0.1) create sharper transitions. Higher values (e.g., 0.9) create more
  gradual, diffuse transitions where vegetation probability persists
  further below the vegetation boundary (default: 0.5).

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "diffuse" containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "diffuse"

- params:

  List of all input parameters used to generate the landscape

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md),
[`create_landscape_bands()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_clustered.md),
[`create_landscape_dense()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_dense.md),
[`create_landscape_fingers()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_fingers.md),
[`create_landscape_gaps()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_gaps.md),
[`create_landscape_labyrinth()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_labyrinth.md),
[`create_landscape_random()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md),
[`create_landscape_sharp()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_sharp.md),
[`create_landscape_spots()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md),
[`create_landscapes()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)

## Examples

``` r
# Default diffuse vegetation boundary
diffuse_default <- create_landscape_diffuse()

# Sharp transition (lower steepness)
diffuse_sharp <- create_landscape_diffuse(
  boundary_position = 0.2,
  steepness = 0.1
)

# Gradual transition (higher steepness)
diffuse_gradual <- create_landscape_diffuse(
  boundary_position = 0.3,
  steepness = 0.9
)

# With rotation
diffuse_rotated <- create_landscape_diffuse(
  boundary_position = 0.3,
  steepness = 0.7,
  rotation = 45
)
```
