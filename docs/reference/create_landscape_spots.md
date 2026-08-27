# Create a Landscape with Spots Pattern

Generates a binary landscape with circular spots representing either
vegetated patches in bare ground (spots) or bare patches in vegetated
ground (when inverted, gaps).

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

- invert_landscape:

  Logical. If TRUE, creates bare patches in vegetated ground (equivalent
  to "gaps" pattern). If FALSE (default), creates vegetated spots in
  bare ground.

- regular_spots:

  Logical. If TRUE, spots are arranged on a hexagonal grid using k-means
  clustering. If FALSE, spots are placed randomly (default: FALSE).

## Value

A landscape object with pattern "spots" containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "spots"

- params:

  List of all input parameters used to generate the landscape

## Details

This function can generate both "spots" and "gaps" patterns depending on
`invert_landscape`. For semantic clarity in training data, use
[`create_landscape_gaps`](https://ecomods.github.io/patternscaper/reference/create_landscape_gaps.md)
when you want bare patches in vegetated ground, which sets
`invert_landscape = TRUE` by default and labels the pattern as "gaps".

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
[`create_landscape_sharp()`](https://ecomods.github.io/patternscaper/reference/create_landscape_sharp.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

## Examples

``` r
# Default spots (random placement)
spots_default <- create_landscape_spots()

# More spots with random size variation
spots_modified <- create_landscape_spots(
  n_spots = 15,
  spot_radius = 8,
  spot_radius_sd = 2
)

# Regular hexagonal arrangement with slight jitter
spots_regular <- create_landscape_spots(
  n_spots = 12,
  spot_radius = 10,
  regular_spots = TRUE
)

# Gradual edges using radius noise fraction
spots_gradual <- create_landscape_spots(
  n_spots = 10,
  spot_radius = 12,
  radius_noise_fraction = 0.3
)

# Inverted (bare patches in vegetated ground)
spots_inverted <- create_landscape_spots(
  n_spots = 15,
  spot_radius = 8,
  invert_landscape = TRUE
)
```
