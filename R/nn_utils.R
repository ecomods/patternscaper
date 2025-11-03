#' Convert landscape metrics from long to wide format
#'
#' This function transforms landscape metrics from a long format to a wide
#' format that is needed to train nn models
#'
#' @param metrics A data frame containing landscape metrics in long format.
#'   Expected columns include: `metric`, `class`, `id`, `value`, `pattern`.
#'   Must include either `landscape_id` or `landscape_name` for identification.
#' @param keep_id Logical. Whether to keep the identification column in output (default: FALSE).
#'
#' @return A data frame in wide format where each metric becomes a column and each
#'   row is a landscape. Metric names are modified to include class and patch IDs
#'   when applicable (format: `metric_class_id`).
#' @keywords internal
#' @importFrom dplyr mutate select
#' @importFrom rlang sym
#' @importFrom stringr str_remove
#' @importFrom tidyr pivot_wider
metrics_to_wide <- function(metrics, keep_id = FALSE) {
  # Determine which ID column to use (prefer landscape_id over landscape_name)
  id_col <- if ("landscape_id" %in% colnames(metrics)) {
    "landscape_id"
  } else if ("landscape_name" %in% colnames(metrics)) {
    "landscape_name"
  } else {
    cli::cli_abort(
      "Metrics must contain either 'landscape_id' or 'landscape_name' column"
    )
  }

  # Build metric names with class/patch ID when not at landscape level
  metrics <- metrics |>
    dplyr::mutate(
      metric = stringr::str_remove(
        paste0(metric, "_", class, "_", id),
        "_NA_NA"
      )
    ) |>
    dplyr::select(!!rlang::sym(id_col), metric, value, pattern)

  # Pivot to wide format
  metrics_wide <- metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    )

  # Drop ID column unless requested
  if (!keep_id) {
    metrics_wide <- metrics_wide |>
      dplyr::select(-!!rlang::sym(id_col))
  }

  metrics_wide
}

#' Validate and adjust cross-validation parameters
#'
#' Checks if the dataset is suitable for the requested cross-validation method
#' and adjusts parameters if needed. Issues warnings or errors for problematic
#' configurations.
#'
#' @param patterns Factor or character vector. Class labels for training data.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", or "loo".
#' @param cv_folds Integer. Number of folds for k-fold CV.
#' @param n_predictors Integer. Number of predictor variables (optional, for sample-to-predictor ratio check).
#'
#' @return List with validated/adjusted CV parameters:
#'   \item{cv_method}{Adjusted CV method (may switch from k-fold to loo)}
#'   \item{cv_folds}{Adjusted number of folds}
#'   \item{class_counts}{Named vector of sample counts per class}
#'   \item{total_samples}{Total number of samples}
#'
#' @keywords internal
#' @importFrom cli cli_warn cli_abort cli_alert_warning
validate_cv_params <- function(
  patterns,
  cv_method,
  cv_folds,
  n_predictors = NULL
) {
  # Get sample counts
  class_counts <- table(patterns)
  min_class_count <- min(class_counts)
  total_samples <- length(patterns)

  # No validation needed for cv_method = "none"
  if (cv_method == "none") {
    return(list(
      cv_method = cv_method,
      cv_folds = NULL,
      class_counts = class_counts,
      total_samples = total_samples
    ))
  }

  # Check sample-to-predictor ratio if n_predictors provided
  # TODO: Check if this is recommended
  if (!is.null(n_predictors)) {
    min_total_samples <- n_predictors * 5
    if (total_samples < min_total_samples) {
      cli::cli_warn(
        "Small sample-to-predictor ratio ({total_samples} samples, {n_predictors} predictors). Consider LOO CV or reducing features."
      )
    }
  }

  # Check for severe class imbalance
  imbalance_ratio <- max(class_counts) / min(class_counts)
  if (imbalance_ratio > 5) {
    cli::cli_warn(
      "Severe class imbalance detected (ratio: {round(imbalance_ratio, 1)}:1). CV results may be unreliable for minority classes."
    )
  }

  # Validate and adjust k-fold parameters
  if (cv_method == "k-fold") {
    # Minimum samples per class per fold (3 recommended for stable training)
    min_samples_per_fold <- 3

    # Check if dataset is fundamentally too small for k-fold
    if (total_samples < 30 || min_class_count < 5) {
      cli::cli_warn(
        "Dataset is small (n={total_samples}) or has classes with few samples (min={min_class_count}). Switching to leave-one-out CV for more reliable estimates."
      )
      cv_method <- "loo"
    } else {
      # Calculate maximum suitable folds to maintain min_samples_per_fold
      max_suitable_folds <- floor(min_class_count / min_samples_per_fold)

      # If we can't maintain enough samples even with 2 folds
      if (max_suitable_folds < 2) {
        cli::cli_warn(
          "Cannot maintain {min_samples_per_fold} samples per class per fold. Switching to leave-one-out CV."
        )
        cv_method <- "loo"
      } else if (cv_folds > max_suitable_folds) {
        # Reduce folds but keep k-fold CV
        cli::cli_warn(
          "Reducing CV folds from {cv_folds} to {max_suitable_folds} to ensure at least {min_samples_per_fold} samples per class per fold."
        )
        cv_folds <- max_suitable_folds
      }
    }
  }

  # Validate LOO parameters
  if (cv_method == "loo") {
    # Warn if LOO will be computationally expensive
    if (total_samples > 500) {
      cli::cli_warn(
        "LOO CV with {total_samples} samples will be slow. Consider k-fold CV instead."
      )
    }

    # Check for singleton classes (fatal for LOO)
    if (any(class_counts == 1)) {
      singleton_classes <- names(class_counts[class_counts == 1])
      cli::cli_abort(
        "Cannot perform LOO CV: class{?es} {.val {singleton_classes}} ha{?s/ve} only 1 sample. Need at least 2 per class."
      )
    }

    # Set cv_folds to total samples for reporting
    cv_folds <- total_samples
  }

  # Warn about very small classes
  small_classes <- names(class_counts[class_counts < 3])
  if (length(small_classes) > 0) {
    cli::cli_warn(
      "Some classes have very few samples (< 3): {.val {small_classes}}. Cross-validation results for these classes may be unreliable."
    )
  }

  return(list(
    cv_method = cv_method,
    cv_folds = cv_folds,
    class_counts = class_counts,
    total_samples = total_samples
  ))
}

#' Create balanced fold indices for cross-validation
#'
#' Creates stratified fold assignments ensuring each class is represented
#' proportionally in each fold.
#'
#' @param patterns Factor or character vector. Class labels for training data.
#' @param cv_folds Integer. Number of folds for k-fold CV
#'
#' @return Integer vector of fold assignments (length = length(patterns)).
#'   Each element indicates which fold that sample belongs to.
#'
#' @keywords internal
find_balanced_cv_folds <- function(patterns, cv_folds) {
  n_samples <- length(patterns)

  # For k-fold: stratified sampling to ensure class balance across folds
  fold_indices <- integer(n_samples)
  class_names <- unique(patterns)

  for (class_name in class_names) {
    class_indices <- which(patterns == class_name)
    # Randomly assign folds, cycling through 1:cv_folds
    class_folds <- sample(rep(
      1:cv_folds,
      length.out = length(class_indices)
    ))
    fold_indices[class_indices] <- class_folds
  }

  return(fold_indices)
}
