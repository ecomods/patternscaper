# Create a Landscape with Gaps Pattern

Generates a binary landscape with circular gaps (vegetation patches in
bare ground). This is a convenience wrapper around
[`create_landscape_spots`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md)
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
  invert_landscape = TRUE,
  regular_spots = FALSE,
  rotation = 0
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

  Numeric. Standard deviation for random variation in spot radius.
  Default is 0 (no variation). Each spot's radius is sampled from
  N(spot_radius, spot_radius_sd).

- radius_noise_fraction:

  Numeric (0 to 1). Proportion of the spot radius where gradual edge
  noise is applied. 0 creates sharp circular edges, 1 applies
  probabilistic cell inclusion across the entire radius. For example,
  0.2 means the outer 20 Works independently of \`spot_radius_sd\`
  (which varies the overall size, while this parameter affects edge
  sharpness).

- invert_landscape:

  Logical. If TRUE (default), creates vegetation patches in bare ground
  (gaps pattern). If FALSE, creates bare spots in vegetation (equivalent
  to spots pattern). This parameter is exposed to allow users to
  override the default behavior if needed.

- regular_spots:

  Logical. If TRUE, spots are arranged on a hexagonal grid using k-means
  clustering. If FALSE, spots are placed randomly (default: FALSE).

- rotation:

  Numeric. Rotation angle in degrees (unused, present for compatibility
  with other landscape generators). Required by
  [`create_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md).

## Value

A landscape object with pattern "gaps" containing the generated
landscape data and parameters.

## Details

The distinction between "spots" and "gaps":

- **spots**: Bare patches in vegetation matrix
  (`invert_landscape = FALSE`)

- **gaps**: Vegetation patches in bare ground
  (`invert_landscape = TRUE`)

Both patterns use the same algorithm; the pattern name primarily serves
as a semantic label for training data organization.

## See also

[`create_landscape_spots`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md)
for the underlying implementation

## Examples

``` r
# Default gaps (vegetation patches in bare ground)
gaps_default <- create_landscape_gaps()
#> Error in create_landscape_gaps(): could not find function "create_landscape_gaps"

# More gaps with size variation
gaps_modified <- create_landscape_gaps(
  n_spots = 15,
  spot_radius = 8,
  spot_radius_sd = 2
)
#> Error in create_landscape_gaps(n_spots = 15, spot_radius = 8, spot_radius_sd = 2): could not find function "create_landscape_gaps"
```
