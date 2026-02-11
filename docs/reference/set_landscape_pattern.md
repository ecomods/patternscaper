# Set Landscape pattern

Sets the pattern attribute of a landscape object.

## Usage

``` r
set_landscape_pattern(x, pattern)
```

## Arguments

- x:

  A landscape object

- pattern:

  Character string specifying the new pattern

## Value

The landscape object with updated pattern

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
landscapes <- mapply(set_landscape_pattern, landscapes, patterns_vec, SIMPLIFY = FALSE)
```
