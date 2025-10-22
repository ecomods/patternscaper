# ecotoneClassifyR Design Document

## S3 Class System for Landscapes

### Core Design Decisions

- **Data representation**: Standardize on SpatRaster internally
  - Accept both matrices and SpatRaster objects as input
  - Convert matrices to SpatRaster during object creation
  - Provide methods to convert back to matrix/array when needed
  - Rationale: Preserves spatial information and provides consistent interface

- **Class structure**:
  - `data`: SpatRaster object containing the landscape data
  - `type`: Character string identifying the landscape type
  - `params`: List of parameters used to create or describe the landscape

### Implementation Plan

1. Create the basic S3 class structure (landscape_class.R)
2. Develop core methods (print, plot, as.matrix, dim, etc.)
3. Update landscape creation functions to return landscape objects
4. Update analysis functions to work with landscape objects
5. Update visualization functions

### Function Updates Required

- [ ] `landscape_class.R`: Core class definition and methods
- [ ] `create_landscape()`: Return landscape objects
- [ ] `generate_training_landscapes()`: Return list of landscape objects
- [ ] `plot_landscape()`: Adapt to work with landscape objects
- [ ] `plot_landscape_list()`: Adapt to work with lists of landscape objects
- [ ] Landscape metric functions: Update to accept landscape objects
- [ ] Neural network functions: Update to work with landscape objects

### Conversion Utilities

- Matrix to SpatRaster:

```r
  matrix_to_raster <- function(x, crs = NULL) {
    terra::rast(x, crs = crs)
  }
```

- SpatRaster to formats needed for analysis

```r
# For landscape metrics
as.matrix.landscape <- function(x, ...) { ... }

# For neural networks
as.array.landscape <- function(x, ...) { ... }
```