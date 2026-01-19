#' Train a multi-layer Neural Network for Landscape Classification
#'
#' Trains a multi-layer neural network model to classify landscapes
#' based on landscape metrics. Uses the neuralnet package.
#'
#' @param metrics Tibble or data frame. Output from calculate_landscape_metrics()
#'   containing landscape metrics in long format with required columns:
#'   landscape_id, landscape_name, pattern, level, class, id, metric, value.
#' @param metrics_selected Character vector of metric names to use as features,
#'   or NULL to use all available metrics. Default: NULL.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", or "loo".
#'   May be automatically adjusted based on dataset size via validate_cv_params().
#'   Default: "k-fold".
#' @param cv_folds Integer. Number of folds for k-fold cross-validation.
#'   May be automatically reduced if dataset is too small. Default: 5.
#' @param hidden_layers Integer vector. Number of neurons in each hidden layer.
#'   Length determines number of hidden layers. Default: 6 (single hidden layer with 6 neurons).
#' @param threshold Numeric. Threshold for partial derivatives as stopping criteria.
#'   Smaller values = more training iterations. Default: 0.01.
#' @param stepmax Integer. Maximum number of training steps. Default: 1e+05.
#' @param model_path Character. Optional file path (must end in .rds) to save
#'   the trained model. Default: NULL (no saving).
#' @param verbose Logical. Print training details and cross-validation results.
#'   Default: TRUE.
#'
#' @return List containing:
#'   \describe{
#'     \item{model}{Trained neuralnet model object}
#'     \item{features}{Character vector of metric names used as features}
#'     \item{features_level}{Character. Metric aggregation level ("landscape" or "class")}
#'     \item{scaling}{List with 'center' and 'scale' parameters for normalization}
#'     \item{classes}{Character vector of class names in alphabetical order}
#'     \item{performance}{List from evaluate_cv_performance() with confusion matrix,
#'       accuracy, per-class metrics, and validation results. NULL if cv_method = "none".}
#'   }
#'
#' @export
#' @importFrom cli cli_abort cli_alert_warning
#' @importFrom dplyr filter select any_of all_of
#' @importFrom purrr pmap_lgl
#' @importFrom neuralnet neuralnet
#' @importFrom readr write_rds
train_nn_metrics <- function(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_layers = 6,
  threshold = 0.01,
  stepmax = 1e+05,
  model_path = NULL,
  verbose = TRUE
) {
  # Validate input parameters -------------------------------------------------
  if (!is.logical(verbose) || length(verbose) != 1) {
    cli::cli_abort("verbose must be a single logical value (TRUE or FALSE)")
  }

  if (
    !is.numeric(hidden_layers) ||
      any(hidden_layers < 1) ||
      any(hidden_layers != floor(hidden_layers))
  ) {
    cli::cli_abort("hidden_layers must be positive integer(s)")
  }

  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    cli::cli_abort("threshold must be a single positive numeric value")
  }

  if (
    !is.numeric(stepmax) ||
      length(stepmax) != 1 ||
      stepmax < 1 ||
      stepmax != floor(stepmax)
  ) {
    cli::cli_abort("stepmax must be a single positive integer")
  }

  if (!is.null(model_path)) {
    if (!is.character(model_path) || length(model_path) != 1) {
      cli::cli_abort("model_path must be a single character string")
    }
    if (!grepl("\\.rds$", model_path, ignore.case = TRUE)) {
      cli::cli_abort("model_path must end with .rds extension")
    }
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
    missing_cols <- needed_columns[!needed_columns %in% colnames(metrics)]
    cli::cli_abort(c(
      "Metrics data is missing required columns",
      "x" = "Missing: {.val {missing_cols}}",
      "i" = "Make sure metrics is calculated by {.fn calculate_landscape_metrics}"
    ))
  }

  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold", "loo")) {
    cli::cli_abort('cv_method must be one of: "none", "k-fold", or "loo"')
  }

  # Subset selected metrics if provided
  if (!is.null(metrics_selected)) {
    missing_metrics <- setdiff(metrics_selected, unique(metrics$metric))
    if (length(missing_metrics) > 0) {
      cli::cli_abort(c(
        "Some selected metrics not found in data:",
        "x" = "{.val {missing_metrics}}"
      ))
    }
    metrics <- metrics |> dplyr::filter(metric %in% metrics_selected)
  }

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Deal with NA values -------------------------------------------------------
  predictor_cols <- setdiff(
    colnames(metrics_wide),
    c("landscape_id", "landscape_name", "pattern")
  )

  metrics_wide <- remove_incomplete_landscapes(metrics_wide, predictor_cols)

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

  training_data <- data.frame(
    predictors_scaled,
    pattern = factor(metrics_wide$pattern, levels = class_names)
  )

  # Cross-validation ----------------------------------------------------------
  # Validate and adjust CV parameters
  cv_params <- validate_cv_params(
    patterns = training_data$pattern,
    cv_method = cv_method,
    cv_folds = cv_folds,
    n_predictors = ncol(training_data) - 1
  )

  # Update cv_method and cv_folds based on validation
  cv_method <- cv_params$cv_method
  cv_folds <- cv_params$cv_folds
  class_counts <- cv_params$class_counts

  # Run model with cross validation --------------------------------------------
  if (cv_method != "none") {
    # Create stratified fold assignments ---------------------------------------
    if (cv_method == "loo") {
      # If method is "loo", each sample is its own fold
      fold_indices <- seq_len(nrow(training_data))
    } else {
      fold_indices <- find_balanced_cv_folds(training_data$pattern, cv_folds)
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
      val_indices <- fold_indices == fold

      train_data <- training_data[train_indices, ]
      val_data <- training_data[val_indices, ]

      # Train model on training data
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
        newdata = val_data[,
          -which(names(val_data) == "pattern")
        ]
      )

      # Add class names as column names
      colnames(probs) <- class_names

      # Get predicted class labels
      predictions <- colnames(probs)[max.col(probs, ties.method = "first")]

      # Store results for this fold
      cv_predictions[[fold]] <- predictions
      cv_probabilities[[fold]] <- probs
      cv_actual[[fold]] <- val_data$pattern
      cv_landscape_ids[[fold]] <- metrics_wide$landscape_id[val_indices]
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
    data = training_data,
    hidden = hidden_layers,
    threshold = threshold,
    stepmax = stepmax
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


#' Apply Neural Network for Landscape Classification
#'
#' Applies a trained neural network model to classify new landscapes. The function
#' automatically calculates the required landscape metrics needed by the model
#' and scales them appropriately.
#'
#' @param landscapes Landscape object (single) or list of landscape objects to classify.
#'   Landscapes must have valid raster data that can be analyzed by landscapemetrics.
#' @param nn_model List. Trained model object returned from train_nn_metrics().
#'   Must contain elements: model, scaling, classes, features, and features_level.
#' @param return_performance Logical. If TRUE and landscapes contain known classes
#'   (pattern attribute), calculate and return performance metrics. If FALSE or
#'   classes unknown, only return predictions. Default: FALSE.
#'
#' @return When return_performance = FALSE or actual classes unavailable:
#'   Tibble with columns:
#'   \describe{
#'     \item{landscape_id}{Numeric landscape identifier}
#'     \item{landscape_name}{Character landscape name (if available)}
#'     \item{predicted_class}{Predicted landscape pattern}
#'     \item{confidence}{Prediction confidence (maximum probability across classes)}
#'     \item{<class_name>}{Probability for each class the model was trained on}
#'   }
#'
#'   When return_performance = TRUE and actual classes available:
#'   List containing:
#'   \describe{
#'     \item{predictions}{Tibble as above, plus actual_class column}
#'     \item{performance}{Performance metrics from evaluate_cv_performance():
#'       confusion matrix, accuracy, and per-class recall/precision/F1}
#'   }
#'
#' @export
#' @importFrom cli cli_abort cli_alert_warning cli_warn
#' @importFrom dplyr filter select any_of all_of relocate rename bind_cols
#' @importFrom purrr pmap_lgl
#' @importFrom tibble as_tibble
apply_nn_metrics <- function(
  landscapes,
  nn_model,
  return_performance = FALSE
) {
  # Input validation ---------------------------------------------------------
  if (!is.logical(return_performance) || length(return_performance) != 1) {
    cli::cli_abort("return_performance must be a single logical value")
  }

  if (
    !is.list(nn_model) ||
      !all(
        c("model", "scaling", "classes", "features", "features_level") %in%
          names(nn_model)
      )
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
  level <- nn_model$features_level

  # Determine metrics to calculate based on level
  if (level == "landscape") {
    metrics_to_calculate <- nn_model$features
  } else if (level == "class") {
    # Remove the last part after last underscore
    metrics_to_calculate <- gsub("_[^_]+$", "", nn_model$features)
  } else {
    cli::cli_abort(
      "Unsupported features_level '{level}' in nn_model"
    )
  }

  # Calculate the necessary metrics for the input landscape(s)
  metrics <- calculate_landscape_metrics(
    landscapes = landscapes,
    metrics = metrics_to_calculate,
    level = level
  )

  # Filter to only features needed by the model
  metrics <- metrics |> dplyr::filter(metric %in% nn_model$features)

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Deal with NA values -------------------------------------------------------
  predictor_cols <- setdiff(
    colnames(metrics_wide),
    c("landscape_id", "landscape_name", "pattern")
  )

  metrics_wide <- remove_incomplete_landscapes(metrics_wide, predictor_cols)

  # Prepare predictors -------------------------------------------------------
  predictors <- metrics_wide |>
    dplyr::select(
      -dplyr::any_of(c(
        "landscape_id",
        "landscape_name",
        "pattern"
      ))
    )

  # Validate we have all required features
  predictor_names <- colnames(predictors)
  missing_features <- setdiff(nn_model$features, predictor_names)

  if (length(missing_features) > 0) {
    cli::cli_abort(c(
      "Input landscapes missing required metrics",
      "x" = "Missing: {.val {missing_features}}",
      "i" = "Model requires: {.val {nn_model$features}}"
    ))
  }

  # Check for extra predictors (can happen with class-level metrics)
  extra_predictors <- setdiff(predictor_names, nn_model$features)

  if (length(extra_predictors) > 0) {
    cli::cli_warn(c(
      "Input landscapes contain additional metrics not used by the model",
      "i" = "Ignored: {.val {extra_predictors}}"
    ))
  }

  # Select only model features in correct order
  predictors <- predictors |>
    dplyr::select(dplyr::all_of(nn_model$features))

  # Scale the metrics using the same parameters as during training
  predictors_scaled <- scale(
    predictors,
    center = scaling_params$center,
    scale = scaling_params$scale
  )

  # Make predictions ---------------------------------------------------------
  pred <- predict(
    model,
    newdata = predictors_scaled,
    type = "raw"
  )

  # Add class names as column names
  colnames(pred) <- class_names

  # Turn into a tibble and add columns for predicted class and confidence
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

  # Rename pattern to actual_class if it exists
  if ("pattern" %in% colnames(landscape_info)) {
    landscape_info <- landscape_info |>
      dplyr::rename(actual_class = pattern)
  }

  predictions <- dplyr::bind_cols(landscape_info, predictions)

  # Evaluate performance if actual classes are available ---------------------
  if ("actual_class" %in% colnames(predictions) & return_performance) {
    # Check if actual classes match model's trained classes
    unique_actual <- unique(predictions$actual_class)
    unknown_classes <- setdiff(unique_actual, class_names)

    if (length(unknown_classes) > 0) {
      cli::cli_warn(c(
        "Input landscapes contain classes not seen during training",
        "x" = "Unknown: {.val {unknown_classes}}",
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
      cv_method = "none",
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
