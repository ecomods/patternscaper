# Needed packages
library(dplyr)
library(purrr)
library(cli)
library(furrr)

devtools::load_all()
# source("inst/HPC/systematic_test_functions.R")
source("systematic_test_functions.R")

# Parse command line arguments -------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
  cli::cli_abort(
    "Usage: Rscript systematic_test_neuralnet.R <pattern_type> <results_dir> <rep>
  pattern_type: 'selforg' or 'ecotones'
  results_dir: directory for output
  rep: replicate number (from SLURM_ARRAY_TASK_ID)"
  )
}

pattern_type <- args[1]
results_dir <- args[2]
rep <- as.integer(args[3])

# Add test values instead:
# pattern_type <- "ecotones"
# results_dir <- "test_output"
# rep <- 1

set.seed(12345 + rep * 1000)

cli::cli_alert_info(
  "Processing replicate {rep} for pattern type: {pattern_type}"
)

# Validate and create output directory -----------------------------------------
if (!dir.exists(results_dir)) {
  cli::cli_alert_info("Creating output directory: {results_dir}")
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
}

# Test write permissions
test_file <- file.path(results_dir, ".write_test")
tryCatch(
  {
    writeLines("test", test_file)
    file.remove(test_file)
  },
  error = function(e) {
    cli::cli_abort("Cannot write to directory {results_dir}: {e$message}")
  }
)

cli::cli_alert_success("Output directory validated: {results_dir}")


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
n_test_landscapes <- 100

config <- tidyr::expand_grid(
  rep = rep,
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

# config <- tidyr::expand_grid(
#   rep = rep, # 10 -> 2 reps
#   training_size = 50, # c(50, 100, 150) -> just 50
#   n_input_metrics = c(5, 7), # c(5, 7, 10, 13, 15, 20) -> just 2
#   metrics_method = "coeffvar_all", # 4 methods -> 1
#   nlayers = 1 # 1:3 -> just 1
# )
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

training_data_lookup <- training_combos |>
  pmap(
    \(rep, training_size) {
      devtools::load_all()
      prepare_training_data_single(
        rep = rep,
        training_size = training_size,
        requested_patterns = patterns,
        metric_level = metric_level
      )
    }
  ) |>
  set_names(with(training_combos, paste0(rep, "_", training_size)))

cli_alert_info("Evaluating best metrics...")
best_metrics_combos <- config |>
  distinct(rep, training_size, metrics_method, n_input_metrics)

best_metrics_lookup <- prepare_best_metrics(
  best_metric_combos = best_metrics_combos,
  training_data_lookup = training_data_lookup,
  class_filter = class_filter
)


# Step 2: model training
cli_alert_info("Training neural networks ...")

results_list <- config |>
  transpose() |>
  map(
    \(row) {
      devtools::load_all()
      #source("inst/HPC/load_package_functions.R")
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

# Save results with replicate number
cli_alert_info("Saving results...")
readr::write_rds(
  results_list,
  file.path(
    results_dir,
    paste0("systematic_test_nn_", pattern_type, "_rep", rep, "_results.rds")
  )
)

cli_alert_success(
  "Complete! Trained {length(results_list)} models for replicate {rep}."
)
