# Evaluate predictions against their true classes

Used in both
[`apply_metric_model()`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md)
and
[`apply_pixel_model()`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
to evaluate model performance. Decides whether performance can and
should be evaluated, then evaluates it on the landscapes by comparing
the predicted with the actual class.

## Usage

``` r
evaluate_predictions(
  predictions,
  class_names,
  evaluate = "auto",
  verbose = TRUE
)
```

## Arguments

- predictions:

  Tibble of predictions from the calling `apply_*` function. Must carry
  `predicted_class` and, to be scorable at all, an `actual_class`
  column.

- class_names:

  Character vector of the classes the model was trained on.

- evaluate:

  Character. One of "auto", "required" or "none". See
  [`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md).

- verbose:

  Logical. Show the performance summary and the note about landscapes
  skipped for having no true class.

## Value

List of performance metrics from
[`evaluate_cv_performance()`](https://ecomods.github.io/patternscaper/reference/evaluate_cv_performance.md),
or NULL when nothing was scored.

## Details

Landscapes with no actual class are excluded. Landscapes whose actual
class the model was never trained on are different: the model cannot
produce that label, so they are guaranteed wrong, and scoring only the
rest would report a higher accuracy than the batch achieved. Nothing is
evaluated in that case, the result is NULL, and the user is warned.
