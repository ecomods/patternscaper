# Project description

The goal of the project is to create an R package called `EcotoneClassifyR` that provides functions for classifying ecotone patterns using a neural network. The ecotones are classified based on a selectable range of landscape metrics that are calculated from raster images of landscapes. Classes can include scattered trees, sharp treelines, diffuse treelines, clustered trees, and more.
In addition to the classification functionality, the package will also include functions for generating synthetic landscapes with various ecotone characteristics. These landscapes can be used for testing and training the classification model.

The package can be used for any type of ecotone, but the initial focus will be on mangrove and salt marsh ecotones. Therefore, this document will use mangroves and salt marshes as examples, but the package is not limited to these two vegetation types.

## Context

Ecotones are the transition zones between different ecological communities. One example are the transition zones between mangrove forests and salt marshes. These transition zones can look very different depending on many factors. For example, there can be a sharp treeline between mangroves and salt marsh, there can be an ecotone where mangroves are clustered or scattered in the salt marsh, or mangroves can grow finger-like into the salt marsh.

The package is designed for ecologists, and researchers in general who are interested in studying vegetation patterns in ecotones, which is not limited to mangroves and salt marsh.

## User experience

A user of the package has images (e.g. satellite images) of ecotone landscapes.
The images are already prepared and classified and are available in a raster format.
What the user can do with the package:

- Plot their own landscapes using a plot function that the packages provides.
- Generate synthetic landscapes with various ecotone characteristics.
- Calculate a range of landscape metrics from the raster images and/or generated synthetic landscapes (custom selection of the metric or default selection).
- Train a neural network with cross-validation either on the synthetic landscapes or on a subset of the user's own landscapes.
- Save trained models and load them for later use.
- Classify the user's landscapes using the trained neural network.

### User input

- Raster images of landscapes (ecotones) that are already prepared and classified.
  - Binary classification (e.g. mangrove vs. salt marsh)
  - Multi-class classification support

### Output

- Plots of the landscapes with customizable styling
- Classification table for the landscapes (which of the images belong to which vegetation pattern class with a probability score)
- Landscape metrics table for the landscapes (which of the images have which landscape metrics with a value)
- Trained neural network model that can be used for further classification tasks
- Cross-validation results for model evaluation

### Complete Workflow Example

```r
# Generate artificial landscapes in a list for training
training_landscapes <- generate_training_landscapes(
  n = 50,                           # Number of landscapes per type
  types = c("sharp", "scattered"),  # Types to generate
  width = 100, height = 100         # Dimensions
)

# Calculate metrics for all landscapes
metrics <- calculate_landscape_metrics(training_landscapes)

# Select the most sensitive metrics
metrics_selected <- evaluate_landscape_metrics(
  metrics,
  method = "lin_mod_r2",
  metrics_number = 15,
  plot = TRUE                      # Create visualization of metrics
)

# Train the neural network model
model <- train_nn(
  metrics,
  metrics_selected,
  test = TRUE                      # Perform cross-validation
)

# Read in a real landscape image
image <- terra::rast("data-raw/satellite_images/Picture9.png")

# Classify the landscape
classification <- apply_nn_metrics(
  image,
  nn_model = model,
  test_data = metrics, 
  metric_list = metrics_selected
)

# View classification results
print(classification)
# A tibble: 1 × 5
# landscape_name predicted_class confidence sharp scattered warning
# <chr>          <chr>               <dbl> <dbl>    <dbl> <chr>
# 1 Picture9       scattered            0.83  0.17     0.83 NA
```

## Functionality details

### Generate synthetic landscapes

The package will provide one function to generate synthetic landscapes with different ecotone characteristics. The user can specify the type of landscape they want to generate with a string argument. Additional arguments can be used to define specific parameters of the landscape, such as the size of the landscape, the density of trees, or the curvature of treelines. Behind the scene this function will call more specific functions for each type of landscape.

The landscapes that can be generated include:

- **sharp treelines**: A sharp transition between two vegetation types, e.g. mangroves and salt marsh, with no ecotone zone in between.
  - **Algorithm**: Simple horizontal division of landscape with all pixels above treeline_position = 1, below = 0
  - **Key parameters**: width, height, treeline_position (0-1), rotation (degrees)

