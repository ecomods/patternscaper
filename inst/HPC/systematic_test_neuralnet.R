# Needed packages
library(dplyr)
library(purrr)
library(cli)
library(furrr)

devtools::load_all()
source("systematic_test_functions.R")

set.seed(12345)

# Parse command line arguments -------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  cli::cli_abort(
    "Usage: Rscript systematic_test_neuralnet.R <pattern_type> <results_dir>
  pattern_type: 'selforg' or 'ecotones'
  results_dir: directory for output"
  )
}

pattern_type <- args[1]
results_dir <- args[2]

# Add test values instead:
# pattern_type <- "ecotones"
# results_dir <- "test_output"

# Define patterns based on type ------------------------------------------------
if (pattern_type == "selforg") {
  patterns <- c("bare", "spots", "labyrinth", "gaps", "dense")
  metric_level <- "class"
  class_filter <- 1
} else if (pattern_type == "ecotones") {
  patterns <- c("random", "sharp", "diffuse", "fingers", "clustered", "bands")
  metric_level <- "landscape"
  class_filter <- NULL
} else {
  cli::cli_abort(
    "pattern_type must be 'selforg' or 'ecotones', got: {pattern_type}"
  )
}

cli::cli_alert_info("Running experiments for pattern type: {pattern_type}")
cli::cli_alert_info("Metric level: {metric_level}")
if (!is.null(class_filter)) {
  cli::cli_alert_info("Class filter: {class_filter}")
}
cli::cli_alert_info("Results will be saved to: {results_dir}")

#--------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------
n_cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "4"))
# n_cores <- 4 # For local testing
n_test_landscapes <- 10 #100

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

config <- tidyr::expand_grid(
  rep = 1:2, # 10 -> 2 reps
  training_size = 50, # c(50, 100, 150) -> just 50
  n_input_metrics = c(5, 7), # c(5, 7, 10, 13, 15, 20) -> just 2
  metrics_method = "coeffvar_all", # 4 methods -> 1
  nlayers = 1 # 1:3 -> just 1
)
# This gives you 2 * 1 * 2 * 1 * 1 = 4 models

#--------------------------------------------------------------------
# Main Execution
#--------------------------------------------------------------------

cli_alert_info("Preparing test landscapes...")
test_data_lookup <- prepare_test_data(
  reps = unique(config$rep),
  requested_patterns = patterns,
  n_test_landscapes = n_test_landscapes
)

cli_alert_info("Preparing training landscapes and metrics (parallel)...")
training_combos <- config |>
  distinct(rep, training_size)

# Setup parallel backend
plan(multisession, workers = n_cores)

training_data_lookup <- training_combos |>
  future_pmap(
    \(rep, training_size) {
      devtools::load_all()
      prepare_training_data_single(
        rep = rep,
        training_size = training_size,
        requested_patterns = patterns,
        metric_level = metric_level
      )
    },
    .options = furrr_options(seed = TRUE)
  ) |>
  set_names(with(training_combos, paste0(rep, "_", training_size)))


plan(sequential) # Close workers to free memory

cli_alert_info("Evaluating best metrics...")
best_metrics_combos <- config |>
  distinct(rep, training_size, metrics_method, n_input_metrics)

best_metrics_lookup <- prepare_best_metrics(
  best_metric_combos = best_metrics_combos,
  training_data_lookup = training_data_lookup,
  class_filter = class_filter
)


# Step 2: Parallel model training
cli_alert_info("Training neural networks (parallel)...")
plan(multisession, workers = n_cores)

results_list <- config |>
  transpose() |>
  future_map(
    \(row) {
      devtools::load_all()
      #source("inst/HPC/load_package_functions.R")
      train_and_validate(
        config_row = row,
        test_data_lookup = test_data_lookup,
        training_data_lookup = training_data_lookup,
        best_metrics_lookup = best_metrics_lookup
      )
    },
    .options = furrr_options(
      seed = TRUE,
      packages = c("nnet", "terra", "landscapemetrics", "dplyr", "purrr", "cli")
    )
  ) |>
  compact()

plan(sequential)

# Set names of the result list
results_list <- set_names(results_list, map_chr(results_list, "name"))

cli_alert_info("Saving results...")
readr::write_rds(
  results_list,
  file.path(
    results_dir,
    paste0("systematic_test_", pattern_type, "_results.rds")
  )
)
cli_alert_success("Complete! Trained {length(results_list)} models.")
