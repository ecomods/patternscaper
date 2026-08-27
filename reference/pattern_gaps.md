# Parameters for the Gaps Pattern

Circular bare gaps in vegetated ground.

## Usage

``` r
pattern_gaps(
  n_gaps = 5,
  gap_radius = 10,
  gap_radius_sd = 0,
  radius_noise_fraction = 0,
  regular_gaps = FALSE
)
```

## Arguments

- n_gaps:

  Integer. Number of gaps (default: 5). Regular placement may reduce
  this number if the landscape cannot accommodate the requested count
  with the given `gap_radius`.

- gap_radius:

  Numeric. Mean radius of each gap in pixels (default: 10). Must be
  positive and smaller than landscape dimensions.

- gap_radius_sd:

  Numeric. Standard deviation of normally sampled gap radii (default: 0,
  no variation).

- radius_noise_fraction:

  Numeric. Fraction of the gap radius with a gradual edge transition
  (0-1). Zero gives sharp edges; 1 applies probabilistic cell inclusion
  across the full radius. For example, 0.2 applies the transition to the
  outer 20%. This is independent of `gap_radius_sd`, which varies
  overall gap size.

- regular_gaps:

  Logical. Arrange gaps on a hexagonal grid using k-means clustering
  rather than placing them randomly (default: FALSE).

## Value

A named `"landscape_params"` list containing the supplied parameters.

## Details

This is the inverse of
[`pattern_spots`](https://ecomods.github.io/patternscaper/reference/pattern_spots.md)
and therefore has no `invert_landscape` parameter.

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
[`pattern_labyrinth()`](https://ecomods.github.io/patternscaper/reference/pattern_labyrinth.md),
[`pattern_random()`](https://ecomods.github.io/patternscaper/reference/pattern_random.md),
[`pattern_sharp()`](https://ecomods.github.io/patternscaper/reference/pattern_sharp.md),
[`pattern_spots()`](https://ecomods.github.io/patternscaper/reference/pattern_spots.md)

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
| `n_gaps`                | 1 or more     | 5 to 9                     |
| `gap_radius`            | 1 or more     | 10 to 15, scales with size |
| `gap_radius_sd`         | 0 or more     | 0 to 2, scales with size   |
| `radius_noise_fraction` | 0 to 1        | 0 to 0.2                   |
| `regular_gaps`          | TRUE or FALSE | TRUE or FALSE              |

## Examples

``` r
# A single landscape, with fixed values
create_landscape("gaps", params = pattern_gaps(n_gaps = 5, gap_radius = 8))
#> Landscape: <unnamed> [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 5, gap_radius = 8, gap_radius_sd = 0, radius_noise_fraction = 0, regular_gaps = FALSE 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "gaps",
  params_list = list(
    gaps = pattern_gaps(
      n_gaps = c(4, 10),
      gap_radius = c(5, 10)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $gaps_1
#> Landscape: "gaps_1" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 5, gap_radius = 6, gap_radius_sd = 1.5879343166016, radius_noise_fraction = 0.0886702800169587, regular_gaps = TRUE 
#> 
#> $gaps_2
#> Landscape: "gaps_2" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 5, gap_radius = 7, gap_radius_sd = 1.62646044883877, radius_noise_fraction = 0.161126356152818, regular_gaps = TRUE 
#> 
#> $gaps_3
#> Landscape: "gaps_3" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 8, gap_radius = 9, gap_radius_sd = 1.38248990988359, radius_noise_fraction = 0.141771729057655, regular_gaps = FALSE 
#> 
#> $gaps_4
#> Landscape: "gaps_4" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 7, gap_radius = 9, gap_radius_sd = 1.52434144355357, radius_noise_fraction = 0.0125860714819282, regular_gaps = FALSE 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "gaps",
  params_list = list(
    gaps = pattern_gaps(
      n_gaps = 6,
      gap_radius = c(5, 10)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $gaps_1
#> Landscape: "gaps_1" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 6, gap_radius = 7, gap_radius_sd = 1.45131252333522, radius_noise_fraction = 0.0583874429110438, regular_gaps = FALSE 
#> 
#> $gaps_2
#> Landscape: "gaps_2" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 6, gap_radius = 9, gap_radius_sd = 1.98492909874767, radius_noise_fraction = 0.098158588912338, regular_gaps = TRUE 
#> 
#> $gaps_3
#> Landscape: "gaps_3" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 6, gap_radius = 8, gap_radius_sd = 1.77985197212547, radius_noise_fraction = 0.137208430189639, regular_gaps = TRUE 
#> 
#> $gaps_4
#> Landscape: "gaps_4" [pattern: gaps]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, invert_landscape = TRUE, n_gaps = 6, gap_radius = 8, gap_radius_sd = 0.958843165077269, radius_noise_fraction = 0.161440896522254, regular_gaps = TRUE 
#> 
```
