# Create Training Landscapes

Create a series of landscape models with variations for training
purposes. Creates a total of n landscapes distributed across different
landscape patterns.

## Usage

``` r
create_training_landscapes(
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
landscapes <- create_training_landscapes(n = 20)
#> ✔ Successfully generated all 20 training landscapes

# Access a landscape
landscapes[[1]]
#> Landscape: "random_1" [ pattern: random ]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, tree_prop = 0.200145037658513 

# Check the pattern
landscapes[[1]]$pattern
#> [1] "random"

# Get all landscape patterns
sapply(landscapes, function(x) x$pattern)
#>            random_1              bare_2    diffuse_3_rot123             dense_4 
#>            "random"              "bare"           "diffuse"             "dense" 
#>      bands_5_rot203     diffuse_6_rot39      sharp_7_rot139            random_8 
#>             "bands"           "diffuse"             "sharp"            "random" 
#>              bare_9     spots_10_rot275    fingers_11_rot53        labyrinth_12 
#>              "bare"             "spots"           "fingers"         "labyrinth" 
#>      bands_13_rot81    fingers_14_rot16 clustered_15_rot220      gaps_16_rot350 
#>             "bands"           "fingers"         "clustered"              "gaps" 
#>  clustered_17_rot41      sharp_18_rot54            dense_19     spots_20_rot354 
#>         "clustered"             "sharp"             "dense"             "spots" 
```
