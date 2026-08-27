# spatPatClassifyR: Classify Spatial Landscape Patterns Using Neural Networks

Classification of spatial landscape patterns using neural networks. The
package provides tools for generating artificial landscapes with
different spatial patterns, calculating landscape metrics, and training
neural network classifiers.

Two classification approaches are supported:

- \*\*Pixel-based classification\*\* using convolutional neural networks
  via keras3 (see
  [`train_nn_pixels`](https://ecomods.github.io/patternscaper/reference/train_nn_pixels.md))

- \*\*Metrics-based classification\*\* using landscape metrics computed
  with landscapemetrics as input features for a neural network (see
  [`train_nn_metrics`](https://ecomods.github.io/patternscaper/reference/train_nn_metrics.md))

## Typical workflow

1.  Generate training landscapes with
    [`create_landscapes`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)

2.  Optionally calculate and evaluate landscape metrics with
    [`calculate_landscape_metrics`](https://ecomods.github.io/patternscaper/reference/calculate_landscape_metrics.md)
    and
    [`evaluate_landscape_metrics`](https://ecomods.github.io/patternscaper/reference/evaluate_landscape_metrics.md)

3.  Train a classifier with
    [`train_nn_pixels`](https://ecomods.github.io/patternscaper/reference/train_nn_pixels.md)
    or
    [`train_nn_metrics`](https://ecomods.github.io/patternscaper/reference/train_nn_metrics.md)

4.  Apply the trained model to new landscapes with
    [`apply_nn_pixels`](https://ecomods.github.io/patternscaper/reference/apply_nn_pixels.md)
    or
    [`apply_nn_metrics`](https://ecomods.github.io/patternscaper/reference/apply_nn_metrics.md)

5.  Visualize results with
    [`plot_classified_landscapes`](https://ecomods.github.io/patternscaper/reference/plot_classified_landscapes.md)

## References

Baldauf, S., Tietjen, B., & Berger, U. (2025). spatPatClassifyR: An R
package for classifying spatial landscape patterns using neural
networks. \*Methods in Ecology and Evolution\*. In review.

## See also

Useful links:

- <https://ecomods.github.io/spatPatClassifyR/>

- <https://github.com/ecomods/spatPatClassifyR/>

- Report bugs at <https://github.com/ecomods/spatPatClassifyR/issues>

## Author

**Maintainer**: Selina Baldauf <selina.baldauf@fu-berlin.de>
([ORCID](https://orcid.org/0000-0002-3393-725X))

Authors:

- Britta Tietjen <britta.tietjen@fu-berlin.de>
  ([ORCID](https://orcid.org/0000-0003-4767-6406))

- Uta Berger <uta.berger@tu-dresden.de>
  ([ORCID](https://orcid.org/0000-0001-6920-136X))
