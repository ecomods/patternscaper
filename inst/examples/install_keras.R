#' Complete Installation Guide for ecotoneClassifyR with keras3
#'
#' This script guides you through installing Python, TensorFlow, and keras3
#' from scratch. Run each section in order.

# =============================================================================
# Step 1: Install Required R Packages
# =============================================================================

cat("=== Step 1: Installing R packages ===\n")

# Core packages needed
required_packages <- c(
  "reticulate", # R-Python interface
  "keras3" # Keras 3 for R
)

# Install any missing packages
new_packages <- required_packages[
  !(required_packages %in% installed.packages()[, "Package"])
]
if (length(new_packages) > 0) {
  cat("Installing:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages)
} else {
  cat("✓ All required R packages already installed\n")
}

library(reticulate)
library(keras3)

# =============================================================================
# Step 2: Check Python Installation
# =============================================================================

cat("\n=== Step 2: Checking Python ===\n")

# Check if Python is available
python_available <- !inherits(try(py_config(), silent = TRUE), "try-error")

if (python_available) {
  config <- py_config()
  cat("✓ Python found:\n")
  cat("  Version:", config$version, "\n")
  cat("  Path:", config$python, "\n")

  # Check Python version
  py_version <- as.numeric(paste0(
    config$version_major,
    ".",
    config$version_minor
  ))

  if (py_version < 3.9) {
    cat("⚠ Warning: Python version is too old (need >= 3.9)\n")
    cat("  Recommendation: Install Python 3.9, 3.10, or 3.11\n")
    needs_python <- TRUE
  } else if (py_version > 3.11) {
    cat(
      "⚠ Warning: Python version may be too new (keras3 works best with 3.9-3.11)\n"
    )
    cat(
      "  You can try to continue, but may need to install Python 3.10 or 3.11\n"
    )
    needs_python <- FALSE
  } else {
    cat("✓ Python version is compatible\n")
    needs_python <- FALSE
  }
} else {
  cat("✗ No Python installation detected\n")
  needs_python <- TRUE
}

# =============================================================================
# Step 3: Install Python (if needed)
# =============================================================================

if (needs_python) {
  cat("\n=== Step 3: Installing Python ===\n")
  cat("Installing Python 3.10 (recommended for keras3)...\n")
  cat("This may take several minutes...\n\n")

  tryCatch(
    {
      # Install Python 3.10 using reticulate
      install_python(version = "3.10:latest")
      cat("✓ Python 3.10 installed successfully\n")
    },
    error = function(e) {
      cat("✗ Automatic Python installation failed\n")
      cat("\nManual installation required:\n")
      cat(
        "1. Download Python 3.10 or 3.11 from: https://www.python.org/downloads/\n"
      )
      cat("2. During installation, check 'Add Python to PATH'\n")
      cat("3. Restart R/RStudio after installation\n")
      cat("4. Run this script again\n\n")
      stop("Please install Python manually and restart R")
    }
  )
} else {
  cat("\n=== Step 3: Python check ===\n")
  cat("✓ Python installation is adequate\n")
}

# =============================================================================
# Step 4: Install TensorFlow and keras3
# =============================================================================

cat("\n=== Step 4: Installing TensorFlow backend ===\n")
cat("This creates a Python virtual environment with TensorFlow...\n")
cat("This may take 5-15 minutes depending on your internet connection.\n\n")

# Check if keras is already installed
keras_installed <- py_module_available("keras")

if (!keras_installed) {
  cat("Installing keras3 with TensorFlow backend...\n")

  tryCatch(
    {
      # Install keras with TensorFlow
      # This creates a virtual environment at ~/.virtualenvs/r-keras
      install_keras()

      cat("\n✓ keras3 and TensorFlow installed successfully!\n")
    },
    error = function(e) {
      cat("\n✗ Installation failed with error:\n")
      cat(conditionMessage(e), "\n\n")
      cat("Troubleshooting steps:\n")
      cat("1. Ensure you have a stable internet connection\n")
      cat("2. Try running: keras3::install_keras()\n")
      cat("3. If that fails, try: keras3::install_keras(method = 'conda')\n")
      cat("4. Check for firewall/antivirus blocking Python installations\n")
      stop("keras3 installation failed")
    }
  )
} else {
  cat("✓ keras/TensorFlow already installed\n")
}

# =============================================================================
# Step 5: Verify Installation
# =============================================================================

cat("\n=== Step 5: Verifying installation ===\n")

# Check backend
tryCatch(
  {
    backend_name <- backend()
    cat("✓ Keras backend:", backend_name, "\n")
  },
  error = function(e) {
    cat("✗ Could not load keras backend\n")
    stop("Installation verification failed")
  }
)

# Check TensorFlow availability
tf_available <- py_module_available("tensorflow")
if (tf_available) {
  cat("✓ TensorFlow is available\n")
} else {
  cat("✗ TensorFlow not found\n")
  stop("TensorFlow installation failed")
}

# Test basic keras functionality
cat("\nTesting keras3 functionality...\n")
cat("(This first operation may take 10-30 seconds to initialize TensorFlow)\n")

test_start <- Sys.time()
tryCatch(
  {
    test_array <- to_categorical(c(0, 1, 2), num_classes = 3)
    test_end <- Sys.time()

    cat(sprintf(
      "✓ Test successful! (%.1f seconds)\n",
      as.numeric(difftime(test_end, test_start, units = "secs"))
    ))
  },
  error = function(e) {
    cat("✗ keras3 test failed:\n")
    cat(conditionMessage(e), "\n")
    stop("keras3 is not functioning correctly")
  }
)

# =============================================================================
# Step 6: Final Configuration
# =============================================================================

cat("\n=== Step 6: Final setup ===\n")

# Show final configuration
cat("\nYour configuration:\n")
config <- py_config()
cat("  Python:", config$python, "\n")
cat("  Version:", config$version, "\n")
cat("  TensorFlow available:", py_module_available("tensorflow"), "\n")

# Create helper function for future sessions
cat("\nCreating helper function for future sessions...\n")

prewarm_keras <- function() {
  cat("Initializing keras3/TensorFlow backend...\n")
  start_time <- Sys.time()
  invisible(keras3::to_categorical(0))
  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  cat(sprintf("✓ Backend ready (%.1f seconds)\n", elapsed))
  invisible(TRUE)
}

# Test the prewarm function
cat("\nTesting quick initialization (should be fast now)...\n")
test_start2 <- Sys.time()
test_array2 <- to_categorical(c(0, 1))
test_end2 <- Sys.time()
cat(sprintf(
  "✓ Second operation: %.3f seconds (fast!)\n",
  as.numeric(difftime(test_end2, test_start2, units = "secs"))
))

# =============================================================================
# Installation Complete!
# =============================================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("✓ Installation Complete!\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("\n")
cat("You can now use ecotoneClassifyR with keras3.\n")
cat("\n")
cat("For each new R session, run:\n")
cat("  library(keras3)\n")
cat("  prewarm_keras()  # Optional: absorbs 10-30s initialization upfront\n")
cat("\n")
cat("Then proceed with your analysis:\n")
cat("  library(ecotoneClassifyR)\n")
cat("  model <- train_nn_landscapes(...)\n")
cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