- **diffuse treelines**: A gradual transition between the two vegetation types.
  - **Algorithm**: Probability of tree presence decreases with row index using formula: prob = 1 - (normalized_row)^steepness
  - **Key parameters**: width, height, steepness (controls transition rate), rotation

- **curvy treelines**: A transition with a sharp but curvy treeline.
  - **Algorithm**: Uses sine wave to create undulating boundary following formula: i > (treeline_row + sin(2π*j/sine_length) \* sine_height)
  - **Key parameters**: width, height, treeline_position, sine_length (wavelength, default: 20), sine_height (amplitude, default: 5)

- **fingers**: A transition zone where one vegetation type grows finger-like into the other.
  - **Straight Fingers Algorithm**: Creates rectangular extensions from treeline evenly distributed across landscape width
  - **Bent Fingers Algorithm**: Similar to straight fingers but uses sine function to create bending effect
  - **Key parameters**: width, height, treeline_position, num_fingers (default: 5), finger_width (pixels, default: 3), finger_length_prop (proportion of height, default: 0.3)

- **scattered trees**: A landscape where trees are randomly scattered in one vegetation type.
  - **Algorithm**: Creates sharp treeline base landscape with random tree placement below treeline based on scatter_density
  - **Key parameters**: width, height, treeline_position, scatter_density (0-1), scatter_zone_prop (proportion of height)

- **sine bands**: Parallel bands of vegetation types arranged in a sine wave pattern.
  - **Algorithm**: Generates wavy bands parallel to treeline with each band following a sine wave pattern
  - **Key parameters**: width, height, treeline_position, band_thickness (default: 3), band_spacing (default: 10), frequency (2π/100 recommended for 100×100), amplitude (default: 5), noise (TRUE/FALSE), noise_sd (default: 1)

- **clustered trees**: A landscape where trees are clustered.
  - **Algorithm**: Places specified number of cluster centers in scatter zone with decreasing tree probability based on distance from centers using formula: 1-(dist/radius)²
  - **Key parameters**: width, height, treeline_position, num_clusters (default: 5), cluster_radius (default: 5), scatter_zone_prop, elongation_x/y (for elliptical clusters, default: 1), seed (for reproducibility)

All landscapes can be created in different sizes and with different parameters, such as the density of trees, the curvature of treelines, or the size of the fingers. In addition, each landscape can also be created in a rotated version, because also rotated landscapes should be classified correctly by the neural network.

To make it easy for the user to generate training landscapes, the package will also provide a function to generate a set of synthetic landscapes with different ecotone characteristics (function `generate_training_landscapes`). The user can specify the number of landscapes they want to generate and the type of landscapes they want to include in the set. Then, this function will call the landscape generation function multiple times and return a list of generated landscapes.

### Plot landscapes

The user can use a general `plot_landscape` function to plot their own landscapes or the generated synthetic landscapes. The function will take either a raster image or a matrix as input and plot it using ggplot2. The user can specify additional arguments to customize the plot, such as the titles or colors of the plot.

### Calculate landscape metrics

The package allows users to calculate a range of landscape metrics for the raster images or the generated synthetic landscapes. The metrics are calculated using the `landscapemetrics` R package, which contains the metrics from the FRAGSTATS software.

There are different options to select which metrics to calculate:

- Select metric via their name: The users can get a list of all available metrics and select the ones they want to calculate.
- Use a default selection of metrics: By default, the package will calculate all metrics available and then select the ones that are most sensitive to the ecotone patterns. For this, there is a function that will be called and that will return a list of the most sensitive metrics.

#### Metrics Table Format

The metrics table will be a standardized tibble with the following structure:

```r
# Example structure of metrics tibble
tibble(
  landscape_name = c("landscape1", "landscape1", "landscape2", ...),  # Unique landscape identifier
  type = c("sharp", "sharp", "scattered", ...),                       # Categorical landscape type (for training)
  metric = c("lsm_c_ai", "lsm_c_np", "lsm_c_ai", ...),               # Metric name from landscapemetrics
  class = c(1, 1, 1, ...),                                            # Class value (if class-level metric)  
  value = c(0.82, 15, 0.65, ...)                                      # Computed metric value
)
```

