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
  parameters <- one_result$parameters
  accuracy <- one_result$validation_accuracy
  per_class <- one_result$validation_per_class

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
