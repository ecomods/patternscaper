#' Train a Convolutional Neural Network for Landscape Classification
#'
#' Trains a CNN model using the Keras framework to classify landscapes based on their
#' spatial patterns. The function uses a multiscale CNN architecture optimized for
#' distinguishing different landscape patterns.
#'
#' @param landscapes List. List of landscapes or landscape objects with metadata.
#' @param cv_method Character. Cross-validation method: "none", "k-fold" (default: "k-fold").
#' @param cv_folds Integer. Number of cross-validation folds when cv_method="k-fold" (default: 5).
#' @param epochs Integer. Number of training epochs (default: 20).
#' @param batch_size Integer. Batch size for training (default: 16).
#' @param validation_split Numeric. Proportion of data to use for validation when cv_method="none" (default: 0.2).
#' @param learning_rate Numeric. Learning rate for Adam optimizer (default: 0.001).
#' @param save_model Logical. Whether to save the model (default: FALSE).
#' @param model_path Character. Path to save model (default: NULL).
#' @param seed Integer. Random seed for reproducibility (default: 123).
#'
#' @return List. Trained CNN model and associated metadata.
#' @export
train_nn_keras <- function(
    landscapes,
    cv_method = "k-fold",
    cv_folds = 5,
    epochs = 20,
    batch_size = 16,
    validation_split = 0.2,
    learning_rate = 0.001,
    save_model = FALSE,
    model_path = NULL,
    seed = 123) {
  # Load required libraries
  requireNamespace("keras", quietly = TRUE)
  requireNamespace("reticulate", quietly = TRUE)
  requireNamespace("terra", quietly = TRUE)
  requireNamespace("abind", quietly = TRUE)
  requireNamespace("caret", quietly = TRUE)

  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold")) {
    stop('cv_method must be one of: "none" or "k-fold"')
  }

  # Set random seed for reproducibility
  set.seed(seed)

  # Extract labels and landscapes
  training_labels <- purrr::map_chr(landscapes, ~ .x$type)
  training_plots <- purrr::map(landscapes, ~ .x$landscape)

  # Convert all landscapes to arrays
  training_arrays <- lapply(training_plots, function(r) {
    terra::as.array(r)
  })

  # Show distribution of landscape types
  cat("Landscape type distribution:\n")
  print(table(training_labels))

  # Get the unique class names
  class_names <- sort(unique(training_labels))
  n_classes <- length(class_names)

  # Convert labels to integers and one-hot encode
  y_int <- as.integer(factor(training_labels, levels = class_names)) - 1
  y_data <- keras::to_categorical(y_int)

  # Stack all arrays into one 4D array (samples, height, width, channels)
  x_data <- abind::abind(training_arrays, along = 0)
  input_shape <- c(dim(x_data)[2], dim(x_data)[3], dim(x_data)[4])

  # Function to create the multiscale CNN architecture
  create_model <- function() {
    model <- keras::keras_model_sequential() %>%
      # Detect fine details with small kernels
      keras::layer_conv_2d(
        filters = 32, kernel_size = c(3, 3), padding = "same",
        input_shape = input_shape
      ) %>%
      keras::layer_activation("relu") %>%
      # Detect larger patterns with bigger kernels
      keras::layer_conv_2d(filters = 32, kernel_size = c(5, 5), padding = "same") %>%
      keras::layer_activation("relu") %>%
      keras::layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      # Additional feature extraction
      keras::layer_conv_2d(filters = 64, kernel_size = c(3, 3), padding = "same") %>%
      keras::layer_activation("relu") %>%
      keras::layer_conv_2d(filters = 64, kernel_size = c(5, 5), padding = "same") %>%
      keras::layer_activation("relu") %>%
      keras::layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      # Classifier
      keras::layer_flatten() %>%
      keras::layer_dropout(rate = 0.3) %>%
      keras::layer_dense(units = 128, activation = "relu") %>%
      keras::layer_dense(units = n_classes, activation = "softmax")

    # Compile model
    model %>% keras::compile(
      loss = "categorical_crossentropy",
      optimizer = keras::optimizer_adam(learning_rate = learning_rate),
      metrics = c("accuracy")
    )

    return(model)
  }

  # Initialize performance metrics storage
  performance <- NULL

  # If using cross-validation
  if (cv_method == "k-fold") {
    # Results storage
    fold_results <- list()
    all_predictions <- list()
    all_true_labels <- list()

    # Create stratified folds
    fold_indices <- caret::createFolds(y_int, k = cv_folds, list = TRUE, returnTrain = FALSE)

    cat("\n--- Starting", cv_folds, "fold cross-validation ---\n")

    for (fold in 1:cv_folds) {
      cat("Fold", fold, "of", cv_folds, "\n")

      # Split data into training and validation
      val_indices <- fold_indices[[fold]]
      train_indices <- setdiff(1:length(y_int), val_indices)

      x_train <- x_data[train_indices, , , , drop = FALSE]
      y_train <- y_data[train_indices, , drop = FALSE]
      x_val <- x_data[val_indices, , , , drop = FALSE]
      y_val <- y_data[val_indices, , drop = FALSE]
      y_val_int <- y_int[val_indices]

      # Create and train the model
      model <- create_model()

      history <- model %>% keras::fit(
        x = x_train,
        y = y_train,
        epochs = epochs,
        batch_size = batch_size,
        validation_data = list(x_val, y_val),
        verbose = 1
      )

      # Evaluate the model
      evaluation <- model %>% keras::evaluate(x_val, y_val)

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

    cat("\nCross-Validation Results:\n")
    cat("Mean accuracy:", mean(accuracies), "±", sd(accuracies), "\n")
    cat("Mean loss:", mean(losses), "±", sd(losses), "\n\n")

    cat("Overall Confusion Matrix:\n")
    print(overall_confusion)
    cat("\n")

    # Calculate per-class metrics
    class_counts <- table(factor(training_labels, levels = class_names))
    class_recall <- diag(overall_confusion) / colSums(overall_confusion)
    class_precision <- diag(overall_confusion) / rowSums(overall_confusion)

    # Handle divisions by zero
    class_precision[is.na(class_precision)] <- 0
    class_recall[is.na(class_recall)] <- 0

    # F1 score
    class_f1 <- 2 *
      class_precision *
      class_recall /
      (class_precision + class_recall)
    class_f1[is.na(class_f1)] <- 0

    performance <- list(
      confusion_matrix = overall_confusion,
      accuracy = mean(accuracies),
      sd_accuracy = sd(accuracies),
      mean_loss = mean(losses),
      sd_loss = sd(losses),
      class_precision = class_precision,
      class_recall = class_recall,
      class_f1 = class_f1,
      cv_method = cv_method,
      cv_folds = cv_folds,
      class_counts = as.vector(class_counts)
    )

    # Print per-class performance summary
    cat("\nPer-class performance:\n")
    per_class_metrics <- data.frame(
      Class = class_names,
      Count = as.vector(class_counts),
      Recall = round(class_recall, 2),
      Precision = round(class_precision, 2),
      F1_Score = round(class_f1, 2)
    )
    print(per_class_metrics)

    # Build final model with all data
    final_model <- create_model()
    history <- final_model %>% keras::fit(
      x = x_data,
      y = y_data,
      epochs = epochs,
      batch_size = batch_size,
      validation_split = validation_split,
      verbose = 1
    )
  } else {
    # Train on all data with validation split (no cross-validation)
    final_model <- create_model()
    history <- final_model %>% keras::fit(
      x = x_data,
      y = y_data,
      epochs = epochs,
      batch_size = batch_size,
      validation_split = validation_split,
      verbose = 1
    )

    # Evaluate on validation set
    val_indices <- sample(1:nrow(x_data),
      size = floor(nrow(x_data) * validation_split)
    )
    val_evaluation <- final_model %>% keras::evaluate(
      x_data[val_indices, , , , drop = FALSE],
      y_data[val_indices, , drop = FALSE]
    )

    cat("\nTraining Results (with validation split):\n")
    cat("Validation accuracy:", val_evaluation[["accuracy"]], "\n")
    cat("Validation loss:", val_evaluation[["loss"]], "\n")

    # Create simple performance metrics
    performance <- list(
      accuracy = val_evaluation[["accuracy"]],
      loss = val_evaluation[["loss"]],
      cv_method = "none",
      validation_split = validation_split
    )
  }

  # Prepare return object
  result <- list(
    model = final_model,
    history = history,
    classes = class_names,
    input_shape = input_shape,
    performance = performance,
    architecture = "multiscale"
  )

  # Save model if requested
  if (save_model && !is.null(model_path)) {
    # check if the model path ends with .keras. Otherwise replace/add .keras file
    # ending and warn the user
    keras_file_ending <- stringr::str.detect(model_path, "\\.keras$")

    if (!keras_file_ending) {
      warning(
        "model_path should end with .keras, while current name is: ",
        model_path, ". Automatically adding .keras file ending."
      )
      model_path <- paste0(model_path, ".keras")
    }

    keras::save_model_tf(final_model, model_path)
    # Save metadata separately
    metadata_path <- gsub("\\.keras$", "_metadata.rds", model_path)
    if (model_path == metadata_path) {
      metadata_path <- paste0(model_path, "_metadata.rds")
    }
    metadata <- result
    metadata$model <- NULL # Remove model from metadata to avoid duplication
    readr::write_rds(metadata, metadata_path)
  }

  return(result)
}

