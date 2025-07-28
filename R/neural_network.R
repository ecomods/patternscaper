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
    tidyr:::pivot_wider(
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

  # Train the neural network model with softmax = TRUE for multinomial classification
  model <- nnet::nnet(
    type ~ .,
    data = metrics_scaled,
    size = hidden_neurons,
    decay = decay,
    maxit = maxit,
    trace = FALSE
  )

  # split into training and test data before we train
  if (test == TRUE) {
    # Predict class probabilities on the training data
    probs <- predict(
      model,
      newdata = metrics_scaled[,
        -which(names(metrics_scaled) == "type")
      ],
      type = "raw"
    )
    # Convert probabilities to predicted class labels
    predictions <- colnames(probs)[max.col(probs, ties.method = "first")]
    # Create a confusion matrix comparing predicted and actual classes
    print(table(Predicted = predictions, Actual = metrics_wide$type))
  }

  return(model)
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
