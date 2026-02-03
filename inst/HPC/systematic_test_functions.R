#--------------------------------------------------------------------
# Helper Functions
#--------------------------------------------------------------------

prepare_test_data <- function(
  reps,
  requested_patterns,
  n_test_landscapes = 100
) {
  reps |>
    map(\(r) {
      test_landscapes <- create_landscapes(
        n = n_test_landscapes,
        patterns = requested_patterns
      )
      list(
        rep = r,
        test_landscapes = test_landscapes
      )
    }) |>
    set_names(as.character(reps))
}

prepare_training_data_single <- function(
  rep,
  training_size,
  requested_patterns,
  metric_level = "class"
) {
  training_landscapes <- create_landscapes(
    n = training_size,
    patterns = requested_patterns
  )

  training_metrics <- calculate_landscape_metrics(
    training_landscapes,
    level = metric_level
  )

  list(
    rep = rep,
    training_size = training_size,
    training_metrics = training_metrics
  )
}

prepare_best_metrics <- function(
  best_metric_combos,
  training_data_lookup,
  class_filter = NULL
) {
  best_metric_combos |>
    pmap(\(rep, training_size, metrics_method, n_input_metrics) {
      training_key <- paste0(rep, "_", training_size)
      training_metrics <- training_data_lookup[[training_key]]$training_metrics

      if (!is.null(class_filter)) {
        training_metrics <- training_metrics |>
          filter(class == class_filter)
      }

      best_metrics <- evaluate_landscape_metrics(
        metrics = training_metrics,
        method = metrics_method,
        metrics_number = n_input_metrics
      )

      list(
        rep = rep,
        training_size = training_size,
        metrics_method = metrics_method,
        n_input_metrics = n_input_metrics,
        best_metrics = best_metrics
      )
    }) |>
    set_names(
      with(
        best_metric_combos,
        paste0(
          rep,
          "_",
          training_size,
          "_",
          metrics_method,
          "_",
          n_input_metrics
        )
      )
    )
}

train_and_validate <- function(
  config_row,
  test_data_lookup,
  training_data_lookup,
  best_metrics_lookup
) {
  rep <- config_row$rep
  training_size <- config_row$training_size
  n_input_metrics <- config_row$n_input_metrics
  metrics_method <- config_row$metrics_method
  nlayers <- config_row$nlayers
  n_neurons <- config_row$n_neurons

  # Lookup pre-computed data
  test_key <- as.character(rep)
  training_key <- paste0(rep, "_", training_size)
  best_metrics_key <- paste0(
    rep,
    "_",
    training_size,
    "_",
    metrics_method,
    "_",
    n_input_metrics
  )

  test_landscapes <- test_data_lookup[[test_key]]$test_landscapes
  training_metrics <- training_data_lookup[[training_key]]$training_metrics
  best_metrics <- best_metrics_lookup[[best_metrics_key]]$best_metrics

  # Calculate layer configuration based on number of layers
  # Scale neurons proportionally to input metrics
  base_neurons <- round(n_input_metrics * n_neurons, 0)

  hidden_layers <- rep(base_neurons, nlayers)
  layer_name <- paste(hidden_layers, collapse = "-")

  # Train model
  model_neuralnet <- tryCatch(
    {
      train_nn_metrics(
        metrics = training_metrics,
        metrics_selected = best_metrics,
        hidden_layers = hidden_layers,
        threshold = 0.01,
        stepmax = 1e+05,
        cv_method = "none",
        verbose = FALSE
      )
    },
    error = function(e) {
      cli::cli_alert_warning("Training failed: {conditionMessage(e)}")
      return(NULL)
    }
  )

  if (is.null(model_neuralnet)) {
    return(NULL)
  }

  # Validate model
  validation <- tryCatch(
    {
      apply_nn_metrics(
        landscapes = test_landscapes,
        nn_model = model_neuralnet,
        return_performance = TRUE
      )
    },
    error = function(e) {
      cli::cli_alert_warning("Validation failed: {conditionMessage(e)}")
      return(NULL)
    }
  )

  if (is.null(validation)) {
    return(NULL)
  }

  # Build result
  result_name <- paste0(
    "T",
    training_size,
    "_L",
    layer_name,
    "_M",
    metrics_method,
    "_IM",
    n_input_metrics,
    "_R",
    rep
  )

  list(
    name = result_name,
    training_size = training_size,
    layers = layer_name,
    metric = metrics_method,
    inputmetrics = n_input_metrics,
    replicate = rep,
    validation = validation
  )
}
