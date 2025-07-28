#' Train a Neural Network for Landscape Classification
#'
#' Trains a neural network model to classify landscapes based on metrics.
#'
#' @param metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_selected Character vector. Names of metrics to use as features.
#' @param test Logical. Whether to perform cross-validation (default: TRUE).
#' @param cv_folds Integer. Number of cross-validation folds (default: 5).
#' @param hidden_neurons Integer. Number of neurons in hidden layer (default: 5).
#' @param decay Numeric. Weight decay parameter for nnet (default: 0.01).
#' @param maxit Integer. Maximum iterations for training (default: 500).
#' @param save_model Logical. Whether to save the model (default: FALSE).
#' @param model_path Character. Path to save model (default: NULL).
#'
#' @return List. Trained neural network model and associated metadata.
#' @export
train_nn <- function(
  metrics,
  metrics_selected = NULL,
  test = TRUE,
  cv_folds = 5,
  hidden_neurons = 5,
  decay = 0.01,
  maxit = 500,
  save_model = FALSE,
  model_path = NULL,
  seed = 123
) {
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
  # Combine the scaled predictors with the target variable
  metrics_scaled <- data.frame(
    predictors_scaled,
    type = factor(metrics_wide$type)
  )

  # Store the class names
  class_names <- levels(metrics_scaled$type)

  # Initialize performance metrics storage
  performance <- NULL

  if (test == TRUE) {
    # Perform k-fold cross-validation
    # Create fold indices
    set.seed(seed)
    fold_indices <- sample(rep(1:cv_folds, length.out = nrow(metrics_scaled)))

    # Initialize confusion matrix and other metrics
    all_predictions <- character(0)
    all_actual <- character(0)

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

    # Create and print confusion matrix
    conf_matrix <- table(Predicted = all_predictions, Actual = all_actual)
    print("Cross-validation results:")
    print(conf_matrix)

    # Calculate performance metrics
    accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)
    performance <- list(
      confusion_matrix = conf_matrix,
      accuracy = accuracy
    )

    cat(sprintf("Cross-validation accuracy: %.2f%%\n", accuracy * 100))
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
    classes = class_names
  )

  # Add performance metrics if cross-validation was performed
  if (!is.null(performance)) {
    result$performance <- performance
  }

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
