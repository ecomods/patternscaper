# Parameters for the Diffuse Pattern

A vegetated and a bare zone with a gradual transition between them,
where the chance of a cell being vegetated decreases with distance from
the boundary.

## Usage

``` r
pattern_diffuse(steepness = 0.5, boundary_position = 0.2)
```

## Arguments

- steepness:

  Numeric. Shape of the vegetation-probability decline below the
  boundary (0-1, default: 0.5). Values near 0 produce a sparse, abrupt
  transition; values near 1 produce a denser, more gradual transition.
  The potential extent of the transition remains unchanged.

- boundary_position:

  Numeric. Relative position of the horizontal vegetation boundary (if
  not rotated) from the top (0-1, default: 0.2).

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
[`pattern_fingers()`](https://ecomods.github.io/patternscaper/reference/pattern_fingers.md),
[`pattern_gaps()`](https://ecomods.github.io/patternscaper/reference/pattern_gaps.md),
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

|                     |           |             |
|---------------------|-----------|-------------|
| **Parameter**       | **Valid** | **Sampled** |
| `steepness`         | 0 to 1    | 0.1 to 1    |
| `boundary_position` | 0 to 1    | 0.1 to 0.4  |

## Examples

``` r
# A single landscape, with fixed values
create_landscape(
  "diffuse",
  params = pattern_diffuse(steepness = 0.1, boundary_position = 0.3)
)
#> Landscape: <unnamed> [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.3, steepness = 0.1, rotation = 0 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "diffuse",
  params_list = list(
    diffuse = pattern_diffuse(
      steepness = c(0.1, 1),
      boundary_position = c(0.1, 0.4)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $diffuse_1_rot41
#> Landscape: "diffuse_1_rot41" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.393685674504377, steepness = 0.206397260143422, rotation = 41 
#> 
#> $diffuse_2_rot304
#> Landscape: "diffuse_2_rot304" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.36057325869333, steepness = 0.316394871450029, rotation = 304 
#> 
#> $diffuse_3_rot244
#> Landscape: "diffuse_3_rot244" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.265111538837664, steepness = 0.154594413610175, rotation = 244 
#> 
#> $diffuse_4_rot179
#> Landscape: "diffuse_4_rot179" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.373677007760853, steepness = 0.225622180383652, rotation = 179 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "diffuse",
  params_list = list(
    diffuse = pattern_diffuse(
      steepness = 0.5,
      boundary_position = c(0.1, 0.4)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $diffuse_1_rot80
#> Landscape: "diffuse_1_rot80" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.190730696124956, steepness = 0.5, rotation = 80 
#> 
#> $diffuse_2_rot2
#> Landscape: "diffuse_2_rot2" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.119293758925051, steepness = 0.5, rotation = 2 
#> 
#> $diffuse_3_rot340
#> Landscape: "diffuse_3_rot340" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.237901764782146, steepness = 0.5, rotation = 340 
#> 
#> $diffuse_4_rot15
#> Landscape: "diffuse_4_rot15" [pattern: diffuse]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.158919703494757, steepness = 0.5, rotation = 15 
#> 
```
