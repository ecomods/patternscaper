# Parameters for the Fingers Pattern

Finger-like extensions of vegetation growing into the bare zone.

## Usage

``` r
pattern_fingers(
  boundary_position = 0.5,
  sine_length_mean = 20,
  sine_length_sd = 12,
  sine_height_mean = 5,
  sine_height_sd = 5
)
```

## Arguments

- boundary_position:

  Numeric. Relative position of the horizontal vegetation boundary (if
  not rotated) from the top (0-1, default: 0.5).

- sine_length_mean:

  Numeric. Mean wavelength of sinusoidal curve in pixels. Larger values
  produce longer, more widely spaced bends (default: 20).

- sine_length_sd:

  Numeric. Standard deviation of wavelength in pixels. Larger values
  produce less regular curves (default: 12).

- sine_height_mean:

  Numeric. Mean amplitude of sinusoidal curve in pixels. Larger values
  produce more pronounced bends (default: 5).

- sine_height_sd:

  Numeric. Standard deviation of amplitude in pixels. Larger values
  increase variation in bend height (default: 5).

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

|                     |                |                            |
|---------------------|----------------|----------------------------|
| **Parameter**       | **Valid**      | **Sampled**                |
| `boundary_position` | 0 to 1         | 0.3 to 0.6                 |
| `sine_length_mean`  | greater than 0 | 20 to 50, scales with size |
| `sine_length_sd`    | 0 or more      | 10 to 50, scales with size |
| `sine_height_mean`  | 0 or more      | 5 to 20, scales with size  |
| `sine_height_sd`    | 0 or more      | 5 to 25, scales with size  |

## Examples

``` r
# A single landscape, with fixed values
create_landscape(
  "fingers",
  params = pattern_fingers(sine_length_mean = 15, sine_height_mean = 10)
)
#> Landscape: <unnamed> [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.5, sine_length_mean = 15, sine_length_sd = 12, sine_height_mean = 10, sine_height_sd = 5, rotation = 0 

# A batch, with parameters drawn from ranges once per landscape.
# Parameters left unset vary too, over their default ranges
create_landscapes(
  n = 4,
  patterns = "fingers",
  params_list = list(
    fingers = pattern_fingers(
      sine_length_mean = c(10, 30),
      sine_height_mean = c(5, 15)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $fingers_1_rot228
#> Landscape: "fingers_1_rot228" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.328568306285888, sine_length_mean = 21.8705789325759, sine_length_sd = 44.7297929879278, sine_height_mean = 5.72784828254953, sine_height_sd = 5.93640517443419, rotation = 228 
#> 
#> $fingers_2_rot326
#> Landscape: "fingers_2_rot326" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.345179196749814, sine_length_mean = 27.6155733736232, sine_length_sd = 36.0893513634801, sine_height_mean = 14.117089335341, sine_height_sd = 13.7059455737472, rotation = 326 
#> 
#> $fingers_3_rot133
#> Landscape: "fingers_3_rot133" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.403399932221509, sine_length_mean = 26.5964952250943, sine_length_sd = 49.1867499798536, sine_height_mean = 13.9035515883006, sine_height_sd = 19.7369659971446, rotation = 133 
#> 
#> $fingers_4_rot85
#> Landscape: "fingers_4_rot85" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.445987639110535, sine_length_mean = 17.1896539768204, sine_length_sd = 17.1918841544539, sine_height_mean = 13.727365094237, sine_height_sd = 22.491088504903, rotation = 85 
#> 

# A batch, mixing a fixed value with a range
create_landscapes(
  n = 4,
  patterns = "fingers",
  params_list = list(
    fingers = pattern_fingers(
      sine_length_mean = 20,
      sine_height_mean = c(5, 15)
    )
  )
)
#> ✔ Successfully generated all 4 training landscapes
#> $fingers_1_rot261
#> Landscape: "fingers_1_rot261" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.570406128326431, sine_length_mean = 20, sine_length_sd = 30.7585501205176, sine_height_mean = 13.446258790791, sine_height_sd = 5.6898803729564, rotation = 261 
#> 
#> $fingers_2_rot26
#> Landscape: "fingers_2_rot26" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.485261995531619, sine_length_mean = 20, sine_length_sd = 31.1241553258151, sine_height_mean = 7.14850739808753, sine_height_sd = 7.28074305690825, rotation = 26 
#> 
#> $fingers_3_rot316
#> Landscape: "fingers_3_rot316" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.482379484106787, sine_length_mean = 20, sine_length_sd = 13.6161938402802, sine_height_mean = 14.8700977233239, sine_height_sd = 7.96006672084332, rotation = 316 
#> 
#> $fingers_4_rot300
#> Landscape: "fingers_4_rot300" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.559707279643044, sine_length_mean = 20, sine_length_sd = 22.5451841019094, sine_height_mean = 10.090159624815, sine_height_sd = 23.6511834338307, rotation = 300 
#> 
```
