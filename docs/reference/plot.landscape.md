# Plot method for landscape objects

Creates a basic ggplot2 visualization of a landscape object.

## Usage

``` r
# S3 method for class 'landscape'
plot(x, ...)
```

## Arguments

- x:

  A landscape object created by
  [`landscape`](https://ecomods.github.io/spatPatClassifyR/reference/landscape.md).

- ...:

  Additional arguments passed to ggplot2 functions.

## Value

A ggplot2 object representing the landscape data.

## Details

This function creates a minimal ggplot2 visualization of the landscape
raster data. The returned plot can be further customized by adding
ggplot2 elements or by using the
[`plot_landscape`](https://ecomods.github.io/spatPatClassifyR/reference/plot_landscape.md)
function for higher-level customization.

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/landscape.md),
[`print.landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/print.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_name.md),
[`set_landscape_pattern()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_pattern.md)

## Examples

``` r
# Create a landscape
mat <- matrix(1:100, 10, 10)
l <- landscape(mat, pattern = "test", name = "example")

# Get basic plot
p <- plot(l)

# Add your own customization
p + ggplot2::ggtitle("My custom title") +
    ggplot2::theme_dark()

```
