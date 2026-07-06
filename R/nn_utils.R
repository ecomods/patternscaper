#' Set Random Seeds for Reproducible Neural Network Training
#'
#' Sets random seeds for R and Keras to ensure reproducible results when
#' training neural networks. This is a convenience wrapper around [base::set.seed()]
#' and [keras3::set_random_seed()].
#'
#' @param seed Integer seed value.
#'
#' @details
#' Neural network training involves randomness from:
#' - R's RNG (data shuffling, CV fold creation)
#' - Keras/TensorFlow's RNG (weight initialization, dropout)
#'
#' Both must be seeded for reproducible results. Note that minor variations
#' may still occur across different hardware/software configurations.
#'
#' @return Invisibly returns `NULL`. Called for side effects.
#'
#' @family neural network training
#' @export
#' @examples
#' \donttest{
#' # Ensure reproducible training
#' set_random_seed(42)
#' landscapes <- create_landscapes(n=5)
#' model <- train_pixel_model(landscapes, cv_method = "none", epochs = 10)
#' }
set_random_seed <- function(seed) {
  if (!is.numeric(seed) || length(seed) != 1) {
    cli::cli_abort("{.arg seed} must be a single integer value")
  }

  seed <- as.integer(seed)

  # R's RNG
  set.seed(seed)

  # Keras3's RNG (includes TensorFlow backend)
  keras3::set_random_seed(seed)

  invisible(NULL)
}

