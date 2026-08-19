# Select one batch size and dropout rate for the systematic pixel analysis
#
# This is a validation-only pilot, not part of the final analysis pipeline. It
# never creates or evaluates final systematic test landscapes. Every paired fit
# uses the same training and validation landscapes.
#
# Run from the package root:
#   source("dev/pilot_pixel_batch_dropout.R")

# Load required libraries -------------------------------------------------

devtools::load_all(quiet = TRUE)
library(dplyr)

if (!keras_available()) {
  cli::cli_abort("A working Keras TensorFlow backend is required.")
}

# Settings ----------------------------------------------------------------

pilot_version <- "v1"
resume_existing <- TRUE

training_sizes <- c(50L, 400L)
batch_sizes <- c(8L, 16L)
dropout_rates <- c(0.2, 0.3, 0.4)
model_seeds <- 4231:4233

epochs <- 20L
learning_rate <- 0.001
n_validation_per_pattern <- 20L

pattern_families <- list(
  ecotones = c(
    "random",
    "sharp",
    "diffuse",
    "fingers",
    "clustered",
    "bands"
  ),
  selforg = c(
    "bare",
    "spots",
    "labyrinth",
    "gaps",
    "dense"
  )
)

results_directory <- file.path(
  "dev",
  "pixel_batch_dropout_pilot_results",
  pilot_version
)
checkpoint_directory <- file.path(results_directory, "checkpoints")
dir.create(checkpoint_directory, recursive = TRUE, showWarnings = FALSE)

# Helper functions --------------------------------------------------------

training_data_seed <- function(pattern_family, training_size) {
  family_index <- match(pattern_family, names(pattern_families))
  as.integer(50000 + family_index * 1000 + training_size)
}

validation_data_seed <- function(pattern_family) {
  family_index <- match(pattern_family, names(pattern_families))
  as.integer(70000 + family_index * 1000)
}

last_history_metric <- function(history_metrics, metric) {
  if (!metric %in% names(history_metrics)) {
    return(NA_real_)
  }
  as.numeric(utils::tail(history_metrics[[metric]], 1))
}

mean_or_na <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  mean(x, na.rm = TRUE)
}

sd_or_na <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) < 2) {
    return(NA_real_)
  }
  stats::sd(x)
}

max_or_na <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  max(x, na.rm = TRUE)
}

# Create fixed training and validation data -------------------------------

pilot_data <- list()

for (pattern_family in names(pattern_families)) {
  patterns <- pattern_families[[pattern_family]]

  validation_seed <- validation_data_seed(pattern_family)
  set.seed(validation_seed)
  validation_landscapes <- create_landscapes(
    n = length(patterns) * n_validation_per_pattern,
    patterns = patterns
  )

  training_sets <- list()
  training_seeds <- integer()

  for (training_size in training_sizes) {
    data_seed <- training_data_seed(pattern_family, training_size)
    set.seed(data_seed)
    training_sets[[as.character(training_size)]] <- create_landscapes(
      n = training_size,
      patterns = patterns
    )
    training_seeds[as.character(training_size)] <- data_seed
  }

  pilot_data[[pattern_family]] <- list(
    training = training_sets,
    training_seeds = training_seeds,
    validation = validation_landscapes,
    validation_seed = validation_seed
  )
}

# Create the paired configuration grid -----------------------------------

pilot_grid <- expand.grid(
  pattern_family = names(pattern_families),
  training_size = training_sizes,
  batch_size = batch_sizes,
  dropout_rate = dropout_rates,
  model_seed = model_seeds,
  stringsAsFactors = FALSE
) |>
  tibble::as_tibble() |>
  arrange(
    pattern_family,
    training_size,
    batch_size,
    dropout_rate,
    model_seed
  ) |>
  mutate(
    configuration_id = sprintf(
      "%s_n%d_bs%d_dr%02d_seed%d",
      pattern_family,
      training_size,
      batch_size,
      as.integer(round(dropout_rate * 10)),
      model_seed
    )
  )

if (anyDuplicated(pilot_grid$configuration_id)) {
  cli::cli_abort("Pilot configuration IDs must be unique.")
}

