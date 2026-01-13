# Change Log for EcotoneClassifyR

Here I document changes made to the function packages.

## 2025-10-22/23/24

- Implement landscape class as S3 class
- Re-implement all landscape creation functions to return landscape objects
- Update all plotting functions to work with landscape objects
- Write tests for functions related to landscape creation and plotting
- Update documentation

## 2025-10-21

- Change seed argument behaviours: Instead of setting a seed by default, I now 
set the seed to NULL which sets no seed. If the user sets the seed argument to 
something else, they can do so explicitly and the seed is set inside the function
- Reorganize and rename files:
  - All landscapes function now get their own file with filename `landscape_<type>.R`. 
  I renamed other files starting with `landscape_` so only landscape generation files are called like this.
  Reasoning: It started to be confusing with some landscape generation files long with many functions and some short.
  Also, you had to know which function is in which file and then you had to scroll through the file to find the right
  function. This is not ideal for maintenance.

## 2025-09-17

### Summary of Changes

### Remaining questions/problems

- The `train_nn` function still has some parts that could be simplified. For example, the cross-validation part could be made more straightforward and moved to a separate function.
- Selection of cv-folds could be in a separate function that is shared between `train_nn` and `train_nn_keras`
- The `apply_nn_metrics` function could also be simplified further and the data structure between the metrics and the keras version could be clearer
- `train_nn_keras` should also have a loo cross-validation option
- The model architecture could be moved to a separate function. This way, I can easily provide different architectures to select from and compare
- The prediction accuracy of the keras model is not very good. I need to find out why

### Technical details

- `train_nn_keras` and `apply_nn_keras` now provide output that can be plotted with `plot_classified_landscapes` to show correctly predicted classes and landscapes

## 2025-09-10

### Summary of Changes

### Remaining questions/problems

- I think that the structure of a landscape object should be an S3 class with defined attributes and methods. This would make it easier to handle landscapes and ensure that they have the correct structure. Right now the pipeline feels a bit shaky because we just use lists and data frames without any structure. But this is a bigger change that will require more refactoring.

### Technical details

#### `plot_classified_landscapes`

- Don't take the model as input but the classification results from `train_nn` or `apply_nn`

#### `apply_nn`

- Simplify function quite a bit
  - Input is now just a list of landscapes and a trained model
  - The metrics are calculated for the landscape list and then the model is applied to the metrics
  - Before there were complex subfunction and loops. Now the functionality is much more straightforward operating on the whole list at once
- Output is compatible with plotting functions

## 2025-09-09

### Summary of Changes

### Remaining questions/problems

- plot for Cross-validation confidence still needs work as it does not look nice

### Technical details

#### `plot_classification_results`

- Refactor function and add wrapper to create different types of plots
  - `confusion`: Confusion matrix
  - `probabilities`: Probabilities of each class
  - `confidence`: Confidence of the classification
  - `misclassifications`: Most common misclassifications with average confidence
- Work on all plots and their aesthetics

#### `train_nn`

- Simplify code and remove unnecessary parts
  - Cross-validation results are now summarized more straightforwardly
- Add landscape_id to the output to link predictions to landscapes
  - Reason is that when performing the cross validation, the landscapes are shuffled and split into folds. So they are not in the same order as the input list of landscapes. Adding the landscape_id allows to link the predictions back to the original landscapes. This is important for plotting the landscapes with their predictions.

#### `plot_classified_landscapes`

- New function to plot landscapes with their predicted classes and confidence values
- Can be used to visualize results from `apply_nn` or from the cross-validation in `train_nn`

## 2025-09-08

### Summary of Changes



### Remaining questions/problems



### Technical details

#### `evaluate_landscape_metrics`

- Implement method to select only uncorrelated metrics based on correlation threshold
  - New function `select_metrics_correlation` to select metrics based on ranking while ensuring low correlation among them
- Refactor to have separate functions for different selection methods
  - `rank_by_coefficient_variation`
  - `rank_by_mean_differences`
  - `rank_by_linear_model`
  - This way we don't have repeated code and it's easier to add new methods in the future
- Calculate cv directly using tidyverse. Before, the cv was calculated once for all landscapes and once for
  each landscape type separately. But then this result was never used -> I removed it
- Update methods for selection based on linear models 
  - Simplify the logic to avoid code duplication

#### `select_metrics_correlation`

- New function to select the best metrics based on a ranking while ensuring low correlation among them

#### `generate_training_landscapes`

- Distribute the number of landscapes more evenly among the different types of landscapes
  - Before, it was assigned randomly which often led to very uneven distributions especially for small total numbers of landscapes
  - There still is an option to assign randomly if desired but default is evenly

## 2025-09-07

### Summary of Changes
### Remaining questions/problems

- rotated landscape sometimes don't use space on the sides
  - E.g. in the rotated finger landscape, the fingers are not generated on the sides of the landscape
- Unify terminology:
  - of parameters: thickness, width, frequency, amplitude, sine_length, etc.
  - of file and function names: generate_landscape vs. create_landscape

### Technical Details

- Update documentation
- diffuse treeline function now has argument treeline_position
- fingers function fix argument `finger_length_prop` to work the same in bend and straight fingers
- setting seed: Default is now 42 to ensure reproducibility. If set to NULL, the current time is used to create different landscapes each time.
- spot pattern: remove rotation
- sine wave pattern: Add option for `scatter_zone_prop` and adjust the number of bands accordingly
- fix problem with rotation in scatter landscapes (the border cells were not rotated correctly)
- Update ranges for parameters in `generate_training_landscapes`

## 2025-08-29

### Summary of Changes

### Remaining questions/problems

