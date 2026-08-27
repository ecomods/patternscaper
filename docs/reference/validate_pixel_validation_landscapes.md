# Validate Landscapes Used for Pixel-Model Validation

Checks that validation landscapes can be encoded with a fitted pixel
model and that every trained pattern class is represented.

## Usage

``` r
validate_pixel_validation_landscapes(
  validation_landscapes,
  expected_dimensions,
  class_names,
  land_cover_values
)
```

## Arguments

- validation_landscapes:

  List of landscape objects.

- expected_dimensions:

  Integer vector with rows and columns.

- class_names:

  Character vector of trained pattern classes.

- land_cover_values:

  Numeric vector of land-cover codes fitted on the training landscapes.

## Value

Character vector of validation pattern labels.
