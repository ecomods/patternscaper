# Package index

## Package overview

- [`spatPatClassifyR-package`](https://ecomods.github.io/spatPatClassifyR/reference/spatPatClassifyR.md)
  [`spatPatClassifyR`](https://ecomods.github.io/spatPatClassifyR/reference/spatPatClassifyR.md)
  : spatPatClassifyR: Classify Spatial Landscape Patterns Using Neural
  Networks

## Landscape creation

Functions for generating artificial landscapes with different spatial
patterns

- [`create_landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape.md)
  : Create a Landscape with Specified Pattern
- [`create_landscapes()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscapes.md)
  : Create Multiple Landscapes
- [`create_landscape_bands()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bands.md)
  : Create a Landscape with Sine Wave Bands
- [`create_landscape_bare()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_bare.md)
  : Create a bare landscape with very sparse vegetation
- [`create_landscape_clustered()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_clustered.md)
  : Create a Landscape with Clustered Features
- [`create_landscape_dense()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_dense.md)
  : Create a landscape with very dense vegetation
- [`create_landscape_diffuse()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_diffuse.md)
  : Create a Landscape with Diffuse Vegetation Boundary
- [`create_landscape_fingers()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_fingers.md)
  : Create a Landscape with Finger-like Treeline
- [`create_landscape_gaps()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_gaps.md)
  : Create a Landscape with Gaps Pattern
- [`create_landscape_labyrinth()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_labyrinth.md)
  : Create a Landscape with Labyrinths as in Turing patterns
- [`create_landscape_random()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_random.md)
  : Create a Binary Landscape with Randomly Distributed Vegetation
- [`create_landscape_sharp()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_sharp.md)
  : Create a Landscape with a Sharp Vegetation Boundary
- [`create_landscape_spots()`](https://ecomods.github.io/spatPatClassifyR/reference/create_landscape_spots.md)
  : Create a Landscape with Spots Pattern

## Landscape objects

Functions for creating and manipulating landscape objects

- [`landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/landscape.md)
  : Create a landscape object
- [`plot(`*`<landscape>`*`)`](https://ecomods.github.io/spatPatClassifyR/reference/plot.landscape.md)
  : Plot method for landscape objects
- [`print(`*`<landscape>`*`)`](https://ecomods.github.io/spatPatClassifyR/reference/print.landscape.md)
  : Print a landscape object
- [`set_landscape_name()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_name.md)
  : Set Landscape Name
- [`set_landscape_pattern()`](https://ecomods.github.io/spatPatClassifyR/reference/set_landscape_pattern.md)
  : Set Landscape pattern

## Landscape metrics

Calculate and evaluate landscape metrics

- [`calculate_landscape_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/calculate_landscape_metrics.md)
  : Calculate Landscape Metrics
- [`evaluate_landscape_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/evaluate_landscape_metrics.md)
  : Evaluate Landscape Metrics

## Neural network training

Train neural network classifiers

- [`train_nn_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_metrics.md)
  : Train a Multi-Layer Neural Network for Landscape Pattern
  Classification
- [`train_nn_pixels()`](https://ecomods.github.io/spatPatClassifyR/reference/train_nn_pixels.md)
  : Train a Convolutional Neural Network for Landscape Pattern
  Classification
- [`set_random_seed()`](https://ecomods.github.io/spatPatClassifyR/reference/set_random_seed.md)
  : Set Random Seeds for Reproducible Neural Network Training

## Neural network application

Apply trained classifiers to new landscapes

- [`apply_nn_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/apply_nn_metrics.md)
  : Apply Neural Network for Landscape Pattern Classification Based on
  their Landscape Metrics
- [`apply_nn_pixels()`](https://ecomods.github.io/spatPatClassifyR/reference/apply_nn_pixels.md)
  : Apply a Keras CNN Model for Landscape Pattern Classification

## Visualization

Plot landscapes, metrics, and classification results

- [`plot_landscape()`](https://ecomods.github.io/spatPatClassifyR/reference/plot_landscape.md)
  : Plot a Landscape
- [`plot_landscape_list()`](https://ecomods.github.io/spatPatClassifyR/reference/plot_landscape_list.md)
  : Plot Multiple Landscapes
- [`plot_classified_landscapes()`](https://ecomods.github.io/spatPatClassifyR/reference/plot_classified_landscapes.md)
  : Plot Neural Network Classification Landscapes
- [`plot_metrics()`](https://ecomods.github.io/spatPatClassifyR/reference/plot_metrics.md)
  : Plot Landscape Metrics
