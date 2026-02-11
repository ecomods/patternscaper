# Create a Landscape with Specified Pattern

A generic function that creates various patterns of landscape matrices
using specialized functions. The pattern of landscape is determined by
the 'pattern' parameter.

## Usage

``` r
create_landscape(
  pattern = c("random", "bare", "dense", "sharp", "diffuse", "fingers", "clustered",
    "bands", "spots", "gaps", "labyrinth"),
  name = NULL,
  custom_pattern = NULL,
  ...
)
```

## Arguments

- pattern:

  Character. pattern of landscape to generate: "random", "sharp",
  "diffuse", "fingers", "bands", "clusters", "spots", "gaps",
  "labyrinth"

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

A landscape object with pattern corresponding to the pattern pattern,
containing the generated landscape data and parameters.

## See also

[`create_landscape_random`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md)
for "random" pattern parameters. "bare" and "dense" are aliases but are
produced either with low or high tree probabilities

[`create_landscape_sharp_treeline`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_sharp_treeline.md)
for "sharp" pattern parameters

[`create_landscape_diffuse_treeline`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_diffuse_treeline.md)
for "diffuse" pattern parameters

[`create_landscape_fingers`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_fingers.md)
for "fingers" pattern parameters

[`create_landscape_clustered`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_clustered.md)
for "clusters" pattern parameters

[`create_landscape_bands`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bands.md)
for "bands" pattern parameters

[`create_landscape_spots`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md)
for "spots" pattern parameters

[`create_landscape_gaps`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_gaps.md)
for "gaps" pattern parameters

[`create_landscape_labyrinth`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_labyrinth.md)
for "labyrinth" pattern parameters

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
  tree_prop = 0.3
)

# Create a modified landscape with custom parameters
diffuse_modified <- create_landscape(
  "diffuse",
  treeline_position = 0.3,
  scatter_density = 0.7,
  scatter_zone_prop = 0.2
)
#> Error in create_landscape_diffuse_treeline(...): unused arguments (scatter_density = 0.7, scatter_zone_prop = 0.2)

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
