# Create a Single Landscape

Generates one binary landscape with the requested spatial pattern. Use
the matching `pattern_*()` constructor to set pattern-specific
parameters.

- **Control** patterns have no spatial structure and differ only in
  vegetation cover:
  [`"bare"`](https://ecomods.github.io/patternscaper/reference/pattern_bare.md),
  [`"random"`](https://ecomods.github.io/patternscaper/reference/pattern_random.md),
  [`"dense"`](https://ecomods.github.io/patternscaper/reference/pattern_dense.md).

- **Ecotone** patterns have a vegetated and a bare zone separated by a
  transition:
  [`"sharp"`](https://ecomods.github.io/patternscaper/reference/pattern_sharp.md)
  (abrupt),
  [`"diffuse"`](https://ecomods.github.io/patternscaper/reference/pattern_diffuse.md)
  (gradual),
  [`"fingers"`](https://ecomods.github.io/patternscaper/reference/pattern_fingers.md)
  (finger-like extensions),
  [`"clustered"`](https://ecomods.github.io/patternscaper/reference/pattern_clustered.md)
  (scattered clusters),
  [`"bands"`](https://ecomods.github.io/patternscaper/reference/pattern_bands.md)
  (sinusoidal bands).

- **Patch** patterns are self-organized, without a boundary:
  [`"spots"`](https://ecomods.github.io/patternscaper/reference/pattern_spots.md)
  (vegetation patches),
  [`"gaps"`](https://ecomods.github.io/patternscaper/reference/pattern_gaps.md)
  (bare gaps),
  [`"labyrinth"`](https://ecomods.github.io/patternscaper/reference/pattern_labyrinth.md)
  (maze-like bands).

## Usage

``` r
create_landscape(
  pattern,
  width = 100,
  height = 100,
  name = NULL,
  params = NULL,
  rotation = 0
)
```

## Arguments

- pattern:

  Character. Pattern to generate. Valid patterns are: "random", "bare",
  "dense", "sharp", "diffuse", "fingers", "clustered", "bands", "spots",
  "gaps", "labyrinth".

- width:

  Integer. Landscape width in pixels (default: 100).

- height:

  Integer. Landscape height in pixels (default: 100).

- name:

  Character. Optional landscape name (default: NULL).

- params:

  Output of the `pattern_*()` constructor matching `pattern`, such as
  [`pattern_spots`](https://ecomods.github.io/patternscaper/reference/pattern_spots.md)
  (default: NULL). Parameters must be single values; length-2 sampling
  ranges apply only to
  [`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md).

- rotation:

  Numeric. Rotation angle in degrees (0-360, default: 0). Only "sharp",
  "diffuse", "fingers", "clustered", and "bands" are rotated. Other
  patterns ignore this argument and issue a warning.

## Value

A
[`landscape`](https://ecomods.github.io/patternscaper/reference/landscape.md)
object, containing:

- data:

  SpatRaster of the generated pattern (0 = bare ground, 1 = vegetation).

- pattern:

  Character pattern name.

- params:

  Parameters used to generate the landscape.

- name:

  Character landscape name, or `NA` if none was given.

## See also

[`landscape`](https://ecomods.github.io/patternscaper/reference/landscape.md)
to wrap an existing raster, for example a real map, into the same object
type;
[`plot_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md)
to plot the result.

Other landscape creation:
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md),
[`pattern_bands()`](https://ecomods.github.io/patternscaper/reference/pattern_bands.md),
[`pattern_bare()`](https://ecomods.github.io/patternscaper/reference/pattern_bare.md),
[`pattern_clustered()`](https://ecomods.github.io/patternscaper/reference/pattern_clustered.md),
[`pattern_dense()`](https://ecomods.github.io/patternscaper/reference/pattern_dense.md),
[`pattern_diffuse()`](https://ecomods.github.io/patternscaper/reference/pattern_diffuse.md),
[`pattern_fingers()`](https://ecomods.github.io/patternscaper/reference/pattern_fingers.md),
[`pattern_gaps()`](https://ecomods.github.io/patternscaper/reference/pattern_gaps.md),
[`pattern_labyrinth()`](https://ecomods.github.io/patternscaper/reference/pattern_labyrinth.md),
[`pattern_random()`](https://ecomods.github.io/patternscaper/reference/pattern_random.md),
[`pattern_sharp()`](https://ecomods.github.io/patternscaper/reference/pattern_sharp.md),
[`pattern_spots()`](https://ecomods.github.io/patternscaper/reference/pattern_spots.md)

## Examples

``` r
# Create a default landscape of various patterns
random_default <- create_landscape("random")
sharp_default <- create_landscape("sharp")
diffuse_default <- create_landscape("diffuse")
clustered_default <- create_landscape("clustered")

# Set pattern parameters through the matching constructor
random_modified <- create_landscape(
  "random",
  params = pattern_random(veg_prob = 0.3)
)

diffuse_modified <- create_landscape(
  "diffuse",
  params = pattern_diffuse(boundary_position = 0.3, steepness = 0.1)
)

# Rotation is an argument of create_landscape(), not a pattern parameter
bands_rotated <- create_landscape(
  "bands",
  params = pattern_bands(
    band_thickness = 4,
    band_spacing = 12,
    amplitude = 6,
    noise_sd = 2
  ),
  rotation = 45
)
```
