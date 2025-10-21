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
#' @param model_path Character. Path to save model (default: NULL means that the
#'     model is not saved).
#' @param seed Integer. Random seed for reproducibility. If NULL, a random seed will be used (default: NULL).
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
  model_path = NULL,
  seed = NULL
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }
  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold")) {
    stop('cv_method must be one of: "none" or "k-fold"')
  }

  # Check if the landscapes have metadata and is a valid structure
  if (all(unlist(lapply(landscapes, has_landscape_metadata)))) {
    # Extract landscapes if they have metadata
    training_plots <- lapply(landscapes, get_landscape)
    training_labels <- sapply(landscapes, get_landscape_type)
  } else {
    stop(
      "All landscapes must have metadata with 'type' and 'landscape' information."
    )
  }

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
        filters = 32,
        kernel_size = c(3, 3),
        padding = "same",
        input_shape = input_shape
      ) %>%
      keras::layer_activation("relu") %>%
      # Detect larger patterns with bigger kernels
      keras::layer_conv_2d(
        filters = 32,
        kernel_size = c(5, 5),
        padding = "same"
      ) %>%
      keras::layer_activation("relu") %>%
      keras::layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      # Additional feature extraction
      keras::layer_conv_2d(
        filters = 64,
        kernel_size = c(3, 3),
        padding = "same"
      ) %>%
      keras::layer_activation("relu") %>%
      keras::layer_conv_2d(
        filters = 64,
        kernel_size = c(5, 5),
        padding = "same"
      ) %>%
      keras::layer_activation("relu") %>%
      keras::layer_max_pooling_2d(pool_size = c(2, 2)) %>%
      # Classifier
      keras::layer_flatten() %>%
      keras::layer_dropout(rate = 0.3) %>%
      keras::layer_dense(units = 128, activation = "relu") %>%
      keras::layer_dense(units = n_classes, activation = "softmax")

    # Compile model
    model %>%
      keras::compile(
        loss = "categorical_crossentropy",
        optimizer = keras::optimizer_adam(learning_rate = learning_rate),
        metrics = c("accuracy")
      )

    return(model)
  }

  # Initialize performance metrics storage
  performance <- NULL

  # Check cross-validation method and parameters -------------------------------
  if (cv_method != "none") {
    # Adjust CV method based on dataset characteristics
    if (cv_method == "k-fold") {
      # Adjust the number of folds if necessary
      class_counts <- table(training_labels)
      min_class_count <- min(class_counts)
      total_samples <- length(training_labels)

      # Minimum recommended samples per class per fold for neural networks
      min_samples_per_fold <- 3
      # First, check if the dataset is fundamentally too small for k-fold
      if (total_samples < 30 || min_class_count < 5) {
        warning(
          "Dataset is small (n=",
          total_samples,
          ") or has classes with few samples (min=",
          min_class_count,
          "). Switching to leave-one-out CV for more reliable estimates."
        )
        cv_method <- "loo"
      } else {
        # If dataset is large enough, check if we can maintain enough samples per fold
        # Calculate maximum suitable folds to maintain min_samples_per_fold
        max_suitable_folds <- floor(min_class_count / min_samples_per_fold)

        # If we can't maintain enough samples even with 2 folds
        if (max_suitable_folds < 2) {
          warning(
            "Cannot maintain ",
            min_samples_per_fold,
            " samples per class per fold. Switching to leave-one-out CV."
          )
          cv_method <- "loo"
        } else if (cv_folds > max_suitable_folds) {
          # If we need to reduce folds but can still do k-fold CV
          warning(sprintf(
            "Reducing CV folds from %d to %d to ensure at least %d samples per class per fold.",
            cv_folds,
            max_suitable_folds,
            min_samples_per_fold
          ))
          cv_folds <- max_suitable_folds
        }
        # Otherwise, keep the user-specified fold count
      }
    }
  }

  # If using cross-validation
  if (cv_method == "k-fold") {
    # Results storage
    fold_results <- list()
    cv_probabilities <- list()
    cv_predictions <- list()
    cv_actual <- list()
    cv_indices <- list()

    # Create stratified fold assignments
    # Ensure each landscape type is represented in each fold
    fold_indices <- list()
    for (fold in 1:cv_folds) {
      fold_indices[[fold]] <- integer(0)
    }

    # Distribute indices for each landscape type across folds
    for (class_name in class_names) {
      # Get indices of samples for this landscape type
      class_indices <- which(training_labels == class_name)

      # Distribute these indices evenly across folds
      class_folds <- sample(rep(1:cv_folds, length.out = length(class_indices)))

      # Add indices to appropriate fold lists
      for (fold in 1:cv_folds) {
        fold_indices[[fold]] <- c(
          fold_indices[[fold]],
          class_indices[class_folds == fold]
        )
      }
    }

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

      history <- model %>%
        keras::fit(
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
      probs <- model %>% predict(x_val)
      pred_classes <- apply(probs, 1, which.max) - 1

      cv_predictions[[fold]] <- class_names[pred_classes + 1]
      cv_actual[[fold]] <- class_names[y_val_int + 1]
      cv_probabilities[[fold]] <- probs
      cv_indices[[fold]] <- val_indices

      # Store results for this fold
      fold_results[[fold]] <- list(
        evaluation = evaluation
      )

      cat("Fold", fold, "accuracy:", evaluation[["accuracy"]], "\n")
    }

    # Overall confusion matrix
    overall_confusion <- table(
      Predicted = unlist(cv_predictions),
      Actual = unlist(cv_actual)
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
    history <- final_model %>%
      keras::fit(
        x = x_data,
        y = y_data,
        epochs = epochs,
        batch_size = batch_size,
        verbose = 1
      )
  } else {
    # Train on all data with validation split (no cross-validation)
    final_model <- create_model()
    history <- final_model %>%
      keras::fit(
        x = x_data,
        y = y_data,
        epochs = epochs,
        batch_size = batch_size,
        validation_split = validation_split,
        verbose = 1
      )

    # Evaluate on validation set
    val_indices <- sample(
      1:nrow(x_data),
      size = floor(nrow(x_data) * validation_split)
    )
    val_evaluation <- final_model %>%
      keras::evaluate(
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

  # Assemble validation results into a tibble
  validation_results <- cv_probabilities |>
    purrr::reduce(rbind) |>
    tibble::as_tibble()

  colnames(validation_results) <- class_names

  validation_results <- validation_results |>
    dplyr::mutate(
      landscape_id = unlist(cv_indices),
      actual_class = unlist(cv_actual),
      predicted_class = unlist(cv_predictions),
      confidence = apply(dplyr::across(dplyr::all_of(class_names)), 1, max)
    ) |>
    dplyr::relocate(c(
      landscape_id,
      actual_class,
      predicted_class,
      confidence
    ))

  # Prepare return object
  result <- list(
    model = final_model,
    history = history,
    classes = class_names,
    input_shape = input_shape,
    performance = performance,
    validation_results = validation_results,
    architecture = "multiscale"
  )

  # Save model if requested
  if (!is.null(model_path)) {
    # check if the model path ends with .keras. Otherwise replace/add .keras file
    # ending and warn the user
    keras_file_ending <- stringr::str_detect(model_path, "\\.keras$")

    if (!keras_file_ending) {
      warning(
        "model_path should end with .keras, while current name is: ",
        model_path,
        ". Automatically adding .keras file ending."
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
#' @param landscapes SpatRaster, matrix, or list. Landscape(s) to classify.
#'   Can be a single landscape or list of landscapes, with or without metadata.
#' @param nn_model List. CNN model from train_nn_keras().
#' @param show_progress Logical. Whether to display progress bar for multiple landscapes (default: TRUE).
#'
#' @return tibble. Classification results with columns for landscape name,
#'   predicted class, confidence score, warning flag, and probability for each class.
#' @export
apply_nn_keras <- function(
  landscapes,
  nn_model,
  show_progress = TRUE
) {
  # Extract required elements from the model
  model <- nn_model$model
  class_names <- nn_model$classes
  input_shape <- nn_model$input_shape

  # Initialize results list
  results_list <- list()

  # Extract the landscapes if they are in a list with metadata
  if (all(unlist(lapply(landscapes, has_landscape_metadata)))) {
    # Extract landscapes if they have metadata
    landscape_plots <- lapply(landscapes, get_landscape)
    landscape_type <- sapply(landscapes, get_landscape_type)
  } else {
    landscape_plots <- landscapes
    landscape_type <- paste0("landscape_", seq_along(landscape_plots))
  }

  # Convert all landscapes to arrays
  landscape_arrays <- lapply(landscape_plots, function(r) {
    terra::as.array(r)
  })

  # Stack all arrays into one 4D array (samples, height, width, channels)
  landscape_data <- abind::abind(landscape_arrays, along = 0)

  predictions <- predict(model, landscape_data)

  # Add classes as column names
  colnames(predictions) <- class_names

  # Find the class with the highest probability (this is the predicted class)
  max_col <- apply(predictions, 1, which.max)
  predicted_class <- colnames(predictions)[max_col]

  # Find the confidence (the probability for the predicted class)
  confidence <- apply(predictions, 1, max)

  # turn into a tibble and add columns for actual and predicted class and confidence
  predictions <- tibble::as_tibble(predictions)

  predictions$predicted_class <- predicted_class
  predictions$confidence <- confidence
  predictions$actual_class <- landscape_type
  predictions$landscape_id <- seq_len(nrow(predictions))

  # Reorder the columns
  predictions <- predictions |>
    dplyr::relocate(c(
      landscape_id,
      actual_class,
      predicted_class,
      confidence
    ))

  # Create confusion matrix and return it
  conf_matrix <- table(
    Predicted = factor(predictions$predicted_class, levels = class_names),
    Actual = factor(predictions$actual_class, levels = class_names)
  )

  return(list(
    predictions = predictions,
    confusion_matrix = conf_matrix
  ))
}
