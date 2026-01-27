# This file contains all the functions to plot systematic test results for
# Keras or Neuralnet model results
#' Extract best and worst performing classes across multiple metrics
#'
#' @param one_result Single result object from neural network training
#'
#' @return Tibble with parameters and best/worst class performance across
#'   precision, recall, and F1 score
#'
#' @keywords internal
combine_validation_results <- function(one_result) {
  # if parameters exists, then extract the parameters (from keras tests)
  # otherwise create parameters by extracting information from the list (neural
  # net results)
  if ("parameters" %in% names(one_result)) {
    parameters <- one_result$parameters
    accuracy <- one_result$validation_accuracy
    per_class <- one_result$validation_per_class
  } else {
    parameters <- tibble(
      n_landscapes = one_result$training_size,
      layers = one_result$layers,
      metric = one_result$metric,
      inputmetrics = one_result$inputmetrics,
      replicate = one_result$replicate
    )
    accuracy <- one_result$validation$performance$accuracy
    per_class <- one_result$validation$performance$per_class_metrics
  }

  # Helper to extract best/worst with random tie-breaking
  get_extreme_class <- function(metric_col, fn) {
    extreme_val <- fn(metric_col, na.rm = TRUE)
    extreme_classes <- per_class$class[metric_col == extreme_val]

    if (length(extreme_classes) > 1) {
      sample(extreme_classes, 1)
    } else {
      extreme_classes
    }
  }

  # Extract for each metric
  best_precision <- get_extreme_class(per_class$precision, max)
  worst_precision <- get_extreme_class(per_class$precision, min)

  best_recall <- get_extreme_class(per_class$recall, max)
  worst_recall <- get_extreme_class(per_class$recall, min)

  best_f1 <- get_extreme_class(per_class$f1_score, max)
  worst_f1 <- get_extreme_class(per_class$f1_score, min)

  # Get corresponding values
  val_best_precision <- max(per_class$precision, na.rm = TRUE)
  val_worst_precision <- min(per_class$precision, na.rm = TRUE)

  val_best_recall <- max(per_class$recall, na.rm = TRUE)
  val_worst_recall <- min(per_class$recall, na.rm = TRUE)

  val_best_f1 <- max(per_class$f1_score, na.rm = TRUE)
  val_worst_f1 <- min(per_class$f1_score, na.rm = TRUE)

  # Combine into a tibble
  parameters |>
    bind_cols(tibble(
      validation_accuracy = accuracy,
      best_class_precision = best_precision,
      best_precision = val_best_precision,
      worst_class_precision = worst_precision,
      worst_precision = val_worst_precision,
      best_class_recall = best_recall,
      best_recall = val_best_recall,
      worst_class_recall = worst_recall,
      worst_recall = val_worst_recall,
      best_class_f1 = best_f1,
      best_f1 = val_best_f1,
      worst_class_f1 = worst_f1,
      worst_f1 = val_worst_f1
    ))
}

#' Create custom accuracy color scale with configurable threshold
#'
#' @param data_range Numeric vector of length 2 with [min, max] values
#' @param threshold Numeric value marking the "good" performance boundary (default: 0.8)
#' @param colors Named vector of 5 colors for low, mid1, mid2, high1, high2
#'
#' @return List with components for use in scale_fill_gradientn:
#'   - colours: color vector
#'   - values: rescaled boundaries
#'   - limits: data range
#'
#' @keywords internal
create_accuracy_scale <- function(
  data_range,
  threshold = 0.8,
  colors = c(
    "low" = "red",
    "mid1" = "orange",
    "mid2" = "yellow",
    "high1" = "#99ccff",
    "high2" = "#001f3f"
  )
) {
  # Validate inputs
  if (length(data_range) != 2 || data_range[1] >= data_range[2]) {
    cli::cli_abort("data_range must be a vector [min, max] with min < max")
  }
  if (threshold < data_range[1] || threshold > data_range[2]) {
    cli::cli_alert_warning(
      "threshold ({threshold}) is outside data range [{data_range[1]}, {data_range[2]}]"
    )
  }

  min_val <- data_range[1]
  max_val <- data_range[2]

  # Create 5 breakpoints: 3 below threshold, 2 above
  boundaries <- c(
    min_val,
    min_val + (threshold - min_val) / 3,
    min_val + 2 * (threshold - min_val) / 3,
    threshold,
    max_val
  )

  list(
    colours = unname(colors),
    values = scales::rescale(boundaries),
    limits = data_range
  )
}


