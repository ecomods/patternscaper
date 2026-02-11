# Create a Landscape with Finger-like Treeline

Generates a binary landscape with a curvy finger treeline following a
sine wave pattern with random length and amplitude for each wave
segment.

## Usage

``` r
create_landscape_fingers(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  random_spots = c(0, 0),
  sine_length_mean = 20,
  sine_length_sd = 12,
  sine_height_mean = 5,
  sine_height_sd = 4,
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

- random_spots:

  Numeric vector of length 2. Probabilities for flipping cells: \[1→0,
  0→1\] (default: c(0,0)).

- sine_length_mean:

  Numeric. Mean wavelength of sinusoidal curve in pixels (default: 20).

- sine_length_sd:

  Numeric. Standard deviation of wavelength in pixels (default: 12).

- sine_height_mean:

  Numeric. Mean amplitude of sinusoidal curve in pixels (default: 5).

- sine_height_sd:

  Numeric. Standard deviation of amplitude in pixels (default: 4).

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "fingers" containing the generated
landscape data and parameters.

## Examples

``` r
# Default curvy fingers treeline
fingers_default <- create_landscape_fingers()
#> Error in create_landscape_fingers(): could not find function "create_landscape_fingers"

# Modified parameters for more variation
fingers_modified <- create_landscape_fingers(
  sine_length_mean = 15,
  sine_length_sd = 10,
  sine_height_mean = 10,
  sine_height_sd = 6
)
#> Error in create_landscape_fingers(sine_length_mean = 15, sine_length_sd = 10,     sine_height_mean = 10, sine_height_sd = 6): could not find function "create_landscape_fingers"

# With rotation
fingers_rotated <- create_landscape_fingers(
  rotation = 45
)
#> Error in create_landscape_fingers(rotation = 45): could not find function "create_landscape_fingers"
```
