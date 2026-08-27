# Fill Missing Matrix Values by Linear Interpolation

Applies [`zoo::na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html)
across rows and then columns. The result can optionally be binarized at
a threshold of 0.5.

## Usage

``` r
fill_and_binarize_matrix(mat, binarize = TRUE)
```

## Arguments

- mat:

  Numeric matrix containing missing values.

- binarize:

  Logical. Whether to set values below 0.5 to 0 and values at least 0.5
  to 1 (default: TRUE).

## Value

A numeric matrix with missing values filled. If `binarize = TRUE`, it
contains only 0 and 1.

## Details

The function applies
[`zoo::na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html) with
`rule = 2` to extend edge values. Missing values remaining after both
passes are set to 0.
