prewarm_keras <- function() {
  cat("Initializing keras3/TensorFlow backend...\n")

  start_time <- Sys.time()

  # The simplest operation that triggers TensorFlow initialization
  # You don't need a full model!
  invisible(to_categorical(0))

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  cat(sprintf("✓ Backend ready (%.1f seconds)\n", elapsed))
  invisible(TRUE)
}

library(keras3)
prewarm_keras()

cv_method = "k-fold"
cv_folds = 5
epochs = 20
batch_size = 16
validation_split = 0.2
learning_rate = 0.001
model_path = NULL
seed = NULL
