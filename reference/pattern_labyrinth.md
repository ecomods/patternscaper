# Parameters for the Labyrinth Pattern

Maze-like vegetation bands that mimic a Turing pattern.

## Usage

``` r
pattern_labyrinth(
  frequency = 3,
  veg_threshold = 0.5,
  band_fuzziness = 0.08,
  octaves = 2
)
```

## Arguments

- frequency:

  Numeric. Spatial scale of the noise pattern. Lower values produce
  broad, smooth bands; higher values produce finer, more maze-like
  structures (default: 3).

- veg_threshold:

  Numeric. Threshold separating vegetated and bare cells (0-1, default:
  0.5). Values above it become vegetation. Lower thresholds increase
  vegetation cover; higher thresholds reduce it.

- band_fuzziness:

  Numeric. Probability that an edge cell is eroded after thresholding
  (0-1, default: 0.08). This changes edge roughness without changing the
  underlying noise field. Zero gives deterministic boundaries; values
  around 0.05 to 0.1 add slight irregularities while largely preserving
  topology. Higher values may fragment bands, and values above roughly
  0.3 can appear increasingly random rather than maze-like.

- octaves:

  Integer. Number of noise layers combined into the continuous field (at
  least 1, default: 2). One octave emphasizes smooth, large-scale
  structure. Two to three add fine-scale variation while preserving a
  dominant wavelength. Higher values add fractal-like detail that can
  obscure the bands.

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

|                  |                |              |
|------------------|----------------|--------------|
| **Parameter**    | **Valid**      | **Sampled**  |
| `frequency`      | greater than 0 | 2.5 to 3.5   |
| `veg_threshold`  | 0 to 1         | 0.45 to 0.55 |
| `band_fuzziness` | 0 to 1         | 0.06 to 0.25 |
| `octaves`        | 1 or more      | 2 to 4       |

## Examples

``` r
# A single landscape, with fixed values
create_landscape(
  "labyrinth",
  params = pattern_labyrinth(frequency = 3.5, octaves = 3)
)
#> Landscape: <unnamed> [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3.5, veg_threshold = 0.5, band_fuzziness = 0.08, octaves = 3 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "labyrinth",
  params_list = list(
    labyrinth = pattern_labyrinth(
      frequency = c(2.5, 4),
      octaves = c(2, 4)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $labyrinth_1
#> Landscape: "labyrinth_1" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3.96111232577823, veg_threshold = 0.539127231482416, band_fuzziness = 0.12784308383707, octaves = 4 
#> 
#> $labyrinth_2
#> Landscape: "labyrinth_2" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3.31825935002416, veg_threshold = 0.49874360668473, band_fuzziness = 0.237971883695573, octaves = 2 
#> 
#> $labyrinth_3
#> Landscape: "labyrinth_3" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 2.53940396627877, veg_threshold = 0.542101821652614, band_fuzziness = 0.14045161819784, octaves = 3 
#> 
#> $labyrinth_4
#> Landscape: "labyrinth_4" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 2.90126859536394, veg_threshold = 0.452147987834178, band_fuzziness = 0.240882745850831, octaves = 2 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "labyrinth",
  params_list = list(
    labyrinth = pattern_labyrinth(
      frequency = 3,
      octaves = c(2, 4)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $labyrinth_1
#> Landscape: "labyrinth_1" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3, veg_threshold = 0.478663486149162, band_fuzziness = 0.122412023027427, octaves = 2 
#> 
#> $labyrinth_2
#> Landscape: "labyrinth_2" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3, veg_threshold = 0.488082625088282, band_fuzziness = 0.209662749522831, octaves = 2 
#> 
#> $labyrinth_3
#> Landscape: "labyrinth_3" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3, veg_threshold = 0.505458245659247, band_fuzziness = 0.0917158329067752, octaves = 2 
#> 
#> $labyrinth_4
#> Landscape: "labyrinth_4" [pattern: labyrinth]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, frequency = 3, veg_threshold = 0.462240721937269, band_fuzziness = 0.220382585627958, octaves = 2 
#> 
```
