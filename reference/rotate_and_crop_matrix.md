# Rotate and Crop a Landscape Matrix

Rotates a landscape matrix, takes a centered crop of the requested size,
fills missing values by linear interpolation, and restores binary
values.

## Usage

``` r
rotate_and_crop_matrix(mat, rotation, target_width, target_height)
```

## Arguments

- mat:

  Landscape matrix to rotate and crop.

- rotation:

  Numeric rotation angle in degrees.

- target_width:

  Integer. Number of columns in the output.

- target_height:

  Integer. Number of rows in the output.

## Value

A matrix with `target_height` rows and `target_width` columns, rotated
and cropped from the input landscape.

## Details

The function uses
[`omnibus::rotateMatrix`](https://adamlilith.github.io/omnibus/reference/rotateMatrix.html)
for rotation and `fill_and_binarize_matrix` to fill missing values and
binarize the result.

## See also

[`rotateMatrix`](https://adamlilith.github.io/omnibus/reference/rotateMatrix.html),
`fill_and_binarize_matrix`
