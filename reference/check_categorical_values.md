# Check that cell values are categorical

The pixel workflow reads raw cell values and we need to ensure that they
are categorical in nature. We accept whole numbers but warn if there are
too many as many distinct whole values are legal but usually mean
integer-coded continuous data (e.g. elevation in whole metres). Used by
both
[`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)
and
[`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
so the two refuse the same input.

## Usage

``` r
check_categorical_values(landscapes, action, max_distinct = 20)
```

## Arguments

- landscapes:

  List of landscape objects.

- action:

  Character. Verb naming what the caller was about to do, used in the
  message ("train on", "classify").

- max_distinct:

  Integer. Distinct-value count above which the input is reported as
  probably continuous (default: 20). Chosen to sit above any land-cover
  classification scheme in practical use and far below the hundreds or
  thousands of levels continuous data carries.

## Value

Invisibly \`NULL\`. Called for the error and the warning.
