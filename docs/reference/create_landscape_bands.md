# Create a Landscape with Sine Wave Bands

Generates a binary landscape with parallel sine-wave bands.

## Usage

``` r
create_landscape_bands(
  width = 100,
  height = 100,
  treeline_position = 0.5,
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

- treeline_position:

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

A landscape object with pattern "bands" containing the generated
landscape data and parameters.

## Examples

``` r
# Default sine bands
bands_default <- create_landscape_bands()
#> Error in create_landscape_bands(): could not find function "create_landscape_bands"

# Modified sine bands with thicker bands, wider spacing and noise
bands_modified <- create_landscape_bands(
  treeline_position = 0.3,
  band_zone_prop = 0.5,
  band_thickness = 5,
  band_spacing = 15,
  frequency = 1,
  amplitude = 8,
  noise_sd = 1.5
)
#> Error in create_landscape_bands(treeline_position = 0.3, band_zone_prop = 0.5,     band_thickness = 5, band_spacing = 15, frequency = 1, amplitude = 8,     noise_sd = 1.5): could not find function "create_landscape_bands"

# With rotation
bands_rotated <- create_landscape_bands(
  band_thickness = 4,
  band_spacing = 12,
  amplitude = 6,
  noise_sd = 2,
  rotation = 45
)
#> Error in create_landscape_bands(band_thickness = 4, band_spacing = 12,     amplitude = 6, noise_sd = 2, rotation = 45): could not find function "create_landscape_bands"
```
