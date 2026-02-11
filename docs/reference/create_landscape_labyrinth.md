# Create a Landscape with Labyrinths as in Turing patterns

Generates a landscape with banded and spotted vegetation (labyrinth),
this mimics Turing patterns.

## Usage

``` r
create_landscape_labyrinth(
  width = 100,
  height = 100,
  frequency = 3,
  veg_threshold = 0.5,
  band_fuzziness = 0.08,
  octaves = 2
)
```

## Arguments

- width:

  Integer. Number of columns in the landscape (default: 100).

- height:

  Integer. Number of rows in the landscape (default: 100).

- frequency:

  Numeric. Controls the spatial scale of the noise pattern: Lower values
  produce broad, smooth bands, higher values produce finer, maze-like
  structures (default: 3).

- veg_threshold:

  Numeric between 0 and 1. Defines the cutoff value that separates
  vegetated from non-vegetated cells. Values above the threshold become
  vegetation. Adjusting this changes the overall proportion of vegetated
  area (default: 0.5).

- band_fuzziness:

  Numeric between 0 and 0.5. Controls the amount of geometric edge
  roughness applied \*after\* thresholding. At 0, vegetation boundaries
  are sharp and fully deterministic. Small values (≈ 0.05–0.1) introduce
  slight, irregular boundary perturbations without changing the overall
  topology of the pattern. Larger values progressively erode vegetation
  edges and can fragmet bands if set too high. This parameter affects
  boundary geometry only and does not influence the global structure or
  connectivity of the labyrinth. (default: 0.08)

- octaves:

  Integer \>= 1. Number of noise layers (octaves) combined to generate
  the underlying continuous field. A single octave produces very smooth,
  large-scale bands. Using two to three octaves adds limited fine
  structure while preserving a dominant wavelength, which is
  characteristic of labyrinth (Turing-like) patterns. Higher values
  introduce fractal detail at smaller scales and can obscure the banded
  structure, making patterns less clearly classifiable as labyrinths.
  (default: 2).

## Value

A landscape object with pattern "labyrinth" containing the generated
landscape data and parameters.

## Details

The labyrinth pattern is generated using fractal Brownian motion (fBm):

1\. \*\*Noise generation\*\*: Creates a continuous noise field using
multiple octaves of Perlin noise with \`fbm_perlin()\`.

2\. \*\*Normalization\*\*: Scales noise values to \[0, 1\] range.

3\. \*\*Thresholding\*\*: Applies \`veg_threshold\` to create binary
pattern. Cells with noise \> threshold become vegetation.

4\. \*\*Fuzzy boundaries\*\*: Adds probabilistic transitions within
\`band_fuzziness\` distance of the threshold for natural-looking edges.

The combination of \`frequency\` and \`octaves\` controls pattern
complexity, while \`veg_threshold\` determines vegetation proportion.

## Examples

``` r
# Default labyrinth pattern
labyrinth_default <- create_landscape_labyrinth()
#> Error in create_landscape_labyrinth(): could not find function "create_landscape_labyrinth"

# Modified labyrinth with higher frequency and multiple octaves
labyrinth_modified <- create_landscape_labyrinth(
  frequency = 8,
  octaves = 3,
  band_fuzziness = 0.05
)
#> Error in create_landscape_labyrinth(frequency = 8, octaves = 3, band_fuzziness = 0.05): could not find function "create_landscape_labyrinth"

# Adjust vegetation coverage
labyrinth_sparse <- create_landscape_labyrinth(
  veg_threshold = 0.6  # Less vegetation
)
#> Error in create_landscape_labyrinth(veg_threshold = 0.6): could not find function "create_landscape_labyrinth"

labyrinth_dense <- create_landscape_labyrinth(
  veg_threshold = 0.3  # More vegetation
)
#> Error in create_landscape_labyrinth(veg_threshold = 0.3): could not find function "create_landscape_labyrinth"
```
