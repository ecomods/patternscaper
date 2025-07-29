#' Train a Neural Network for Landscape Classification
#'
#' Trains a neural network model to classify landscapes based on metrics.
#'
#' @param metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_selected Character vector. Names of metrics to use as features.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", or "loo" (leave-one-out) (default: "k-fold").
#' @param cv_folds Integer. Number of cross-validation folds when cv_method="k-fold" (default: 5).
#' @param hidden_neurons Integer. Number of neurons in hidden layer (default: 5).
#' @param decay Numeric. Weight decay parameter for nnet (default: 0.01).
#' @param maxit Integer. Maximum iterations for training (default: 500).
#' @param save_model Logical. Whether to save the model (default: FALSE).
#' @param model_path Character. Path to save model (default: NULL).
#' @param seed Integer. Random seed for reproducibility (default: 123).
#'
#' @return List. Trained neural network model and associated metadata.
#' @export
train_nn <- function(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_neurons = 5,
  decay = 0.01,
  maxit = 500,
  save_model = FALSE,
  model_path = NULL,
  seed = 123
) {
  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold", "loo")) {
    stop('cv_method must be one of: "none", "k-fold", or "loo"')
  }

  set.seed(seed)
  # subset selected metrics if provided
  if (!is.null(metrics_selected)) {
    # Subset only the selected metrics
    metrics <- subset(metrics, metric %in% metrics_selected)
  }

  # Filter out NA values and warn the user about how many were removed
  metrics_na <- subset(metrics, is.na(value))
  if (nrow(metrics_na) > 0) {
    warning(paste(
      "Removed",
      nrow(metrics_na),
      "metrics with NA values (Check the \"value\" column in your metrics data for details)"
    ))
  }
  # Remove the missing values
  metrics <- subset(metrics, !is.na(value))

  # if needed, add info on class and patch id to the metric name
  # this is needed when the metric is calculated not on the landscape level,
  # but on the class or patch level
  metrics <- metrics |>
    dplyr::mutate(
      metric = stringr::str_remove(
        paste0(metric, "_", class, "_", id),
        "_NA_NA"
      )
    ) |>
    dplyr::select(metric, value, type, landscape)

  # Reformat the table to wide format
  metrics_wide <- metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    ) |>
    dplyr::select(-landscape)

  # Normalize the predictor variables (all columns except for the type column)
  predictors <- metrics_wide |> dplyr::select(-type)
  predictors_scaled <- scale(predictors)

  # Store scaling parameters for future use
  # This will be used to scale new data before prediction
  scaling_params <- list(
    center = attr(predictors_scaled, "scaled:center"),
    scale = attr(predictors_scaled, "scaled:scale")
  )

  # Combine the scaled predictors with the target variable
  metrics_scaled <- data.frame(
    predictors_scaled,
    type = factor(metrics_wide$type)
  )

  # Store the class names
  class_names <- levels(metrics_scaled$type)

  # Initialize performance metrics storage
  performance <- NULL

  # Check cross-validation method and parameters -------------------------------
  if (cv_method != "none") {
    # Adjust CV method based on dataset characteristics
    if (cv_method == "k-fold") {
      # Get count of samples per class
      class_counts <- table(metrics_scaled$type)
      min_class_count <- min(class_counts)
      total_samples <- nrow(metrics_scaled)

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

    # Initialize confusion matrix and other metrics
    all_predictions <- character(0)
    all_actual <- character(0)

    # Initialize storage for CV results
    cv_predictions <- list()
    cv_probabilities <- list()
    cv_actual <- list()

    if (cv_method == "loo") {
      # Perform leave-one-out cross-validation
      for (i in 1:nrow(metrics_scaled)) {
        # Split data into training and validation
        train_data <- metrics_scaled[-i, ]
        validation_data <- metrics_scaled[i, , drop = FALSE]

        # Train model on training data
        fold_model <- nnet::nnet(
          type ~ .,
          data = train_data,
          size = hidden_neurons,
          decay = decay,
          maxit = maxit,
          trace = FALSE
        )

        # Predict on validation data
        probs <- predict(
          fold_model,
          newdata = validation_data[,
            -which(names(validation_data) == "type"),
            drop = FALSE
          ],
          type = "raw"
        )

        # Get predicted class label
        prediction <- colnames(probs)[max.col(probs, ties.method = "first")]

        # Store actual and predicted values
        all_predictions <- c(all_predictions, prediction)
        all_actual <- c(all_actual, as.character(validation_data$type))

        # Store predictions for this fold
        fold_probabilities <- predict(
          fold_model,
          newdata = validation_data[,
            -which(names(validation_data) == "type"),
            drop = FALSE
          ],
          type = "raw"
        )
        fold_predictions <- class_names[apply(fold_probabilities, 1, which.max)]

        # Store results for this fold
        cv_predictions[[i]] <- fold_predictions
        cv_probabilities[[i]] <- fold_probabilities
        cv_actual[[i]] <- validation_data$type
      }

      # Set cv_folds for reporting
      cv_folds <- nrow(metrics_scaled)
    } else if (cv_method == "k-fold") {
      # Perform stratified k-fold cross-validation
      set.seed(seed)

      # Create stratified fold assignments
      # Ensure each class is represented in each fold
      fold_indices <- integer(nrow(metrics_scaled))
      for (class_name in levels(metrics_scaled$type)) {
        class_indices <- which(metrics_scaled$type == class_name)
        class_folds <- sample(rep(
          1:cv_folds,
          length.out = length(class_indices)
        ))
        fold_indices[class_indices] <- class_folds
      }

      # Perform k-fold cross-validation
      for (fold in 1:cv_folds) {
        # Split data into training and validation
        train_indices <- fold_indices != fold
        validation_indices <- fold_indices == fold

        train_data <- metrics_scaled[train_indices, ]
        validation_data <- metrics_scaled[validation_indices, ]

        # Train model on training data
        fold_model <- nnet::nnet(
          type ~ .,
          data = train_data,
          size = hidden_neurons,
          decay = decay,
          maxit = maxit,
          trace = FALSE
        )

        # Predict on validation data
        probs <- predict(
          fold_model,
          newdata = validation_data[, -which(names(validation_data) == "type")],
          type = "raw"
        )

        # Get predicted class labels
        predictions <- colnames(probs)[max.col(probs, ties.method = "first")]

        # Store actual and predicted values
        all_predictions <- c(all_predictions, predictions)
        all_actual <- c(all_actual, as.character(validation_data$type))

        # Store predictions for this fold
        fold_probabilities <- predict(
          fold_model,
          newdata = validation_data[, -which(names(validation_data) == "type")],
          type = "raw"
        )
        fold_predictions <- class_names[apply(fold_probabilities, 1, which.max)]

        # Store results for this fold
        cv_predictions[[fold]] <- fold_predictions
        cv_probabilities[[fold]] <- fold_probabilities
        cv_actual[[fold]] <- validation_data$type
      }
    }

    # Create and print confusion matrix
    # Ensure all classes appear in the confusion matrix, even if not predicted
    conf_matrix <- table(
      Predicted = factor(all_predictions, levels = class_names),
      Actual = factor(all_actual, levels = class_names)
    )

    # Check for classes that were never correctly predicted
    correctly_predicted <- diag(conf_matrix)
    never_predicted_classes <- class_names[correctly_predicted == 0]

    if (length(never_predicted_classes) > 0) {
      warning(sprintf(
        "Some classes were never correctly predicted during cross-validation: %s. Results for these classes are unreliable.",
        paste(never_predicted_classes, collapse = ", ")
      ))
    }

    # Check for classes with few samples
    class_counts <- table(metrics_scaled$type)
    small_classes <- names(class_counts[class_counts < 3])

    if (length(small_classes) > 0) {
      warning(sprintf(
        "Some classes have very few samples (< 3): %s. Cross-validation results for these classes may be unreliable.",
        paste(small_classes, collapse = ", ")
      ))
    }

    print("Cross-validation results:")
    print(conf_matrix)

    # Calculate performance metrics
    accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)

    # Calculate per-class metrics
    class_recall <- diag(conf_matrix) / colSums(conf_matrix)
    class_precision <- diag(conf_matrix) / rowSums(conf_matrix)

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
      confusion_matrix = conf_matrix,
      accuracy = accuracy,
      class_precision = class_precision,
      class_recall = class_recall,
      class_f1 = class_f1,
      cv_method = cv_method,
      cv_folds = cv_folds,
      class_counts = as.vector(class_counts)
    )

    cat(sprintf(
      "Cross-validation accuracy: %.2f%% (using %s with %d folds)\n",
      accuracy * 100,
      ifelse(cv_method == "loo", "leave-one-out", cv_method),
      cv_folds
    ))

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
  }

  # Train final model on all data
  final_model <- nnet::nnet(
    type ~ .,
    data = metrics_scaled,
    size = hidden_neurons,
    decay = decay,
    maxit = maxit,
    trace = FALSE
  )

  # Get probabilities for training data
  training_probabilities <- predict(
    final_model,
    newdata = metrics_scaled[,
      -which(names(metrics_scaled) == "type"),
      drop = FALSE
    ],
    type = "raw"
  )

  # Create dataframe with training predictions and actual classes
  training_results <- data.frame(
    actual_class = metrics_scaled$type
  )

  # Add probability for each class
  for (class_name in class_names) {
    training_results[[class_name]] <- training_probabilities[, class_name]
  }

  # Add predicted class and confidence
  training_results$predicted_class <- class_names[max.col(
    training_probabilities,
    ties.method = "first"
  )]
  training_results$confidence <- apply(training_probabilities, 1, max)

  # Prepare return object
  result <- list(
    model = final_model,
    features = colnames(predictors),
    scaling = scaling_params,
    classes = class_names,
    performance = performance,
    training_results = training_results
  )

  # Save model if requested
  if (save_model && !is.null(model_path)) {
    readr::write_rds(result, model_path)
  }

  # After CV loop, combine all fold results
  validation_actual_class <- unlist(cv_actual)
  validation_predicted_class <- unlist(cv_predictions)

  # Create matrix of all probabilities
  validation_probabilities <- matrix(
    0,
    nrow = length(validation_actual_class),
    ncol = length(class_names)
  )
  colnames(validation_probabilities) <- class_names
  row_index <- 1
  for (fold in 1:length(cv_probabilities)) {
    n_rows <- nrow(cv_probabilities[[fold]])
    for (i in 1:n_rows) {
      validation_probabilities[row_index, ] <- cv_probabilities[[fold]][i, ]
      row_index <- row_index + 1
    }
  }

  # Create validation results dataframe similar to training_results
  validation_results <- data.frame(
    actual_class = validation_actual_class,
    predicted_class = validation_predicted_class,
    confidence = apply(validation_probabilities, 1, max)
  )

  # Add probability for each class
  for (class_name in class_names) {
    validation_results[[class_name]] <- validation_probabilities[, class_name]
  }

  # Add to result object
  result$validation_results <- validation_results

  return(result)
}

