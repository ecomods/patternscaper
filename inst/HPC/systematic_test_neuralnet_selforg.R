# Needed packages
library(dplyr)
library(purrr)
library(cli)
library(furrr)

devtools::load_all()

#--------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------
result_path <- "systematic_test_neuralnet_selforg_results.rds"
seed <- 56
n_cores <- 4 # Adjust based on your system

selforganization_patterns <- c(
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

#--------------------------------------------------------------------
# Helper Functions
#--------------------------------------------------------------------

prepare_test_data <- function(reps, selforganization_patterns) {
  reps |>
    map(\(r) {
      test_landscapes <- create_training_landscapes(
        n = 100,
        patterns = selforganization_patterns
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
  selforganization_patterns,
  metric_level = "class"
) {
  training_landscapes <- create_training_landscapes(
    n = training_size,
    patterns = selforganization_patterns
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

  # Calculate layer configuration
  adjuster <- n_input_metrics / 5
  layers_config <- list(
    round(adjuster * 3, 0),
    round(adjuster * 4, 0),
    round(adjuster * 5, 0)
  )
  hidden_layers <- layers_config[[nlayers]]
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
      cli_alert_warning("Training failed: {conditionMessage(e)}")
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
      cli_alert_warning("Validation failed: {conditionMessage(e)}")
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

#--------------------------------------------------------------------
# Main Execution
#--------------------------------------------------------------------
set.seed(seed)

# Setup parallel backend
plan(multisession, workers = n_cores)

cli_alert_info("Preparing test landscapes...")
test_data_lookup <- prepare_test_data(
  reps = unique(config$rep),
  selforganization_patterns = selforganization_patterns
)

cli_alert_info("Preparing training landscapes and metrics (parallel)...")
training_combos <- config |>
  distinct(rep, training_size)


# PARALLEL: This is the bottleneck so I parallelized it
training_data_lookup <- training_combos |>
  future_pmap(
    \(rep, training_size) {
      # Load package functions in each worker
      devtools::load_all()
      prepare_training_data_single(
        rep = rep,
        training_size = training_size,
        selforganization_patterns = selforganization_patterns,
        metric_level = "class"
      )
    },
    .options = furrr_options(seed = TRUE)
  ) |>
  set_names(with(training_combos, paste0(rep, "_", training_size)))


cli_alert_info("Evaluating best metrics...")
best_metrics_combos <- config |>
  distinct(rep, training_size, metrics_method, n_input_metrics)

best_metrics_lookup <- prepare_best_metrics(
  best_metric_combos = best_metrics_combos,
  training_data_lookup = training_data_lookup,
  class_filter = 1
)

cli_alert_info("Training neural networks...")
results_list <- config |>
  transpose() |>
  map(
    \(row) {
      devtools::load_all()
      train_and_validate(
        config_row = row,
        test_data_lookup = test_data_lookup,
        training_data_lookup = training_data_lookup,
        best_metrics_lookup = best_metrics_lookup
      )
    }
  ) |>
  compact()

# Set names of the result list
results_list <- set_names(results_list, map_chr(results_list, "name"))

cli_alert_info("Saving results...")
readr::write_rds(results_list, file = result_path)
cli_alert_success("Complete! Trained {length(results_list)} models.")

plan(sequential)
