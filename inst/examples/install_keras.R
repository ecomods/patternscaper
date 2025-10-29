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
# Step 2: Install keras3 (handles Python automatically)
# =============================================================================

cat("\n=== Step 2: Installing keras3 ===\n")

# Check if already installed
keras_env_path <- file.path(
  rappdirs::user_data_dir("r-keras"),
  "python.exe" # .exe for Windows, remove for Unix
)

if (file.exists(keras_env_path)) {
  cat("✓ keras3 virtual environment already exists\n")
  cat("  Location:", keras_env_path, "\n")
  cat("  Skipping installation\n")
} else {
  cat("Installing keras3 with TensorFlow backend...\n")
  cat("This will install Python 3.10 in a virtual environment if needed\n")
  cat("This may take 5-15 minutes...\n\n")

  tryCatch(
    {
      install_keras()
      cat("\n✓ Installation complete!\n")
    },
    error = function(e) {
      stop("Installation failed: ", conditionMessage(e))
    }
  )
}

# =============================================================================
# Step 3: Verify Installation
# =============================================================================

cat("\n=== Step 3: Verifying installation ===\n")

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
# Step 4: Final Configuration
# =============================================================================

cat("\n=== Step 4: Final setup ===\n")

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