### Find sensitive landscape metrics

The package provides a function `evaluate_landscape_metrics()` that analyzes calculated landscape metrics to identify which are most effective at distinguishing between different ecotone patterns. The function supports multiple selection methods, each with different statistical approaches:

#### Currently implemented methods:

1. **"coeffvar_all"** (Default method):
   - Calculates coefficient of variation (CV = standard deviation/mean) for each metric across all landscapes
   - Ranks metrics by CV and selects the top N with highest variability
   - Formula: `CV = sd_types$all / means_types$all`
   - Best for: Identifying metrics with the highest relative variability across all landscape types

2. **"linmod"** (Linear model p-value method):
   - Fits a linear model for each metric with landscape type as predictor 
   - Ranks metrics by p-values from ANOVA test
   - Formula: `lm(value ~ type)` followed by `anova(model)$"Pr(>F)"[1]`
   - Best for: Finding metrics that show statistically significant differences between landscape types

3. **"mean_groups"** (Mean differences method):
   - Calculates relative deviation from overall mean for each metric and landscape type
   - For each landscape type, selects metrics with largest positive and negative deviations
   - Formula: `rel_mean_diff = (means_types[, 1:num_types] - means_types$all) / means_types$all`
   - Best for: Identifying characteristic metrics for specific landscape patterns

#### Parameters:

- `calculated_metrics`: Dataframe containing previously calculated metrics
- `metrics_number`: Number of top metrics to return (default: 10)
- `method`: Selection method to use (default: "coeffvar_all")

#### Output:

Returns a character vector containing the names of the most sensitive metrics for distinguishing between landscape types.

#### Visualization:

The package will also provide a function to visualize the results of the sensitive metrics detection. The visualization will show the selected metrics and their values for each landscape type, allowing the user to see which metrics are most effective at distinguishing between different ecotone patterns. In this way, the user can compare the selected top metrics from the 
evaluation function and compare it to the visualization of the metrics for each landscape type.

### Train the neural network

The function to train the neural network will:

- Scale the input features (landscape metrics) to standardized values using the `scale()` function
- Create a neural network model using the nnet package (single-hidden-layer neural network)
- Process metrics data for neural network training
- Handle normalization of input features
- Implement cross-validation for model evaluation with three options:
  - **"none"**: No cross-validation, train on all data
  - **"k-fold"**: Stratified k-fold cross-validation (default)
  - **"loo"**: Leave-one-out cross-validation
- Automatically adjust cross-validation method based on dataset size:
  - Switch to leave-one-out CV when dataset is small (<30 samples) or has classes with few samples
  - Reduce fold count to maintain sufficient samples per class per fold
- Calculate comprehensive performance metrics:
  - **Accuracy**: Overall proportion of correct predictions
  - **Precision**: How many of the predicted positives are true positives (for each class)
  - **Recall**: How many of the actual positives are correctly predicted (for each class)
  - **F1 Score**: Harmonic mean of precision and recall, balancing both concerns
- Provide informative warnings for:
  - Classes with very few samples (<3)
  - Classes that were never correctly predicted during cross-validation
- Save trained models using readr::write_rds
- Default configuration: 5 neurons in hidden layer, 0.01 decay, 500 iterations

#### Performance Metrics Explained

- **Confusion Matrix**: Shows how many instances of each actual class were predicted as each possible class
- **Accuracy**: Proportion of all predictions that were correct (sum of diagonal / total)
- **Precision**: For each class, how many predictions were correct out of all predictions of that class
  - Formula: True Positives / (True Positives + False Positives)
  - Answers: "When the model predicts class X, how often is it right?"
- **Recall**: For each class, how many instances were correctly identified out of all actual instances
  - Formula: True Positives / (True Positives + False Negatives)
  - Answers: "Of all actual instances of class X, how many did the model find?"
- **F1 Score**: Harmonic mean of precision and recall, providing a balanced metric
  - Formula: 2 * (Precision * Recall) / (Precision + Recall)
  - Particularly valuable for datasets with class imbalance
  - Ranges from 0 (worst) to 1 (best)

