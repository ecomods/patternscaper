#' Train a Convolutional Neural Network for Landscape Pattern Classification
#'
#' Trains a CNN model using the Keras framework via \pkg{keras3} to classify landscapes based on their
#' spatial patterns (pixel data). The function uses a multiscale CNN architecture optimized for
#' distinguishing different landscape patterns.
#'
#' @param landscapes List. List of landscape objects created by \code{\link{create_landscape}} or
#' \code{\link{create_landscapes}}.
#' **Note**: Input landscapes must contain categorical/discrete habitat data
#' (e.g., 0/1 for two habitat types, or 0/1/2 for three types).
#' Continuous data (e.g., elevation, gradients) is not supported.
#' All landscapes used for training are required to have the same spatial extent.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", "loo" (default: "k-fold").
#'   \itemize{
#'     \item "k-fold" or "loo": Performs cross-validation and returns performance metrics
#'     \item "none": Trains on ALL provided data without validation. Use \code{\link{apply_nn_pixels}}
#'           with a separate test set to evaluate performance.
#'   }
#' @param cv_folds Integer. Number of cross-validation folds when cv_method="k-fold" (default: 5).
#'   Note: May be automatically reduced to ensure adequate samples per fold.
#' @param epochs Integer. Number of training epochs (default: 50).
#' @param batch_size Integer. Batch size for training (default: 16).
#' @param learning_rate Numeric. Learning rate for Adam optimizer (default: 0.001).
#' @param model_path Character. Path to save model. Models are saved as `.keras` files.
#'   (default: NULL means model is not saved).
#' @param architecture Character. CNN architecture (default: "multiscale").
#'   Currently only "multiscale" is supported, which uses multiple kernel sizes
#'   (3x3 and 5x5) to capture patterns at different spatial scales.
#' @param dropout_rate Numeric. Dropout rate for regularization (0-1, default: 0.3).
#'  Higher values reduce overfitting but may decrease model capacity. Applied between
#'  convolutional and dense layers.
#' @param dense_units Integer. Number of units in the final dense layer before output
#'  (default: 128). Controls model capacity for learning complex pattern combinations.
#' @param loss Character. Loss function for training (default: "categorical_crossentropy").
#'   Use "sparse_categorical_crossentropy" if labels are integers rather than one-hot encoded.
#'   See \code{\link[keras3]{loss_categorical_crossentropy}} for details.
#' @param optimizer Character. Optimizer algorithm: "adam" (default), "sgd", "rmsprop".
#'   Adam is recommended for most cases. See \code{\link[keras3]{optimizer_adam}}.
#'   Note: Advanced optimizer parameters (e.g., momentum, beta values) are not currently exposed.
#' @param metrics Character vector. Metrics to track during training (default: c("accuracy")).
#'   Additional options: "categorical_accuracy", "top_k_categorical_accuracy".
#'   Does not affect training, only monitoring. See \code{\link[keras3]{metric_accuracy}}.
#' @param callbacks List. Optional keras callbacks for advanced training control (default: NULL).
#'   Examples: early stopping, learning rate scheduling, model checkpointing.
#'   Note: Only applies to final model training. CV folds always use patience-based
#'   early stopping if patience is specified. For an overview of available callbacks,
#'   see \code{\link[keras3]{callback_early_stopping}} (the callback used by default) and related `callback_` functions.
#' @param patience Integer. Number of epochs with no improvement before early stopping (default: 15).
#'   Applied to both CV fold training (monitors validation loss) and final model training (monitors validation loss if `validation_split` > 0).
#'   Only used when callbacks=NULL. Set to NULL to train for full epoch count without early stopping.
#'   Is passed to \code{\link[keras3]{callback_early_stopping}}.
#' @param validation_split Numeric. Fraction of training data to use as validation set during
#'   final model training and passed to \code{\link[keras3]{fit}}(0-1, default: 0).
#'   When > 0, enables monitoring and early stopping on validation loss. Particularly useful when cv_method="none"
#'   to prevent overfitting. Ignored during CV fold training (which uses its own validation splits).
#' @param verbose Logical. Show training progress and performance summaries (default: TRUE).
#'   When TRUE, displays epoch-by-epoch training/validation metrics during final model training,
#'   plus CV fold accuracies and final performance summaries. CV fold epoch details are not shown.
#'   When FALSE, runs silently.
#'
#' @return List containing:
#'   \describe{
#'     \item{model}{Trained keras model object}
#'     \item{history}{Training history object from keras3::fit()}
#'     \item{classes}{Character vector of class names used during training}
#'     \item{input_shape}{Integer vector of input dimensions (height, width, channels)}
#'     \item{architecture}{Character, architecture type used ("multiscale")}
#'     \item{performance}{Performance metrics. When cv_method != "none", contains
#'       results from evaluate_cv_performance() including confusion matrix, per-class
#'       metrics, and overall accuracy. When cv_method = "none", contains training
#'       metadata only (see note field for evaluation instructions).}
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Create training data
#' training_landscapes <- create_landscapes(
#'   n = 200,
#'   patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
#' )
#'
#' # Train with cross-validation
#' model <- train_nn_pixels(
#'   landscapes = training_landscapes,
#'   cv_method = "k-fold",
#'   cv_folds = 5
#' )
#'
#' # Train without cross validation on all data
#' final_model <- train_nn_pixels(
#'   landscapes = training_landscapes,
#'   cv_method = "none",
#'   epochs = 100
#' )
#' }
train_nn_pixels <- function(
  landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 50,
  batch_size = 16,
  learning_rate = 0.001,
  architecture = "multiscale",
  dropout_rate = 0.3,
  dense_units = 128,
  model_path = NULL,
  loss = "categorical_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy"),
  validation_split = 0,
  callbacks = NULL,
  patience = 15,
  verbose = TRUE
) {
  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold", "loo")) {
    cli::cli_abort('cv_method must be one of: "none", "k-fold", or "loo"')
  }

  # Validate numeric parameters
  if (epochs < 1 || !is.numeric(epochs)) {
    cli::cli_abort("epochs must be a positive integer")
  }
  if (batch_size < 1 || !is.numeric(batch_size)) {
    cli::cli_abort("batch_size must be a positive integer")
  }
  if (learning_rate <= 0 || learning_rate >= 1) {
    cli::cli_abort("learning_rate must be between 0 and 1")
  }
  # validate validation_split
  if (validation_split < 0 || validation_split >= 1) {
    cli::cli_abort("validation_split must be between 0 and 1")
  }

  # Validate and normalize model_path if provided
  if (!is.null(model_path)) {
    if (!stringr::str_detect(model_path, "\\.keras$")) {
      cli::cli_alert_info(
        "model_path should end with .keras (current: {model_path}). Automatically adding .keras extension."
      )
      model_path <- paste0(model_path, ".keras")
    }

    # Check if directory exists and is writable
    model_dir <- dirname(model_path)
    if (!dir.exists(model_dir)) {
      cli::cli_abort(
        "Directory for model_path does not exist: {model_dir}. Please create it first."
      )
    }
  }

  # Check if landscapes is empty
  if (length(landscapes) == 0) {
    cli::cli_abort("landscapes must contain at least one landscape object")
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
  if (verbose) {
    cli::cli_h2("Landscape type distribution:")
    print(table(training_labels))
  }

  # Get the unique class names
  class_names <- sort(unique(training_labels))
  n_classes <- length(class_names)

  # Convert labels to integers and one-hot encode
  y_int <- as.integer(factor(training_labels, levels = class_names)) - 1
  y_data <- keras3::to_categorical(y_int)

  # Stack all arrays into one 4D array (samples, height, width, channels)
  x_data <- abind::abind(training_arrays, along = 0)
  input_shape <- c(dim(x_data)[2], dim(x_data)[3], dim(x_data)[4])

  # Setup callbacks ---------------------------------------------------------
  # If user didn't provide callbacks, patience is specified and the user
  # wants to add a validation split to final model training, add early stopping
  # This callback will be used for final model training (not CV folds)
  if (is.null(callbacks) && !is.null(patience) && validation_split > 0) {
    callbacks <- list(
      keras3::callback_early_stopping(
        monitor = "val_loss",
        patience = patience,
        restore_best_weights = TRUE
      )
    )
  }

  # Add a progress callback when verbose = TRUE
  if (verbose) {
    progress_callback <- keras3::callback_lambda(
      on_epoch_end = function(epoch, logs) {
        # Check if we have validation data
        if (validation_split > 0) {
          cat(sprintf(
            "Epoch %d - loss: %.4f - acc: %.4f - val_loss: %.4f - val_acc: %.4f\n",
            epoch,
            logs$loss,
            logs$accuracy,
            logs$val_loss,
            logs$val_accuracy
          ))
        } else {
          cat(sprintf(
            "Epoch %d - loss: %.4f - accuracy: %.4f\n",
            epoch,
            logs$loss,
            logs$accuracy
          ))
        }
        flush.console()
      }
    )

    if (is.null(callbacks)) {
      callbacks <- list(progress_callback)
    } else {
      callbacks <- c(callbacks, progress_callback)
    }
  }

  # Cross-validation ----------------------------------------------------------
  # Validate and adjust CV parameters based on class distribution
  # May downgrade CV method (k-fold -> LOO) or reduce folds if dataset is small
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
    cli::cli_h2("Cross-validation ({cv_method}, {cv_folds} folds)")
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

      # Create fold-specific callbacks
      fold_callbacks <- NULL
      if (!is.null(patience)) {
        fold_callbacks <- list(
          keras3::callback_early_stopping(
            monitor = "val_loss",
            patience = patience,
            restore_best_weights = TRUE
          )
        )
      }

      fold_model |>
        keras3::fit(
          x = x_train,
          y = y_train,
          epochs = epochs,
          batch_size = batch_size,
          validation_data = list(x_val, y_val),
          callbacks = fold_callbacks,
          verbose = 0
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

      # Conditional fold accuracy
      cli::cli_alert_success(
        "Fold {fold}/{cv_folds} accuracy: {round(evaluation[['accuracy']], 4)}"
      )
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
      verbose = verbose
    )
    # Calculate average accuracy and loss across folds
    accuracies <- sapply(cv_evaluation, function(x) x$evaluation[["accuracy"]])
    losses <- sapply(cv_evaluation, function(x) x$evaluation[["loss"]])

    if (verbose) {
      cli::cli_h2("Accuracy and loss across folds")

      cli::cli_text(
        "Mean accuracy: {round(mean(accuracies), 4)} +- {round(sd(accuracies), 4)}"
      )
      cli::cli_text(
        "Mean loss: {round(mean(losses), 4)} +- {round(sd(losses), 4)}"
      )
      cli::cli_text("")
    }

    cli::cli_h2(
      "Training final model on all data (validation split: {validation_split})"
    )

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
      model = final_model,
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
        validation_split = validation_split,
        verbose = 0
      )
  } else {
    # No cross-validation: train on ALL data
    cli::cli_h2("Training final model on all data")
    if (verbose) {
      cli::cli_alert_info(
        "Training on all data (validation split is {validation_split})..."
      )
    }

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
        verbose = 0
      )

    # No validation metrics available
    performance <- list(
      cv_method = "none",
      n_training_samples = nrow(x_data),
      n_classes = n_classes,
      class_distribution = table(training_labels),
      note = "Model trained on all data. Use apply_nn_pixels() to evaluate on test set."
    )
  }

  # Prepare return object

  result <- list(
    model = final_model,
    history = history,
    classes = class_names,
    input_shape = input_shape,
    architecture = architecture,
    performance = performance
  )

  # Save model if requested
  if (!is.null(model_path)) {
    keras3::save_model(final_model, model_path)

    # Save metadata separately
    metadata_path <- gsub("\\.keras$", "_metadata.rds", model_path)
    metadata <- result
    metadata$model <- NULL
    readr::write_rds(metadata, metadata_path)
  }

  return(result)
}

