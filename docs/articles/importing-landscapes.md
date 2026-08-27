# Import user-defined landscapes

Convert your own categorical land-cover matrices or rasters into
`landscape` objects for model training or classification. If you are new
to the package, begin with [Get started with
patternscaper](https://ecomods.github.io/patternscaper/articles/patternscaper.md)
for an overview of the complete classification workflow.

Input data can be created manually or read from files.

``` r

library(patternscaper)

set.seed(123456)
```

`patternscaper` functions that use raster landscapes all expect a
`landscape` object or a list of `landscape` objects. To wrap a matrix or
a `SpatRaster` from the [`terra` R
package](https://rspatial.github.io/terra/index.html) into a `landscape`
object, use the
[`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md)
function.

Both workflows use categorical land-cover data represented by finite
whole-number codes. These codes don’t need to start at zero or be
consecutive. This means that you should classify continuous measurements
(e.g. elevation, vegetation indices), and raw images into land-cover
classes before converting them to `landscape` objects. Use one
categorical land-cover layer per landscape.

The pixel workflow does not support `NA` cells in the raster. The metric
workflow excludes `NA` cells from the analysed landscape. See [Matching
training and application
data](https://ecomods.github.io/patternscaper/articles/matching-training-application.md)
for how missing cells and raster geometry affect the two workflows.

## Read or create input data

Read a classified raster file as a `SpatRaster` with
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html):

``` r

land_cover_raster <- terra::rast("path/to/classified-land-cover.tif")
```

Alternatively, you can create landscapes directly as a matrix. The
examples below create a matrix and a `SpatRaster` containing the same
land-cover values:

``` r

landscape_matrix <- matrix(
  sample(1:3, 100, replace = TRUE),
  nrow = 10
)

landscape_raster <- terra::rast(landscape_matrix)
```

For example, the values `1`, `2`, and `3` in the matrix can represent
land-cover classes forest, grassland, and water. Training and
application rasters must use the same code for the same land-cover
category.

## Convert one landscape into a `landscape` object

Use
[`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md)
to wrap the input data and optionally add metadata:

- `name` identifies an individual landscape in tables and plots.
- `pattern` is the known spatial pattern class used for model training
  and performance evaluation.

Both default to `NA` and can be set during conversion.

> **Note**
>
> For model training, landscapes need a known pattern label. For
> application landscapes that should be classified, you can leave
> `pattern` at its default `NA`.

``` r

matrix_landscape <- landscape(
  landscape_matrix,
  name = "Matrix landscape example",
  pattern = "custom"
)

raster_landscape <- landscape(
  landscape_raster,
  name = "Raster landscape example",
  pattern = "custom"
)
```

Wrapping a `SpatRaster` in a `landscape` object preserves its cell
values, extent, resolution, and coordinate reference system. Data
without this spatial information (e.g. from a simple matrix) give a
raster with a default cell resolution of 1 and no coordinate reference
system.

Printing a landscape object shows its properties:

``` r

matrix_landscape
#> Landscape: "Matrix landscape example" [pattern: custom]
#> -----------------------------------------
#> Dimensions: 10x10 (100 cells)
#> Resolution: 1.0x1.0
#> Extent    : xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0
#> Values    : min=1.0, max=3.0
#> Parameters: none
```

## Update landscape metadata

Names and known pattern labels can also be updated after conversion with
[`set_landscape_name()`](https://ecomods.github.io/patternscaper/reference/set_landscape_name.md)
and
[`set_landscape_pattern()`](https://ecomods.github.io/patternscaper/reference/set_landscape_pattern.md):

``` r

matrix_landscape <- matrix_landscape |>
  set_landscape_name("Landscape 1") |>
  set_landscape_pattern("pattern_a")
```

These functions change only the stored metadata. They do not alter the
raster cells.

## Convert multiple landscapes

Use [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html) to
convert a list of matrices or rasters. Use
[`purrr::pmap()`](https://purrr.tidyverse.org/reference/pmap.html) when
names and patterns are supplied as parallel vectors.

``` r

landscape_matrices <- list(
  matrix1 = matrix(sample(1:3, 100, replace = TRUE), nrow = 10),
  matrix2 = matrix(sample(1:3, 100, replace = TRUE), nrow = 10),
  matrix3 = matrix(sample(1:3, 100, replace = TRUE), nrow = 10)
)
landscape_names <- c("Landscape 1", "Landscape 2", "Landscape 3")
landscape_patterns <- c("pattern_a", "pattern_a", "pattern_b")

landscape_objects <- purrr::pmap(
  list(
    data = landscape_matrices,
    name = landscape_names,
    pattern = landscape_patterns
  ),
  landscape
)
```

After conversion, you can use the landscapes like any other `landscape`
objects in `patternscaper`. For example, you can plot them with
[`plot_landscapes()`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md):

``` r

plot_landscapes(landscape_objects)
```

![Three categorical landscapes labelled pattern_a, pattern_a, and
pattern_b](importing-landscapes_files/figure-html/plot-landscapes-1.png)

## Next steps

Continue with the guide for one of the classification workflows:

- [Classify landscapes with landscape
  metrics](https://ecomods.github.io/patternscaper/articles/classify-metrics.md)
- [Classify landscapes with
  pixels](https://ecomods.github.io/patternscaper/articles/classify-pixels.md)
