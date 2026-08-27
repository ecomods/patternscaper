# Check Land-Cover Codes Against a Fitted Pixel Model

Check Land-Cover Codes Against a Fitted Pixel Model

## Usage

``` r
abort_on_unseen_land_cover_values(
  landscapes,
  land_cover_values,
  action = "classify"
)
```

## Arguments

- landscapes:

  List of landscape objects to classify.

- land_cover_values:

  Numeric land-cover codes fitted during training.

- action:

  User-facing verb describing the attempted operation.

## Value

Invisibly \`NULL\`.
