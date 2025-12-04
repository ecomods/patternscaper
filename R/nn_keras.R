#' Train a Convolutional Neural Network for Landscape Classification
#'
#' Trains a CNN model using the Keras framework to classify landscapes based on their
#' spatial patterns. The function uses a multiscale CNN architecture optimized for
#' distinguishing different landscape patterns.
#'
#' @param landscapes List. List of landscape objects created by `create_landscape()` or `create_training_landscapes()`.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", "loo" (default: "k-fold").
#' @param cv_folds Integer. Number of cross-validation folds when cv_method="k-fold" (default: 5).
#' @param epochs Integer. Number of training epochs (default: 20).
#' @param batch_size Integer. Batch size for training (default: 16).
#' @param validation_split Numeric. Proportion of data to use for validation when cv_method="none" (default: 0.2).
#' @param learning_rate Numeric. Learning rate for Adam optimizer (default: 0.001).
#' @param model_path Character. Path to save model (default: NULL means model is not saved).
#' @param architecture Character. CNN architecture: "multiscale" (default).
#' @param dropout_rate Numeric. Dropout rate for regularization (default: 0.3).
#' @param dense_units Integer. Units in dense layer (default: 128).
#' @param loss Character. Loss function for training (default: "categorical_crossentropy").
#'   Common alternatives: "sparse_categorical_crossentropy", "kullback_leibler_divergence".
#' @param optimizer Character. Optimizer to use: "adam" (default), "sgd", "rmsprop".
#'   Note: optimizer-specific parameters like momentum are currently not exposed.
#' @param metrics Character vector. Metrics to track during training (default: c("accuracy")).
#'   Common additions: "categorical_accuracy", "top_k_categorical_accuracy".
#' @param callbacks List. Optional keras callbacks for advanced training control (default: NULL).
#'   Examples: early stopping, learning rate scheduling, model checkpointing.
#' @param verbose Integer. Verbosity mode: 0 = silent, 1 = progress bar, 2 = one line per epoch (default: 1).
#'
#' @return List. Trained CNN model and associated metadata.
#' @export
train_nn_landscapes <- function(
  landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 20,
  batch_size = 16,
  validation_split = 0.2,
  learning_rate = 0.001,
  architecture = "multiscale",
  dropout_rate = 0.3,
  dense_units = 128,
  model_path = NULL,
  loss = "categorical_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy"),
  callbacks = NULL,
  verbose = 1
) {
  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold", "loo")) {
    stop('cv_method must be one of: "none", "k-fold", or "loo"')
  }

  # Check if landscapes is a list of landscape objects
  if (any(!sapply(landscapes, is_landscape))) {
    # find out which element is not a landscape
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    cli::cli_abort(c(
      "All elements must be landscape objects.",
      "x" = "Invalid element(s) at index(es): {paste(invalid_indices, collapse = ', ')}"
    ))
  }

  # Get the training labels (pattern field of the landscape object)
  training_labels <- sapply(landscapes, function(l) l$pattern)

  # Check if all training labels are neither NA nor unclassified
  if (any(is.na(training_labels) | training_labels == "unclassified")) {
    bad_patterns <- which(
      is.na(training_labels) | training_labels == "unclassified"
    )
    cli::cli_abort(c(
      "All training labels must be classified.",
      "x" = "Invalid label(s) at index(es): {paste(bad_patterns, collapse = ', ')}"
    ))
  }

  # Convert all landscapes to arrays
  training_arrays <- lapply(landscapes, function(l) {
    landscape_data <- l$data
    terra::as.array(landscape_data)
  })

  # Show distribution of landscape types
  cat("Landscape type distribution:\n")
  print(table(training_labels))

  # Get the unique class names
  class_names <- sort(unique(training_labels))
  n_classes <- length(class_names)

  # Convert labels to integers and one-hot encode
  y_int <- as.integer(factor(training_labels, levels = class_names)) - 1
  y_data <- keras3::to_categorical(y_int)

  # Stack all arrays into one 4D array (samples, height, width, channels)
  x_data <- abind::abind(training_arrays, along = 0)
  input_shape <- c(dim(x_data)[2], dim(x_data)[3], dim(x_data)[4])

  # Create the model with selected architecture
  model <- create_keras_model(
    architecture = architecture,
    input_shape = input_shape,
    n_classes = n_classes,
    dropout_rate = dropout_rate,
    dense_units = dense_units
  )

  # Compile model
  model <- compile_keras_model(
    model = model,
    learning_rate = learning_rate,
    loss = loss,
    optimizer = optimizer,
    metrics = metrics
  )

  # Cross-validation ----------------------------------------------------------
  # Validate and adjust CV parameters
  cv_params <- validate_cv_params(
    patterns = training_labels,
    cv_method = cv_method,
    cv_folds = cv_folds
  )

  # Update cv_method and cv_folds based on validation
  cv_method <- cv_params$cv_method
  cv_folds <- cv_params$cv_folds
  class_counts <- cv_params$class_counts

  # Check cross-validation method and parameters -------------------------------
  # Run model with cross validation --------------------------------------------
  if (cv_method != "none") {
    # Create stratified fold assignments ---------------------------------------
    if (cv_method == "loo") {
      # If method is "loo", each sample is it's own fold
      fold_indices <- seq_len(length(landscapes))
    } else {
      fold_indices <- find_balanced_cv_folds(training_labels, cv_folds)
    }

    # Initialize storage for CV results for each fold
    cv_predictions <- list()
    cv_probabilities <- list()
    cv_actual <- list()
    cv_landscape_ids <- list()
    cv_evaluation <- list()

    for (fold in 1:cv_folds) {
      train_indices <- fold_indices != fold
      val_indices <- fold_indices == fold

      x_train <- x_data[train_indices, , , , drop = FALSE]
      y_train <- y_data[train_indices, , drop = FALSE]
      x_val <- x_data[val_indices, , , , drop = FALSE]
      y_val <- y_data[val_indices, , drop = FALSE]
      y_val_int <- y_int[val_indices]

      # Train the model on the training data
      fold_model <- create_keras_model(
        architecture = architecture,
        input_shape = input_shape,
        n_classes = n_classes,
        dropout_rate = dropout_rate,
        dense_units = dense_units
      )
      # Compile the fold model
      fold_model <- compile_keras_model(
        model = fold_model,
        learning_rate = learning_rate,
        loss = loss,
        optimizer = optimizer,
        metrics = metrics
      )
      # Train the fold model
      fold_model |>
        keras3::fit(
          x = x_train,
          y = y_train,
          epochs = epochs,
          batch_size = batch_size,
          validation_data = list(x_val, y_val),
          callbacks = callbacks,
          verbose = verbose
        )

      # Evaluate the model on the validation fold
      evaluation <- fold_model |> keras3::evaluate(x_val, y_val)

      # Store predictions
      probs <- fold_model |> predict(x_val)

      # Add class names as column names
      colnames(probs) <- class_names

      pred_classes <- apply(probs, 1, which.max)

      # Store results for this fold
      cv_predictions[[fold]] <- class_names[pred_classes]
      cv_probabilities[[fold]] <- probs
      cv_actual[[fold]] <- class_names[y_val_int + 1]
      cv_landscape_ids[[fold]] <- which(val_indices)

      # Store results for this fold
      cv_evaluation[[fold]] <- list(
        evaluation = evaluation
      )

      cat("Fold", fold, "accuracy:", evaluation[["accuracy"]], "\n")
    }

    # Evaluate cv performance -------------------------------------------------
    performance <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = class_names,
      cv_method = cv_method,
      cv_folds = cv_folds,
      verbose = TRUE
    )
    # Calculate average accuracy and loss across folds
    accuracies <- sapply(cv_evaluation, function(x) x$evaluation[["accuracy"]])
    losses <- sapply(cv_evaluation, function(x) x$evaluation[["loss"]])

    # Header
    cli::cli_h2("Accuracy and loss across folds")

    cat("Mean accuracy:", mean(accuracies), "±", sd(accuracies), "\n")
    cat("Mean loss:", mean(losses), "±", sd(losses), "\n\n")

    # Build final model with all data
    final_model <- create_keras_model(
      architecture = architecture,
      input_shape = input_shape,
      n_classes = n_classes,
      dropout_rate = dropout_rate,
      dense_units = dense_units
    )
    # Compile the fold model
    final_model <- compile_keras_model(
      model = fold_model,
      learning_rate = learning_rate,
      loss = loss,
      optimizer = optimizer,
      metrics = metrics
    )
    # Train the fold model
    history <- final_model |>
      keras3::fit(
        x = x_data,
        y = y_data,
        epochs = epochs,
        batch_size = batch_size,
        callbacks = callbacks,
        verbose = verbose
      )
  } else {
    # No cross-validation: simple train/validation split
    cat("\nTraining with validation split (no cross-validation)...\n")

    final_model <- create_keras_model(
      architecture = architecture,
      input_shape = input_shape,
      n_classes = n_classes,
      dropout_rate = dropout_rate,
      dense_units = dense_units
    )

    final_model <- compile_keras_model(
      model = final_model,
      learning_rate = learning_rate,
      loss = loss,
      optimizer = optimizer,
      metrics = metrics
    )

    history <- final_model |>
      keras3::fit(
        x = x_data,
        y = y_data,
        epochs = epochs,
        batch_size = batch_size,
        validation_split = validation_split,
        callbacks = callbacks,
        verbose = verbose
      )

    # Get validation metrics from history
    val_accuracy <- history$metrics$val_accuracy[length(
      history$metrics$val_accuracy
    )]
    val_loss <- history$metrics$val_loss[length(history$metrics$val_loss)]

    cat("\nTraining Results (with validation split):\n")
    cat("Final validation accuracy:", round(val_accuracy, 4), "\n")
    cat("Final validation loss:", round(val_loss, 4), "\n")

    # Create performance metrics structure
    performance <- list(
      accuracy = val_accuracy,
      loss = val_loss,
      cv_method = "none",
      validation_split = validation_split
    )

    # Create empty structures for consistency with CV path
    cv_probabilities <- list()
    cv_landscape_ids <- list()
    cv_actual <- list()
    cv_predictions <- list()
  }

  # Prepare return object

  result <- list(
    model = final_model,
    performance = performance,
    history = history
  )

  # Save model if requested
  if (!is.null(model_path)) {
    # check if the model path ends with .keras. Otherwise replace/add .keras file
    # ending and warn the user
    keras_file_ending <- stringr::str_detect(model_path, "\\.keras$")

    if (!keras_file_ending) {
      cli::cli_alert_info(
        "model_path should end with .keras (current: {model_path}). Automatically adding .keras file ending."
      )
      model_path <- paste0(model_path, ".keras")
    }

    keras3::save_model(final_model, model_path)
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
#' @param nn_model List. CNN model from train_nn_landscapes().
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

  # Validate inputs

  # If landscapes is a single landscape, wrap it into a list
  if (is_landscape(landscapes)) {
    # Wrap single landscape into a list
    landscapes <- list(landscapes)
  }

  # Check if landscapes is a list of landscape objects
  if (any(!sapply(landscapes, is_landscape))) {
    # find out which element is not a landscape
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    cli::cli_abort(c(
      "All elements must be landscape objects.",
      "x" = "Invalid element(s) at index(es): {paste(invalid_indices, collapse = ', ')}"
    ))
  }

  # Get the training labels (pattern field of the landscape object) if available
  landscape_pattern <- sapply(landscapes, function(l) l$pattern)

  # Convert all landscapes to arrays
  landscape_arrays <- lapply(landscapes, function(l) {
    landscape_data <- l$data
    terra::as.array(landscape_data)
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
  predictions$actual_class <- landscape_pattern
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

#' Create Keras Model Architecture
#'
#' @param architecture Character. Architecture type.
#' @param input_shape Integer vector. Input dimensions (height, width, channels).
#' @param n_classes Integer. Number of output classes.
#' @param dropout_rate Numeric. Dropout rate for regularization (default: 0.3).
#' @param dense_units Integer. Units in dense layer (default: 128).
#'
#' @return Uncompiled keras model.
#' @keywords internal
create_keras_model <- function(
  architecture = "multiscale",
  input_shape,
  n_classes,
  dropout_rate = 0.3,
  dense_units = 128
) {
  if (architecture == "multiscale") {
    model <- create_multiscale_model(
      input_shape = input_shape,
      n_classes = n_classes,
      dropout_rate = dropout_rate,
      dense_units = dense_units
    )
  } else {
    cli::cli_abort(c(
      "Unsupported architecture: {architecture}",
      "i" = "Available architectures: 'multiscale'"
    ))
  }

  return(model)
}

#' Compile Keras Model
#'
#' Compiles a keras model with specified loss function and optimizer.
#' Currently configured for multi-class classification problems.
#'
#' @param model Keras model. Uncompiled model from create_keras_model().
#' @param learning_rate Numeric. Learning rate for optimizer (default: 0.001).
#' @param loss Character. Loss function (default: "categorical_crossentropy").
#' @param optimizer Character. Optimizer name: "adam", "sgd", "rmsprop" (default: "adam").
#' @param metrics Character vector. Metrics to track (default: c("accuracy")).
#'
#' @return Compiled keras model.
#' @keywords internal
compile_keras_model <- function(
  model,
  learning_rate = 0.001,
  loss = "categorical_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy")
) {
  # Create optimizer based on type
  opt <- switch(
    tolower(optimizer),
    "adam" = keras3::optimizer_adam(learning_rate = learning_rate),
    "sgd" = keras3::optimizer_sgd(learning_rate = learning_rate),
    "rmsprop" = keras3::optimizer_rmsprop(learning_rate = learning_rate),
    {
      cli::cli_abort(c(
        "Unsupported optimizer: {optimizer}",
        "i" = "Available optimizers: 'adam', 'sgd', 'rmsprop'"
      ))
    }
  )

  compiled_model <- model |>
    keras3::compile(
      loss = loss,
      optimizer = opt,
      metrics = metrics
    )

  return(compiled_model)
}

#' Create Multiscale CNN Architecture
#'
#' @param input_shape Integer vector. Input dimensions.
#' @param n_classes Integer. Number of output classes.
#' @param dropout_rate Numeric. Dropout rate for regularization.
#' @param dense_units Integer. Units in dense layer.
#'
#' @return Uncompiled keras model.
#' @keywords internal
create_multiscale_model <- function(
  input_shape,
  n_classes,
  dropout_rate = 0.3,
  dense_units = 128
) {
  model <- keras3::keras_model_sequential() |>
    # Detect fine details with small kernels
    keras3::layer_conv_2d(
      filters = 32,
      kernel_size = c(3, 3),
      padding = "same",
      input_shape = input_shape
    ) |>
    keras3::layer_activation("relu") |>
    # Detect larger patterns with bigger kernels
    keras3::layer_conv_2d(
      filters = 32,
      kernel_size = c(5, 5),
      padding = "same"
    ) |>
    keras3::layer_activation("relu") |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    # Additional feature extraction
    keras3::layer_conv_2d(
      filters = 64,
      kernel_size = c(3, 3),
      padding = "same"
    ) |>
    keras3::layer_activation("relu") |>
    keras3::layer_conv_2d(
      filters = 64,
      kernel_size = c(5, 5),
      padding = "same"
    ) |>
    keras3::layer_activation("relu") |>
    keras3::layer_max_pooling_2d(pool_size = c(2, 2)) |>
    # Classifier
    keras3::layer_flatten() |>
    keras3::layer_dropout(rate = dropout_rate) |>
    keras3::layer_dense(units = dense_units, activation = "relu") |>
    keras3::layer_dense(units = n_classes, activation = "softmax")

  return(model)
}
