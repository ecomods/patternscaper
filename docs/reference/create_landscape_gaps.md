# Create a Landscape with Gaps Pattern

Generates a binary landscape with circular gaps (bare patches in
vegetated ground). This is a convenience wrapper around
[`create_landscape_spots`](https://ecomods.github.io/patternscaper/reference/create_landscape_spots.md)
with `invert_landscape = TRUE` by default, making "gaps" and "spots"
semantically distinct pattern names for the same underlying algorithm.

## Usage

``` r
create_landscape_gaps(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_spots = FALSE
)
```

## Arguments

- width:

  Integer. Number of columns in the landscape (default: 100).

- height:

  Integer. Number of rows in the landscape (default: 100).

- n_spots:

  Integer. Number of circular spots to generate. For regular placement,
  this may be automatically reduced if the landscape cannot accommodate
  the requested number at the given \`spot_radius\`.

- spot_radius:

  Numeric. Mean radius of each spot in cells. Must be positive and
  smaller than landscape dimensions.

- spot_radius_sd:

  Numeric. Standard deviation for random variation in spot radius. Each
  spot's radius is sampled from N(spot_radius, spot_radius_sd).
  (default: 0 - no variation)

- radius_noise_fraction:

  Numeric (0 to 1). Proportion of the spot radius where gradual edge
  noise is applied. 0 creates sharp circular edges, 1 applies
  probabilistic cell inclusion across the entire radius. For example,
  0.2 means the outer 20 Works independently of \`spot_radius_sd\`
  (which varies the overall size, while this parameter affects edge
  sharpness).

- regular_spots:

  Logical. If TRUE, spots are arranged on a hexagonal grid using k-means
  clustering. If FALSE, spots are placed randomly (default: FALSE).

## Value

A landscape object with pattern "gaps" containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "gaps"

- params:

  List of all input parameters used to generate the landscape

## Details

The distinction between "spots" and "gaps":

- **gaps**: Bare patches in vegetation matrix)

- **spots**: Vegetation patches in bare ground)

Both patterns use the same algorithm; the pattern name primarily serves
as a semantic label for training data organization.

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscape_bands()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/patternscaper/reference/create_landscape_clustered.md),
[`create_landscape_dense()`](https://ecomods.github.io/patternscaper/reference/create_landscape_dense.md),
[`create_landscape_diffuse()`](https://ecomods.github.io/patternscaper/reference/create_landscape_diffuse.md),
[`create_landscape_fingers()`](https://ecomods.github.io/patternscaper/reference/create_landscape_fingers.md),
[`create_landscape_labyrinth()`](https://ecomods.github.io/patternscaper/reference/create_landscape_labyrinth.md),
[`create_landscape_random()`](https://ecomods.github.io/patternscaper/reference/create_landscape_random.md),
[`create_landscape_sharp()`](https://ecomods.github.io/patternscaper/reference/create_landscape_sharp.md),
[`create_landscape_spots()`](https://ecomods.github.io/patternscaper/reference/create_landscape_spots.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

## Examples

``` r
# Default gaps (vegetation patches in bare ground)
gaps_default <- create_landscape_gaps()

# More gaps with size variation
gaps_modified <- create_landscape_gaps(
  n_spots = 15,
  spot_radius = 8,
  spot_radius_sd = 2
)
```
