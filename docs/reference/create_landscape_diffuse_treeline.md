# Create a Landscape with Diffuse Treeline

Generates a binary landscape with a diffuse treeline where tree
probability decreases with distance.

## Usage

``` r
create_landscape_diffuse_treeline(
  width = 100,
  height = 100,
  treeline_position = 0.2,
  steepness = 0.5,
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

- steepness:

  Numeric. Controls the transition gradient (0-1). Lower values (e.g.,
  0.1) create sharper transitions. Higher values (e.g., 0.9) create more
  gradual, diffuse transitions where tree probability persists further
  below the treeline (default: 0.5).

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "diffuse" containing the generated
landscape data and parameters.

## Examples

``` r
# Default diffuse treeline
diffuse_default <- create_landscape_diffuse_treeline()
#> Error in create_landscape_diffuse_treeline(): could not find function "create_landscape_diffuse_treeline"

# Sharp transition (lower steepness)
diffuse_sharp <- create_landscape_diffuse_treeline(
  treeline_position = 0.2,
  steepness = 0.1
)
#> Error in create_landscape_diffuse_treeline(treeline_position = 0.2, steepness = 0.1): could not find function "create_landscape_diffuse_treeline"

# Gradual transition (higher steepness)
diffuse_gradual <- create_landscape_diffuse_treeline(
  treeline_position = 0.3,
  steepness = 0.9
)
#> Error in create_landscape_diffuse_treeline(treeline_position = 0.3, steepness = 0.9): could not find function "create_landscape_diffuse_treeline"

# With rotation
diffuse_rotated <- create_landscape_diffuse_treeline(
  treeline_position = 0.3,
  steepness = 0.7,
  rotation = 45
)
#> Error in create_landscape_diffuse_treeline(treeline_position = 0.3, steepness = 0.7,     rotation = 45): could not find function "create_landscape_diffuse_treeline"
```
