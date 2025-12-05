# Needed packages
library(dplyr)
library(purrr)

#--------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------
# Here you can adjust parameters for the systematic test

result_path <- "inst/examples/SelfOrga_Results_Class/Results/"
seed <- 56
# ecotone types
selforganization_patterns = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)

config <- tidyr::expand_grid(
  rep = 1:10,
  training_size = c(50, 100, 150),
  n_input_metrics = c(7, 10, 13),
  metrics_method = c(
    "coeffvar_all",
    "mean_groups",
    "fisher_score",
    "kruskal_p"
  ),
  nlayers = 1:3
)


train_and_validate <- function() {}

# Define function to train and validate the model
# param_row is a row in the parameter data frame
# landscapes_cache is a list of landscapes
train_validate_model <- function(param_row, landscapes_cache) {
  # Extract parameters
  replicate <- param_row$replicate
  training_size <- param_row$training_size
  metric_method <- param_row$metric_method
  n_metrics <- param_row$n_metrics
  layer_index <- param_row$layer_index

  # Get cached landscapes and metrics
  cache_key <- paste0("r", replicate, "_t", training_size)
  training_metrics <- landscapes_cache[[cache_key]]$training_metrics
  test_landscapes <- landscapes_cache[[cache_key]]$test_landscapes

  # Evaluate best metrics
  best_metrics <- evaluate_landscape_metrics(
    metrics = training_metrics,
    method = metric_method,
    metrics_number = n_metrics
  )

  # Get layer architecture
  layers <- get_layer_architecture(n_metrics, layer_index)
  layer_name <- paste(layers, collapse = "-")

  # Train model
  model <- tryCatch(
    train_nn_metrics(
      metrics = training_metrics,
      metrics_selected = best_metrics,
      hidden_layers = layers,
      threshold = 0.01,
      stepmax = 1e+05,
      cv_method = "none",
      verbose = FALSE
    ),
    error = function(e) {
      message(sprintf("Model training failed: %s", conditionMessage(e)))
      return(NULL)
    }
  )

  if (is.null(model)) {
    return(NULL)
  }

  # Validate model
  validation <- tryCatch(
    apply_nn_metrics(
      landscapes = test_landscapes,
      nn_model = model
    ),
    error = function(e) {
      message(sprintf("Validation failed: %s", conditionMessage(e)))
      return(NULL)
    }
  )

  if (is.null(validation)) {
    return(NULL)
  }

  # Return results
  result_name <- sprintf(
    "T%d_L%s_M%s_IM%d_R%d",
    training_size,
    layer_name,
    metric_method,
    n_metrics,
    replicate
  )

  list(
    result_name = result_name,
    training_size = training_size,
    layers = layers,
    metric = metric_method,
    inputmetrics = n_metrics,
    replicate = replicate,
    df1 = validation$performance$per_class_metrics,
    df2 = validation$performance$confusion_matrix,
    acc = validation$performance$accuracy,
    best_metrics = best_metrics
  )
}