cli::cli_inform(c(
  "Running the batch-size and dropout pilot.",
  "i" = "Pilot version: {pilot_version}",
  "i" = "Configurations: {nrow(pilot_grid)}",
  "i" = "Final systematic test landscapes are not used."
))

# Fit models --------------------------------------------------------------

checkpoint_files <- file.path(
  checkpoint_directory,
  paste0(pilot_grid$configuration_id, ".rds")
)

for (i in seq_len(nrow(pilot_grid))) {
  config <- pilot_grid[i, ]
  checkpoint_file <- checkpoint_files[i]

  if (resume_existing && file.exists(checkpoint_file)) {
    checkpoint <- readr::read_rds(checkpoint_file)
    if (
      !identical(checkpoint$pilot_version, pilot_version) ||
        !identical(
          checkpoint$summary$configuration_id,
          config$configuration_id
        )
    ) {
      cli::cli_abort(
        "Checkpoint metadata does not match {.val {config$configuration_id}}."
      )
    }
    if (isTRUE(checkpoint$summary$success)) {
      cli::cli_inform(
        "Skipping completed configuration {i}/{nrow(pilot_grid)}: {config$configuration_id}"
      )
      next
    }
    cli::cli_inform(
      "Retrying failed configuration {i}/{nrow(pilot_grid)}: {config$configuration_id}"
    )
  }

  cli::cli_inform(
    "Fitting configuration {i}/{nrow(pilot_grid)}: {config$configuration_id}"
  )

  family_data <- pilot_data[[config$pattern_family]]
  training_landscapes <-
    family_data$training[[as.character(config$training_size)]]
  validation_landscapes <- family_data$validation
  data_seed <- unname(
    family_data$training_seeds[as.character(config$training_size)]
  )

  gc(verbose = FALSE)
  keras3::clear_session()
  set_random_seed(config$model_seed)

  model <- NULL
  start_time <- Sys.time()

  checkpoint <- tryCatch(
    {
      model <- train_pixel_model(
        landscapes = training_landscapes,
        validation_landscapes = validation_landscapes,
        cv_method = "none",
        epochs = epochs,
        batch_size = config$batch_size,
        learning_rate = learning_rate,
        dropout_rate = config$dropout_rate,
        patience = NULL,
        verbose = FALSE
      )

      performance <- model$performance
      history <- tibble::as_tibble(model$history$metrics) |>
        mutate(
          configuration_id = config$configuration_id,
          pattern_family = config$pattern_family,
          training_size = config$training_size,
          batch_size = config$batch_size,
          dropout_rate = config$dropout_rate,
          model_seed = config$model_seed,
          epoch = dplyr::row_number(),
          .before = 1
        )

      summary <- tibble::tibble(
        configuration_id = config$configuration_id,
        pattern_family = config$pattern_family,
        training_size = config$training_size,
        batch_size = config$batch_size,
        dropout_rate = config$dropout_rate,
        model_seed = config$model_seed,
        training_data_seed = data_seed,
        validation_data_seed = family_data$validation_seed,
        epochs = epochs,
        learning_rate = learning_rate,
        n_training = length(training_landscapes),
        n_validation = length(validation_landscapes),
        success = TRUE,
        error_message = NA_character_,
        validation_accuracy = performance$accuracy,
        validation_loss = performance$validation_loss,
        best_epoch = performance$best_epoch,
        best_validation_loss = performance$best_validation_loss,
        final_training_accuracy = last_history_metric(history, "accuracy"),
        final_training_loss = last_history_metric(history, "loss")
      )

      per_class <- performance$per_class_metrics |>
        mutate(
          configuration_id = config$configuration_id,
          pattern_family = config$pattern_family,
          training_size = config$training_size,
          batch_size = config$batch_size,
          dropout_rate = config$dropout_rate,
          model_seed = config$model_seed,
          .before = 1
        )

      list(
        pilot_version = pilot_version,
        summary = summary,
        per_class = per_class,
        history = history
      )
    },
    error = function(cnd) {
      list(
        pilot_version = pilot_version,
        summary = tibble::tibble(
          configuration_id = config$configuration_id,
          pattern_family = config$pattern_family,
          training_size = config$training_size,
          batch_size = config$batch_size,
          dropout_rate = config$dropout_rate,
          model_seed = config$model_seed,
          training_data_seed = data_seed,
          validation_data_seed = family_data$validation_seed,
          epochs = epochs,
          learning_rate = learning_rate,
          n_training = length(training_landscapes),
          n_validation = length(validation_landscapes),
          success = FALSE,
          error_message = conditionMessage(cnd),
          validation_accuracy = NA_real_,
          validation_loss = NA_real_,
          best_epoch = NA_integer_,
          best_validation_loss = NA_real_,
          final_training_accuracy = NA_real_,
          final_training_loss = NA_real_
        ),
        per_class = tibble::tibble(),
        history = tibble::tibble()
      )
    }
  )

  checkpoint$summary$runtime_minutes <- as.numeric(difftime(
    Sys.time(),
    start_time,
    units = "mins"
  ))

  readr::write_rds(checkpoint, checkpoint_file)

  if (!is.null(model)) {
    rm(model)
  }
  gc(verbose = FALSE)
  keras3::clear_session()
}

