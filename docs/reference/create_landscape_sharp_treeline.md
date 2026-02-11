# Create a Landscape with Sharp Treeline

Generates a binary landscape with a sharp treeline.

## Usage

``` r
create_landscape_sharp_treeline(
  width = 100,
  height = 100,
  treeline_position = 0.5,
  random_spots = c(0, 0),
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

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "sharp" containing the generated
landscape data and parameters.

## Examples

``` r
# Default sharp treeline
sharp_default <- create_landscape_sharp_treeline()
#> Error in create_landscape_sharp_treeline(): could not find function "create_landscape_sharp_treeline"

# Modified sharp treeline with higher treeline position
sharp_modified <- create_landscape_sharp_treeline(
  treeline_position = 0.7
)
#> Error in create_landscape_sharp_treeline(treeline_position = 0.7): could not find function "create_landscape_sharp_treeline"

# Landscape with rotation and some spots
sharp_rotated <- create_landscape_sharp_treeline(
  treeline_position = 0.3,
  random_spots = c(0, 0.1),
  rotation = 45
)
#> Error in create_landscape_sharp_treeline(treeline_position = 0.3, random_spots = c(0,     0.1), rotation = 45): could not find function "create_landscape_sharp_treeline"
```
