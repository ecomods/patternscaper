# Create a Landscape with Sine Wave Bands

Generates a binary landscape with parallel sine-wave bands.

## Usage

``` r
create_landscape_bands(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  band_zone_prop = 0.2,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 2 * pi/100,
  amplitude = 5,
  noise_sd = 0,
  rotation = 0
)
```

## Arguments

- width:

  Integer. Width of the landscape in pixels (default: 100).

- height:

  Integer. Height of the landscape in pixels (default: 100).

- boundary_position:

  Numeric. Relative position of treeline from top (0-1) (default: 0.5).

- band_zone_prop:

  Numeric. Proportion of height of the total landscape to allocate for
  bands below the treeline (default: 0.2). If the band zone is too small
  for the given band spacing, no bands will be drawn and a warning will
  be issued.

- band_thickness:

  Integer. Thickness of each band in pixels (default: 3).

- band_spacing:

  Integer. Spacing between bands in pixels (default: 10).

- frequency:

  Numeric. Frequency of sine wave (default: 2\*pi/100).

- amplitude:

  Numeric. Amplitude of sine wave in pixels (default: 5).

- noise_sd:

  Numeric. Standard deviation for random noise (default: 0).

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "bands" containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "bands"

- params:

  List of all input parameters used to generate the landscape

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscape_bare()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/patternscaper/reference/create_landscape_clustered.md),
[`create_landscape_dense()`](https://ecomods.github.io/patternscaper/reference/create_landscape_dense.md),
[`create_landscape_diffuse()`](https://ecomods.github.io/patternscaper/reference/create_landscape_diffuse.md),
[`create_landscape_fingers()`](https://ecomods.github.io/patternscaper/reference/create_landscape_fingers.md),
[`create_landscape_gaps()`](https://ecomods.github.io/patternscaper/reference/create_landscape_gaps.md),
[`create_landscape_labyrinth()`](https://ecomods.github.io/patternscaper/reference/create_landscape_labyrinth.md),
[`create_landscape_random()`](https://ecomods.github.io/patternscaper/reference/create_landscape_random.md),
[`create_landscape_sharp()`](https://ecomods.github.io/patternscaper/reference/create_landscape_sharp.md),
[`create_landscape_spots()`](https://ecomods.github.io/patternscaper/reference/create_landscape_spots.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

## Examples

``` r
# Default sine bands
bands_default <- create_landscape_bands()

# Modified sine bands with thicker bands, wider spacing and noise
bands_modified <- create_landscape_bands(
  boundary_position = 0.3,
  band_zone_prop = 0.5,
  band_thickness = 5,
  band_spacing = 15,
  frequency = 1,
  amplitude = 8,
  noise_sd = 1.5
)

# With rotation
bands_rotated <- create_landscape_bands(
  band_thickness = 4,
  band_spacing = 12,
  amplitude = 6,
  noise_sd = 2,
  rotation = 45
)
```
