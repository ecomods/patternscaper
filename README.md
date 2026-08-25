
<!-- README.md is generated from README.Rmd. Please edit that file -->

# patternscaper <a href="https://ecomods.github.io/patternscaper/"><img src="man/figures/logo.png" align="right" height="138" alt="patternscaper website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/ecomods/patternscaper/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ecomods/patternscaper/actions/workflows/R-CMD-check.yaml)
[![GPL-3.0-or-later](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
<!-- badges: end -->

## Overview

`patternscaper` classifies spatial vegetation patterns into ecologically
meaningful, user-defined pattern types. It provides a reproducible
alternative to visual classification or the manual interpretation of
multiple landscape metrics. It can be used to compare landscape
structure across space or time, monitor ecosystem change, evaluate
spatial simulation outputs, and analyze classified remote-sensing data.

Users define the pattern classes according to their research question
and provide representative, labeled training landscapes. These
landscapes can be generated with `patternscaper` or imported from
ecological simulation outputs or other categorical raster data.
Artificial landscapes are particularly useful when labeled empirical
training data are scarce because their classes are known by construction
and their variation can be controlled.

The package provides two complementary approaches. The metric-based
approach calculates established landscape metrics using the
[`landscapemetrics` R
package](https://r-spatialecology.github.io/landscapemetrics/index.html),
selects informative metrics, and trains a neural network classifier on
them. The pixel-based approach trains a convolutional neural network
directly on categorical raster cells without prior feature selection.
Both approaches support landscape preparation, model training and
evaluation, classification of new landscapes, and visualization of the
results.

<div class="figure">

<img src="man/figures/workflow.png" alt="Diagram showing the patternscaper workflow in two phases: (1) Training phase where training landscapes are fed into a neural network using either landscape metrics or pixel information, and (2) Application phase where new artificial or real landscapes are classified by the trained neural network to predict the landscape pattern class." width="100%" />
<p class="caption">

Overview of the patternscaper workflow. Classifiers are trained using
either the metric-based or pixel-based approach and applied to new
artificial or empirical landscapes.
</p>

</div>

## Installation

Install the development version of patternscaper from
[GitHub](https://github.com/ecomods/patternscaper):

``` r
# install.packages("pak")
pak::pak("ecomods/patternscaper")
```

## Get started

Follow [Get
started](https://ecomods.github.io/patternscaper/articles/patternscaper.html)
for an overview of the complete classification workflow and a short
runnable example. Depending on your starting point, you can also check
out how to:

- [Generate artificial
  landscapes](https://ecomods.github.io/patternscaper/articles/landscape-generation.html)
  for labeled training or test data
- [Import your own
  landscapes](https://ecomods.github.io/patternscaper/articles/importing-landscapes.html)
  from categorical raster data or matrices

## Citation

To cite `patternscaper`, use:

Baldauf, S., Tietjen, B., & Berger, U. (2025). patternscaper: An R
package for classifying spatial landscape patterns using neural
networks. *Methods in Ecology and Evolution*. In review.

Run `citation("patternscaper")` for the BibTeX entry.

## Contributing

See the [contributing
guide](https://ecomods.github.io/patternscaper/CONTRIBUTING.html) to get
involved.

## Code of Conduct

Contributions are governed by the project [Code of
Conduct](https://ecomods.github.io/patternscaper/CODE_OF_CONDUCT.html).
