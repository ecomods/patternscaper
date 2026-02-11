# Rotate and Crop a Landscape Matrix

Rotates a given landscape matrix by a specified angle and crops the
rotated matrix to the target dimensions, centering the crop. Any missing
values after cropping are filled using nearest neighbor interpolation
and binarized.

## Usage

``` r
rotate_and_crop_matrix(mat, rotation, target_width, target_height)
```

## Arguments

- mat:

  A matrix representing the landscape to be rotated and cropped.

- rotation:

  Numeric value specifying the rotation angle (in degrees).

- target_width:

  Integer specifying the desired number of columns in the output.

- target_height:

  Integer specifying the desired number of rows in the output.

## Value

A matrix with `target_height` rows and `target_width` columns, rotated
and cropped from the input landscape, with missing values filled.

## Details

The function uses
[`omnibus::rotateMatrix`](https://adamlilith.github.io/omnibus/reference/rotateMatrix.html)
for rotation and centers the crop on the rotated matrix. Missing values
after cropping are filled using the `fill_and_binarize_matrix` function.

## See also

[`rotateMatrix`](https://adamlilith.github.io/omnibus/reference/rotateMatrix.html),
`fill_and_binarize_matrix`
