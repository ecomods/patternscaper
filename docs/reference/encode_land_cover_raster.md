# One-Hot Encode a Land-Cover Raster

Converts one numeric categorical raster layer into one binary array
channel per fitted land-cover code.

## Usage

``` r
encode_land_cover_raster(landscape_data, land_cover_values)
```

## Arguments

- landscape_data:

  Single-layer SpatRaster.

- land_cover_values:

  Numeric vector fixing the channel order.

## Value

Numeric array with dimensions rows by columns by land-cover channels.
