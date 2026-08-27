# Warn when application landscapes differ in geometry from training

Internal helper comparing the geometry of the landscapes a model is
being applied to against the geometry summary stored at training time,
and issuing a warning for each substantial difference. It compares
\*\*physical extent\*\* (cells times resolution, so a change in either
cell count or cell size is caught), cell resolution, and aspect ratio.
When the training resolution is 1 (dimensionless, as for landscapes
built from matrices) a resolution difference is reported as not
assessable rather than as a calibrated ratio. When \`training\` is
\`NULL\` (a model trained before geometry was recorded, or from a
metrics table without geometry columns) it notes – when \`verbose\` –
that the checks are skipped, and does nothing else. Used by
[`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md).

## Usage

``` r
check_geometry(application, training, tolerance = 0.25, verbose = TRUE)
```

## Arguments

- application:

  A per-landscape geometry tibble for the application landscapes
  (columns \`n_row\`, \`n_col\`, \`cell_size_x\`, \`cell_size_y\`; see
  [`landscapes_geometry`](https://ecomods.github.io/patternscaper/reference/landscapes_geometry.md)).

- training:

  A one-row training-geometry summary (see
  [`summarise_geometry`](https://ecomods.github.io/patternscaper/reference/summarise_geometry.md)),
  or \`NULL\`.

- tolerance:

  Numeric. Relative difference in extent or aspect ratio beyond which a
  landscape is flagged (default 0.25, i.e. 25%).

- verbose:

  Logical. Whether to emit an informative note when the checks are
  skipped because the model has no stored training geometry (default
  TRUE).

## Value

Invisibly \`NULL\`; called for the warnings it emits.
