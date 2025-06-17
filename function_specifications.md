# EcotoneClassifyR Package Function Specifications

This document outlines all the functions required for the EcotoneClassifyR package. Each function specification includes the function name, input arguments with formats and default values, output format, and a step-by-step description of the function's operation.

## Table of Contents

1. [Utility Functions](#utility-functions)
2. [Landscape Generation Functions](#landscape-generation-functions)
3. [Visualization Functions](#visualization-functions)
4. [Metrics Calculation Functions](#metrics-calculation-functions)
5. [Neural Network Functions](#neural-network-functions)

## Utility Functions

### `validate_raster`

**Input:**
- `raster` (SpatRaster): The raster to validate
- `categorical` (logical): Whether to check if the raster has categorical values (default: FALSE)
- `max_size` (numeric): Maximum allowed raster size in pixels (default: 10000)
- `verbose` (logical): Whether to print additional information (default: FALSE)

**Output:**
- If verbose=FALSE: No return value, throws error if validation fails
- If verbose=TRUE: List with raster size and unique classes

**Description:**
1. Checks if input is a valid SpatRaster object
2. If categorical=TRUE, checks if values are categorical (discrete)
3. Checks if raster size exceeds max_size and issues a warning
4. Verifies that raster has valid dimensions
5. If verbose=TRUE, returns size and unique class information

### `rotate_and_crop_landscape`

**Input:**
- `landscape` (matrix or SpatRaster): Landscape to rotate
- `angle` (numeric): Rotation angle in degrees (default: 0)
- `fill_value` (numeric): Value to fill new cells created during rotation (default: NA)

**Output:**
- SpatRaster: Rotated landscape with NA cells cropped out

**Description:**
1. Converts input to SpatRaster if not already
2. Rotates the landscape by the specified angle
3. Crops the result to remove NA cells at the edges
4. Returns the rotated and cropped landscape

### `matrix_to_raster`

**Input:**
- `matrix` (matrix): Binary landscape matrix to convert
- `resolution` (numeric): Spatial resolution of output raster (default: 1)
- `crs` (character): Coordinate reference system (default: NULL)

**Output:**
- SpatRaster: Raster representation of input matrix

**Description:**
1. Converts binary matrix to SpatRaster object
2. Sets resolution if provided
3. Sets CRS if provided
4. Returns the resulting SpatRaster

### `fill_na_with_nearest`

**Input:**
- `landscape` (SpatRaster): Landscape with NA values to fill
- `max_distance` (numeric): Maximum distance to search for non-NA values (default: 5)

**Output:**
- SpatRaster: Landscape with NA values filled

**Description:**
1. Identifies NA cells in the input raster
2. For each NA cell, searches for nearest non-NA cells within max_distance
3. Replaces NA values with values from nearest non-NA cells
4. Returns filled landscape raster

## Landscape Generation Functions

### `create_landscape_sharp_treeline`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)

**Output:**
- SpatRaster: Binary landscape with sharp treeline (1 above treeline, 0 below)

**Description:**
1. Creates a matrix with values 1 above treeline_position*height and 0 below
2. Converts matrix to raster
3. If rotation != 0, rotates landscape using rotate_and_crop_landscape()
4. Returns the resulting landscape

### `create_landscape_diffuse_treeline`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `steepness` (numeric): Steepness of the transition (default: 2)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)
- `seed` (integer): Random seed for reproducibility (default: NULL)

**Output:**
- SpatRaster: Binary landscape with diffuse treeline (decreasing probability with row)

**Description:**
1. If seed is not NULL, sets random seed
2. Creates a matrix where probability of tree presence decreases with row index
3. For each cell, assigns 1 with probability = 1 - (normalized_row)^steepness
4. Converts matrix to raster
5. If rotation != 0, rotates landscape
6. Returns the resulting landscape

### `create_landscape_curvy_treeline`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `sine_length` (numeric): Wavelength of sinusoidal curve in pixels (default: 20)
- `sine_height` (numeric): Amplitude of sinusoidal curve in pixels (default: 5)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)

**Output:**
- SpatRaster: Binary landscape with curvy treeline

**Description:**
1. Calculates treeline row position
2. Creates matrix where cells above curvy treeline = 1, below = 0
3. Uses sine wave to create undulating boundary using formula i > (treeline_row + sin(2π*j/sine_length) * sine_height)
4. Converts to raster and rotates if needed
5. Returns the resulting landscape

### `create_landscape_fingers`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `num_fingers` (integer): Number of fingers (default: 5)
- `finger_width` (integer): Width of each finger in pixels (default: 3)
- `finger_length_prop` (numeric): Length of fingers as proportion of height (default: 0.3)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)

**Output:**
- SpatRaster: Binary landscape with finger-like extensions from treeline

**Description:**
1. Creates a sharp treeline base landscape
2. Adds rectangular extensions from treeline evenly distributed across width
3. Converts to raster and rotates if needed
4. Returns the resulting landscape

### `create_landscape_bent_fingers`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `num_fingers` (integer): Number of fingers (default: 5)
- `finger_width` (integer): Width of each finger in pixels (default: 3)
- `finger_length_prop` (numeric): Length of fingers as proportion of height (default: 0.3)
- `bend_factor` (numeric): Degree of finger bending (default: 3)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)

**Output:**
- SpatRaster: Binary landscape with bent finger-like extensions

**Description:**
1. Creates a sharp treeline base landscape
2. Adds bent extensions using sine function to create bending effect
3. Converts to raster and rotates if needed
4. Returns the resulting landscape

### `create_landscape_scattered_trees`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `scatter_density` (numeric): Probability of tree presence (0-1) (default: 0.1)
- `scatter_zone_prop` (numeric): Proportion of height for scatter zone (default: 0.5)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)
- `seed` (integer): Random seed for reproducibility (default: NULL)

**Output:**
- SpatRaster: Binary landscape with randomly scattered trees below treeline

**Description:**
1. If seed is not NULL, sets random seed
2. Creates sharp treeline base landscape
3. In scatter zone below treeline, randomly places trees based on scatter_density
4. Converts to raster and rotates if needed
5. Returns the resulting landscape

### `create_landscape_sine_bands`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `band_thickness` (integer): Thickness of each band in pixels (default: 3)
- `band_spacing` (integer): Spacing between bands in pixels (default: 10)
- `frequency` (numeric): Frequency of sine wave (default: 2*pi/100)
- `amplitude` (numeric): Amplitude of sine wave in pixels (default: 5)
- `noise` (logical): Whether to add random noise to bands (default: FALSE)
- `noise_sd` (numeric): Standard deviation for random noise (default: 1)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)
- `seed` (integer): Random seed for reproducibility (default: NULL)

