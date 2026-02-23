# Basic Workflow with spatPatClassifyR

``` r

library(spatPatClassifyR)
library(tidyverse)
#> ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
#> ✔ dplyr     1.1.4     ✔ readr     2.1.5
#> ✔ forcats   1.0.0     ✔ stringr   1.5.2
#> ✔ ggplot2   4.0.0     ✔ tibble    3.3.0
#> ✔ lubridate 1.9.4     ✔ tidyr     1.3.1
#> ✔ purrr     1.1.0     
#> ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
#> ✖ dplyr::filter() masks stats::filter()
#> ✖ dplyr::lag()    masks stats::lag()
#> ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
```

## Introduction

This vignette demonstrates the basic workflow for using the
`spatPatClassifyR` package to classify landscapes patterns.

### Basic Workflow Overview

1.  Generate synthetic landscapes for training
2.  Calculate landscape metrics for these landscapes
3.  Evaluate and select the most informative metrics
4.  Train a neural network classification model
5.  Visualize model performance
6.  Apply the model to classify new landscapes

Let’s walk through each step.

### 1. Generating Training Landscapes

First, we’ll generate a set of synthetic landscapes that represent
different ecotone patterns. These will serve as our training data.

The `generate_training_landscapes()` function creates synthetic
landscapes with different ecotone patterns. The following patterns are
generated:

- sharp, diffuse or curvy boundaries
- fingers
- clustered
- parallel sine bands

You can also control different aspects about the landscapes, such as
width and height, or which of the supported types should be included in
the training landscapes.

If you want to know more about the generation of specific landscapes,
check out the [Landscape
Generation](https://ecomods.github.io/spatPatClassifyR/articles/landscape-generation.md)
vignette.

By default, the `generate_training_landscapes()` function generates
landscapes of size 100x100 pixles, including all supported landscape
patterns at an equal probability.

``` r

# Generate training landscapes with different ecotone patterns
```

You can visualize a few or all of the generated landscapes to see the
different patterns:

``` r

# Visualize a few of the generated landscapes
```

### 2. Calculating Landscape Metrics

Next, we’ll calculate landscape metrics for each of our training
landscapes. These metrics will be used as features for the
classification model.

You have the option to list all available metrics using the `list_lsm()`
function from the `landscapemetrics` package:

Landscape metrics can be calculated at different levels: “landscape”,
“patch”, or “class”. Here, we calculate all metrics on the landscape
level. This calculation takes some time and the runtime increases with
the number of landscapes and the number of metrics.

### 3. Evaluating Landscape Metrics

We can now choose those metrics that are most informative for our
classification task. For this, we can use the `evaluate_metrics()`
function, which provides different methods to evaluate and select
metrics based. Here, we use the default method, which selects the
metrics with the highest variance across all landscapes. If you want to
learn more details about the different methods, check out the [landscape
metrics
vignette](https://ecomods.github.io/spatPatClassifyR/articles/landscape-metrics.md).

``` r

# Find the 10 best metrics
```

#### Caveat

Right now, this function is not perfect. We aim for metrics that are
informative, but that also do not contain missing values. If we have a
missing value in just one metric, the landscape will be excluded from
model training. Until this is fixed, I recommend using all metrics but
removing the ones that either contain NAs or are constant across all
landscapes.

``` r

# Find metrics with NA value
```

### 4. Training the Neural Network Model

Now we’ll train a neural network model using our filtered metrics.

The
[`train_nn_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_metrics.md)
function trains a neural network model with cross-validation. We can
optionally specify the metrics to use with the `metrics_selected`
argument. Also, we can specify the cross validation method (kfold or
leave-one-out) and the number of folds. For a low number of data points,
the function will automatically use leave-one-out cross-validation.

The trained model comes as an object including cross-validation results
and performance checks. Just have a look at the model object:

### 5. Visualizing Model Performance

We can visualize the performance of our model using several different
plots:

``` r


# Or plot individual plots
# Plot confusion matrix
# plot_classification_results(model, plot_type = "confusion")

# Plot class probabilities
# plot_classification_results(model, plot_type = "probabilities")

# Plot classification confidence
# plot_classification_results(model, plot_type = "confidence")

# Plot misclassifications
# plot_classification_results(model, plot_type = "misclassifications")
```

### 6. Applying the Model to New Landscapes

Finally, we can apply our trained model to classify new landscapes. For
this, we first need to generate new landscapes and calculate their
metrics.

We can also apply our model to a list of landscapes:
