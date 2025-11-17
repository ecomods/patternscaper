#------------------------------------------------------------------------------#
# Landscape Classification using Convolutional Neural Networks
# This script implements a comprehensive workflow for training and evaluating
# CNN models for classifying different types of landscape patterns
#------------------------------------------------------------------------------#

# Setup and Environment -------------------------------------------------------
library(reticulate)
library(keras3)
library(terra)
library(tidyverse)
library(purrr)
library(abind)
library(caret) # For confusion matrix
library(ggplot2)

# Load the ecotoneClassifyR package
devtools::load_all()

# Use TensorFlow environment
use_virtualenv("r-tensorflow", required = TRUE)

# Set random seed for reproducibility
set.seed(42)

#------------------------------------------------------------------------------#
# Generate Landscape Training Data
#------------------------------------------------------------------------------#
# Increase number of landscapes for better training
training_landscapes <- generate_training_landscapes(
  n = 500, # Larger dataset for better generalization
  types = c(
    "sharp",
    "diffuse",
    "curvy",
    "fingers",
    "clustered",
    "sine_bands"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE,
  rotation_angles = c(0, 45, 90, 135, 180)
)

# Extract labels and landscape arrays
training_labels <- map_chr(training_landscapes, ~ .x$type)
training_plots <- map(training_landscapes, ~ .x$landscape)

# Convert all landscapes to arrays
training_arrays <- lapply(training_plots, function(r) {
  terra::as.array(r)
})

# Show distribution of landscape types
cat("Landscape type distribution:\n")
print(table(training_labels))

#------------------------------------------------------------------------------#
# Data Preparation
#------------------------------------------------------------------------------#

# Get the unique class names
class_names <- sort(unique(training_labels))
n_classes <- length(class_names)

# Convert labels to integers and one-hot encode
y_int <- as.integer(factor(training_labels, levels = class_names)) - 1
# convert to a binary class matrix
# 7 columns because we have 7 classes, 1 plot per row, 1 in the column that is
# the correct class, 0 in all other columns
y_data <- to_categorical(y_int)

# Stack all arrays into one 4D array (samples, height, width, channels)
x_data <- abind::abind(training_arrays, along = 0)
input_shape <- c(dim(x_data)[2], dim(x_data)[3], dim(x_data)[4])
cat("Input shape:", paste(input_shape, collapse = "x"), "\n")

#------------------------------------------------------------------------------#
# Model Architecture Definitions
#------------------------------------------------------------------------------#

# Define multiple model architectures to compare
create_model <- function(
  architecture = c("basic", "deeper", "multiscale", "residual")
) {
  architecture <- match.arg(architecture)

  if (architecture == "basic") {
    # Basic CNN architecture (baseline)
    model <- keras_model_sequential() %>%
      layer_conv_2d(
        filters = 32,
        kernel_size = c(3, 3),
        activation = "relu",
        input_shape = input_shape
      ) %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      layer_conv_2d(
        filters = 64,
        kernel_size = c(3, 3),
        activation = "relu"
      ) %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      layer_flatten() %>%
      layer_dense(units = 128, activation = "relu") %>%
      layer_dropout(0.3) %>%
      layer_dense(units = n_classes, activation = "softmax")
  } else if (architecture == "deeper") {
    # Deeper architecture with batch normalization
    model <- keras_model_sequential() %>%
      layer_conv_2d(
        filters = 64,
        kernel_size = c(3, 3),
        padding = "same",
        input_shape = input_shape
      ) %>%
      layer_batch_normalization() %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      layer_conv_2d(filters = 128, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization() %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      layer_conv_2d(filters = 256, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization() %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      layer_flatten() %>%
      layer_dropout(rate = 0.3) %>%
      layer_dense(units = 256, activation = "relu") %>%
      layer_dropout(rate = 0.3) %>%
      layer_dense(units = n_classes, activation = "softmax")
  } else if (architecture == "multiscale") {
    # Multi-scale architecture with different kernel sizes
    model <- keras_model_sequential() %>%
      # Detect fine details with small kernels
      layer_conv_2d(
        filters = 32,
        kernel_size = c(3, 3),
        padding = "same",
        input_shape = input_shape
      ) %>%
      layer_activation("relu") %>%
      # Detect larger patterns with bigger kernels
      layer_conv_2d(filters = 32, kernel_size = c(5, 5), padding = "same") %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      # Additional feature extraction
      layer_conv_2d(filters = 64, kernel_size = c(3, 3), padding = "same") %>%
      layer_activation("relu") %>%
      layer_conv_2d(filters = 64, kernel_size = c(5, 5), padding = "same") %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      # Classifier
      layer_flatten() %>%
      layer_dropout(rate = 0.3) %>%
      layer_dense(units = 128, activation = "relu") %>%
      layer_dense(units = n_classes, activation = "softmax")
  } else if (architecture == "residual") {
    # Residual connections (skip connections) for better feature learning
    inputs <- layer_input(shape = input_shape)

    # First convolutional block
    x <- inputs %>%
      layer_conv_2d(filters = 32, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization() %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2))

    # First residual block
    input_res1 <- x
    x <- x %>%
      layer_conv_2d(filters = 32, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization() %>%
      layer_activation("relu") %>%
      layer_conv_2d(filters = 32, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization()

    x <- layer_add(list(x, input_res1)) %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2))

    # Second residual block
    input_res2 <- layer_conv_2d(filters = 64, kernel_size = c(1, 1))(x)
    x <- x %>%
      layer_conv_2d(filters = 64, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization() %>%
      layer_activation("relu") %>%
      layer_conv_2d(filters = 64, kernel_size = c(3, 3), padding = "same") %>%
      layer_batch_normalization()

    x <- layer_add(list(x, input_res2)) %>%
      layer_activation("relu") %>%
      layer_max_pooling_2d(pool_size = c(2, 2))

    # Classifier
    x <- x %>%
      layer_flatten() %>%
      layer_dropout(rate = 0.3) %>%
      layer_dense(units = 128, activation = "relu") %>%
      layer_dense(units = n_classes, activation = "softmax")

    model <- keras_model(inputs = inputs, outputs = x)
  }

  # Compile model
  model %>%
    compile(
      loss = "categorical_crossentropy",
      optimizer = optimizer_adam(learning_rate = 0.001),
      metrics = c("accuracy")
    )

  return(model)
}

#------------------------------------------------------------------------------#
# Cross-Validation Implementation
#------------------------------------------------------------------------------#

# K-fold cross validation function
run_cross_validation <- function(
  architecture = "basic",
  k_folds = 5,
  epochs = 20,
  batch_size = 16
) {
  # Results storage
  fold_results <- list()
  all_predictions <- list()
  all_true_labels <- list()

  # Create folds
  fold_indices <- createFolds(
    y_int,
    k = k_folds,
    list = TRUE,
    returnTrain = FALSE
  )

  cat(
    "\n--- Starting",
    k_folds,
    "fold cross-validation for",
    architecture,
    "model ---\n"
  )

  for (fold in 1:k_folds) {
    cat("Fold", fold, "of", k_folds, "\n")

    # Split data into training and validation
    val_indices <- fold_indices[[fold]]
    train_indices <- setdiff(1:length(y_int), val_indices)

    x_train <- x_data[train_indices, , , , drop = FALSE]
    y_train <- y_data[train_indices, , drop = FALSE]
    x_val <- x_data[val_indices, , , , drop = FALSE]
    y_val <- y_data[val_indices, , drop = FALSE]
    y_val_int <- y_int[val_indices]

    # Create and train the model
    model <- create_model(architecture)

    history <- model %>%
      fit(
        x = x_train,
        y = y_train,
        epochs = epochs,
        batch_size = batch_size,
        validation_data = list(x_val, y_val),
        verbose = 1
      )

    # Evaluate the model
    evaluation <- model %>% evaluate(x_val, y_val)

    # Store predictions
    predictions <- model %>% predict(x_val)
    pred_classes <- apply(predictions, 1, which.max) - 1

    # Store results for this fold
    fold_results[[fold]] <- list(
      evaluation = evaluation,
      history = history,
      confusion = table(
        Predicted = class_names[pred_classes + 1],
        Actual = class_names[y_val_int + 1]
      )
    )

    all_predictions[[fold]] <- pred_classes
    all_true_labels[[fold]] <- y_val_int

    cat("Fold", fold, "accuracy:", evaluation[["accuracy"]], "\n")
  }

  # Combine predictions from all folds
  all_preds <- unlist(all_predictions)
  all_trues <- unlist(all_true_labels)

  # Overall confusion matrix
  overall_confusion <- table(
    Predicted = class_names[all_preds + 1],
    Actual = class_names[all_trues + 1]
  )

  # Calculate average accuracy and loss across folds
  accuracies <- sapply(fold_results, function(x) x$evaluation[["accuracy"]])
  losses <- sapply(fold_results, function(x) x$evaluation[["loss"]])

  cat("\nCross-Validation Results for", architecture, "model:\n")
  cat("Mean accuracy:", mean(accuracies), "±", sd(accuracies), "\n")
  cat("Mean loss:", mean(losses), "±", sd(losses), "\n\n")

  cat("Overall Confusion Matrix:\n")
  print(overall_confusion)
  cat("\n")

  # Return all results
  return(list(
    fold_results = fold_results,
    mean_accuracy = mean(accuracies),
    sd_accuracy = sd(accuracies),
    mean_loss = mean(losses),
    sd_loss = sd(losses),
    overall_confusion = overall_confusion,
    architecture = architecture
  ))
}

#------------------------------------------------------------------------------#
# Run Models and Compare
#------------------------------------------------------------------------------#

# Run cross-validation for each architecture
results <- list()

# List of architectures to try
architectures <- c("basic", "deeper", "multiscale", "residual")
architectures <- "basic"

for (arch in architectures) {
  cat("\nTraining", arch, "model\n")
  results[[arch]] <- run_cross_validation(
    architecture = arch,
    k_folds = 5,
    epochs = 20,
    batch_size = 16
  )
}

#------------------------------------------------------------------------------#
# Results Visualization
#------------------------------------------------------------------------------#

# Compare model accuracies
accuracy_data <- data.frame(
  Architecture = names(results),
  Accuracy = sapply(results, function(x) x$mean_accuracy),
  SD = sapply(results, function(x) x$sd_accuracy)
)

# Print accuracy comparison
cat("\nAccuracy Comparison:\n")
print(accuracy_data)

# Plot accuracy comparison
ggplot(accuracy_data, aes(x = Architecture, y = Accuracy)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_errorbar(aes(ymin = Accuracy - SD, ymax = Accuracy + SD), width = 0.2) +
  theme_minimal() +
  labs(
    title = "Model Architecture Comparison",
    subtitle = "Mean accuracy across 5-fold cross-validation",
    x = "Model Architecture",
    y = "Accuracy"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Find best performing model
best_arch <- accuracy_data$Architecture[which.max(accuracy_data$Accuracy)]
cat("\nBest performing architecture:", best_arch, "\n")

# Plot confusion matrix for best model
best_confusion <- results[[best_arch]]$overall_confusion
conf_matrix_df <- as.data.frame.table(best_confusion)
names(conf_matrix_df) <- c("Predicted", "Actual", "Count")

# Create a heatmap of the confusion matrix
ggplot(conf_matrix_df, aes(x = Actual, y = Predicted, fill = Count)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "steelblue") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    title = paste("Confusion Matrix -", best_arch, "model"),
    x = "Actual Class",
    y = "Predicted Class"
  )

#------------------------------------------------------------------------------#
# Train Final Model and Save
#------------------------------------------------------------------------------#

# Train final model on all data using the best architecture
cat("\nTraining final model with", best_arch, "architecture on all data...\n")

final_model <- create_model(best_arch)

history <- final_model %>%
  fit(
    x = x_data,
    y = y_data,
    epochs = 30, # More epochs for final model
    batch_size = 16,
    validation_split = 0.2
  )

# Plot training history
plot(history)

# Save the model
model_filename <- paste0(
  "landscape_classifier_",
  best_arch,
  "_",
  format(Sys.time(), "%Y%m%d"),
  ".h5"
)
save_model_hdf5(final_model, model_filename)
cat("Model saved as:", model_filename, "\n")

#------------------------------------------------------------------------------#
# Test Model on New Landscapes (optional)
#------------------------------------------------------------------------------#

# Generate a small set of test landscapes
test_landscapes <- generate_training_landscapes(
  n = 50,
  add_rotation = TRUE
)

# Extract test labels and convert to arrays
test_labels <- map_chr(test_landscapes, ~ .x$type)
test_plots <- map(test_landscapes, ~ .x$landscape)
test_arrays <- lapply(test_plots, function(r) terra::as.array(r))
x_test <- abind::abind(test_arrays, along = 0)

# Predict on test data
test_predictions <- final_model %>% predict(x_test)
pred_class_indices <- apply(test_predictions, 1, which.max) - 1
predicted_classes <- class_names[pred_class_indices + 1]

# Create confusion matrix
test_conf_matrix <- table(Predicted = predicted_classes, Actual = test_labels)
cat("\nTest Data Confusion Matrix:\n")
print(test_conf_matrix)

# Calculate test accuracy
test_accuracy <- sum(diag(test_conf_matrix)) / sum(test_conf_matrix)
cat("\nTest Accuracy:", test_accuracy, "\n")

# Display sample predictions with visual confirmation
cat("\nGenerating visual prediction samples...\n")

# Randomly select some test samples to visualize
sample_indices <- sample(1:length(test_labels), min(10, length(test_labels)))

# Create titles for plots with predicted and actual labels
predicted_titles <- ifelse(
  predicted_classes[sample_indices] == test_labels[sample_indices],
  paste0(
    "<span style='color:forestgreen'>",
    predicted_classes[sample_indices],
    "</span>"
  ),
  paste0(
    "<span style='color:red'>",
    predicted_classes[sample_indices],
    "</span>"
  )
)

titles <- paste0(test_labels[sample_indices], "<br>", predicted_titles)

# Plot the landscapes with their predicted classes
plot_validation <- test_plots[sample_indices] |>
  plot_landscape_list(titles = titles)
print(plot_validation)

cat("\nLandscape classification complete!\n")
