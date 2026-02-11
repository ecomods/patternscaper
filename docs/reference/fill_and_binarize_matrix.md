# Fill NA Values in a Matrix Using Linear Interpolation

This function fills NA values in a matrix by applying linear
interpolation row-wise and then column-wise using
[`zoo::na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html).
Optionally, the function can binarize the resulting matrix based on a
threshold of 0.5.

## Usage

``` r
fill_and_binarize_matrix(mat, binarize = TRUE)
```

## Arguments

- mat:

  A numeric matrix containing NA values to be filled.

- binarize:

  Logical. If TRUE (default), the output matrix will be binarized, with
  values \< 0.5 set to 0 and values \>= 0.5 set to 1. If FALSE, the
  interpolated values are returned as is.

## Value

A numeric matrix with NA values filled using linear interpolation. If
`binarize = TRUE`, the matrix will contain only 0s and 1s.

## Details

The function applies
[`zoo::na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html) with
`rule = 2` to ensure that NA values at the edges are filled with the
nearest non-NA value. Interpolation is performed first row-wise, then
column-wise to fill all remaining NAs. If any NAs remain after both
passes, they are filled with 0.
