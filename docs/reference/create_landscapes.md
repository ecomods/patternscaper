# Create Multiple Landscapes

Create a series of landscape models with variations. Creates a total of
n landscapes distributed across different landscape patterns.

## Usage

``` r
create_landscapes(
  n = 50,
  patterns = c("random", "bare", "dense", "sharp", "diffuse", "fingers", "clustered",
    "bands", "spots", "gaps", "labyrinth"),
  width = 100,
  height = 100,
  rotation = 0:360,
  params_list = NULL,
  pattern_probs = NULL,
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

- rotation:

  Numeric vector. Rotation angles in degrees (default: c(0, 45, 90,
  135)).

- params_list:

  List. List of parameter ranges or single values for the parameters of
  each landscape pattern (default: NULL). The names and default
  parameter ranges for the different patterns can be found in the
  documentation of
  [`create_landscape`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md).

- pattern_probs:

  Numeric vector. Probability that a specific landscape pattern is
  chosen from the list of patterns. Should be a numeric vector of the
  same length as 'patterns'. The default value NULL creates equally
  balanced patterns.

- max_retries:

  Integer. Maximum number of retries for failed landscape generations
  (default: 3).

## Value

A named list of landscape objects. Names indicate the pattern and
optional rotation.

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md),
[`create_landscape_bands()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bands.md),
[`create_landscape_bare()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bare.md),
[`create_landscape_clustered()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_clustered.md),
[`create_landscape_dense()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_dense.md),
[`create_landscape_diffuse()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_diffuse.md),
[`create_landscape_fingers()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_fingers.md),
[`create_landscape_gaps()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_gaps.md),
[`create_landscape_labyrinth()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_labyrinth.md),
[`create_landscape_random()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md),
[`create_landscape_sharp()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_sharp.md),
[`create_landscape_spots()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md)

## Examples

``` r
# Generate 20 landscapes
landscapes <- create_landscapes(n = 20)
#> ✔ Successfully generated all 20 training landscapes

# Access a landscape
landscapes[[1]]
#> Landscape: "fingers_1_rot263" [ pattern: fingers ]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.308938690577634, sine_length_mean = 22.120583623182, sine_length_sd = 46.8808206822723, sine_height_mean = 10.546226123115, sine_height_sd = 15.6450144061819, random_spots = c(0, 0), rotation = 263 

# Check the pattern
landscapes[[1]]$pattern
#> [1] "fingers"

# Get all landscape patterns
sapply(landscapes, function(x) x$pattern)
#>   fingers_1_rot263 clustered_2_rot235   diffuse_3_rot109            dense_4 
#>          "fingers"        "clustered"          "diffuse"            "dense" 
#>             bare_5            spots_6           random_7            spots_8 
#>             "bare"            "spots"           "random"            "spots" 
#>             bare_9     sharp_10_rot51       labyrinth_11  diffuse_12_rot351 
#>             "bare"            "sharp"        "labyrinth"          "diffuse" 
#>    bands_13_rot335            gaps_14 clustered_15_rot54           dense_16 
#>            "bands"             "gaps"        "clustered"            "dense" 
#>          random_17     sharp_18_rot83  fingers_19_rot341    bands_20_rot133 
#>           "random"            "sharp"          "fingers"            "bands" 

# Custom parameters for spot patterns and sharp vegetation boundary
# Can be given as a range (min, max) or a single value.
pattern_params <- list(
  spots = list(
    n_spots = 15,
    spot_radius = 10,
    spot_radius_sd = 3
  ),
  sharp = list(
    boundary_position = c(0.4,0.6)
))
landscapes_custom <- create_landscapes(
  n = 12,
 patterns = c("spots", "sharp"),
 params_list = pattern_params
)
#> ✔ Successfully generated all 12 training landscapes
```