#### Banded landscapes

- Only 3 hills possible with fixed positions -> What if the landscape gets bigger?
- Too many parameters to set that overlap with each other: hilltop, slopes, x/y_ext_hill, nbands -> The values should also be constrained because some combinations don't make sense. E.g. y/x_ext_hill cannot be 0.

#### Spot landscapes

No ecotones, because they have no treeline. Does this make sense? In theory, spots can also be created with a slightly adjusted scattered trees algorithm:

```r
create_landscape_clustered(
    treeline_position = 0,
    n_clusters = 5,
    cluster_radius = 5,
    scatter_zone_prop = 1
) |> plot_landscape()
```

### Technical Details

#### Add new landscapes to `generate_landscape` and `generate_training_landscapes`

#### Add and modify function to create spotted landscape

- Added function according to Britta's code to `scatter_landscapes.R`
- Adjusted function to fit with package specs
  - Optionally add metadata, return as SpatRaster
- Change logic for noise addition: 
  - Add noise to the radius to create spots of different sizes (if `spot_radius_sd` > 0).
  - Before: noise had no effect because in the end only cells in the radius without noise were considered for vegetation spots
- Add option for setting seed

#### Add and modify function to create banded vegetation patterns

- Added function according to Britta's code to `banded_landscapes.R`
- Remove flag for noise addition `noise`: Does not make sense to have a flag if we always add noise with a certain standard deviation. Instead, we can set `noise_sd=0` to have no noise.
- Adjusted function to fit with package specs
  - Optionally add metadata, return as SpatRaster
- Add option for setting seed


## 2025-06-24: Improved `mean_groups` method in `evaluate_landscape_metrics`

### Summary of Changes

The `mean_groups` method in `evaluate_landscape_metrics()` was redesigned to:

1. Use a total deviation-based approach instead of selecting a fixed number of metrics per landscape type
2. Respect the user's requested `metrics_number` parameter
3. Improve robustness against NaN/Inf values and missing data
4. Ensure deterministic results by eliminating random sampling
5. Handle edge cases where no metrics can be selected

### Technical Details

**Original implementation:**
- Selected exactly 4 metrics per landscape type (2 with lowest and 2 with highest deviation)
- Used random sampling for tied metrics (`sample()` function)
- Final number of metrics was unpredictable (anywhere from 1 to 4×num_types unique metrics)
- Did not respect the user's requested `metrics_number` parameter

```r
# Original approach (pseudocode)
mymetrics <- array(data = NA, dim = 4 * num_types)
for (t in 1:num_types) {
  # Get 2 metrics with highest positive deviation for this type
  ranking <- rank(rel_mean_diff[, t], na.last = TRUE)
  mymetrics[(t * 4 - 3):(t * 4 - 2)] <- sample(metrics_names[ranking <= 2], 2)
  
  # Get 2 metrics with highest negative deviation for this type
  ranking <- rank(rel_mean_diff[, t], na.last = FALSE)
  mymetrics[(t * 4 - 1):(t * 4)] <- sample(metrics_names[ranking > (num_metrics - 2)])
}
top_metrics <- sort(unique(mymetrics))
```

**New implementation:**
- Calculates total absolute deviation across all landscape types
- Ranks metrics by total deviation (higher = better discriminating power)
- Returns exactly the number of metrics requested by the user
- Handles NA values gracefully with `na.rm=TRUE`
- Replaces non-finite values (NaN/Inf) with NA
- Includes fallback behavior if no metrics can be selected

```r
# New approach
rel_mean_diff <- (means_types[, 1:num_types] - means_types$all) / means_types$all
rel_mean_diff[!is.finite(rel_mean_diff)] <- NA
abs_diff <- abs(rel_mean_diff)
importance_scores <- rowSums(abs_diff, na.rm = TRUE)
ranking <- rank(-importance_scores, na.last = TRUE)
top_metrics <- metrics_names[ranking <= metrics_number]
```

### Example Case

Consider a dataset with 3 landscape types and these relative mean differences:

| Metric  | Type A | Type B | Type C | Total Abs Deviation |
|---------|--------|--------|--------|---------------------|
| Metric1 | 0.1    | 0.2    | 0.3    | 0.6                 |
| Metric2 | 0.9    | -0.1   | 0.1    | 1.1                 |
| Metric3 | 0.4    | 0.5    | 0.4    | 1.3                 |
| Metric4 | 0.1    | -0.1   | -0.1   | 0.3                 |
| Metric5 | 0.7    | 0.6    | 0.8    | 2.1                 |

**Original method** would:
- For Type A: Select Metrics 2, 5 (highest deviation) and 1, 4 (lowest deviation)
- For Type B: Select Metrics 3, 5 (highest deviation) and 2, 4 (lowest deviation)
- For Type C: Select Metrics 5, 3 (highest deviation) and 2, 4 (lowest deviation)
- Final set: Metrics 1, 2, 3, 4, 5 (possibly all metrics!)

**New method** (with `metrics_number=3`) would:
- Calculate total absolute deviation across all types
- Select top 3 metrics: Metrics 5, 3, 2

The new approach selects metrics with the greatest overall discriminatory power across all landscape types, providing a more focused and meaningful selection. It also respects the user's requested number of metrics, ensuring consistent output size.

### Benefits

1. **Better feature selection**: Focuses on metrics that differ consistently across landscape types
2. **Predictable output**: Always returns the exact number of metrics requested
3. **Reproducible results**: Eliminates randomness for consistent outputs
4. **More robust**: Better handling of edge cases, NaN/Inf values
5. **Respects user input**: Honors the metrics_number parameter
6. **Simpler code**: Easier to understand and maintain


