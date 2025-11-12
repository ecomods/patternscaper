#' Train a multi-layer Neural Network for Landscape Classification
#'
#' Trains a multi-layer neural network model to classify landscapes
#' based on metrics. Uses neuralnet package.
#'
#' @param metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_selected Character vector. Names of metrics to use as features.
#' @param hidden_layers List of Integers. Number of neurons in each hidden layer (default: c(3,3)).
#' @param threshold Numeric. Threshold for the partial derivatives of the error function as stopping criteria in neuralnet. Default: 0.01,
#' @param stepmax = Ingeger. Maximum steps for the training of the neural network in neuralnet. Reaching this maximum leads to a stop of the neural network's training process.Default: 1e+05,
#' @param seed Integer. Random seed for reproducibility. If NULL, a random seed will be used (default: NULL).
#'
#' @return List. Trained neural network model and associated metadata.
#' @export
train_nn_neuralnet <- function(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_layers = c(3, 3),
  threshold = 0.01,
  stepmax = 1e+05,
  model_path = NULL,
  seed = NULL,
  verbose = TRUE
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

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Deal with NA values -------------------------------------------------------
  # Check if we have any NA values in the predictor columns
  # If yes, warn the user and remove the landscape
  predictor_cols <- setdiff(
    colnames(metrics_wide),
    c("landscape_id", "landscape_name", "pattern")
  )

  na_rows <- apply(metrics_wide[, predictor_cols], 1, function(row) {
    any(is.na(row))
  })

  if (any(na_rows)) {
    n_removed <- sum(na_rows)
    removed_names <- metrics_wide$landscape_name[na_rows]

    cli::cli_alert_warning(
      "Removed {n_removed} landscape{?s} with incomplete metrics: {paste(removed_names, collapse = ', ')}"
    )

    metrics_wide <- metrics_wide[!na_rows, ]
    # Check if we have any landscapes left
    if (nrow(metrics_wide) == 0) {
      cli::cli_abort(c(
        "No landscapes remaining after removing those with incomplete metrics",
        "i" = "All {n_removed} landscape{?s} had NA values in required features"
      ))
    }
  }

  # Normalize the predictor variables (remove landscape columns)
  predictors <- metrics_wide |>
    dplyr::select(
      -dplyr::any_of(c(
        "landscape_id",
        "landscape_name",
        "pattern"
      ))
    )
  predictors_scaled <- scale(predictors)

  # Store scaling parameters for future use
  # This will be used to scale new data before prediction
  scaling_params <- list(
    center = attr(predictors_scaled, "scaled:center"),
    scale = attr(predictors_scaled, "scaled:scale")
  )

  # Combine the scaled predictors with the target variable
  # Explicitly set factor levels in alphabetical order for consistency
  class_names <- sort(unique(metrics_wide$pattern))

  metrics_scaled <- data.frame(
    predictors_scaled,
    pattern = factor(metrics_wide$pattern, levels = class_names)
  )

  # Cross-validation ----------------------------------------------------------
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
      # Train final model on all data
      fold_model <- neuralnet::neuralnet(
        formula = pattern ~ .,
        data = train_data,
        threshold = threshold,
        stepmax = stepmax,
        hidden = hidden_layers
      )

      # Predict on validation data
      probs <- predict(
        fold_model,
        newdata = validation_data[,
          -which(names(validation_data) == "pattern")
        ]
      )

      # Add class names as column names
      colnames(probs) <- class_names

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
      cv_folds = cv_folds,
      verbose = verbose
    )
  }

  # Train final model on all data
  final_model <- neuralnet::neuralnet(
    formula = pattern ~ .,
    data = metrics_scaled,
    hidden = hidden_layers
  )

  # Prepare return object
  result <- list(
    model = final_model,
    features = colnames(predictors),
    features_level = unique(metrics$level),
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


#' Apply Neural Network (from neuralnet package) for Landscape Classification
#'
#' Applies a trained neural network model to classify new landscapes. The function
#' automatically calculates the required landscape metrics needed by the model.
#'
#' @param landscapes landscape object, or list of landscape objects. Landscape(s) to classify.
#' @param nn_model List. Neural network model from train_nn_metrics().
#'
#' @return When actual classes unavailable: tibble with columns:
#'   \describe{
#'     \item{landscape_id}{Numeric landscape identifier}
#'     \item{landscape_name}{Character landscape name (if available)}
#'     \item{predicted_class}{Predicted landscape pattern}
#'     \item{confidence}{Prediction confidence (max probability)}
#'     \item{<class_name>}{Probability for each trained class}
#'   }
#'
#'   When actual classes available: List containing:
#'   \describe{
#'     \item{predictions}{Tibble as above, plus actual_class column}
#'     \item{performance}{Performance metrics from evaluate_cv_performance()}
#'   }
#' @export
apply_nn_neuralnet <- function(
  landscapes,
  nn_model,
  return_performance = FALSE
) {
  # Input validation
  if (
    !is.list(nn_model) ||
      !all(c("model", "scaling", "classes", "features") %in% names(nn_model))
  ) {
    cli::cli_abort("'nn_model' must be a trained model from train_nn_metrics()")
  }

  # Validate landscapes structure
  if (!is.list(landscapes) && !is_landscape(landscapes)) {
    cli::cli_abort(
      "'landscapes' must be a landscape object or list of landscapes"
    )
  }

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

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Check if we have any NA values in the predictor columns
  # If yes, warn the user and remove the landscape
  predictor_cols <- setdiff(
    colnames(metrics_wide),
    c("landscape_id", "landscape_name", "pattern")
  )

  na_rows <- apply(metrics_wide[, predictor_cols], 1, function(row) {
    any(is.na(row))
  })

  if (any(na_rows)) {
    n_removed <- sum(na_rows)
    removed_names <- metrics_wide$landscape_name[na_rows]

    cli::cli_alert_warning(
      "Removed {n_removed} landscape{?s} with incomplete metrics: {paste(removed_names, collapse = ', ')}"
    )

    metrics_wide <- metrics_wide[!na_rows, ]

    # Check if we have any landscapes left
    if (nrow(metrics_wide) == 0) {
      cli::cli_abort(c(
        "No landscapes remaining after removing those with incomplete metrics",
        "i" = "All {n_removed} landscape{?s} had NA values in required features"
      ))
    }
  }

  # Normalize the predictor variables (remove landscape columns)
  predictors <- metrics_wide |>
    dplyr::select(
      -dplyr::any_of(c(
        "landscape_id",
        "landscape_name",
        "pattern"
      ))
    )

  # Scale the metrics using the same parameters as during training
  predictors_scaled <- scale(
    predictors,
    center = scaling_params$center,
    scale = scaling_params$scale
  )

  # Make predictions using the neural network
  pred <- predict(
    model,
    newdata = predictors_scaled,
    type = "raw"
  )

  # Add class names as column names
  colnames(pred) <- class_names

  # turn into a tibble and add columns for actual and predicted class and confidence
  predictions <- tibble::as_tibble(pred)
  # Find the confidence (the probability for the predicted class)
  predictions$confidence <- apply(pred, 1, max)

  # Find the class with the highest probability (this is the predicted class)
  max_col <- apply(pred, 1, which.max)
  predicted_class <- colnames(pred)[max_col]
  predictions$predicted_class <- predicted_class

  # Reorder the columns
  predictions <- predictions |>
    dplyr::relocate(c(
      predicted_class,
      confidence
    ))

  # Add all landscape information available to the output
  landscape_info <- metrics_wide |>
    dplyr::select(
      dplyr::any_of(c("landscape_id", "landscape_name", "pattern"))
    )

  # rename pattern to actual_class if it exists
  if ("pattern" %in% colnames(landscape_info)) {
    landscape_info <- landscape_info |>
      dplyr::rename(actual_class = pattern)
  }

  predictions <- dplyr::bind_cols(landscape_info, predictions)

  # Evaluate performance if actual classes are available -----------------------
  if ("actual_class" %in% colnames(predictions)) {
    # Check if actual classes match model's trained classes
    unique_actual <- unique(predictions$actual_class)
    unknown_classes <- setdiff(unique_actual, class_names)

    if (length(unknown_classes) > 0) {
      cli::cli_warn(c(
        "Input landscapes contain classes not seen during training:",
        "x" = "{.val {unknown_classes}}",
        "i" = "Model trained on: {.val {class_names}}",
        "i" = "Performance evaluation skipped - returning predictions only"
      ))

      return(predictions)
    }

    # All classes are valid - proceed with performance evaluation
    # Create single-fold structure for evaluate_cv_performance
    cv_predictions <- list(predictions$predicted_class)
    cv_probabilities <- list(as.matrix(
      predictions |>
        dplyr::select(dplyr::all_of(class_names))
    ))
    cv_actual <- list(predictions$actual_class)
    cv_landscape_ids <- list(predictions$landscape_id)

    # Evaluate performance using same function as training
    performance <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = class_names,
      cv_method = "none", # Not actual CV, just test set evaluation
      cv_folds = 1,
      verbose = TRUE,
      return_predictions = FALSE
    )

    return(list(
      predictions = predictions,
      performance = performance
    ))
  } else {
    # No actual classes - just return predictions
    return(predictions)
  }
}
