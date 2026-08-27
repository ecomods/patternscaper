# Set a Landscape Name

Replaces the name stored in a landscape object.

## Usage

``` r
set_landscape_name(x, name)
```

## Arguments

- x:

  A landscape object.

- name:

  Character. New landscape name to store.

## Value

The landscape object with its updated name.

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md),
[`plot.landscape()`](https://ecomods.github.io/patternscaper/reference/plot.landscape.md),
[`print.landscape()`](https://ecomods.github.io/patternscaper/reference/print.landscape.md),
[`set_landscape_pattern()`](https://ecomods.github.io/patternscaper/reference/set_landscape_pattern.md)

## Examples

``` r
# Single landscape
landscape <- create_landscape("sharp", width = 10, height = 10)
landscape <- set_landscape_name(landscape, "alpine_treeline")

# Multiple landscapes with purrr
landscapes <- list(
  create_landscape("sharp", width = 10, height = 10),
  create_landscape("random", width = 10, height = 10)
)
names_vec <- c("alpine", "subalpine")
landscapes <- purrr::map2(landscapes, names_vec, set_landscape_name)

# Multiple landscapes with base R
landscapes <- mapply(
  set_landscape_name, landscapes, names_vec,
  SIMPLIFY = FALSE
)
```
