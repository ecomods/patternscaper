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
#> ✔ Successfully generated all 20 training landscapes

# Access a landscape
landscapes[[1]]
#> Landscape: "clustered_1_rot106" [ pattern: clustered ]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, treeline_position = 0.439413185697049, n_clusters = 5, cluster_radius = 7, scatter_zone_prop = 0.73616346064955, elongation_x = 0.658146824687719, elongation_y = 1.14093149756081, rotation = 106, random_spots = c(0, 0) 

# Check the pattern
landscapes[[1]]$pattern
#> [1] "clustered"

# Get all landscape patterns
sapply(landscapes, function(x) x$pattern)
#>  clustered_1_rot106      sharp_2_rot228            random_3      spots_4_rot195 
#>         "clustered"             "sharp"            "random"             "spots" 
#>    diffuse_5_rot242      bands_6_rot254    diffuse_7_rot333       gaps_8_rot287 
#>           "diffuse"             "bands"           "diffuse"              "gaps" 
#>    fingers_9_rot306     spots_10_rot312             bare_11     fingers_12_rot5 
#>           "fingers"             "spots"              "bare"           "fingers" 
#>           random_13            dense_14        labyrinth_15 clustered_16_rot235 
#>            "random"             "dense"         "labyrinth"         "clustered" 
#>            dense_17             bare_18     bands_19_rot319     sharp_20_rot314 
#>             "dense"              "bare"             "bands"             "sharp" 
```