# Find the most frequently occuring value
mode_random <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA)
  }
  tab <- table(x)
  max_freq <- max(tab)
  candidates <- names(tab)[tab == max_freq]
  sample(candidates, 1)
}

# how consistent is the worst class across runs?
entropy <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) <= 1) {
    return(0)
  }
  tab <- table(x) / length(x)
  -sum(tab * log2(tab))
}

#' Create summary statistics for systematic test results
#'
#' Aggregates validation results across replicates, computing mean/SD accuracy
#' and worst class statistics for precision, recall, and F1 scores.
#'
#' @param df_raw Tibble from map_dfr(all_results, combine_validation_results)
#' @param grouping_vars Character vector of column names to group by
#'
#' @return List with two tibbles:
#'   \describe{
#'     \item{accuracy}{Mean and SD accuracy by grouping variables}
#'     \item{worst_classes}{Worst class identification and entropy across metrics}
#'   }
#'
#' @keywords internal
create_systematic_summaries <- function(df_raw, grouping_vars) {
  # Validate grouping variables exist
  missing_vars <- setdiff(grouping_vars, names(df_raw))
  if (length(missing_vars) > 0) {
    cli::cli_abort(c(
      "Grouping variables not found in data:",
      "x" = "{.val {missing_vars}}"
    ))
  }

  # Accuracy summary
  df_summary <- df_raw |>
    summarize(
      mean_accuracy = mean(validation_accuracy),
      sd_accuracy = sd(validation_accuracy),
      .by = all_of(grouping_vars)
    ) |>
    mutate(
      across(
        where(is.numeric) & !matches("mean_|sd_"),
        factor
      )
    )

  # Worst class summary
  df_worst_summary <- df_raw |>
    summarize(
      # Precision-based worst class
      worst_class_precision = mode_random(worst_class_precision),
      worst_precision_entropy = entropy(worst_precision),
      mean_worst_precision = mean(worst_precision, na.rm = TRUE),

      # Recall-based worst class
      worst_class_recall = mode_random(worst_class_recall),
      worst_recall_entropy = entropy(worst_recall),
      mean_worst_recall = mean(worst_recall, na.rm = TRUE),

      # F1-based worst class
      worst_class_f1 = mode_random(worst_class_f1),
      worst_f1_entropy = entropy(worst_f1),
      mean_worst_f1 = mean(worst_f1, na.rm = TRUE),

      .by = all_of(grouping_vars)
    )

  df_worst_summary <- df_worst_summary |>
    mutate(
      across(
        where(is.numeric) & !matches("mean_|entropy|alpha"),
        factor
      ),

      # Normalized entropy for alpha mapping
      precision_entropy_norm = worst_precision_entropy /
        max(worst_precision_entropy, na.rm = TRUE),
      recall_entropy_norm = worst_recall_entropy /
        max(worst_recall_entropy, na.rm = TRUE),
      f1_entropy_norm = worst_f1_entropy /
        max(worst_f1_entropy, na.rm = TRUE),

      # Alpha values (high entropy = low alpha = more transparent)
      alpha_precision = 1 - precision_entropy_norm,
      alpha_recall = 1 - recall_entropy_norm,
      alpha_f1 = 1 - f1_entropy_norm
    )

  list(
    accuracy = df_summary,
    worst_classes = df_worst_summary
  )
}
