#' Train a multi-layer Neural Network for Landscape Classification
#'
#' Trains a multi-layer neural network model to classify landscapes
#' based on metrics. Uses neuralnet package.
#'
#' @param metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_selected Character vector. Names of metrics to use as features.
#' @param hidden_layers List of Integers. Number of neurons in each hidden layer (default: c(3,3)).
#' @param seed Integer. Random seed for reproducibility. If NULL, a random seed will be used (default: NULL).
#'
#' @return List. Trained neural network model and associated metadata.
#' @export
train_nn_neuralnet <- function(
    metrics,
    metrics_selected = NULL,
    hidden_layers = c(3,3),
    seed = NULL
) {

  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
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

  # train a network
  model_ecotones_nn <- neuralnet::neuralnet(
    formula = pattern ~ .,
    data = metrics_scaled,
    hidden = hidden_layers
  )

  # return model object
  model_ecotones_nn

}


#' Tests a multi-layer Neural Network for Landscape Classification
#'
#' Tests a multi-layer neural network model to classify landscapes
#' based on metrics. Uses neuralnet package.
#'
#' @param metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_selected Character vector. Names of metrics to use as features.
#' @param nn_model neural network model. Result from train_nn_neuralnet()
#'
#' @export
test_nn_neuralnet <- function(
    test_metrics,
    metrics_selected = NULL,
    nn_model = NULL
) {


  # subset selected metrics if provided
  if (!is.null(metrics_selected)) {
    # Subset only the selected metrics
    test_metrics <- subset(test_metrics, metric %in% metrics_selected)
  }

  # Filter out NA values and warn the user about how many were removed
  metrics_na_test <- subset(test_metrics, is.na(value))
  if (nrow(metrics_na) > 0) {
    warning(paste(
      "Removed",
      nrow(metrics_na),
      "metrics with NA values (Check the \"value\" column in your metrics data for details)"
    ))
  }
  # Remove the missing values
  test_metrics <- subset(test_metrics, !is.na(value))

  # extract the level of metrics so it can be accessed later
  test_metric_levels <- unique(test_metrics$level)

  # if needed, add info on class and patch id to the metric name
  # this is needed when the metric is calculated not on the landscape level,
  # but on the class or patch level
  test_metrics <- test_metrics |>
    dplyr::mutate(
      metric = stringr::str_remove(
        paste0(metric, "_", class, "_", id),
        "_NA_NA"
      )
    ) |>
    dplyr::select(metric, value, pattern, landscape_name)

  # Reformat the table to wide format
  test_metrics_wide <-test_metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    ) |>
    dplyr::select(-landscape_name)

  # Normalize the predictor variables (all columns except for the pattern column)
  test_predictors <- test_metrics_wide |> dplyr::select(-pattern)
  test_predictors_scaled <- scale(test_predictors)

  # Store scaling parameters for future use
  # This will be used to scale new data before prediction
  test_scaling_params <- list(
    center = attr(test_predictors_scaled, "scaled:center"),
    scale = attr(test_predictors_scaled, "scaled:scale")
  )

  # Combine the scaled predictors with the target variable
  test_metrics_scaled <- data.frame(
    test_predictors_scaled,
    pattern = factor(test_metrics_wide$pattern)
  )

  # Store the class names
  test_class_names <- levels(test_metrics_scaled$pattern)

  pred <- predict(model_ecotones_nn, test_metrics_scaled)
  labels <- ecotone_types
  prediction_label <- data.frame(max.col(pred)) %>%
    mutate(pred=labels[max.col.pred.]) %>% select(2) %>% unlist()

  print(table(test_metrics_scaled$pattern, prediction_label))

  check = as.numeric(test_metrics_scaled$pattern) == max.col(pred)
  accuracy = (sum(check)/nrow(test_metrics_scaled))*100
  print(accuracy)


}