The model evaluation process intelligently handles small datasets and rare classes by:
1. Detecting when k-fold CV isn't appropriate and switching to leave-one-out
2. Setting appropriate warnings about reliability for classes with few samples
3. Ensuring all classes appear in confusion matrix even if never predicted
4. Handling edge cases like division by zero in metric calculations

### Classify landscapes

The package provides a function to classify landscapes using a neural network (using the `nnet` function from the `nnet` package). The user can train the neural network on their own landscapes or on the generated synthetic landscapes. The function will take the landscape metrics as input and return a classification table with the predicted classes and probabilities for each landscape.

#### Classification Output Format

Classification results will be returned as a tibble with:

```r
# Example structure of classification results
tibble(
  landscape_name = c("landscape1", "landscape2", ...),                # Landscape identifier
  predicted_class = c("sharp", "scattered", ...),                     # Primary classification
  confidence = c(0.85, 0.72, ...),                                    # Classification confidence
  sharp = c(0.85, 0.15, ...),                                         # Class probability for "sharp"
  scattered = c(0.10, 0.72, ...),                                     # Class probability for "scattered"
  clustered = c(0.05, 0.13, ...)                                      # Class probability for "clustered"
  # Additional columns for other landscape types
  warning = c(NA, "Low classification confidence", ...)               # Warning messages if applicable
)
```

## Development and Documentation

- **Documentation**: All functions will be documented using roxygen2 comments, with additional vignettes showcasing example workflows
- **Website**: Documentation will be published as a GitHub Pages site
- **Testing**: Unit tests will be implemented using the testthat framework
- **Publication target**: rOpenSci (not necessarily CRAN)

## Future development

- Add support for more complex landscapes that are not binary but continuous or support 
multilayer classification that can also consider e.g. vegetation height or density.
- Support more landscape metrics that are not from the `landscapemetrics` package.
- Support for other types of NNs
- Idea for additional evaluation:
  - **"lin_mod_r2"** method: Will rank metrics by R² values, showing how much variance is explained by landscape type
- Parallel processing support for large raster datasets to improve performance

# Development plan

## Technical Architecture and specifications

### Coding Standards

- Follow tidyverse style guide for consistency
- Use the base R pipe `|>` for chaining operations
- Reference functions from external packages using the `::` operator
- Use meaningful variable and function names in `snake_case`
- Use roxygen2 for documentation comments
- Abundant use of comments to explain complex logic

### Dependencies

- **Core functionality**: landscapemetrics, nnet
- **Data manipulation**: tidyverse packages (dplyr, tidyr, ggplot2)
- **File operations**: readr (for model saving/loading)

### Package Organization

The package will follow a process-based organization with logical grouping of functions:
- Landscape generation functions
- Metric calculation functions
- Model training and application functions
- Visualization functions
- Utility functions

### Input/Output Support

- Standardized support for terra's SpatRaster objects only
- Binary and multi-class classifications (continuous data support planned for future versions)
- Model persistence using readr::read_rds and readr::write_rds

### Input Data Specifications

#### Raster Requirements

- **Size limitations**: The package supports rasters of any size, though processing time increases with raster dimensions. For optimal performance, rasters smaller than 5000x5000 pixels are recommended. The package will issue warnings when processing very large rasters (>10000x10000 pixels) that may cause memory or performance issues.

- **Coordinate systems**: Coordinate systems are optional for input rasters.
  - With coordinate system: Landscape metrics will have real-world units (e.g., meters, square kilometers)
  - Without coordinate system: Metrics will use pixel units (e.g., pixel count, pixel area)
  - Both approaches are fully supported by the underlying landscapemetrics calculations

- **Class labels**: 
  - Supports both binary (0/1) and multi-class classifications
  - Labels can be either numeric values or strings (e.g., "mangrove"/"saltmarsh" or 1/2)
  - For multi-class: each unique value represents a different vegetation type or landscape feature
  - NA values are supported and will be handled appropriately by the metrics calculations
  
