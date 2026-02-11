# Calculates fractal Perlin noise value for coordinates x,y

Generates a fractal Brownian motion (fBm) noise value by combining
multiple layers (octaves) of Perlin noise at increasing frequencies and
decreasing amplitudes. Used internally for generating labyrinth
structures.

## Usage

``` r
fbm_perlin(x, y, frequency, octaves = 6, lacunarity = 2, gain = 0.5)
```

## Arguments

- x:

  Numeric. x-coordinate at which to evaluate the noise.

- y:

  Numeric. y-coordinate at which to evaluate the noise.

- frequency:

  Numeric. Base frequency for the first octave of Perlin noise.

- octaves:

  Integer. Number of noise layers to combine. Default: 6.

- lacunarity:

  Numeric. Multiplier applied to the frequency at each octave. Default:
  2.

- gain:

  Numeric. Multiplier applied to the amplitude at each octave. Default:
  0.5.

## Value

A combined noise value for coordinate x,y