#' Apply Neural Network for Landscape Classification
#'
#' Applies a trained neural network model to classify new landscapes. The function
#' automatically calculates the required landscape metrics needed by the model.
#'
#' @param landscape SpatRaster, matrix, or list. Landscape(s) to classify.
#'   Can be a single landscape or list of landscapes, with or without metadata.
#' @param nn_model List. Neural network model from train_nn().
#' @param confidence_threshold Numeric. Threshold for warning flag (default: 0.6).
#' @param show_progress Logical. Whether to display progress bar for multiple landscapes (default: TRUE).
#'
#' @return tibble. Classification results with columns for landscape name,
#'   predicted class, confidence score, warning flag, and probability for each class.
#' @export
apply_nn <- function(
  landscape,
  nn_model,
  confidence_threshold = 0.6,
  show_progress = TRUE
) {
  # Validate inputs
  if (is.null(nn_model)) {
    stop("Neural network model is required")
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
  scaling_params <- nn_model$scaling
  class_names <- nn_model$classes

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

    # Calculate metrics for the landscape
    # Only calculate the metrics needed by the model
    current_metrics <- calculate_landscape_metrics(
      raster_landscape,
      metrics = nn_model$features
    )

    # Process metrics into the right format (following train_nn logic)
    processed_metrics <- current_metrics |>
      dplyr::mutate(
        metric = stringr::str_remove(
          paste0(metric, "_", class, "_", id),
          "_NA_NA"
        )
      ) |>
      dplyr::select(metric, value)

    # Convert to wide format
    metrics_wide <- processed_metrics |>
      tidyr::pivot_wider(
        names_from = metric,
        values_from = value
      )

    # Collect potential issues for a single consolidated warning
    issues <- character(0)

    # Check if we have all required metrics
    missing_metrics <- setdiff(nn_model$features, colnames(metrics_wide))
    if (length(missing_metrics) > 0) {
      issues <- c(
        issues,
        sprintf(
          "Missing required metrics: %s",
          paste(missing_metrics, collapse = ", ")
        )
      )

      # Add missing columns with NA values
      for (missing_metric in missing_metrics) {
        metrics_wide[[missing_metric]] <- NA
      }
    }

    # Ensure metrics are in the same order as the training data
    metrics_ordered <- metrics_wide[, nn_model$features, drop = FALSE]

    # Handle any NA values by imputing with column means from training data
    has_na <- any(is.na(metrics_ordered))
    if (has_na) {
      issues <- c(issues, "NA values detected and imputed with means")

      # Replace NA with column means from training data
      for (col in colnames(metrics_ordered)) {
        if (any(is.na(metrics_ordered[[col]]))) {
          metrics_ordered[[col]][is.na(metrics_ordered[[col]])] <-
            scaling_params$center[col]
        }
      }
    }

    # Issue a consolidated warning if needed
    if (length(issues) > 0) {
      warning(sprintf(
        "Issues for landscape '%s': %s. Classification may be unreliable.",
        landscape_name,
        paste(issues, collapse = "; ")
      ))
    }

    # Scale the metrics using the same parameters as during training
    metrics_scaled <- scale(
      metrics_ordered,
      center = scaling_params$center,
      scale = scaling_params$scale
    )

    # Make predictions using the neural network
    predictions <- predict(
      model,
      newdata = metrics_scaled,
      type = "raw"
    )

    # Get the class with the highest probability
    predicted_class <- class_names[which.max(predictions)]

    # Get the confidence (probability) for the predicted class
    confidence <- max(predictions)

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
    for (class_name in class_names) {
      result_row[[class_name]] <- predictions[, class_name]
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
