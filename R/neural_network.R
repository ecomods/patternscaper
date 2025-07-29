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

  # Prepare return object
  result <- list(
    model = final_model,
    features = colnames(predictors),
    scaling = scaling_params,
    classes = class_names,
    performance = performance
  )

  # Save model if requested
  if (save_model && !is.null(model_path)) {
    readr::write_rds(result, model_path)
  }

  return(result)
}

#' Apply Neural Network for Landscape Classification
#'
#' Applies a trained neural network model to classify new landscapes.
#'
#' @param landscape SpatRaster or list. Landscape(s) to classify.
#' @param nn_model List. Neural network model from train_nn().
#' @param test_data tibble. Metrics used for training (default: NULL).
#' @param metric_list Character vector. Metrics to use (default: NULL, uses nn_model$features).
#' @param confidence_threshold Numeric. Threshold for warning flag (default: 0.6).
#'
#' @return tibble. Classification results.
#' @export
apply_nn <- function(
  landscape,
  nn_model,
  test_data = NULL,
  metric_list = NULL,
  confidence_threshold = 0.6
) {
  # Function implementation will go here
}
