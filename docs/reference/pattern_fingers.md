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
#> $fingers_1_rot298
#> Landscape: "fingers_1_rot298" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.446132078650407, sine_length_mean = 19.1744653275236, sine_length_sd = 32.2254263237119, sine_height_mean = 13.5680353990756, sine_height_sd = 14.2519281245768, rotation = 298 
#> 
#> $fingers_2_rot305
#> Landscape: "fingers_2_rot305" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.356431636121124, sine_length_mean = 22.1337623521686, sine_length_sd = 40.3584067989141, sine_height_mean = 6.96983828907833, sine_height_sd = 17.9217813815922, rotation = 305 
#> 
#> $fingers_3_rot99
#> Landscape: "fingers_3_rot99" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.338487040624022, sine_length_mean = 24.8211051477119, sine_length_sd = 38.8728254754096, sine_height_mean = 12.020182586275, sine_height_sd = 12.7841524314135, rotation = 99 
#> 
#> $fingers_4_rot182
#> Landscape: "fingers_4_rot182" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.356214206060395, sine_length_mean = 16.9034961843863, sine_length_sd = 18.1671427190304, sine_height_mean = 8.25869817752391, sine_height_sd = 12.97139165923, rotation = 182 
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
#> $fingers_1_rot151
#> Landscape: "fingers_1_rot151" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.4689416017849, sine_length_mean = 20, sine_length_sd = 19.5710786059499, sine_height_mean = 14.0824759472162, sine_height_sd = 15.9358740923926, rotation = 151 
#> 
#> $fingers_2_rot164
#> Landscape: "fingers_2_rot164" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.389273237460293, sine_length_mean = 20, sine_length_sd = 48.5698829125613, sine_height_mean = 11.2226607254706, sine_height_sd = 5.415148306638, rotation = 164 
#> 
#> $fingers_3_rot74
#> Landscape: "fingers_3_rot74" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.584430665709078, sine_length_mean = 20, sine_length_sd = 36.3467654027045, sine_height_mean = 9.138546991162, sine_height_sd = 16.1352657014504, rotation = 74 
#> 
#> $fingers_4_rot230
#> Landscape: "fingers_4_rot230" [pattern: fingers]
#> -----------------------------------------
#> Dimensions: 100x100 (10000 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=100.0, ymin=0.0, ymax=100.0
#> Values    : min=0.0, max=1.0
#> Parameters: width = 100, height = 100, boundary_position = 0.429039896163158, sine_length_mean = 20, sine_length_sd = 31.627607550472, sine_height_mean = 5.60735244536772, sine_height_sd = 7.37499186769128, rotation = 230 
#> 
```
