prewarm_keras <- function() {
  cat("Initializing keras3/TensorFlow backend...\n")

  start_time <- Sys.time()

  # The simplest operation that triggers TensorFlow initialization
  invisible(keras3::to_categorical(0))

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  cat(sprintf("✓ Backend ready (%.1f seconds)\n", elapsed))
  invisible(TRUE)
}

# Option to reduce TensorFlow logging (makes it feel faster)
prewarm_keras_quiet <- function() {
  # Suppress TensorFlow initialization messages
  old_log <- Sys.getenv("TF_CPP_MIN_LOG_LEVEL")
  Sys.setenv(TF_CPP_MIN_LOG_LEVEL = "3")

  invisible(keras3::to_categorical(0))

  # Restore logging
  if (old_log == "") {
    Sys.unsetenv("TF_CPP_MIN_LOG_LEVEL")
  } else {
    Sys.setenv(TF_CPP_MIN_LOG_LEVEL = old_log)
  }

  invisible(TRUE)
}

# Alternative: Use JAX backend (faster initialization)
# Set before loading keras3:
# Sys.setenv(KERAS_BACKEND = "jax")
# library(keras3)

library(keras3)
prewarm_keras()
