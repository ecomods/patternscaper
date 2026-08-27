# Fit the Land-Cover Encoding for a Pixel Model

Finds the numeric land-cover codes present across the training
landscapes and fixes their order for one-hot encoding.

## Usage

``` r
fit_land_cover_values(landscapes)
```

## Arguments

- landscapes:

  List of landscape objects.

## Value

Sorted numeric vector of land-cover codes.