#' Apply a Keras CNN Model for Landscape Pattern Classification
#'
#' Applies a trained CNN model to classify new landscapes based on their
#' spatial patterns. Automatically resizes input landscapes to match the
#' model's expected dimensions.
#'
#' @param landscapes landscape object, or list of landscape objects. Landscape(s) to classify.
#'   Landscapes will be automatically resized to match the model's input dimensions using
#'   nearest neighbor interpolation, which preserves categorical cell values.
#'   **Note**: Input landscapes must contain categorical/discrete habitat data (e.g., 0/1 for
#'   two habitat types, or 0/1/2 for three types). Continuous data (e.g., elevation,
#'   gradients) is not supported.
#' @param nn_model List. CNN model object from \code{\link{train_nn_pixels}}.
#' @param return_performance Logical. Whether to return performance metrics when actual classes are available (default: FALSE).
#' @param verbose Logical. Show informational messages and performance summaries (default: TRUE).
#'   When TRUE, displays resize operations and performance evaluation results.
#'   When FALSE, runs silently. Warnings about unknown classes or invalid data always appear.
#'
#' @return When actual classes unavailable or return_performance=FALSE: tibble with columns:
#'   \describe{
#'     \item{landscape_id}{Numeric landscape identifier}
#'     \item{landscape_name}{Character landscape name (if available)}
#'     \item{predicted_class}{Predicted landscape pattern}
#'     \item{confidence}{Prediction confidence (max probability)}
#'     \item{<class_name>}{Probability for each trained class}
#'   }
#'
#'   When actual classes available and return_performance=TRUE: List containing:
#'   \describe{
#'     \item{predictions}{Tibble as above, plus actual_class column}
#'     \item{performance}{Performance metrics from evaluate_cv_performance()}
#'   }
#' @examples
#' \dontrun{
#' # Create training data
#' training_landscapes <- create_landscapes(
#'   n = 200,
#'   patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
#' )
#'
#'
#' # Train on all data for final deployment model
#' final_model <- train_nn_pixels(
#'   landscapes = training_landscapes,
#'   cv_method = "none",
#'   epochs = 100
#' )
#'
#' # Evaluate on separate test set
#' test_landscapes <- create_landscapes(
#'   n = 10,
#'   patterns = c("sharp", "diffuse", "clustered", "fingers", "bands", "random")
#' )
#' results <- apply_nn_pixels(
#'   landscapes = test_landscapes,
#'   nn_model = final_model,
#'   return_performance = TRUE
#' )
#' }
#' @export
apply_nn_pixels <- function(
  landscapes,
  nn_model,
  return_performance = FALSE,
  verbose = TRUE
) {
  # Input validation
  if (
    !is.list(nn_model) ||
      !all(c("model", "classes", "input_shape") %in% names(nn_model))
  ) {
    cli::cli_abort(
      "'nn_model' must be a trained model from train_nn_pixels()"
    )
  }

  # Extract required elements from the model
  model <- nn_model$model
  class_names <- nn_model$classes
  input_shape <- nn_model$input_shape

  # Expected dimensions from training
  expected_height <- input_shape[1]
  expected_width <- input_shape[2]

  # Validate landscapes structure
  if (!is.list(landscapes) && !is_landscape(landscapes)) {
    cli::cli_abort(
      "'landscapes' must be a landscape object or list of landscapes"
    )
  }

  # If landscapes is a single landscape, wrap it into a list
  if (is_landscape(landscapes)) {
    landscapes <- list(landscapes)
  }

  # Check if landscapes is a list of landscape objects
  if (any(!sapply(landscapes, is_landscape))) {
    invalid_indices <- which(!sapply(landscapes, is_landscape))
    cli::cli_abort(c(
      "All elements must be landscape objects.",
      "x" = "Invalid element(s) at index(es): {paste(invalid_indices, collapse = ', ')}"
    ))
  }

  # Get the training labels (pattern field of the landscape object) if available
  landscape_pattern <- sapply(landscapes, function(l) l$pattern)
  landscape_names <- sapply(landscapes, function(l) {
    if (!is.null(l$name)) l$name else NA_character_
  })

  # Convert all landscapes to arrays, resizing if needed
  # First, check which ones need resizing
  resize_info <- lapply(landscapes, function(l) {
    landscape_data <- l$data
    current_height <- terra::nrow(landscape_data)
    current_width <- terra::ncol(landscape_data)
    needs_resize <- current_height != expected_height ||
      current_width != expected_width

    list(
      needs_resize = needs_resize,
      current_height = current_height,
      current_width = current_width
    )
  })

  # Print batched resize message
  needs_resize <- sapply(resize_info, function(x) x$needs_resize)
  if (any(needs_resize)) {
    n_resize <- sum(needs_resize)

    # Get unique dimension pairs
    unique_dims <- unique(lapply(resize_info[needs_resize], function(x) {
      c(x$current_height, x$current_width)
    }))

    if (verbose) {
      if (length(unique_dims) == 1) {
        dims <- unique_dims[[1]]
        cli::cli_alert_info(
          "Resizing {n_resize} landscape{?s} from {dims[1]}x{dims[2]} to {expected_height}x{expected_width}"
        )
      } else {
        cli::cli_alert_info(
          "Resizing {n_resize} landscape{?s} to {expected_height}x{expected_width}"
        )
      }
    }
  }

  # Now do the actual conversion/resizing
  landscape_arrays <- lapply(seq_along(landscapes), function(i) {
    l <- landscapes[[i]]
    landscape_data <- l$data

    if (resize_info[[i]]$needs_resize) {
      # Create template raster with target dimensions
      template <- terra::rast(
        nrows = expected_height,
        ncols = expected_width,
        extent = terra::ext(landscape_data),
        crs = terra::crs(landscape_data)
      )

      # Resample using nearest neighbor to preserve binary values
      landscape_data <- terra::resample(
        landscape_data,
        template,
        method = "near"
      )
    }

    terra::as.array(landscape_data)
  })

  # Stack all arrays into one 4D array (samples, height, width, channels)
  landscape_data <- abind::abind(landscape_arrays, along = 0)

  # Get predictions
  pred <- predict(model, landscape_data, verbose = 0)

  # Add classes as column names
  colnames(pred) <- class_names

  # Turn into a tibble and add columns for predicted class and confidence
  predictions <- tibble::as_tibble(pred)

  # Find the confidence (the probability for the predicted class)
  predictions$confidence <- apply(pred, 1, max)

  # Find the class with the highest probability (this is the predicted class)
  max_col <- apply(pred, 1, which.max)
  predicted_class <- colnames(pred)[max_col]
  predictions$predicted_class <- predicted_class

  # Add landscape information
  predictions$landscape_id <- seq_len(nrow(predictions))

  if (any(!is.na(landscape_names))) {
    predictions$landscape_name <- landscape_names
  }

  # Check if we have actual classes (not NA or "unclassified")
  has_actual_classes <- !all(
    is.na(landscape_pattern) | landscape_pattern == "unclassified"
  )

  # Always add actual_class column
  predictions$actual_class <- landscape_pattern

  # Check for mixed scenario (some valid, some invalid actual classes)
  if (return_performance && has_actual_classes) {
    valid_mask <- !is.na(landscape_pattern) &
      landscape_pattern != "unclassified"
    n_valid <- sum(valid_mask)
    n_total <- length(landscape_pattern)

    if (n_valid < n_total) {
      if (verbose) {
        cli::cli_alert_info(
          "Evaluating performance on {n_valid}/{n_total} landscapes with known classes"
        )
      }
    }
  }

  # Reorder columns: landscape info, then actual (if present), then predicted
  predictions <- predictions |>
    dplyr::relocate(c(
      landscape_id,
      dplyr::any_of(c("landscape_name", "actual_class")),
      predicted_class,
      confidence
    ))

  # Evaluate performance if actual classes are available and requested----------
  if (has_actual_classes & return_performance) {
    # Filter to only valid rows for evaluation
    valid_mask <- !is.na(predictions$actual_class) &
      predictions$actual_class != "unclassified"

    if (!any(valid_mask)) {
      cli::cli_warn(
        "No valid actual classes found - returning predictions only"
      )
      return(list(
        predictions = predictions,
        performance = NULL
      ))
    }

    # Check unknown classes only on valid rows
    valid_predictions <- predictions[valid_mask, ]
    unique_actual <- unique(valid_predictions$actual_class)
    unknown_classes <- setdiff(unique_actual, class_names)

    if (length(unknown_classes) > 0) {
      cli::cli_warn(c(
        "Input landscapes contain classes not seen during training:",
        "x" = "{.val {unknown_classes}}",
        "i" = "Model trained on: {.val {class_names}}",
        "i" = "Performance evaluation skipped - returning predictions only"
      ))

      return(list(
        predictions = predictions,
        performance = NULL
      ))
    }

    # Evaluate only on valid rows
    cv_predictions <- list(valid_predictions$predicted_class)
    cv_probabilities <- list(as.matrix(
      valid_predictions |>
        dplyr::select(dplyr::all_of(class_names))
    ))
    cv_actual <- list(valid_predictions$actual_class)
    cv_landscape_ids <- list(valid_predictions$landscape_id)

    # Evaluate performance using same function as training
    performance <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = class_names,
      cv_method = "none", # Not actual CV, just test set evaluation
      cv_folds = 1,
      verbose = verbose,
      return_predictions = FALSE
    )

    # Return all predictions, but performance only on valid subset
    return(list(
      predictions = predictions,
      performance = performance
    ))
  } else {
    # No actual classes or performance not requested
    if (return_performance) {
      # Check if user requested performance but we have no valid classes
      if (!has_actual_classes) {
        cli::cli_warn(
          "No valid actual classes found - returning predictions only"
        )
      }

      # Return a list for consistency
      return(list(
        predictions = predictions,
        performance = NULL
      ))
    } else {
      # Just predictions requested
      return(predictions)
    }
  }
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
