#' Convert landscape metrics from long to wide format
#'
#' This function transforms landscape metrics from a long format to a wide
#' format that is needed to train nn models
#'
#' @param metrics A data frame containing landscape metrics in long format.
#'   Expected columns include: `metric`, `class`, `id`, `value`, `pattern`.
#'   Must include either `landscape_id` or `landscape_name` for identification.
#' @param return_only_metrics Logical. Whether to return only the metrics or
#'   also the the identification columns in output (default: FALSE).
#'
#' @return A data frame in wide format where each metric becomes a column and each
#'   row is a landscape. Metric names are modified to include class and patch IDs
#'   when applicable (format: `metric_class_id`).
#' @keywords internal
#' @importFrom dplyr mutate select
#' @importFrom rlang sym
#' @importFrom stringr str_remove
#' @importFrom tidyr pivot_wider
metrics_to_wide <- function(metrics, return_only_metrics = FALSE) {
  # Determine which ID column to use (prefer landscape_id over landscape_name)
  if (!any(c("landscape_id", "landscape_name") %in% colnames(metrics))) {
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
    dplyr::select(dplyr::any_of(c(
      "landscape_id",
      "landscape_name",
      "metric",
      "value",
      "pattern"
    )))

  # Pivot to wide format
  metrics_wide <- metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    )

  # Drop ID column unless requested
  if (return_only_metrics) {
    metrics_wide <- metrics_wide |>
      dplyr::select(-any_of(c("landscape_id", "landscape_name", "pattern")))
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
#' @param cv_folds Integer. Number of folds for k-fold CV.
#'
#' @return Integer vector of fold assignments (length = length(patterns)).
#'   Each element indicates which fold that sample belongs to (1 to cv_folds).
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

#' Evaluate cross-validation performance
#'
#' Calculates performance metrics from cross-validation results including
#' confusion matrix, accuracy, and per-class metrics (recall, precision, F1).
#'
#' @param cv_predictions List. Predicted class labels for each fold.
#' @param cv_probabilities List. Prediction probabilities for each fold.
#'   Each element should be a matrix or data frame with class probabilities.
#' @param cv_actual List. Actual class labels for each fold.
#' @param cv_landscape_ids List. Landscape IDs for each fold. Needed to
#'   map predictions back to original landscapes.
#' @param class_names Character vector. Names of all classes in the dataset.
#' @param cv_method Character. Cross-validation method used ("none", "k-fold", or "loo").
#' @param cv_folds Integer. Number of folds used.
#' @param verbose Logical. Whether to print detailed results (default: TRUE).
#' @param return_predictions Logical. Whether to include validation_results
#'   tibble with detailed per-landscape predictions (default: TRUE).
#'
#' @return List with performance metrics:
#'   \describe{
#'     \item{confusion_matrix}{Confusion matrix table}
#'     \item{accuracy}{Overall accuracy (numeric)}
#'     \item{per_class_metrics}{Tibble with per-class recall, precision, and F1 scores}
#'     \item{cv_method}{CV method used (character)}
#'     \item{cv_folds}{Number of folds used (integer)}
#'     \item{class_counts}{Sample counts per class (integer vector)}
#'     \item{validation_results}{Tibble with detailed predictions per landscape
#'       (only included if return_predictions = TRUE)}
#'   }
#'
#' @keywords internal
#' @importFrom cli cli_warn cli_abort
evaluate_cv_performance <- function(
  cv_predictions,
  cv_probabilities,
  cv_actual,
  cv_landscape_ids,
  class_names,
  cv_method,
  cv_folds,
  verbose = TRUE,
  return_predictions = TRUE
) {
  # Validate inputs
  if (length(cv_predictions) != length(cv_actual)) {
    stop("Length of cv_predictions and cv_actual must be the same")
  }
  if (length(cv_probabilities) != length(cv_actual)) {
    stop("Length of cv_probabilities and cv_actual must be the same")
  }

  # Add validation at the start of the function
  if (
    !all(
      sapply(cv_probabilities, is.matrix) |
        sapply(cv_probabilities, is.data.frame)
    )
  ) {
    cli::cli_abort("cv_probabilities must contain matrices or data frames")
  }

  # Check probability columns match class_names
  prob_colnames <- colnames(cv_probabilities[[1]])
  if (!identical(sort(prob_colnames), sort(class_names))) {
    cli::cli_abort(
      "Probability column names don't match class_names. Expected: {.val {class_names}}"
    )
  }

  # Create confusion matrix
  conf_matrix <- table(
    Predicted = factor(unlist(cv_predictions), levels = class_names),
    Actual = factor(unlist(cv_actual), levels = class_names)
  )

  # Check for classes that were never correctly predicted
  correctly_predicted <- diag(conf_matrix)
  never_predicted_classes <- class_names[correctly_predicted == 0]

  if (length(never_predicted_classes) > 0) {
    cli::cli_warn(
      "Some classes were never correctly predicted during cross-validation: {.val {never_predicted_classes}}. Results for these classes are unreliable."
    )
  }

  # Calculate overall accuracy
  accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)

  # Calculate per-class metrics
  class_recall <- diag(conf_matrix) / colSums(conf_matrix)
  class_precision <- diag(conf_matrix) / rowSums(conf_matrix)

  # Handle divisions by zero
  class_precision[is.na(class_precision)] <- 0
  class_recall[is.na(class_recall)] <- 0

  # Calculate F1 scores
  class_f1 <- 2 *
    class_precision *
    class_recall /
    (class_precision + class_recall)
  class_f1[is.na(class_f1)] <- 0

  # Get class counts
  class_counts <- table(unlist(cv_actual))

  # Combine into per-class metrics table
  per_class_metrics <- tibble::tibble(
    class = class_names,
    count = as.vector(class_counts[class_names]),
    recall = round(class_recall, 2),
    precision = round(class_precision, 2),
    f1_score = round(class_f1, 2)
  )

  # Assemble validation results tibble
  validation_results <- purrr::map2_dfr(
    cv_probabilities,
    seq_along(cv_probabilities),
    \(probs, fold_num) {
      tibble::as_tibble(probs) |>
        dplyr::mutate(fold = fold_num)
    }
  ) |>
    dplyr::mutate(
      landscape_id = unlist(cv_landscape_ids),
      actual_class = unlist(cv_actual),
      predicted_class = unlist(cv_predictions),
      confidence = apply(dplyr::across(dplyr::all_of(class_names)), 1, max)
    ) |>
    dplyr::relocate(c(
      landscape_id,
      fold,
      actual_class,
      predicted_class,
      confidence
    ))

  if (verbose) {
    # Header
    cli::cli_h2("Cross-validation results")

    # CV method info
    cv_label <- ifelse(
      cv_method == "loo",
      "leave-one-out",
      paste0(cv_folds, "-fold")
    )
    cli::cli_alert_info("Method: {cv_label} cross-validation")
    cli::cli_alert_info("Overall accuracy: {round(accuracy * 100, 2)}%")

    # Confusion matrix
    cli::cli_h3("Confusion matrix")
    print(conf_matrix)

    # Per-class metrics
    cli::cli_h3("Per-class performance")
    print(per_class_metrics)
  }

  result <- list(
    confusion_matrix = conf_matrix,
    accuracy = accuracy,
    per_class_metrics = per_class_metrics,
    cv_method = cv_method,
    cv_folds = cv_folds,
    class_counts = as.vector(class_counts[class_names])
  )
  if (return_predictions) {
    result$validation_results <- validation_results
  }

  return(result)
}
