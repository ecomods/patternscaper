# patternscaper: Classify Spatial Landscape Patterns Using Neural Networks

Generates artificial landscapes with defined spatial patterns,
calculates landscape metrics, and trains neural networks to classify
landscape patterns.

The package supports two classification workflows:

- Pixel-based classification with convolutional neural networks using
  keras3 (see
  [`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md))

- Metrics-based classification with landscape metrics from
  landscapemetrics as neural-network inputs (see
  [`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md))

## Typical workflow

1.  Generate training landscapes with
    [`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

2.  Optionally calculate and evaluate landscape metrics with
    [`calculate_metrics`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md)
    and
    [`evaluate_metrics`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md)

3.  Train a classifier with
    [`train_pixel_model`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)
    or
    [`train_metric_model`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)

4.  Apply the trained model to new landscapes with
    [`apply_pixel_model`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
    or
    [`apply_metric_model`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md)

5.  Visualize results with
    [`plot_classified_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_classified_landscapes.md)

## References

Baldauf, S., Tietjen, B., & Berger, U. (2025). patternscaper: An R
package for classifying spatial landscape patterns using neural
networks. \*Methods in Ecology and Evolution\*. In review.

## See also

Useful links:

- <https://ecomods.github.io/patternscaper/>

- <https://github.com/ecomods/patternscaper/>

- Report bugs at <https://github.com/ecomods/patternscaper/issues>

## Author

**Maintainer**: Selina Baldauf <selina.baldauf@fu-berlin.de>
([ORCID](https://orcid.org/0000-0002-3393-725X))

Authors:

- Selina Baldauf <selina.baldauf@fu-berlin.de>
  ([ORCID](https://orcid.org/0000-0002-3393-725X))

- Britta Tietjen <britta.tietjen@fu-berlin.de>
  ([ORCID](https://orcid.org/0000-0003-4767-6406))

- Uta Berger <uta.berger@tu-dresden.de>
  ([ORCID](https://orcid.org/0000-0001-6920-136X))
