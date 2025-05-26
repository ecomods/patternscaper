# ecotoneClassifyR

## What This Package Does

`ecotoneClassifyR` is an R package for creating and classifying landscape patterns with a focus on ecological ecotones - transition areas between different ecological communities. The package allows you to:

- Generate synthetic landscape patterns with various ecotone characteristics
- Create landscapes with different patterns including:
  - Sharp treelines
  - Diffuse treelines
  - Curvy treelines
  - Scattered tree patterns
  - Clustered vegetation
  - Finger-like extensions
  - Sine wave bands
- Rotate and crop generated landscapes
- Apply classification methods to analyze ecotone patterns

This package is useful for ecologists, landscape ecologists, and researchers studying vegetation patterns, habitat transitions, and spatial analysis.

## How to Use the Package

### Installation

You can install the development version of `ecotoneClassifyR` directly from GitHub:

```r
# Install devtools if you don't have it
if (!require("devtools")) install.packages("devtools")

# Install ecotoneClassifyR from GitHub
devtools::install_github("selinabaldauf/ecotoneClassifyR")
```

### Basic usage

```r
library(ecotoneClassifyR)
```

## Development guide

Setting Up the Development Environment

1 . Clone the repository:

```bash
git clone https://github.com/selinabaldauf/ecotoneClassifyR.git
cd ecotoneClassifyR
```

2. Open the project in RStudio or VS Code:

Development Workflow with devtools
The devtools package provides essential functions for package development:

```r
# Load all functions from the package for testing
devtools::load_all()

# Generate documentation from roxygen comments
devtools::document()

# Install the package locally
devtools::install()

# Run tests
devtools::test()

# Check if the package meets CRAN requirements
devtools::check()

# Build the package
devtools::build()
```

### Adding new functions


1. Create an R script in the R directory
2. Add roxygen comments for documentation
3. Run `devtools::document()` to generate documentation
4. Write tests in the `tests/testthat/` directory
5. Run `devtools::test()` to execute tests

### Contributing

#### Issue tracking

If you find a bug or have a feature request, please open an issue on the [GitHub Issues page](https://github.com/ecomods/ecotoneClassifyR/issues).
Add smaller, active todos to the [Active TODOs issue](https://github.com/ecomods/ecotoneClassifyR/issues/1), for bigger bugs or features, please open a new issue.

#### Via GitHub Desktop

1. **Clone the repository** to your local machine using GitHub Desktop:
   - Click "File" > "Clone Repository"
   - Select the repository from the list or enter the URL
   - Choose where to save it locally
   - Click "Clone"

2. **Before making changes**:
   - Always click "Fetch origin" to check for updates
   - If updates exist, click "Pull origin" to download them
   - This ensures you have the latest version before making changes

3. **Make changes** to the code

4. **Review and commit your changes**:
   - Review your changes in GitHub Desktop
   - Enter a summary and description of your changes
   - Click "Commit to main"

5. **Push your changes**:
   - Click "Push origin" to upload your changes to GitHub

#### Via Command Line

1. **Clone the repository**:

```bash
git clone https://github.com/selinabaldauf/ecotoneClassifyR.git
cd ecotoneClassifyR
```

1. **Before making changes, always pull the latest updates**:

```bash
git pull origin main
```

1. **Make your changes** to the code

2. **Stage and commit** your changes:

```bash
git add .
git commit -m "Add feature: description of changes"
```

1. **Push your changes**:

```bash
git push origin main
```

### Contribution Guidelines

- Follow the existing code style and naming conventions
- Write tests for new functions
- Update documentation with roxygen comments
- Make sure all tests pass before pushing changes
- Communicate with team members about significant changes
- Pull before starting new work to avoid conflicts