#' Convert landscape metrics from long to wide format
#'
#' This function transforms landscape metrics from a long format to a wide
#' format that is needed to train nn models
#'
#' @param metrics A data frame containing landscape metrics in long format.
#'   Expected columns include: `metric`, `class`, `value`, `pattern`.
#'   Must include either `landscape_id` or `landscape_name` for identification.
#' @param return_only_metrics Logical. Whether to return only the metrics or
#'   also the the identification columns in output (default: FALSE).
#'
#' @return A data frame in wide format where each metric becomes a column and each
#'   row is a landscape. Metric names already include class IDs when applicable
#'   (format: `metric_class_id`); that folding is done upstream in
#'   \code{\link{calculate_metrics}}, not here.
#' @keywords internal
#' @importFrom dplyr mutate select
#' @importFrom tidyr pivot_wider
metrics_to_wide <- function(metrics, return_only_metrics = FALSE) {
  # Determine which ID column to use (prefer landscape_id over landscape_name)
  if (!any(c("landscape_id", "landscape_name") %in% colnames(metrics))) {
    cli::cli_abort(
      "Metrics must contain either 'landscape_id' or 'landscape_name' column"
    )
  }

  # Build metric names with class ID when not at landscape level
  metrics <- metrics |>
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

#' Row-wise softmax
#'
#' Converts a matrix of raw (unbounded) row scores into per-row probabilities
#' using a numerically stable softmax (each row's maximum is subtracted before
#' exponentiating).
#'
#' @param x Numeric matrix; each row is a set of raw scores.
#' @return A matrix the same shape as `x` whose rows each sum to 1.
#' @keywords internal
softmax_rows <- function(x) {
  t(apply(x, 1, function(row) {
    exp_row <- exp(row - max(row))
    exp_row / sum(exp_row)
  }))
}

#' Scale a validation fold using only the training fold's statistics
#'
#' Fits centering/scaling on the training-fold predictors alone and applies the
#' same statistics to both the training and validation predictors. This keeps
#' the validation rows from contributing to the `center`/`scale` used on them,
#' avoiding the optimistic leakage that arises when the whole dataset is scaled
#' before cross-validation. Columns that are constant within the training fold
#' (`sd == 0`, or `NA` for a single-row fold) are given `scale = 1` so they
#' become all-zero after centering instead of `NaN`.
#'
#' @param train_predictors Data frame or matrix of training-fold predictors.
#' @param val_predictors Data frame or matrix of validation-fold predictors.
#'
#' @return List with `train` and `val`: numeric matrices scaled with the
#'   training-fold center/scale.
#' @keywords internal
#' @importFrom stats sd
scale_fold <- function(train_predictors, val_predictors) {
  train_predictors <- as.matrix(train_predictors)
  val_predictors <- as.matrix(val_predictors)

  center <- colMeans(train_predictors)
  scale_sd <- apply(train_predictors, 2, stats::sd)
  # Guard columns that are constant within the training fold to avoid /0 -> NaN
  scale_sd[is.na(scale_sd) | scale_sd == 0] <- 1

  list(
    train = scale(train_predictors, center = center, scale = scale_sd),
    val = scale(val_predictors, center = center, scale = scale_sd)
  )
}

#' Validate and adjust cross-validation parameters
#'
#' Checks if the dataset is suitable for the requested cross-validation method
#' and adjusts parameters if needed. Issues warnings or errors for problematic
#' configurations.
#'
#' @param patterns Factor or character vector. Class labels for training data.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", or "loo".
#'   Already validated by calling function.
#' @param cv_folds Integer. Number of folds for k-fold CV.
#'   Already validated by calling function when cv_method = "k-fold".
#' @param n_predictors Integer. Number of predictor variables (optional, for
#'   sample-to-predictor ratio check).
#' @param min_samples_per_fold Integer. Minimum samples per class per fold for
#'   k-fold CV (default: 3).
#'
#' @return List with validated/adjusted CV parameters:
#'   \item{cv_method}{Adjusted CV method (may switch from k-fold to loo)}
#'   \item{cv_folds}{Integer number of folds, or 1L for "none"}
#'   \item{class_counts}{Named vector of sample counts per class}
#'   \item{total_samples}{Total number of samples}
#'
#' @keywords internal
#' @importFrom cli cli_warn cli_alert_info
validate_cv_params <- function(
  patterns,
  cv_method,
  cv_folds,
  n_predictors = NULL,
  min_samples_per_fold = 3
) {
  # Get sample counts
  class_counts <- table(patterns)
  min_class_count <- min(class_counts)
  total_samples <- length(patterns)

  # Return early for cv_method = "none"
  if (cv_method == "none") {
    return(list(
      cv_method = cv_method,
      cv_folds = 1L,
      class_counts = class_counts,
      total_samples = total_samples
    ))
  }

  # Check sample-to-predictor ratio if provided
  if (!is.null(n_predictors)) {
    samples_per_predictor <- total_samples / n_predictors
    if (samples_per_predictor < 5) {
      cli::cli_alert_info(
        "Low sample-to-predictor ratio ({round(samples_per_predictor, 1)}:1). Consider LOO CV or reducing features."
      )
    }
  }

  # Check for severe class imbalance
  imbalance_ratio <- max(class_counts) / min(class_counts)
  if (imbalance_ratio > 5) {
    cli::cli_alert_info(
      "Severe class imbalance detected (ratio {round(imbalance_ratio, 1)}:1). CV results may be unreliable for minority classes."
    )
  }

  # Validate and adjust k-fold parameters
  if (cv_method == "k-fold") {
    # Calculate maximum suitable folds to maintain min_samples_per_fold
    max_suitable_folds <- floor(min_class_count / min_samples_per_fold)

    # If we can't maintain enough samples even with 2 folds
    if (max_suitable_folds < 2) {
      cli::cli_alert_info(
        "Cannot maintain {min_samples_per_fold} samples per class per fold (smallest class: {min_class_count}). Switching to LOO CV."
      )
      cv_method <- "loo"
      cv_folds <- total_samples
    } else if (cv_folds > max_suitable_folds) {
      # Reduce folds but keep k-fold CV
      cli::cli_alert_info(
        "Reducing CV folds from {cv_folds} to {max_suitable_folds} to maintain {min_samples_per_fold} samples per class per fold."
      )
      cv_folds <- max_suitable_folds
    }
  }

  # Validate LOO parameters
  if (cv_method == "loo") {
    # Check for singleton classes (fatal for LOO)
    if (any(class_counts == 1)) {
      singleton_classes <- names(class_counts[class_counts == 1])
      cli::cli_abort(
        "Cannot perform LOO CV: class{?es} {.val {singleton_classes}} ha{?s/ve} only 1 sample. Need at least 2 per class."
      )
    }

    # Warn if LOO will be computationally expensive
    # LOO is reasonable up to ~200 samples for metrics, ~100 for keras
    if (total_samples > 100) {
      cli::cli_alert_info(
        "LOO CV with {total_samples} samples may be slow. Consider k-fold CV instead."
      )
    }

    cv_folds <- total_samples
  }

  # Warn about very small classes
  small_classes <- names(class_counts[class_counts < min_samples_per_fold])
  if (length(small_classes) > 0) {
    cli::cli_alert_info(
      "Some classes have few samples (< {min_samples_per_fold}): {.val {small_classes}}. CV results for these may be unreliable."
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
    cli::cli_abort("Length of cv_predictions and cv_actual must be the same")
  }
  if (length(cv_probabilities) != length(cv_actual)) {
    cli::cli_abort("Length of cv_probabilities and cv_actual must be the same")
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

#' Remove landscapes with incomplete metrics
#'
#' First drops any predictor columns that are NA for every landscape (metrics
#' that are undefined for the given landscapes carry no information and would
#' otherwise remove the entire dataset). Then removes landscapes that still
#' have NA values in any remaining predictor column. Issues warnings listing
#' dropped metrics and removed landscapes, and aborts if no usable predictors
#' or landscapes remain.
#'
#' @param metrics_wide Data frame in wide format. Output from metrics_to_wide().
#' @param predictor_cols Character vector. Names of predictor columns to check for NAs.
#'
#' @return Data frame with incomplete landscapes removed.
#'
#' @keywords internal
#' @importFrom cli cli_warn cli_abort
remove_incomplete_landscapes <- function(metrics_wide, predictor_cols) {
  # Drop predictor columns that are NA for every landscape. These metrics are
  # undefined for the given landscapes (e.g. iji or rpr for two-class
  # landscapes) and carry no information. If left in place they would flag
  # every landscape as incomplete and remove the entire dataset.
  all_na_cols <- predictor_cols[vapply(
    predictor_cols,
    function(col) all(is.na(metrics_wide[[col]])),
    logical(1)
  )]

  if (length(all_na_cols) > 0) {
    cli::cli_warn(c(
      "Dropped {length(all_na_cols)} metric{?s} that {?is/are} NA for all landscapes",
      "i" = "Dropped: {.val {all_na_cols}}"
    ))
    metrics_wide <- metrics_wide[,
      setdiff(colnames(metrics_wide), all_na_cols),
      drop = FALSE
    ]
    predictor_cols <- setdiff(predictor_cols, all_na_cols)
  }

  # If no predictor columns remain there is nothing to train or predict on.
  if (length(predictor_cols) == 0) {
    cli::cli_abort(c(
      "No landscapes remaining after removing those with incomplete metrics",
      "i" = "All required features were NA for every landscape"
    ))
  }

  # Check for rows with any NA values in the remaining predictor columns
  na_rows <- rowSums(is.na(metrics_wide[, predictor_cols, drop = FALSE])) > 0

  if (any(na_rows)) {
    n_removed <- sum(na_rows)
    removed_names <- metrics_wide$landscape_name[na_rows]

    cli::cli_warn(c(
      "Removed {n_removed} landscape{?s} with incomplete metrics",
      "i" = "Removed: {.val {removed_names}}"
    ))

    metrics_wide <- metrics_wide[!na_rows, ]

    # Check if we have any landscapes left
    if (nrow(metrics_wide) == 0) {
      cli::cli_abort(c(
        "No landscapes remaining after removing those with incomplete metrics",
        "i" = "All {n_removed} landscape{?s} had NA values in required features"
      ))
    }
  }

  return(metrics_wide)
}

#' Fit a neural network with a helpful error on training failure
#'
#' Wraps \code{neuralnet::neuralnet()} and converts its cryptic "the error
#' derivative contains a NA" failure into an actionable error. That failure
#' typically means the network is over-parameterized for the data (e.g. far
#' more metrics than landscapes), so the message points the user at metric
#' selection. Any other error is re-raised unchanged.
#'
#' @param data Data frame with predictor columns and a \code{pattern} factor.
#' @param hidden Numeric vector. Hidden layer sizes.
#' @param threshold Numeric. Passed to \code{neuralnet::neuralnet()}.
#' @param stepmax Numeric. Passed to \code{neuralnet::neuralnet()}.
#'
#' @return A trained \code{nn} object.
#'
#' @keywords internal
#' @importFrom cli cli_abort
fit_nn_model <- function(data, hidden, threshold, stepmax) {
  tryCatch(
    neuralnet::neuralnet(
      formula = pattern ~ .,
      data = data,
      hidden = hidden,
      threshold = threshold,
      stepmax = stepmax
    ),
    error = function(e) {
      if (grepl("error derivative contains a NA", conditionMessage(e), fixed = TRUE)) {
        cli::cli_abort(
          c(
            "Neural network training failed to converge.",
            "x" = "The error derivative became NA, usually because there are too many metrics relative to the number of landscapes.",
            "i" = "Select fewer metrics with {.fn evaluate_metrics} and pass them via {.arg metrics_selected}.",
            "i" = "Or train on more landscapes (increase {.arg n} in {.fn create_landscapes})."
          ),
          parent = e
        )
      }
      # Re-raise any other error unchanged
      stop(e)
    }
  )
}