**Output:**
- SpatRaster: Binary landscape with parallel sine-wave bands

**Description:**
1. If seed is not NULL, sets random seed
2. Generates matrix with wavy bands parallel to treeline
3. Each band follows a sine wave pattern
4. Adds noise if noise=TRUE
5. Converts to raster and rotates if needed
6. Returns the resulting landscape

### `create_landscape_clustered_trees`

**Input:**
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `treeline_position` (numeric): Relative position of treeline from top (0-1) (default: 0.5)
- `num_clusters` (integer): Number of cluster centers (default: 5)
- `cluster_radius` (numeric): Radius of clusters in pixels (default: 5)
- `scatter_zone_prop` (numeric): Proportion of height for scatter zone (default: 0.5)
- `elongation_x` (numeric): Horizontal elongation factor for clusters (default: 1)
- `elongation_y` (numeric): Vertical elongation factor for clusters (default: 1)
- `seed` (integer): Random seed for reproducibility (default: NULL)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)

**Output:**
- SpatRaster: Binary landscape with clustered trees

**Description:**
1. If seed is not NULL, sets random seed
2. Creates sharp treeline base landscape
3. Places specified number of cluster centers in scatter zone below treeline
4. For each cluster, calculates probability of tree presence based on distance from center
5. Converts to raster and rotates if needed
6. Returns the resulting landscape

### `create_landscape`

**Input:**
- `type` (character): Type of landscape to generate (options: "sharp", "diffuse", "curvy", "fingers", "bent_fingers", "scattered", "sine_bands", "clustered")
- `...` (various): Parameters specific to the landscape type
- `width` (integer): Width of the landscape in pixels (default: 100)
- `height` (integer): Height of the landscape in pixels (default: 100)
- `rotation` (numeric): Angle to rotate landscape in degrees (default: 0)
- `seed` (integer): Random seed for reproducibility (default: NULL)

**Output:**
- SpatRaster: Generated landscape of specified type

**Description:**
1. Validates input parameters
2. If seed is not NULL, passes it to the specific landscape generation function
3. Calls appropriate landscape generation function based on type
4. Passes additional parameters to specific function
5. Returns the generated landscape

