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
#' @param model_path Character. Path to save model (default: NULL means that
#'     model is not saved).
#' @param seed Integer. Random seed for reproducibility (default: 42).
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
  model_path = NULL,
  seed = 42
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

  # extract the level of metrics so it can be accessed later
  metric_levels <- unique(metrics$level)

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

    # Evaluate cv performance ---------------------------------------------
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

    # Combine them in a table
    per_class_metrics <- data.frame(
      Class = class_names,
      Count = as.vector(class_counts),
      Recall = round(class_recall, 2),
      Precision = round(class_precision, 2),
      F1_Score = round(class_f1, 2)
    )

    performance <- list(
      confusion_matrix = conf_matrix,
      accuracy = accuracy,
      metrics = per_class_metrics,
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
    print(per_class_metrics)

    # Assemble cv validation results ------------------------------------------
    # Store results for this fold
    validation_results <- cv_probabilities |>
      purrr::map(\(x) tibble::as_tibble(x, rownames = "landscape_id")) |>
      dplyr::bind_rows() |>
      dplyr::mutate(
        landscape_id = as.integer(landscape_id),
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

  # Prepare return object
  result <- list(
    model = final_model,
    features = colnames(predictors),
    features_level = metric_levels,
    scaling = scaling_params,
    classes = class_names,
    performance = performance,
    validation_results = validation_results
  )

  # Save model if requested
  if (!is.null(model_path)) {
    readr::write_rds(result, model_path)
  }

  return(result)
}

#' Apply Neural Network for Landscape Classification
#'
#' Applies a trained neural network model to classify new landscapes. The function
#' automatically calculates the required landscape metrics needed by the model.
#'
#' @param landscapes SpatRaster, matrix, or list. Landscape(s) to classify.
#'   Can be a single landscape or list of landscapes, with or without metadata.
#' @param nn_model List. Neural network model from train_nn().
#' @param show_progress Logical. Whether to display progress bar for multiple landscapes (default: TRUE).
#'
#' @return tibble. Classification results with columns for landscape name,
#'   predicted class, confidence score, warning flag, and probability for each class.
#' @export
apply_nn <- function(
  landscapes,
  nn_model,
  show_progress = TRUE
) {
  # Extract required elements from the model
  model <- nn_model$model
  scaling_params <- nn_model$scaling
  class_names <- nn_model$classes

  # Calculate the necessary metrics for the input landscape(s)
  metrics <- calculate_landscape_metrics(
    landscapes = landscapes,
    metrics = nn_model$features,
    level = nn_model$features_level
  )

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

  # Scale the metrics using the same parameters as during training
  predictors_scaled <- scale(
    predictors,
    center = scaling_params$center,
    scale = scaling_params$scale
  )

  # Make predictions using the neural network
  predictions <- predict(
    model,
    newdata = predictors_scaled,
    type = "raw"
  )

  # Find the class with the highest probability (this is the predicted class)
  max_col <- apply(predictions, 1, which.max)
  predicted_class <- colnames(predictions)[max_col]

  # Find the confidence (the probability for the predicted class)
  confidence <- apply(predictions, 1, max)

  # turn into a tibble and add columns for actual and predicted class and confidence
  predictions <- tibble::as_tibble(predictions)

  predictions$actual_class <- metrics_wide$type
  predictions$predicted_class <- predicted_class
  predictions$confidence <- confidence
  predictions$landscape_id <- 1:nrow(predictions)

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
