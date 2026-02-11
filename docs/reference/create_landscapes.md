# Create Training Landscapes

Create a series of landscape models with variations for training
purposes. Creates a total of n landscapes distributed across different
landscape patterns.

## Usage

``` r
create_landscapes(
  n = 50,
  patterns = c("random", "bare", "dense", "sharp", "diffuse", "fingers", "clustered",
    "bands", "spots", "gaps", "labyrinth"),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = 0:360,
  params_list = NULL,
  pattern_probs = NULL,
  balance_patterns = TRUE,
  max_retries = 3
)
```

## Arguments

- n:

  Integer. Total number of landscapes to create (default: 50).

- patterns:

  Character vector. patterns of landscapes to sample from (default: all
  patterns).

- width:

  Integer. Width of all landscapes in pixels (default: 100).

- height:

  Integer. Height of all landscapes in pixels (default: 100).

- add_rotation:

  Logical. Whether to include rotated versions (default: TRUE).

- rotation_angles:

  Numeric vector. Rotation angles in degrees (default: c(0, 45, 90,
  135)).

- params_list:

  List. List of parameter ranges for each landscape pattern (default:
  NULL).

- pattern_probs:

  Numeric vector. Probability that a specific landscape pattern is
  chosen. By default, all patterns have equal probability (1) of being
  chosen. Must be the same length as 'patterns' (default NULL which
  means equal probability).

- balance_patterns:

  Logical. If TRUE, ensures all landscape patterns appear approximately
  equally, overriding any weights specified in pattern_probs. (default:
  TRUE)

- max_retries:

  Integer. Maximum number of retries for failed landscape generations
  (default: 3).

## Value

A named list of landscape objects. Names indicate the pattern and
optional rotation.

## Examples

``` r
# Generate 20 training landscapes
landscapes <- create_landscapes(n = 20)
#> Warning: Regular spot placement requested 9 spots but only ~6 positions fit.
#> ℹ  Adjusting to maximum feasible spots. Consider decreasing `spot_radius`.
#> ✔ Successfully generated all 20 training landscapes

# Access a landscape
landscapes[[1]]
#> Landscape: "labyrinth_1" [ pattern: labyrinth ]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 2.5, veg_threshold = 0.467092503677122, band_fuzziness = 0.244724491096567, octaves = 4 

# Check the pattern
landscapes[[1]]$pattern
#> [1] "labyrinth"

# Get all landscape patterns
sapply(landscapes, function(x) x$pattern)
#>        labyrinth_1           random_2 clustered_3_rot154      bands_4_rot16 
#>        "labyrinth"           "random"        "clustered"            "bands" 
#>     sharp_5_rot107      gaps_6_rot234            dense_7   fingers_8_rot162 
#>            "sharp"             "gaps"            "dense"          "fingers" 
#>      spots_9_rot37 clustered_10_rot10  fingers_11_rot253          random_12 
#>            "spots"        "clustered"          "fingers"           "random" 
#>            bare_13     sharp_14_rot90    bands_15_rot209  diffuse_16_rot132 
#>             "bare"            "sharp"            "bands"          "diffuse" 
#>     spots_17_rot41  diffuse_18_rot111            bare_19           dense_20 
#>            "spots"          "diffuse"             "bare"            "dense" 
```
