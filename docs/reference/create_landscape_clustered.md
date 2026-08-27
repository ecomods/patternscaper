# Create a Landscape with Clustered Features

Generates a binary landscape with clustered features below a treeline.
Features are arranged in clusters within a scatter zone that extends
below the treeline. Clusters can be elongated in x or y directions to
create elliptical patterns.

## Usage

``` r
create_landscape_clustered(
  width = 100,
  height = 100,
  boundary_position = 0.5,
  random_spots = c(0, 0),
  n_clusters = 10,
  cluster_radius = 5,
  scatter_zone_prop = 0.3,
  elongation_x = 1,
  elongation_y = 1,
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

- random_spots:

  Numeric vector of length 2. Probabilities for flipping cells:
  \`\[prob(1→0), prob(0→1)\]\`. Used to add noise to the landscape
  (default: c(0,0)).

- n_clusters:

  Integer. Number of cluster centers (default: 10).

- cluster_radius:

  Numeric. Radius of clusters in pixels (default: 5).

- scatter_zone_prop:

  Numeric. Proportion of height for scatter zone measured downward from
  treeline (0-1, default: 0.3).

- elongation_x:

  Numeric. Horizontal elongation factor for clusters. Values \> 1
  stretch clusters horizontally, creating wider ellipses. Values \< 1
  compress horizontally (default: 1).

- elongation_y:

  Numeric. Vertical elongation factor for clusters. Values \> 1 stretch
  clusters vertically, creating taller ellipses. Values \< 1 compress
  vertically (default: 1).

- rotation:

  Numeric. Angle to rotate landscape in degrees (default: 0).

## Value

A landscape object with pattern "clustered" containing:

- data:

  SpatRaster with binary values (0 = bare ground, 1 = vegetation)

- pattern:

  Character string "clustered"

- params:

  List of all input parameters used to generate the landscape

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscape_bands()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/patternscaper/reference/create_landscape_bare.md),
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
# Default clustered features
clustered_default <- create_landscape_clustered()

# Modified clustered features with horizontally elongated clusters
clustered_modified <- create_landscape_clustered(
  boundary_position = 0.2,
  n_clusters = 8,
  cluster_radius = 7,
  scatter_zone_prop = 0.6,
  elongation_x = 2.5,
  elongation_y = 0.5
)

# Rotated landscape with mixed parameters
clustered_rotated <- create_landscape_clustered(
  n_clusters = 20,
  cluster_radius = 2,
  scatter_zone_prop = 0.5,
  elongation_x = 1.8,
  elongation_y = 1.4,
  rotation = 45
)
```