# Combine and summarize checkpoints --------------------------------------

missing_checkpoints <- checkpoint_files[!file.exists(checkpoint_files)]
if (length(missing_checkpoints) > 0) {
  cli::cli_abort(
    "Pilot finished without {length(missing_checkpoints)} expected checkpoint(s)."
  )
}

checkpoints <- lapply(checkpoint_files, readr::read_rds)
summary_results <- bind_rows(lapply(checkpoints, `[[`, "summary"))
per_class_results <- bind_rows(lapply(checkpoints, `[[`, "per_class"))
training_histories <- bind_rows(lapply(checkpoints, `[[`, "history"))

cell_summary <- summary_results |>
  summarise(
    n_requested = dplyr::n(),
    n_success = sum(success),
    n_failed = sum(!success),
    mean_validation_accuracy = mean_or_na(validation_accuracy),
    sd_validation_accuracy = sd_or_na(validation_accuracy),
    mean_validation_loss = mean_or_na(validation_loss),
    sd_validation_loss = sd_or_na(validation_loss),
    mean_runtime_minutes = mean_or_na(runtime_minutes),
    .by = c(pattern_family, training_size, batch_size, dropout_rate)
  )

global_summary <- cell_summary |>
  filter(n_success > 0) |>
  summarise(
    n_cells = dplyr::n(),
    n_requested = sum(n_requested),
    n_success = sum(n_success),
    n_failed = sum(n_failed),
    mean_cell_accuracy = mean(mean_validation_accuracy),
    minimum_cell_accuracy = min(mean_validation_accuracy),
    maximum_cell_accuracy_sd = max_or_na(sd_validation_accuracy),
    mean_cell_loss = mean(mean_validation_loss),
    mean_runtime_minutes = mean(mean_runtime_minutes),
    .by = c(batch_size, dropout_rate)
  ) |>
  arrange(desc(minimum_cell_accuracy), desc(mean_cell_accuracy), mean_cell_loss)

readr::write_csv(
  summary_results,
  file.path(results_directory, "pilot_fit_summary.csv")
)
readr::write_csv(
  cell_summary,
  file.path(results_directory, "pilot_cell_summary.csv")
)
readr::write_csv(
  global_summary,
  file.path(results_directory, "pilot_global_summary.csv")
)
readr::write_csv(
  per_class_results,
  file.path(results_directory, "pilot_per_class.csv")
)
readr::write_csv(
  training_histories,
  file.path(results_directory, "pilot_training_histories.csv")
)

print(global_summary, n = Inf)

if (any(!summary_results$success)) {
  cli::cli_alert_warning(
    "{sum(!summary_results$success)} pilot configuration(s) failed. Review pilot_fit_summary.csv."
  )
} else {
  cli::cli_alert_success("All {nrow(summary_results)} pilot fits completed.")
}

cli::cli_inform(
  "Pilot outputs were written to {.path {results_directory}}. Select one global batch-size and dropout pair without using final systematic test data."
)
