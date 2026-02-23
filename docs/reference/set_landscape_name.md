# Set Landscape Name

Sets the name attribute of a landscape object.

## Usage

``` r
set_landscape_name(x, name)
```

## Arguments

- x:

  A landscape object

- name:

  Character string specifying the new name

## Value

The landscape object with updated name

## See also

Other landscape objects:
[`landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/landscape.md),
[`set_landscape_pattern()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_pattern.md)

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
landscapes <- mapply(set_landscape_name, landscapes, names_vec, SIMPLIFY = FALSE)
```
