# Plot Neural Network Classification Landscapes

Plots landscapes with neural network classification results,
highlighting correct and misclassified cases. Optionally, only
misclassified landscapes can be shown.

## Usage

``` r
plot_classified_landscapes(
  classification,
  landscapes,
  only_misclassified = FALSE,
  ...
)
```

## Arguments

- classification:

  A data frame with columns: `landscape_id`, `actual_class`,
  `predicted_class`, and `confidence`.

- landscapes:

  A list of landscape objects corresponding to the classification
  results.

- only_misclassified:

  Logical; if `TRUE`, only misclassified landscapes are plotted. Default
  is `FALSE`.

- ...:

  Additional arguments passed to
  [`plot_landscape_list`](https://ecomods.github.io/spatPatClassifyR/reference/plot_landscape_list.md),
  such as `show_legend`, `legend_title`, `ncol`, `max_landscapes`,
  `force`, or `subset_index`.

## Value

A patchwork object combining landscape plots with classification
annotations.

## Details

The function checks input validity, filters misclassified landscapes if
requested, and generates annotated plots for each landscape.

The `titles` parameter is automatically generated from classification
results and cannot be overridden via `...`.

## Examples

``` r
# Example usage:
# plots <- plot_classified_landscapes(classification, landscape_list)

# With custom legend and grid layout
# plots <- plot_classified_landscapes(
#   classification,
#   landscape_list,
#   show_legend = FALSE,
#   ncol = 4
# )
if (FALSE) { # \dontrun{
# Train model and get validation results
model <- train_nn_metrics(landscapes, metrics)

# Plot all classification results
plot_classified_landscapes(
  model$performance$validation_results,
  landscapes
)

# Show only misclassifications without legend
plot_classified_landscapes(
  model$performance$validation_results,
  landscapes,
  only_misclassified = TRUE,
  show_legend = FALSE,
  ncol = 4
)
} # }
```
