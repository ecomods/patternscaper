# Create a Stratified Training and Validation Split

Selects validation landscapes separately within each pattern class.
Every class retains at least one training landscape and contributes at
least one validation landscape.

## Usage

``` r
find_stratified_validation_split(patterns, validation_split)
```

## Arguments

- patterns:

  Character or factor vector of pattern labels.

- validation_split:

  Requested fraction assigned to validation.

## Value

List with integer vectors `training` and `validation`.
