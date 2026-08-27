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
#> $bands_1_rot78
#> Landscape: "bands_1_rot78" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.447094757016748, band_zone = 0.569008397846483, band_thickness = 5, band_spacing = 8, frequency = 0.151280911546201, amplitude = 5, noise_sd = 0.118906778749079, rotation = 78 
#> 
#> $bands_2_rot238
#> Landscape: "bands_2_rot238" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.48428522143513, band_zone = 0.45432768703904, band_thickness = 2, band_spacing = 13, frequency = 0.181990951206535, amplitude = 5, noise_sd = 0.706654506037012, rotation = 238 
#> 
#> $bands_3_rot325
#> Landscape: "bands_3_rot325" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.365900718141347, band_zone = 0.450977541343309, band_thickness = 3, band_spacing = 12, frequency = 0.214472709968686, amplitude = 2, noise_sd = 0.688153600785881, rotation = 325 
#> 
#> $bands_4_rot342
#> Landscape: "bands_4_rot342" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.318147683003917, band_zone = 0.478656369284727, band_thickness = 2, band_spacing = 11, frequency = 0.151046235766262, amplitude = 2, noise_sd = 0.016771481372416, rotation = 342 
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
#> $bands_1_rot179
#> Landscape: "bands_1_rot179" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.42145664007403, band_zone = 0.380211284430698, band_thickness = 3, band_spacing = 11, frequency = 0.168298815051094, amplitude = 3, noise_sd = 0.735634378390387, rotation = 179 
#> 
#> $bands_2_rot134
#> Landscape: "bands_2_rot134" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.44449021522887, band_zone = 0.310705034597777, band_thickness = 3, band_spacing = 11, frequency = 0.111203635111451, amplitude = 3, noise_sd = 0.724067916860804, rotation = 134 
#> 
#> $bands_3_rot146
#> Landscape: "bands_3_rot146" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.422571873292327, band_zone = 0.415128990844823, band_thickness = 3, band_spacing = 16, frequency = 0.295220600161701, amplitude = 3, noise_sd = 0.258750996785238, rotation = 146 
#> 
#> $bands_4_rot237
#> Landscape: "bands_4_rot237" [pattern: bands]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.330101374536753, band_zone = 0.312830257485621, band_thickness = 3, band_spacing = 9, frequency = 0.213819893077016, amplitude = 5, noise_sd = 0.331478802487254, rotation = 237 
#> 
```
