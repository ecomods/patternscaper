# Parameters for the Spots Pattern

Circular vegetation patches on bare ground.

## Usage

``` r
pattern_spots(
  n_spots = 5,
  spot_radius = 10,
  spot_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_spots = FALSE,
  invert_landscape = FALSE
)
```

## Arguments

- n_spots:

  Integer. Number of spots (default: 5). Regular placement may reduce
  this number if the landscape cannot accommodate the requested count
  with the given `spot_radius`.

- spot_radius:

  Numeric. Mean radius of each spot in pixels (default: 10). Must be
  positive and smaller than landscape dimensions.

- spot_radius_sd:

  Numeric. Standard deviation of normally sampled spot radii (default:
  0, no variation).

- radius_noise_fraction:

  Numeric. Fraction of the spot radius with a gradual edge transition
  (0-1). Zero gives sharp edges; 1 applies probabilistic cell inclusion
  across the full radius. For example, 0.2 applies the transition to the
  outer 20%. This is independent of `spot_radius_sd`, which varies
  overall spot size.

- regular_spots:

  Logical. Arrange spots on a hexagonal grid using k-means clustering
  rather than placing them randomly (default: FALSE).

- invert_landscape:

  Logical. Create bare patches in vegetated ground, equivalent to the
  "gaps" pattern (default: FALSE).

## Value

A named `"landscape_params"` list containing the supplied parameters.

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
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
[`pattern_sharp()`](https://ecomods.github.io/patternscaper/reference/pattern_sharp.md)

## Valid values and batch sampling

A single value fixes a parameter. A length-2 vector is a range, sampled
once per landscape by
[`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)
and rejected by
[`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md).
The table below shows for each parameter:

*valid* values that
[`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md)
accepts, and *sampled* ranges that
[`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)
draws from once per landscape for any parameter left unset. The defaults
shown in Usage therefore apply to
[`create_landscape`](https://ecomods.github.io/patternscaper/reference/create_landscape.md)
only. Ranges that scale with landscape size are shown for the default
100 by 100.

|                         |               |                            |
|-------------------------|---------------|----------------------------|
| **Parameter**           | **Valid**     | **Sampled**                |
| `n_spots`               | 1 or more     | 5 to 9                     |
| `spot_radius`           | 1 or more     | 10 to 15, scales with size |
| `spot_radius_sd`        | 0 or more     | 0 to 2, scales with size   |
| `radius_noise_fraction` | 0 to 1        | 0 to 0.2                   |
| `regular_spots`         | TRUE or FALSE | TRUE or FALSE              |
| `invert_landscape`      | TRUE or FALSE | always FALSE               |

## Examples

``` r
# A single landscape, with fixed values
create_landscape("spots", params = pattern_spots(n_spots = 15))
#> Landscape: <unnamed> [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 15, spot_radius = 10, spot_radius_sd = 0, radius_noise_fraction = 0, regular_spots = FALSE 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "spots",
  params_list = list(
    spots = pattern_spots(
      n_spots = c(5, 15),
      spot_radius = c(4, 8)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $spots_1
#> Landscape: "spots_1" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 12, spot_radius = 8, spot_radius_sd = 0.556843919679523, radius_noise_fraction = 0.127978959167376, regular_spots = TRUE 
#> 
#> $spots_2
#> Landscape: "spots_2" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 13, spot_radius = 7, spot_radius_sd = 1.88310010032728, radius_noise_fraction = 0.088484320230782, regular_spots = FALSE 
#> 
#> $spots_3
#> Landscape: "spots_3" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 11, spot_radius = 4, spot_radius_sd = 0.00559949595481157, radius_noise_fraction = 0.0810569220222533, regular_spots = FALSE 
#> 
#> $spots_4
#> Landscape: "spots_4" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 13, spot_radius = 4, spot_radius_sd = 1.20245855813846, radius_noise_fraction = 0.166129577020183, regular_spots = FALSE 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "spots",
  params_list = list(
    spots = pattern_spots(
      n_spots = 10,
      spot_radius = c(4, 8)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $spots_1
#> Landscape: "spots_1" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 10, spot_radius = 8, spot_radius_sd = 0.224441807717085, radius_noise_fraction = 0.128724273247644, regular_spots = FALSE 
#> 
#> $spots_2
#> Landscape: "spots_2" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 10, spot_radius = 4, spot_radius_sd = 0.11422164645046, radius_noise_fraction = 0.187016865704209, regular_spots = FALSE 
#> 
#> $spots_3
#> Landscape: "spots_3" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 10, spot_radius = 8, spot_radius_sd = 1.4696095995605, radius_noise_fraction = 0.130052016023546, regular_spots = FALSE 
#> 
#> $spots_4
#> Landscape: "spots_4" [pattern: spots]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = FALSE, n_spots = 10, spot_radius = 8, spot_radius_sd = 0.716070289723575, radius_noise_fraction = 0.143712487304583, regular_spots = FALSE 
#> 
```