### `generate_training_landscapes`

**Input:**
- `n` (integer): Number of landscapes to generate per type (default: 10)
- `types` (character vector): Types of landscapes to generate (default: all types)
- `width` (integer): Width of landscapes in pixels (default: 100)
- `height` (integer): Height of landscapes in pixels (default: 100)
- `add_rotation` (logical): Whether to include rotated versions (default: TRUE)
- `rotation_angles` (numeric vector): Rotation angles in degrees (default: c(0, 45, 90, 135))
- `params_list` (list): List of parameter ranges for each landscape type (default: NULL)
- `seed` (integer): Master random seed (default: NULL)

**Output:**
- List: Named list of generated landscapes with attributes for type

**Description:**
1. If seed is not NULL, sets master random seed
2. For each landscape type in types:
   a. For each index from 1 to n:
      i. Sets derived seed based on master seed (if provided)
      ii. Randomly selects parameters from params_list or uses defaults
      iii. Generates landscape using create_landscape() with derived seed
      iv. Adds metadata attributes for type
   b. If add_rotation=TRUE, generates rotated versions for each landscape
3. Returns list of all generated landscapes with names indicating type and index

## Visualization Functions

### `plot_landscape`

**Input:**
- `landscape` (SpatRaster or matrix): Landscape to plot
- `title` (character): Plot title (default: "Landscape")
- `color_scale` (character vector): Colors for mapping values (default: NULL)
- `legend_title` (character): Title for the legend (default: "Value")
- `show_legend` (logical): Whether to show legend (default: TRUE)

**Output:**
- ggplot object: Plot of the landscape

**Description:**
1. Converts input to data frame if it's a raster or matrix
2. Determines unique classes in the landscape
3. If color_scale is NULL, automatically selects colors based on number of classes
4. Creates ggplot with appropriate aesthetics
5. Applies color scale and formatting
6. Returns the plot object

### `plot_landscape_list`

**Input:**
- `landscape_list` (list): List of landscapes (SpatRaster or matrix) to plot
- `titles` (character vector): Vector of titles for each landscape (default: NULL)
- `color_scale` (character vector): Colors for mapping values across all plots (default: NULL)
- `ncol` (integer): Number of columns in the plot arrangement (default: NULL)
- `legend_title` (character): Title for the legend (default: "Value")
- `show_legend` (logical): Whether to show legend (default: TRUE)

**Output:**
- patchwork object: Combined plot of all landscapes

**Description:**
1. Validates that input is a list of landscapes
2. Determines unique classes across all landscapes
3. If color_scale is NULL, automatically selects colors based on number of classes
4. For each landscape in the list:
   a. Creates plot using plot_landscape function
   b. Applies consistent color scale across all plots
5. Combines individual plots using patchwork package
6. Arranges plots in grid with ncol columns
7. Returns the combined plot

### `plot_metrics`

**Input:**
- `metrics` (data frame): Metrics dataframe from calculate_landscape_metrics
- `selected_metrics` (character vector): Metrics to visualize
- `title` (character): Plot title (default: "Landscape Metrics")
- `facet` (logical): Whether to create facet plot by metric (default: TRUE)
- `arrange_by_importance` (logical): Whether to order metrics by importance (default: FALSE)
- `method` (character): Method used for metric importance (default: "")

**Output:**
- ggplot object: Visualization of selected metrics across landscape types

**Description:**
1. Filters metrics to include only selected_metrics
2. For each metric, calculates mean and variance across landscape types
3. Creates visualization showing metric values by landscape type
4. If facet=TRUE, creates faceted plot with one panel per metric
5. If arrange_by_importance=TRUE, orders metrics by their discriminative power
6. Returns the plot object

### `plot_classification_results`

**Input:**
- `classification` (data frame): Classification results from apply_nn
- `show_probabilities` (logical): Whether to include probability bars (default: TRUE)
- `confidence_threshold` (numeric): Threshold for highlighting low confidence (default: 0.6)

**Output:**
- ggplot object: Visualization of classification results

**Description:**
1. Creates plot showing predicted classes for each landscape
2. If show_probabilities=TRUE, adds probability bars for each class
3. Highlights classifications below confidence_threshold
4. Returns the plot object

## Metrics Calculation Functions

### `list_available_metrics`

**Input:**
- `level` (character): Level of metrics to list ("patch", "class", "landscape", or "all") (default: "all")
- `sort` (logical): Whether to sort metrics alphabetically (default: TRUE)

