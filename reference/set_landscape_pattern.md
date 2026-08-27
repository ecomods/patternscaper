# Set a Landscape Pattern

Replaces the pattern label stored in a landscape object.

## Usage

``` r
set_landscape_pattern(x, pattern)
```

## Arguments

- x:

  A landscape object.

- pattern:

  Character. New pattern label to store.

## Value

The landscape object with its updated pattern label.

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md),
[`plot.landscape()`](https://ecomods.github.io/patternscaper/reference/plot.landscape.md),
[`print.landscape()`](https://ecomods.github.io/patternscaper/reference/print.landscape.md),
[`set_landscape_name()`](https://ecomods.github.io/patternscaper/reference/set_landscape_name.md)

## Examples

``` r
# Single landscape
landscape <- create_landscape("sharp", width = 10, height = 10)
landscape <- set_landscape_pattern(landscape, "sharp_treeline")

# Multiple landscapes with purrr
landscapes <- list(
  create_landscape("sharp", width = 10, height = 10),
  create_landscape("random", width = 10, height = 10)
)
patterns_vec <- c("sharp_treeline", "random_pattern")
landscapes <- purrr::map2(landscapes, patterns_vec, set_landscape_pattern)

# Multiple landscapes with base R
landscapes <- mapply(
  set_landscape_pattern, landscapes, patterns_vec,
  SIMPLIFY = FALSE
)
```
