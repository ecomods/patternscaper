# Set up Keras and TensorFlow

The pixel-based workflow uses `keras3` with a TensorFlow backend.
Installing `patternscaper` also installs the R package `keras3`, but the
Python environment and TensorFlow backend need a separate setup step.

This guide covers only what is needed to run the [pixel-based
workflow](https://ecomods.github.io/patternscaper/articles/classify-pixels.md).
For platform-specific options, including GPU support, see the official
[`keras3` installation
reference](https://keras3.posit.co/reference/install_keras.html).

## Choose Python 3.12

`patternscaper` currently recommends Python 3.12 for the pixel-based
workflow. Other Python versions can remain installed, but the `r-keras`
environment should use Python 3.12.

Start a fresh R session and check whether `reticulate` can find an
existing Python 3.12 installation:

``` r

reticulate::virtualenv_starter(
  version = "3.12",
  all = TRUE
)
```

If this prints at least one Python installation, continue to [Install
Keras and TensorFlow](#install-keras-and-tensorflow). If it returns an
empty result, install the latest Python 3.12 patch release:

``` r

reticulate::install_python("3.12:latest")
```

This installation is separate from other Python versions already on the
computer. If Python 3.12 is installed in a non-standard location but is
not found, see the official [`reticulate` Python selection
reference](https://rstudio.github.io/reticulate/reference/use_python.html).

## Install Keras and TensorFlow

In the same fresh R session, run:

``` r

keras3::install_keras(
  backend = "tensorflow",
  python_version = "3.12",
  restart_session = FALSE
)

reticulate::py_install(
  packages = "numpy<2",
  envname = "r-keras",
  pip = TRUE
)
```

The Keras installer creates a Python virtual environment named `r-keras`
and installs Keras, TensorFlow, and the required Python dependencies.
`py_install` installs a NumPy version compatible with the current
`keras3` requirements. The download and installation can take several
minutes.

When the installation finished, restart R.

## Verify the backend

In the fresh R session, load `patternscaper` and then ask Keras which
backend it is using:

``` r

library(patternscaper)
keras3::config_backend()
#> [1] "tensorflow"
reticulate::py_config()
```

`config_backend()` should return `"tensorflow"`. The Python
configuration should point to the `r-keras` virtual environment, report
Python 3.12 and a NumPy version below 2, and produce no warning about
unsatisfied requirements declared through `py_require()`.

TensorFlow may print informational oneDNN messages during this step
which do not indicate installation failure.

## Getting more help

If backend verification still fails, consult the official [Keras
installation guide](https://keras.io/getting_started/) and the [`keras3`
installation
reference](https://keras3.posit.co/reference/install_keras.html) for
current setup instructions.

Python compatibility changes over time so consult the current
[TensorFlow installation guide](https://www.tensorflow.org/install/pip)
before selecting a different Python version.

Once verification succeeds, continue with [Classify landscapes with
pixels](https://ecomods.github.io/patternscaper/articles/classify-pixels.md).
