# Create a Landscape with Specified Pattern

A generic function that creates various patterns of landscape matrices
using specialized functions. The pattern of landscape is determined by
the 'pattern' parameter.

## Usage

``` r
create_landscape(
  pattern = c("random", "bare", "dense", "sharp", "diffuse", "fingers", "clustered",
    "bands", "spots", "gaps", "labyrinth"),
  width = 100,
  height = 100,
  name = NULL,
  custom_pattern = NULL,
  ...
)
```

## Arguments

- pattern:

  Character. pattern of landscape to generate: "random", "bare",
  "dense", "sharp", "diffuse", "fingers", "bands", "clustered", "spots",
  "gaps", "labyrinth"

- width:

  Integer. Width of the landscape in pixels (default: 100).

- height:

  Integer. Height of the landscape in pixels (default: 100).

- name:

  Character. Optional name for the landscape (default: NULL).

- custom_pattern:

  Character. Optional pattern for the landscape (default: NULL uses the
  default pattern of the corresponding function).

- ...:

  Parameters passed to specific landscape functions. See the
  documentation of the individual functions for details on required and
  optional parameters.

## Value

A landscape object with pattern corresponding to the pattern,
containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string with the pattern type

- params:

  List of all input parameters used to generate the landscape

## See also

[`plot_landscape`](https://ecomods.github.io/spatPatClassifyR/reference/plot_landscape.md)

Other landscape creation:
[`create_landscape_bands()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_clustered.md),
[`create_landscape_dense()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_dense.md),
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
# Create a default landscape of various patterns
random_default <- create_landscape("random")
sharp_default <- create_landscape("sharp")
diffuse_default <- create_landscape("diffuse")
clustered_default <- create_landscape("clustered")

# Create a modified landscape with custom parameters
random_modified <- create_landscape(
  "random",
  veg_prop = 0.3
)

# Create a modified landscape with custom parameters
diffuse_modified <- create_landscape(
  "diffuse",
  boundary_position = 0.3,
  steepness = 0.1
)

# Create a rotated landscape
bands_rotated <- create_landscape(
  "bands",
  band_thickness = 4,
  band_spacing = 12,
  amplitude = 6,
  noise_sd = 2,
  rotation = 45
)
```
