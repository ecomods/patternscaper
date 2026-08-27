# Package index

## Package overview

- [`patternscaper-package`](https://ecomods.github.io/patternscaper/reference/patternscaper.md)
  [`patternscaper`](https://ecomods.github.io/patternscaper/reference/patternscaper.md)
  : patternscaper: Classify Spatial Landscape Patterns Using Neural
  Networks

## Landscape creation

Functions for generating artificial landscapes with different spatial
patterns

- [`create_landscape()`](https://ecomods.github.io/patternscaper/reference/create_landscape.md)
  : Create a Single Landscape
- [`create_landscapes()`](https://ecomods.github.io/patternscaper/reference/create_landscapes.md)
  : Create Multiple Landscapes

## Pattern parameters

One constructor per pattern, holding that pattern’s parameters. Pass the
result to create_landscape(params = …) or create_landscapes(params_list
= …).

- [`pattern_random()`](https://ecomods.github.io/patternscaper/reference/pattern_random.md)
  : Parameters for the Random Pattern
- [`pattern_bare()`](https://ecomods.github.io/patternscaper/reference/pattern_bare.md)
  : Parameters for the Bare Pattern
- [`pattern_dense()`](https://ecomods.github.io/patternscaper/reference/pattern_dense.md)
  : Parameters for the Dense Pattern
- [`pattern_sharp()`](https://ecomods.github.io/patternscaper/reference/pattern_sharp.md)
  : Parameters for the Sharp Pattern
- [`pattern_diffuse()`](https://ecomods.github.io/patternscaper/reference/pattern_diffuse.md)
  : Parameters for the Diffuse Pattern
- [`pattern_fingers()`](https://ecomods.github.io/patternscaper/reference/pattern_fingers.md)
  : Parameters for the Fingers Pattern
- [`pattern_clustered()`](https://ecomods.github.io/patternscaper/reference/pattern_clustered.md)
  : Parameters for the Clustered Pattern
- [`pattern_bands()`](https://ecomods.github.io/patternscaper/reference/pattern_bands.md)
  : Parameters for the Bands Pattern
- [`pattern_spots()`](https://ecomods.github.io/patternscaper/reference/pattern_spots.md)
  : Parameters for the Spots Pattern
- [`pattern_gaps()`](https://ecomods.github.io/patternscaper/reference/pattern_gaps.md)
  : Parameters for the Gaps Pattern
- [`pattern_labyrinth()`](https://ecomods.github.io/patternscaper/reference/pattern_labyrinth.md)
  : Parameters for the Labyrinth Pattern

## Landscape objects

Functions for creating and manipulating landscape objects

- [`landscape()`](https://ecomods.github.io/patternscaper/reference/landscape.md)
  : Create a Landscape Object
- [`plot(`*`<landscape>`*`)`](https://ecomods.github.io/patternscaper/reference/plot.landscape.md)
  : Plot a Landscape Object
- [`print(`*`<landscape>`*`)`](https://ecomods.github.io/patternscaper/reference/print.landscape.md)
  : Print a Landscape Object
- [`set_landscape_name()`](https://ecomods.github.io/patternscaper/reference/set_landscape_name.md)
  : Set a Landscape Name
- [`set_landscape_pattern()`](https://ecomods.github.io/patternscaper/reference/set_landscape_pattern.md)
  : Set a Landscape Pattern

## Landscape metrics

Calculate and evaluate landscape metrics

- [`calculate_metrics()`](https://ecomods.github.io/patternscaper/reference/calculate_metrics.md)
  : Calculate Landscape Metrics
- [`evaluate_metrics()`](https://ecomods.github.io/patternscaper/reference/evaluate_metrics.md)
  : Evaluate Landscape Metrics
- [`print(`*`<metrics_evaluation>`*`)`](https://ecomods.github.io/patternscaper/reference/print.metrics_evaluation.md)
  : Print a metrics evaluation

## Neural network training

Train neural network classifiers

- [`train_metric_model()`](https://ecomods.github.io/patternscaper/reference/train_metric_model.md)
  : Train a Multi-Layer Neural Network for Landscape Pattern
  Classification
- [`train_pixel_model()`](https://ecomods.github.io/patternscaper/reference/train_pixel_model.md)
  : Train a Convolutional Neural Network for Landscape Pattern
  Classification
- [`set_random_seed()`](https://ecomods.github.io/patternscaper/reference/set_random_seed.md)
  : Set Random Seeds for Neural Network Training

## Neural network application

Apply trained classifiers to new landscapes

- [`apply_metric_model()`](https://ecomods.github.io/patternscaper/reference/apply_metric_model.md)
  : Apply Neural Network for Landscape Pattern Classification Based on
  their Landscape Metrics
- [`apply_pixel_model()`](https://ecomods.github.io/patternscaper/reference/apply_pixel_model.md)
  : Apply a Keras CNN Model for Landscape Pattern Classification

## Model persistence

Save and reload trained classifiers

- [`save_pixel_model()`](https://ecomods.github.io/patternscaper/reference/save_pixel_model.md)
  : Save a Trained Pixel Model
- [`load_pixel_model()`](https://ecomods.github.io/patternscaper/reference/load_pixel_model.md)
  : Load a Trained Pixel Model

## Visualization

Plot landscapes, metrics, and classification results

- [`plot_landscapes()`](https://ecomods.github.io/patternscaper/reference/plot_landscapes.md)
  : Plot One or More Landscapes
- [`plot_classified_landscapes()`](https://ecomods.github.io/patternscaper/reference/plot_classified_landscapes.md)
  : Plot Neural Network Classification Landscapes
- [`plot_metrics()`](https://ecomods.github.io/patternscaper/reference/plot_metrics.md)
  : Plot Landscape Metrics
