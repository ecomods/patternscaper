# Create Multiple Landscapes

Generates `n` binary landscapes from the requested patterns, sampling
pattern-specific parameters independently for each landscape. This
supports the construction of training sets.

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
create_landscapes(
  n = 50,
  patterns = c("random", "bare", "dense", "sharp", "diffuse", "fingers", "clustered",
    "bands", "spots", "gaps", "labyrinth"),
  width = 100,
  height = 100,
  rotation = c(0, 360),
  params_list = NULL,
  pattern_probs = NULL,
  max_retries = 3
)
```

## Arguments

- n:

  Integer. Number of landscapes to generate (default: 50).

- patterns:

  Character vector. Patterns to sample: "random", "bare", "dense",
  "sharp", "diffuse", "fingers", "clustered", "bands", "spots", "gaps",
  or "labyrinth" (default: all patterns).

- width:

  Integer. Width of each landscape in pixels (default: 100).

- height:

  Integer. Height of each landscape in pixels (default: 100).

- rotation:

  Numeric. Angle in degrees (default: `c(0, 360)`). A single value
  applies to every rotatable landscape. A length-2 vector gives the
  bounds of a uniform range sampled as whole degrees. Only "sharp",
  "diffuse", "fingers", "clustered", and "bands" are rotated; other
  patterns ignore this argument.

- params_list:

  Named list of pattern parameters (default: NULL). Each name must match
  a pattern and each element must come from its `pattern_*()`
  constructor, for example `list(spots = pattern_spots())`. A single
  value is fixed across the batch; a length-2 vector is sampled once per
  landscape. Omitted patterns use their default sampling ranges.

- pattern_probs:

  Numeric vector of sampling weights, one per element of `patterns`
  (default: NULL). NULL creates balanced pattern counts. A vector of the
  wrong length issues a warning and uses equal weights.

- max_retries:

  Integer. Maximum retries after a failed landscape generation (default:
  3).

## Value

A named list of
[`landscape`](https://ecomods.github.io/patternscaper/reference/landscape.md)
objects, each as returned by
[`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md).
Landscape names are `"<pattern>_<index>"`, with `"_rot<angle>"` appended
for rotated landscapes. The list holds fewer than `n` landscapes if
generation still fails after `max_retries`; a warning reports the
shortfall.

## See also

[`landscape`](https://ecomods.github.io/patternscaper/reference/landscape.md)
to wrap an existing raster, for example a real map, into the same object
type;
[`plot_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md)
to plot the result.

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
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
# Generate 20 landscapes
landscapes <- create_landscapes(n = 20)
#> ✔ Successfully generated all 20 training landscapes

# Access a landscape
landscapes[[1]]
#> Landscape: "clustered_1_rot94" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.471359662851319, n_clusters = 8, cluster_radius = 8, cluster_zone = 0.714724025502801, elongation_x = 1.37432571477257, elongation_y = 1.36488283867948, rotation = 94 

# Check the pattern
landscapes[[1]]$pattern
#> [1] "clustered"

# Get all landscape patterns
sapply(landscapes, \(x) x$pattern)
#>  clustered_1_rot94   diffuse_2_rot221           random_3            spots_4 
#>        "clustered"          "diffuse"           "random"            "spots" 
#>            spots_5            dense_6   fingers_7_rot306             bare_8 
#>            "spots"            "dense"          "fingers"             "bare" 
#>             bare_9       labyrinth_10    bands_11_rot325            gaps_12 
#>             "bare"        "labyrinth"            "bands"             "gaps" 
#>    sharp_13_rot265    bands_14_rot228  diffuse_15_rot300  fingers_16_rot352 
#>            "sharp"            "bands"          "diffuse"          "fingers" 
#>           dense_17     sharp_18_rot74          random_19 clustered_20_rot85 
#>            "dense"            "sharp"           "random"        "clustered" 

# Custom parameters, as a single value or as a range sampled per landscape
landscapes_custom <- create_landscapes(
  n = 12,
  patterns = c("spots", "sharp"),
  params_list = list(
    spots = pattern_spots(n_spots = 15, spot_radius = c(8, 12)),
    sharp = pattern_sharp(boundary_position = c(0.4, 0.6))
  )
)
#> ✔ Successfully generated all 12 training landscapes
```
