# Parameters for the Bands Pattern

Sinusoidal vegetation bands running parallel to the boundary.

## Usage

``` r
pattern_bands(
  boundary_position = 0.5,
  band_zone = 0.3,
  band_thickness = 3,
  band_spacing = 10,
  frequency = 4 * pi/100,
  amplitude = 5,
  noise_sd = 0
)
```

## Arguments

- boundary_position:

  Numeric. Relative position of the horizontal vegetation boundary (if
  not rotated) from the top (0-1, default: 0.5).

- band_zone:

  Numeric. Proportion of the total landscape height to allocate for
  bands below the vegetation boundary (0-1, default: 0.3). If the band
  zone is too small for the given band spacing, no bands are drawn and a
  warning is issued.

- band_thickness:

  Integer. Thickness of each band in pixels (default: 3).

- band_spacing:

  Integer. Spacing between bands in pixels (default: 10).

- frequency:

  Numeric. Frequency of the bands' sine wave (default: 4\*pi/100).

- amplitude:

  Numeric. Amplitude of the bands' sine wave in pixels (default: 5).

- noise_sd:

  Numeric. Standard deviation of each band's vertical deviation from its
  baseline along the x-axis (default: 0).

## Value

A named `"landscape_params"` list containing the supplied parameters.

## See also

Other landscape creation:
[`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md),
[`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md),
[`pattern_bare()`](https://ecomods.github.io/patternscaper/reference/pattern_bare.md),
[`pattern_clustered()`](https://ecomods.github.io/patternscaper/reference/pattern_clustered.md),
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

|                     |           |                            |
|---------------------|-----------|----------------------------|
| **Parameter**       | **Valid** | **Sampled**                |
| `boundary_position` | 0 to 1    | 0.3 to 0.5                 |
| `band_zone`         | 0 to 1    | 0.3 to 0.6                 |
| `band_thickness`    | 1 or more | 2 to 4, scales with size   |
| `band_spacing`      | 1 or more | 10 to 20, scales with size |
| `frequency`         | 0 or more | 0.1 to 0.3                 |
| `amplitude`         | 0 or more | 0 to 6, scales with size   |
| `noise_sd`          | 0 or more | 0 to 1, scales with size   |

## Examples

``` r
# A single landscape, with fixed values
create_landscape(
  "bands",
  params = pattern_bands(band_thickness = 4, band_spacing = 12)
)
#> Landscape: <unnamed> [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.5, band_zone = 0.3, band_thickness = 4, band_spacing = 12, frequency = 0.125663706143592, amplitude = 5, noise_sd = 0, rotation = 0 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "bands",
  params_list = list(
    bands = pattern_bands(
      band_thickness = c(2, 5),
      band_spacing = c(8, 16)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $bands_1_rot109
#> Landscape: "bands_1_rot109" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.384864045353606, band_zone = 0.408272821898572, band_thickness = 5, band_spacing = 10, frequency = 0.136571329180151, amplitude = 3, noise_sd = 0.959069916512817, rotation = 109 
#> 
#> $bands_2_rot255
#> Landscape: "bands_2_rot255" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.484207416698337, band_zone = 0.379091438557953, band_thickness = 5, band_spacing = 14, frequency = 0.238112794980407, amplitude = 1, noise_sd = 0.936041137203574, rotation = 255 
#> 
#> $bands_3_rot173
#> Landscape: "bands_3_rot173" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.352090624393895, band_zone = 0.498517180373892, band_thickness = 5, band_spacing = 10, frequency = 0.19150053113699, amplitude = 2, noise_sd = 0.00106336851604283, rotation = 173 
#> 
#> $bands_4_rot137
#> Landscape: "bands_4_rot137" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.382286404166371, band_zone = 0.446640252764337, band_thickness = 4, band_spacing = 14, frequency = 0.290677449340001, amplitude = 5, noise_sd = 0.928192451130599, rotation = 137 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "bands",
  params_list = list(
    bands = pattern_bands(
      band_thickness = 3,
      band_spacing = c(8, 16)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $bands_1_rot99
#> Landscape: "bands_1_rot99" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.438778409408405, band_zone = 0.431064933585003, band_thickness = 3, band_spacing = 15, frequency = 0.192194949788973, amplitude = 5, noise_sd = 0.583000144921243, rotation = 99 
#> 
#> $bands_2_rot230
#> Landscape: "bands_2_rot230" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.417278952151537, band_zone = 0.575319525226951, band_thickness = 3, band_spacing = 16, frequency = 0.126188040710986, amplitude = 0, noise_sd = 0.532980548683554, rotation = 230 
#> 
#> $bands_3_rot334
#> Landscape: "bands_3_rot334" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.470294021908194, band_zone = 0.535487921512686, band_thickness = 3, band_spacing = 9, frequency = 0.164389393338934, amplitude = 1, noise_sd = 0.554439563769847, rotation = 334 
#> 
#> $bands_4_rot97
#> Landscape: "bands_4_rot97" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.322918730229139, band_zone = 0.460950511693954, band_thickness = 3, band_spacing = 8, frequency = 0.20570713034831, amplitude = 6, noise_sd = 0.0713230895344168, rotation = 97 
#> 
```
