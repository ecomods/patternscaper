# ecotoneClassifyR Coding Guidelines

## Architecture Overview

This package classifies ecological landscape patterns using neural networks trained on either:
- **2D landscape data** via CNNs with keras3 (`R/nn_keras.R`)
- **Landscape metrics** via nnet with landscapemetrics features (`R/nn_metrics.R`, `R/metrics.R`)

### Core Data Structure

**Landscape objects** are S3 classes with structure:
```r
list(
  data = SpatRaster,      # terra raster object
  pattern = character,    # e.g., 'sharp', 'diffuse', 'spots'
  name = character,       # unique identifier
  params = list          # creation parameters
)
```

- **Landscape generators**: Use `landscape()` which accepts matrices or SpatRaster
- **Low-level utilities**: Use `new_landscape()` when you already have a SpatRaster
- `landscape()` handles matrix-to-raster conversion internally via `matrix_to_raster()`
- Check object validity with `is_landscape(x)`
- **CRS handling**: Artificial landscapes (from `create_landscape()`) may have no CRS - this is acceptable

### File Organization

- **One landscape generator per file**: `R/landscape_create_<type>.R` (e.g., `landscape_create_sharp_treeline.R`)
- **Pattern types**: random, sharp, diffuse, curvy, fingers, curvyfingers, scattered, clustered, sine_bands, spots, gaps, banded, labyrinth
- **Centralized dispatch**: `create_landscape()` in `R/landscape_create.R` routes to specific generators
- **Helper functions**: Can be in same file as exported functions; mark with `@keywords internal` or `@noRd`

### Key Conventions

#### Code Style
- **Pipe operator**: Use `|>` (native pipe), not `%>%`
- **Grouping**: Use `dplyr::filter(.by = ...)` instead of `group_by()` + `ungroup()`
- **Package preference**: Prefer tidyverse solutions over base R

#### Error/Warning Handling
Use `cli` package for all user-facing messages:
- **Errors**: `cli::cli_abort()` for validation failures
- **Warnings**: `cli::cli_alert_warning()` for important non-fatal issues (e.g., NA metrics excluded)
- **Info**: `cli::cli_alert_info()` for verbose output only
- **Never message**: Expected behavior (e.g., filtering via `exclude_metrics`)

#### Landscape Dimensions
- **Standard size**: 100x100 cells (default for all generators)
- Functions should accept `width` and `height` parameters but default to 100

#### Cross-Validation
Both `train_nn_landscapes()` and `train_nn_metrics()` support:
- `cv_method`: "none", "k-fold", "loo"
- Return structure includes `landscape_id` to map predictions back to input order (important: CV shuffles data)

#### Metric Evaluation
- **Default correlation threshold**: 0.7 in `evaluate_landscape_metrics()`
- Threshold is use-case dependent; allow users to override

#### Documentation
- Use roxygen2 with `@importFrom` for explicit imports
- Mark internal functions with `@keywords internal`
- Use `@noRd` for undocumented internal helpers

## Development Workflow

```r
# Load functions for interactive testing
devtools::load_all()

# After editing roxygen comments
devtools::document()

# Run tests (organized by component in tests/testthat/test-*.R)
devtools::test()

# Full package check
devtools::check()
```

### Testing Structure
Tests in `tests/testthat/` organized by component:
- `test-landscape-class.R`: S3 object validation
- `test-landscape-creation.R`: Pattern generators
- `test-metrics.R`: landscapemetrics integration

## Dependencies

### Required Setup
- **keras3**: Users must run `keras3::install_keras()` to set up TensorFlow backend

### Standard Dependencies
- No special system requirements for landscapemetrics (GDAL handled by terra/sf)
- No renv workflow needed for dependency changes

## Known Technical Debt

From `docs/change_log.md`:
- CV fold selection could be shared between keras and metrics trainers
- Keras model architecture should be extractable for comparison experiments
- `apply_nn_metrics` data structure needs alignment with keras version
- Keras prediction accuracy needs investigation

## Future Work (Not Yet Standardized)

Neural network conventions for:
- Model saving/loading directory structure
- Recommended hyperparameters (layers, units, epochs)
- Training callbacks (early stopping, etc.)
