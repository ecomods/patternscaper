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
#' @param seed Integer. Random seed for reproducibility. If NULL, a random seed will be used (default: NULL).
#'
#' @return List. Trained neural network model and associated metadata.
#' @export
train_nn_metrics <- function(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_neurons = 5,
  decay = 0.01,
  maxit = 500,
  model_path = NULL,
  seed = NULL
) {
  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Validate columns of metrics
  needed_columns <- c(
    "landscape_id",
    "landscape_name",
    "pattern",
    "level",
    "class",
    "id",
    "metric",
    "value"
  )
  if (!all(needed_columns %in% colnames(metrics))) {
    cli::cli_abort(
      "Metrics data is missing required columns. Missing columns are: ",
      paste(
        needed_columns[!needed_columns %in% colnames(metrics)],
        collapse = ", "
      ),
      ". Make sure that metrics is calculated by `calculate_landscape_metrics()`"
    )
  }

  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold", "loo")) {
    stop('cv_method must be one of: "none", "k-fold", or "loo"')
  }

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

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Normalize the predictor variables (all columns except for the pattern column)
  predictors <- metrics_wide |> dplyr::select(-pattern)
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
    pattern = factor(metrics_wide$pattern)
  )

  # Store the class names
  class_names <- levels(metrics_scaled$pattern)

  # Validate and adjust CV parameters
  cv_params <- validate_cv_params(
    patterns = metrics_scaled$pattern,
    cv_method = cv_method,
    cv_folds = cv_folds,
    n_predictors = ncol(metrics_scaled) - 1
  )

  # Update cv_method and cv_folds based on validation
  cv_method <- cv_params$cv_method
  cv_folds <- cv_params$cv_folds
  class_counts <- cv_params$class_counts

  # Run model with cross validation --------------------------------------------
  if (cv_method != "none") {
    # Create stratified fold assignments ---------------------------------------
    if (cv_method == "loo") {
      # If method is "loo", each sample is it's own fold
      fold_indices <- seq_len(nrow(metrics_scaled))
    } else {
      fold_indices <- find_balanced_cv_folds(metrics_scaled$pattern, cv_folds)
    }

    # Initialize storage for CV results of each fold
    cv_predictions <- list()
    cv_probabilities <- list()
    cv_actual <- list()
    cv_landscape_ids <- list()

    # Perform k-fold cross-validation or loo by looping over each fold
    for (fold in 1:cv_folds) {
      # Split data into training and validation
      train_indices <- fold_indices != fold
      validation_indices <- fold_indices == fold

      train_data <- metrics_scaled[train_indices, ]
      validation_data <- metrics_scaled[validation_indices, ]

      # Train model on training data
      fold_model <- nnet::nnet(
        pattern ~ .,
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
          -which(names(validation_data) == "pattern")
        ],
        type = "raw"
      )

      # Get predicted class labels
      predictions <- colnames(probs)[max.col(probs, ties.method = "first")]

      # Store results for this fold
      cv_predictions[[fold]] <- predictions
      cv_probabilities[[fold]] <- probs
      cv_actual[[fold]] <- validation_data$pattern
      cv_landscape_ids[[fold]] <- which(validation_indices)
    }

    # Evaluate cv performance -------------------------------------------------
    performance <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = class_names,
      cv_method = cv_method,
      cv_folds = cv_folds
    )

    # Extract validation results from performance object
    validation_results <- performance$validation_results
  }

  # Train final model on all data
  final_model <- nnet::nnet(
    pattern ~ .,
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
    performance = if (cv_method != "none") performance else NULL
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
#' @param nn_model List. Neural network model from apply_nn_landscapes().
#' @param show_progress Logical. Whether to display progress bar for multiple landscapes (default: TRUE).
#'
#' @return tibble. Classification results with columns for landscape name,
#'   predicted class, confidence score, warning flag, and probability for each class.
#' @export
apply_nn_metrics <- function(
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
    dplyr::select(metric, value, pattern, landscape_name)

  # Reformat the table to wide format
  metrics_wide <- metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    ) |>
    dplyr::select(-landscape_name)

  # Normalize the predictor variables (all columns except for the class column)
  predictors <- metrics_wide |> dplyr::select(-pattern)

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

  predictions$actual_class <- metrics_wide$pattern
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
