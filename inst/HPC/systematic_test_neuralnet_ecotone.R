# Needed packages
library(dplyr)
library(purrr)
library(cli)
library(furrr)

devtools::load_all()
source("systematic_test_functions.R")

#--------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------
result_path <- "systematic_test_neuralnet_ecotone_results.rds"
seed <- 12345
n_cores <- 4 # Adjust based on your system

# ecotone types
ecotone_patterns = c(
  "random",
  "sharp",
  "diffuse",
  "fingers",
  "clustered",
  "bands"
)

config <- tidyr::expand_grid(
  rep = 1:10,
  training_size = c(50, 100, 150),
  n_input_metrics = c(5, 7, 10, 13, 15, 20),
  metrics_method = c(
    "coeffvar_all",
    "mean_groups",
    "fisher_score",
    "kruskal_p"
  ),
  nlayers = 1:3
)

#--------------------------------------------------------------------
# Main Execution
#--------------------------------------------------------------------
set.seed(seed)

# Setup parallel backend
plan(multisession, workers = n_cores)

cli_alert_info("Preparing test landscapes...")
test_data_lookup <- prepare_test_data(
  reps = unique(config$rep),
  requested_patterns = ecotone_patterns
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
        requested_patterns = ecotone_patterns,
        metric_level = "landscape"
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
  training_data_lookup = training_data_lookup
)

cli_alert_info("Training neural networks...")
results_list <- config |>
  transpose() |>
  map(
    \(row) {
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
