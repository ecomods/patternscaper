# Change Log for EcotoneClassifyR

Here I document changes made to the function packages.

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


