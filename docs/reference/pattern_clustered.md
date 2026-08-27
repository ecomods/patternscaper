# Parameters for the Clustered Pattern

Vegetation clusters scattered into the bare zone.

## Usage

``` r
pattern_clustered(
  boundary_position = 0.5,
  n_clusters = 10,
  cluster_radius = 5,
  cluster_zone = 0.3,
  elongation_x = 1,
  elongation_y = 1
)
```

## Arguments

- boundary_position:

  Numeric. Relative position of the horizontal vegetation boundary (if
  not rotated) from the top (0-1, default: 0.5).

- n_clusters:

  Integer. Number of cluster centers (default: 10).

- cluster_radius:

  Numeric. Radius of clusters in pixels (default: 5).

- cluster_zone:

  Numeric. Proportion of height for the cluster zone, measured downward
  from the vegetation boundary (0-1, default: 0.3).

- elongation_x:

  Numeric. Horizontal elongation factor for clusters. Values above 1
  stretch clusters horizontally; values below 1 compress them (default:
  1).

- elongation_y:

  Numeric. Vertical elongation factor for clusters. Values above 1
  stretch clusters vertically; values below 1 compress them (default:
  1).

## Value

A named `"landscape_params"` list containing the supplied parameters.

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md),
[`pattern_bands()`](https://ecomods.github.io/patternscaper/reference/pattern_bands.md),
[`pattern_bare()`](https://ecomods.github.io/patternscaper/reference/pattern_bare.md),
[`pattern_dense()`](https://ecomods.github.io/patternscaper/reference/pattern_dense.md),
[`pattern_diffuse()`](https://ecomods.github.io/patternscaper/reference/pattern_diffuse.md),
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

|                     |                         |             |
|---------------------|-------------------------|-------------|
| **Parameter**       | **Valid**               | **Sampled** |
| `boundary_position` | 0 to 1                  | 0.4 to 0.6  |
| `n_clusters`        | 1 or more               | 5 to 12     |
| `cluster_radius`    | 1 or more               | 5 to 10     |
| `cluster_zone`      | greater than 0, up to 1 | 0.2 to 1    |
| `elongation_x`      | greater than 0          | 0.5 to 1.5  |
| `elongation_y`      | greater than 0          | 0.5 to 1.5  |

## Examples

``` r
# A single landscape, with fixed values
create_landscape(
  "clustered",
  params = pattern_clustered(n_clusters = 8, cluster_radius = 7)
)
#> Landscape: <unnamed> [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.5, n_clusters = 8, cluster_radius = 7, cluster_zone = 0.3, elongation_x = 1, elongation_y = 1, rotation = 0 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "clustered",
  params_list = list(
    clustered = pattern_clustered(
      n_clusters = c(5, 12),
      cluster_radius = c(4, 8)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $clustered_1_rot295
#> Landscape: "clustered_1_rot295" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.505583659466356, n_clusters = 10, cluster_radius = 7, cluster_zone = 0.218484943173826, elongation_x = 1.31334675196558, elongation_y = 0.795712298713624, rotation = 295 
#> 
#> $clustered_2_rot140
#> Landscape: "clustered_2_rot140" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.531525111664087, n_clusters = 10, cluster_radius = 4, cluster_zone = 0.82288194168359, elongation_x = 1.26933534746058, elongation_y = 1.38236144790426, rotation = 140 
#> 
#> $clustered_3_rot294
#> Landscape: "clustered_3_rot294" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.401407293090597, n_clusters = 11, cluster_radius = 8, cluster_zone = 0.478881263174117, elongation_x = 1.2572765017394, elongation_y = 0.619193187216297, rotation = 294 
#> 
#> $clustered_4_rot119
#> Landscape: "clustered_4_rot119" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.557512569101527, n_clusters = 9, cluster_radius = 7, cluster_zone = 0.271151128411293, elongation_x = 1.26181372068822, elongation_y = 0.867118057794869, rotation = 119 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "clustered",
  params_list = list(
    clustered = pattern_clustered(
      n_clusters = 8,
      cluster_radius = c(4, 8)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $clustered_1_rot3
#> Landscape: "clustered_1_rot3" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.409347336599603, n_clusters = 8, cluster_radius = 5, cluster_zone = 0.862575111724436, elongation_x = 1.30011919233948, elongation_y = 1.43335558497347, rotation = 3 
#> 
#> $clustered_2_rot27
#> Landscape: "clustered_2_rot27" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.569851662078872, n_clusters = 8, cluster_radius = 8, cluster_zone = 0.61144432015717, elongation_x = 1.44251390895806, elongation_y = 0.687989874510095, rotation = 27 
#> 
#> $clustered_3_rot298
#> Landscape: "clustered_3_rot298" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.409117111191154, n_clusters = 8, cluster_radius = 6, cluster_zone = 0.921592743322253, elongation_x = 0.516906784148887, elongation_y = 0.519754391396418, rotation = 298 
#> 
#> $clustered_4_rot196
#> Landscape: "clustered_4_rot196" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.446799457957968, n_clusters = 8, cluster_radius = 8, cluster_zone = 0.875295421108603, elongation_x = 0.74816533178091, elongation_y = 0.827804027125239, rotation = 196 
#> 
```
