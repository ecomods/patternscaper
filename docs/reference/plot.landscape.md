# Plot a Landscape Object

Plots a landscape object as a ggplot2.

## Usage

``` r
# S3 method for class 'landscape'
plot(x, ...)
```

## Arguments

- x:

  A landscape object created by
  [`landscape`](https://ecomods.github.io/patternscaper/reference/landscape.md).

- ...:

  Must be empty.

## Value

A ggplot2 object.

## Details

Add ggplot2 layers directly to the result, or use
[`plot_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md)
for titles, legends, and multi-panel layouts.

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md),
[`print.landscape()`](https://ecomods.github.io/patternscaper/reference/print.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/patternscaper/reference/set_landscape_name.md),
[`set_landscape_pattern()`](https://ecomods.github.io/patternscaper/reference/set_landscape_pattern.md)

## Examples

``` r
# Create a landscape (0 = bare ground, 1 = vegetation)
mat <- matrix(rbinom(100, 1, 0.5), 10, 10)
l <- landscape(mat, pattern = "random", name = "example")

# Get basic plot
p <- plot(l)

# Add your own customization
p + ggplot2::ggtitle("My custom title") +
    ggplot2::theme_dark()

```
