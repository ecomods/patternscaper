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

## Functionality details

### Generate synthetic landscapes

The package will provide one function to generate synthetic landscapes with different ecotone characteristics. The user can specify the type of landscape they want to generate with a string argument. Additional arguments can be used to define specific parameters of the landscape, such as the size of the landscape, the density of trees, or the curvature of treelines. Behind the scene this function will call more specific functions for each type of landscape.

The landscapes that can be generated include:

- sharp treelines: a sharp transition between two vegetation types, e.g. mangroves and salt marsh, with no ecotone zone in between.
- diffuse treelines: a gradual transition between the two vegetation types
- curvy treelines: a transition with a sharp but curvy treeline
- fingers: a transition zone where one vegetation type, e.g. the mangrove trees, grows finger-like into the other vegetation type, e.g. the salt marsh. These fingers can be straight or bent.
- scattered trees: a landscape where trees are randomly scattered in the salt marsh
- sine bands: parallel bands of vegetation types, e.g. mangroves and salt marsh, that are arranged in a sine wave pattern in the ecotone.
- clustered trees: a landscape where trees are clustered in the salt marsh.

All landscapes can be created in different sizes and with different parameters, such as the density of trees, the curvature of treelines, or the size of the fingers. The user can also specify the resolution of the landscape, which will determine the size of the pixels in the raster image. In addition, each landscape can also be created in a rotated version, because also rotated landscapes should be classified correctly by the neural network.

To make it easy for the user to generate training landscapes, the package will also provide a function to generate a set of synthetic landscapes with different ecotone characteristics. The user can specify the number of landscapes they want to generate and the type of landscapes they want to include in the set. Then, this function will call the landscape generation function multiple times and return a list of generated landscapes.

### Plot landscapes

The user can use a general `plot_landscape` function to plot their own landscapes or the generated synthetic landscapes. The function will take either a raster image or a matrix as input and plot it using ggplot2. The user can specify additional arguments to customize the plot, such as the titles or colors of the plot.

### Calculate landscape metrics

The package allows users to calculate a range of landscape metrics for the raster images or the generated synthetic landscapes. The metrics are calculated using the `landscapemetrics` R package, which contains the metrics from the FRAGSTATS software.

There are different options to select which metrics to calculate:

- Select metric via their name: The users can get a list of all available metrics and select the ones they want to calculate.
- Use a default selection of metrics: By default, the package will calculate all metrics available and then select the ones that are most sensitive to the ecotone patterns. For this, there is a function that will be called and that will return a list of the most sensitive metrics.

### Find sensitive landscape metrics

The function takes calculated landscape metrics (ecological measurements of landscape patterns) and identifies which metrics are most useful for distinguishing between different landscape types. This can be done by different methods:

- "coeffvar_all" (default): Ranks metrics by their coefficient of variation (standard deviation/mean) across all landscapes
- "lin_mod_p": Ranks metrics by p-values from linear models testing for differences between landscape types
- "lin_mod_r2": Ranks metrics by R² values from linear models, showing how much variance is explained by landscape type
- "mean_groups": Selects metrics that show the largest and smallest deviations from the overall mean for each landscape type

### Train the neural network

The function to train the neural network will:

- Create a neural network model using the nnet package (single-hidden-layer neural network)
- Process metrics data for neural network training
- Handle normalization of input features
- Implement cross-validation for model evaluation
- Save trained models using readr::write_rds
- Default configuration: 5 neurons in hidden layer, 0.01 decay, 500 iterations

### Classify landscapes

The package provides a function to classify landscapes using a neural network (using the `nnet` function from the `nnet` package). The user can train the neural network on their own landscapes or on the generated synthetic landscapes. The function will take the landscape metrics as input and return a classification table with the predicted classes and probabilities for each landscape.

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

- Support for all raster formats compatible with the landscapemetrics package
  (SpatRaster, Raster* Layer/Stack/Brick, stars objects)
- Binary and multi-class classifications (continuous data support planned for future versions)
- Model persistence using readr::read_rds and readr::write_rds

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