**Output:**
- data.frame: Table of available metrics with descriptions

**Description:**
1. Gets list of available metrics from landscapemetrics package
2. Filters by level if specified
3. Sorts if requested
4. Returns data frame with metric names and descriptions

### `calculate_landscape_metrics`

**Input:**
- `landscapes` (list or SpatRaster): Landscape(s) to analyze
- `metrics` (character vector): Names of metrics to calculate (default: NULL for all)
- `level` (character): Level of metrics to calculate ("patch", "class", "landscape") (default: "class")
- `progress` (logical): Whether to show progress bar (default: TRUE)

**Output:**
- tibble: Standardized metrics table with columns:
  - landscape_name: Identifier for the landscape
  - type: Landscape type (if available in attributes)
  - metric: Metric name from landscapemetrics
  - class: Class value (if class-level metric)
  - value: Computed metric value

**Description:**
1. Validates input landscapes
2. For each landscape:
   a. Extracts landscape name and type from attributes
   b. Calculates specified metrics using landscapemetrics
   c. Standardizes output format
3. Combines results into a single tibble
4. Returns the standardized metrics table

### `evaluate_landscape_metrics`

**Input:**
- `calculated_metrics` (tibble): Metrics from calculate_landscape_metrics()
- `metrics_number` (integer): Number of top metrics to return (default: 10)
- `method` (character): Selection method (options: "coeffvar_all", "linmod", "lin_mod_r2", "mean_groups") (default: "coeffvar_all")
- `plot` (logical): Whether to generate visualization (default: FALSE)
- `exclude_metrics` (character vector): Metrics to exclude (default: NULL)

**Output:**
- character vector: Names of most sensitive metrics
- (If plot=TRUE) Also prints a visualization using plot_metrics function

**Description:**
1. Validates that metrics contain type information
2. Based on the selected method:
   a. "coeffvar_all": Calculates coefficient of variation for each metric
   b. "linmod": Fits linear models and ranks by p-values
   c. "lin_mod_r2": Fits linear models and ranks by R²
   d. "mean_groups": Calculates relative deviation from overall mean
3. Selects top metrics_number metrics
4. If plot=TRUE, generates visualization of selected metrics
5. Returns vector of selected metric names

## Neural Network Functions

### `train_nn`

**Input:**
- `metrics` (tibble): Metrics from calculate_landscape_metrics()
- `metric_list` (character vector): Names of metrics to use as features
- `test` (logical): Whether to perform cross-validation (default: TRUE)
- `cv_folds` (integer): Number of cross-validation folds (default: 5)
- `hidden_neurons` (integer): Number of neurons in hidden layer (default: 5)
- `decay` (numeric): Weight decay parameter for nnet (default: 0.01)
- `maxit` (integer): Maximum iterations for training (default: 500)
- `save_model` (logical): Whether to save the model (default: FALSE)
- `model_path` (character): Path to save model (default: NULL)

**Output:**
- list: Trained neural network model with components:
  - model: The trained nnet model object
  - features: Names of features used for training
  - scaling: Parameters for feature scaling
  - classes: Vector of class names
  - performance: Cross-validation performance metrics (if test=TRUE)

**Description:**
1. Processes metrics data for neural network training
2. Scales input features to 0-1 range
3. If test=TRUE, performs cross-validation
4. Trains neural network model on full dataset
5. If save_model=TRUE, saves model to specified path using readr::write_rds
6. Returns model object with metadata

### `apply_nn`

**Input:**
- `landscape` (SpatRaster or list): Landscape(s) to classify
- `nn_model` (list): Neural network model from train_nn()
- `test_data` (tibble): Metrics used for training (default: NULL)
- `metric_list` (character vector): Metrics to use (default: NULL, uses nn_model$features)
- `confidence_threshold` (numeric): Threshold for warning flag (default: 0.6)

**Output:**
- tibble: Classification results with columns:
  - landscape_name: Identifier for the landscape
  - predicted_class: Primary classification
  - confidence: Classification confidence
  - [class1, class2, ...]: Class probabilities
  - warning: Warning messages if applicable

**Description:**
1. Validates input landscape and model
2. If landscape is a list, processes each element
3. Calculates metrics for landscape using same metrics as training
4. Scales features using scaling parameters from model
5. Applies neural network model to predict class probabilities
6. Returns classification table with predicted classes and probabilities
