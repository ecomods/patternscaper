# Everything I stumbled over ....

## How to Use the Package

### Installation

You can install the development version of `spatPatClassifyR` directly from GitHub:

```r
# Installation of devtools did not work on MacOS (R version 4.5.2, RStudio Version 2025.09.2+418 (2025.09.2+418))
# Error message pointed to the package shiny which could not be installed with devtools. My solution was:

install.packages("pak")      # once
pak::pkg_install("shiny")   # install shiny + all deps
pak::pkg_install("devtools")
```

