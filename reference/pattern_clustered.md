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
#> $clustered_1_rot177
#> Landscape: "clustered_1_rot177" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.591689004190266, n_clusters = 8, cluster_radius = 4, cluster_zone = 0.607681477069855, elongation_x = 0.902967239031568, elongation_y = 0.731844176771119, rotation = 177 
#> 
#> $clustered_2_rot356
#> Landscape: "clustered_2_rot356" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.479156721988693, n_clusters = 8, cluster_radius = 5, cluster_zone = 0.890481751598418, elongation_x = 1.02773407287896, elongation_y = 1.23859300184995, rotation = 356 
#> 
#> $clustered_3_rot92
#> Landscape: "clustered_3_rot92" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.444279740937054, n_clusters = 12, cluster_radius = 4, cluster_zone = 0.635638977959752, elongation_x = 0.938324093353003, elongation_y = 0.584773896960542, rotation = 92 
#> 
#> $clustered_4_rot49
#> Landscape: "clustered_4_rot49" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.419753044517711, n_clusters = 8, cluster_radius = 8, cluster_zone = 0.580911484360695, elongation_x = 0.557363673113286, elongation_y = 1.47497145133093, rotation = 49 
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
#> $clustered_1_rot89
#> Landscape: "clustered_1_rot89" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.594288135552779, n_clusters = 8, cluster_radius = 4, cluster_zone = 0.59355426300317, elongation_x = 1.20305816852488, elongation_y = 1.20890617207624, rotation = 89 
#> 
#> $clustered_2_rot321
#> Landscape: "clustered_2_rot321" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.472178921988234, n_clusters = 8, cluster_radius = 8, cluster_zone = 0.449984030239284, elongation_x = 0.885540628340095, elongation_y = 1.48698451998644, rotation = 321 
#> 
#> $clustered_3_rot336
#> Landscape: "clustered_3_rot336" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.406134204566479, n_clusters = 8, cluster_radius = 6, cluster_zone = 0.942507328093052, elongation_x = 0.5998674496077, elongation_y = 1.17017687787302, rotation = 336 
#> 
#> $clustered_4_rot231
#> Landscape: "clustered_4_rot231" [pattern: clustered]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.441980333859101, n_clusters = 8, cluster_radius = 7, cluster_zone = 0.299922896921635, elongation_x = 0.669052553595975, elongation_y = 0.65326046012342, rotation = 231 
#> 
```
