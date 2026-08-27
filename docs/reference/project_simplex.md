# Project a vector onto the probability simplex

Returns the closest vector to \`v\`, in squared Euclidean distance,
whose elements are non-negative and sum to 1. It subtracts one shared
offset from every element and clips whatever is left below zero.

## Usage

``` r
project_simplex(v)
```

## Arguments

- v:

  Numeric vector of raw scores.

## Value

A numeric vector as long as \`v\`. For non-empty, finite input it is
non-negative and sums to 1 up to floating-point error. If any element of
\`v\` is \`NA\`, \`NaN\` or infinite, every element of the result is
\`NA_real\_\`; empty input returns \`numeric(0)\`.

## Details

Because the offset is the same for every element, the projection keeps
the input order: whichever class scored highest in \`v\` still scores
highest afterwards. The offset also lifts an all-negative vector onto
the simplex, which "clip at zero, then divide by the sum" cannot do.

The result is a valid probability vector, but that is not evidence that
the numbers are calibrated probabilities.

## References

Wang, W., & Carreira-Perpinan, M. A. (2013). Projection onto the
probability simplex: an efficient algorithm with a simple proof, and an
application. arXiv:1309.1541.
