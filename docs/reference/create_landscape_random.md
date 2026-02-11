# Create a Landscape with Randomly Distributed Trees

Generates a binary landscape with randomly distributed trees.

## Usage

``` r
create_landscape_random(width = 100, height = 100, tree_prop = 0.5)
```

## Arguments

- width:

  Integer. Width of the landscape in pixels (default: 100).

- height:

  Integer. Height of the landscape in pixels (default: 100).

- tree_prop:

  Numeric. Probability of tree presence (0-1) (default: 0.5). Higher
  values result in a denser tree cover.

## Value

@return A landscape object containing the generated landscape data and
parameters.

## Examples

``` r
# Default randomly distributed trees
random_default <- create_landscape_random()
#> Error in create_landscape_random(): could not find function "create_landscape_random"

# Higher tree density
random_dense <- create_landscape_random(tree_prop = 0.7)
#> Error in create_landscape_random(tree_prop = 0.7): could not find function "create_landscape_random"

# Custom dimensions
random_large <- create_landscape_random(width = 200, height = 150)
#> Error in create_landscape_random(width = 200, height = 150): could not find function "create_landscape_random"
```