- **File formats**:
  - Input will be standardized on terra's SpatRaster objects only
  - Users with other formats must first convert to SpatRaster using terra::rast()
  - All file formats supported by terra::rast() function (GeoTIFF, IMG, ascii grid, etc.)
  - This standardization provides better performance, simplifies code, and ensures forward compatibility as the R spatial ecosystem moves away from the older raster package

## Development Phases

### Phase 1: Core Infrastructure & Landscape Generation

1. **Package Setup**
   - Initialize package structure (using `usethis::create_package()`)
   - Set up GitHub repository with continuous integration
   - Create documentation templates
   - Set up testing framework (testthat)

2. **Utility Functions**
   - Implement basic utility functions (rotation, cropping, validation)
   - Write unit tests for each utility function
   - Add matrix to raster conversion functions with tests
   - Create error handling and input validation framework with tests

3. **Landscape Generation Functions**
   - For each landscape generator implementation:
     - Write tests for expected outputs and edge cases
     - Implement the generator function
     - Verify against test cases
   - Include implementations for:
     - Sharp treelines
     - Diffuse treelines
     - Curvy treelines 
     - Fingers (straight and bent)
     - Scattered trees
     - Sine bands
     - Clustered trees
   - Add high-level wrapper function with tests
   - Implement training dataset generation with tests

4. **Basic Visualization**
   - Implement `plot_landscape()` for basic visualization
   - Write tests for plot output consistency
   - Add customization options for plots with tests

### Phase 2: Metrics Calculation & Analysis

1. **landscapemetrics Integration**
   - Create wrapper functions for landscape metrics calculation
   - Write tests comparing results with direct landscapemetrics calls
   - Implement metric selection functionality with tests
   - Add function to list available metrics with tests
   - Optimize performance for batch processing with benchmarking tests

2. **Sensitive Metrics Detection**
   - For each method of finding sensitive metrics:
     - Write tests with known metric patterns
     - Implement the method
     - Verify against test expectations
   - Methods include:
     - Coefficient of variation method
     - Linear model p-value method
     - Linear model R² method
     - Mean groups method
   - Create visualization functions with tests for output consistency
   - Add helper functions for metric selection with tests

### Phase 3: Neural Network & Classification

1. **Neural Network Training**
   - Implement basic neural network training functionality
   - Write tests for model training with simple test cases
   - Add cross-validation framework with tests
   - Create functions for model training with synthetic landscapes
   - Implement model saving/loading with readr and tests for persistence
   - Add normalization/scaling functionality with tests

2. **Classification System**
   - Create functions to apply trained models to new landscapes
   - Write tests with known classification outcomes
   - Implement classification probability reporting with tests
   - Add functions to evaluate model performance with tests
   - Create visualization for classification results with tests

3. **Workflow Integration**
   - Create high-level wrapper functions for common workflows
   - Write integration tests for end-to-end workflows
   - Implement pipeline for end-to-end analysis with tests
   - Add example workflows with sample data and verification tests

### Phase 4: Documentation & Publication

1. **Comprehensive Documentation**
   - Complete roxygen documentation for all functions
   - Create vignettes for key workflows:
     - Synthetic landscape generation
     - Landscape metrics calculation
     - Neural network training
     - Classification of landscapes
   - Set up pkgdown website
   - Test documentation examples to ensure they work as expected

2. **Code Quality & Coverage**
   - Review test coverage and add tests for any uncovered code paths
   - Perform code review for consistency and quality
   - Run static code analysis and address any issues
   - Ensure all tests pass on different platforms

3. **Publication Preparation**
   - Prepare package for rOpenSci submission
   - Address potential CRAN check issues
   - Create publication materials (demo, README)
   - Review and refine API for consistency
   - Test all public-facing functions for usability

## Milestone Deliverables

1. **Milestone 1** (End of Phase 1): Functional and tested landscape generation system with visualization
2. **Milestone 2** (End of Phase 2): Complete tested metrics calculation with sensitive metrics detection
3. **Milestone 3** (End of Phase 3): Thoroughly tested neural network classification system
4. **Milestone 4** (End of Phase 4): Fully documented package ready for publication with comprehensive test

# Known issues and todos

- Calculate landscape metrics in parallel to improve performance for large rasters or many landscapes