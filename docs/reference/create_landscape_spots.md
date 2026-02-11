# Create a Landscape with Spots Pattern

Generates a binary landscape with circular spots representing either
bare patches in vegetation or vegetation patches in bare ground (when
inverted).

## Usage

``` r
create_landscape_spots(
  width = 100,
  height = 100,
  n_spots = 15,
  spot_radius = 5,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  invert_landscape = FALSE,
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

  Logical. If TRUE, creates vegetation patches in bare ground
  (equivalent to "gaps" pattern). If FALSE (default), creates bare spots
  in vegetation.

- regular_spots:

  Logical. If TRUE, spots are arranged on a hexagonal grid using k-means
  clustering. If FALSE, spots are placed randomly (default: FALSE).

- rotation:

  Numeric. Rotation angle in degrees (unused, present for compatibility
  with other landscape generators). Required by
  [`create_landscapes`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md).

## Value

A landscape object with pattern "spots" containing the generated
landscape data and parameters.

## Details

This function can generate both "spots" and "gaps" patterns depending on
`invert_landscape`. For semantic clarity in training data, use
[`create_landscape_gaps`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_gaps.md)
when you want vegetation patches in bare ground, which sets
`invert_landscape = TRUE` by default and labels the pattern as "gaps".

## Examples

``` r
# Default spots (random placement)
spots_default <- create_landscape_spots()
#> Error in create_landscape_spots(): could not find function "create_landscape_spots"

# More spots with random size variation
spots_modified <- create_landscape_spots(
  n_spots = 15,
  spot_radius = 8,
  spot_radius_sd = 2
)
#> Error in create_landscape_spots(n_spots = 15, spot_radius = 8, spot_radius_sd = 2): could not find function "create_landscape_spots"

# Regular hexagonal arrangement with slight jitter
spots_regular <- create_landscape_spots(
  n_spots = 12,
  spot_radius = 10,
  regular_spots = TRUE
)
#> Error in create_landscape_spots(n_spots = 12, spot_radius = 10, regular_spots = TRUE): could not find function "create_landscape_spots"

# Gradual edges using radius noise fraction
spots_gradual <- create_landscape_spots(
  n_spots = 10,
  spot_radius = 12,
  radius_noise_fraction = 0.3
)
#> Error in create_landscape_spots(n_spots = 10, spot_radius = 12, radius_noise_fraction = 0.3): could not find function "create_landscape_spots"

# Inverted (vegetation patches in bare ground)
spots_inverted <- create_landscape_spots(
  n_spots = 15,
  spot_radius = 8,
  invert_landscape = TRUE
)
#> Error in create_landscape_spots(n_spots = 15, spot_radius = 8, invert_landscape = TRUE): could not find function "create_landscape_spots"
```