#' Apply a Keras CNN Model for Landscape Classification
#'
#' Applies a trained CNN model to classify new landscapes based on their
#' spatial patterns.
#'
#' @param landscape SpatRaster, matrix, or list. Landscape(s) to classify.
#'   Can be a single landscape or list of landscapes, with or without metadata.
#' @param nn_model List. CNN model from train_nn_keras().
#' @param confidence_threshold Numeric. Threshold for warning flag (default: 0.6).
#' @param show_progress Logical. Whether to display progress bar for multiple landscapes (default: TRUE).
#'
#' @return tibble. Classification results with columns for landscape name,
#'   predicted class, confidence score, warning flag, and probability for each class.
#' @export
apply_nn_keras <- function(
    landscape,
    nn_model,
    confidence_threshold = 0.6,
    show_progress = TRUE) {
  # Validate inputs
  if (is.null(nn_model)) {
    stop("CNN model is required")
  }

  # Validate confidence threshold
  if (
    !is.numeric(confidence_threshold) ||
      confidence_threshold < 0 ||
      confidence_threshold > 1
  ) {
    stop("confidence_threshold must be a numeric value between 0 and 1")
  }

  # Extract required elements from the model
  model <- nn_model$model
  class_names <- nn_model$classes
  input_shape <- nn_model$input_shape

  # Initialize results list
  results_list <- list()

  # Helper function to extract landscape data from metadata structure
  extract_landscape_data <- function(landscape_obj) {
    if (has_landscape_metadata(landscape_obj)) {
      return(get_landscape(landscape_obj))
    } else {
      return(landscape_obj)
    }
  }

  # Helper function to extract landscape name from metadata structure
  extract_landscape_name <- function(landscape_obj, default_name) {
    if (has_landscape_metadata(landscape_obj)) {
      # Try to get type as name
      type_name <- get_landscape_type(landscape_obj)
      if (!is.null(type_name) && !is.na(type_name)) {
        return(type_name)
      }

      # Try to get landscape name
      landscape_data <- get_landscape(landscape_obj)
      if (!is.null(attr(landscape_data, "name"))) {
        return(attr(landscape_data, "name"))
      }
    }
    return(default_name)
  }

  # Process a single landscape function
  process_one_landscape <- function(one_landscape, landscape_name) {
    # Extract landscape data if it has metadata
    raster_landscape <- extract_landscape_data(one_landscape)

    # Ensure we have a SpatRaster
    raster_landscape <- ensure_spatraster(raster_landscape)

    # Convert to array for keras prediction
    landscape_array <- terra::as.array(raster_landscape)

    # Check if dimensions match expected input
    if (any(dim(landscape_array)[1:2] != input_shape[1:2])) {
      warning(sprintf(
        "Landscape '%s' dimensions (%d x %d) don't match model input (%d x %d). Resizing.",
        landscape_name,
        dim(landscape_array)[1],
        dim(landscape_array)[2],
        input_shape[1],
        input_shape[2]
      ))

      # Resize to match expected dimensions
      # Using terra to resample
      raster_landscape <- terra::resample(
        raster_landscape,
        terra::rast(
          nrows = input_shape[1],
          ncols = input_shape[2],
          extent = terra::ext(raster_landscape)
        )
      )
      landscape_array <- terra::as.array(raster_landscape)
    }

    # Add batch dimension required for keras predictions
    landscape_batch <- array(
      landscape_array,
      dim = c(1, dim(landscape_array))
    )

    # Make predictions
    predictions <- model %>% predict(landscape_batch)

    # Get the class with the highest probability
    predicted_index <- which.max(predictions[1, ])
    predicted_class <- class_names[predicted_index]

    # Get the confidence (probability) for the predicted class
    confidence <- predictions[1, predicted_index]

    # Create warning flag if confidence is below threshold
    warning_message <- NA
    if (confidence < confidence_threshold) {
      warning_message <- "Low classification confidence"
    }

    # Create row with results
    result_row <- data.frame(
      landscape_name = landscape_name,
      predicted_class = predicted_class,
      confidence = confidence,
      warning = warning_message
    )

    # Add probability for each class
    for (i in seq_along(class_names)) {
      result_row[[class_names[i]]] <- predictions[1, i]
    }

    return(result_row)
  }

  # Check if input is a list that's not a SpatRaster
  if (is.list(landscape) && !inherits(landscape, "SpatRaster")) {
    # Check if this is a single landscape with metadata
    if (has_landscape_metadata(landscape)) {
      # Process as a single landscape with metadata
      landscape_name <- extract_landscape_name(landscape, "landscape_1")
      results_list[[1]] <- process_one_landscape(landscape, landscape_name)
    } else {
      # Process multiple landscapes
      if (show_progress && length(landscape) > 1) {
        pb <- utils::txtProgressBar(min = 0, max = length(landscape), style = 3)
      }

      for (i in seq_along(landscape)) {
        current_landscape <- landscape[[i]]

        # Determine landscape name
        default_name <- names(landscape)[i]
        if (is.null(default_name) || default_name == "") {
          default_name <- paste0("landscape_", i)
        }

        landscape_name <- extract_landscape_name(
          current_landscape,
          default_name
        )

        # Process this landscape
        results_list[[i]] <- process_one_landscape(
          current_landscape,
          landscape_name
        )

        if (show_progress && length(landscape) > 1) {
          utils::setTxtProgressBar(pb, i)
        }
      }

      if (show_progress && length(landscape) > 1) {
        close(pb)
      }
    }
  } else {
    # Process a single landscape
    landscape_name <- extract_landscape_name(landscape, "landscape_1")
    results_list[[1]] <- process_one_landscape(landscape, landscape_name)
  }

  # Combine all results into a single tibble
  final_results <- do.call(rbind, results_list)

  # Convert to tibble for cleaner output
  final_results <- tibble::as_tibble(final_results)

  return(final_results)
}
