# Plot a Landscape

A wrapper function for the S3 method `plot.landscape` with additional
customization options.

## Usage

``` r
plot_landscape(
  landscape,
  title = "pattern",
  show_legend = TRUE,
  legend_title = "Value"
)
```

## Arguments

- landscape:

  A landscape object to plot.

- title:

  Character. Controls the plot title: - "name": uses only the landscape
  name - "pattern": uses only the landscape pattern - "both": uses "name
  (pattern)" format - "none": no title - Any other string: used as a
  custom title Default: "pattern"

- show_legend:

  Logical. Whether to show legend (default: TRUE).

- legend_title:

  Character. Title for the legend (default: "Value").

## Value

ggplot object. Plot of the landscape.

## Examples

``` r
# Create a basic landscape
l <- create_landscape("sharp", width = 50, height = 50)

# Default plot (shows both name and pattern)
plot_landscape(l)


# Show only pattern name
plot_landscape(l, title = "pattern")


# Custom title and legend
plot_landscape(l,
              title = "My Sharp Treeline",
              legend_title = "Vegetation",
              show_legend = TRUE)
```
