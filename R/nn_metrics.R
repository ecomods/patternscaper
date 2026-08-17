#' Train a Multi-Layer Neural Network for Landscape Pattern Classification
#'
#' Trains a multi-layer neural network model to classify landscapes
#' using landscape metrics as features and using the \pkg{neuralnet} package.
#' The network's input layer has one neuron per metric, and the
#' output layer represents the pattern classes.
#'
#' @param metrics Tibble or data frame. Output from calculate_metrics()
#'   containing landscape metrics in long format with required columns:
#'   landscape_id, landscape_name, pattern, level, class, metric, value.
#' @param metrics_selected Character vector of metric names to use as features,
#'   or NULL to use all available metrics. Default: NULL.
#' @param cv_method Character. Cross-validation method: "none", "k-fold", or "loo".
#'   May be automatically adjusted based on dataset size via validate_cv_params().
#'   Default: "k-fold".
#' @param cv_folds Integer. Number of folds for k-fold cross-validation.
#'   May be automatically reduced if dataset is too small. Default: 5.
#' @param hidden_layers Integer vector. Number of neurons in each hidden layer
#'   passed to \code{\link[neuralnet]{neuralnet}}.
#'   Length determines number of hidden layers. Default: 6 (single hidden layer with 6 neurons).
#' @param threshold Numeric. Threshold for partial derivatives as stopping criteria
#'   passed to \code{\link[neuralnet]{neuralnet}}.
#'   Smaller values = more training iterations. Default: 0.01.
#' @param stepmax Integer. Maximum number of training steps passed to \code{\link[neuralnet]{neuralnet}}. Default: 1e+05.
#' @param na_action Character. How to obtain the complete predictor matrix the
#'   network requires when a metric is missing for some but not all landscapes.
#'   \code{"drop_metrics"} (default) drops the affected metrics and keeps every
#'   landscape; \code{"drop_landscapes"} keeps every metric and drops the affected
#'   landscapes. Either way the cost of both options is reported. Metrics that are
#'   NA for every landscape, and landscapes that are
#'   NA for every metric, are always removed first as they do not carry any information.
#' @param verbose Logical. Print training details and cross-validation results.
#'   Default: TRUE. When FALSE, most output is silenced, but warnings about the requested CV
#'   configuration being adjusted (e.g. folds reduced, switched to LOO) are
#'   always shown.
#'
#' @return List containing:
#'   \describe{
#'     \item{model}{Trained neuralnet model object}
#'     \item{features}{Character vector of metric names used as features}
#'     \item{features_level}{Character. Metric aggregation level ("landscape" or "class")}
#'     \item{scaling}{List with 'center' and 'scale' parameters for normalization}
#'     \item{classes}{Character vector of class names in alphabetical order}
#'     \item{performance}{List from evaluate_cv_performance() with confusion matrix,
#'       accuracy, per-class metrics, and validation results. NULL if cv_method = "none".}
#'     \item{training_geometry}{One-row tibble summarising the geometry of the training
#'       landscapes, used by \code{\link{apply_metric_model}} to warn on geometry
#'       mismatch. NULL if the metrics table carries no geometry columns.}
#'   }
#' @examples
#' \donttest{
#' # Generate training landscapes
#' landscapes <- create_landscapes(
#'   n = 18,
#'   patterns = c("random", "sharp", "diffuse")
#' )
#'
#' # Calculate landscape metrics
#' metrics <- calculate_metrics(landscapes, level = "landscape")
#'
#' # Find the best 5 metrics for classification
#' best_5 <- evaluate_metrics(metrics, metrics_number = 5)
#'
#' # Train model with cross-validation. Only 2 folds, as each fold needs at
#' # least 3 landscapes per pattern.
#' model <- train_metric_model(
#'   metrics,
#'   metrics_selected = best_5,
#'   cv_method = "k-fold",
#'   cv_folds = 2
#' )
#'
#' # Train with specific metrics, on all data and without cross-validation
#' selected <- c("ai", "lsi", "ed", "np")
#' model <- train_metric_model(
#'   metrics,
#'   metrics_selected = selected,
#'   cv_method = "none",
#'   hidden_layers = c(8, 4)
#' )
#'
#' # Save the model, to apply it later without retraining
#' model_file <- tempfile(fileext = ".rds")
#' saveRDS(model, model_file)
#' model <- readRDS(model_file)
#' }
#' @seealso \code{\link{apply_metric_model}}, \code{\link{evaluate_metrics}}
#' @family neural network training
#' @export
#' @importFrom cli cli_abort cli_alert_warning
#' @importFrom dplyr filter select any_of all_of
#' @importFrom purrr pmap_lgl
#' @importFrom neuralnet neuralnet
#' @importFrom stats predict
train_metric_model <- function(
  metrics,
  metrics_selected = NULL,
  cv_method = "k-fold",
  cv_folds = 5,
  hidden_layers = 6,
  threshold = 0.01,
  stepmax = 1e+05,
  na_action = "drop_metrics",
  verbose = TRUE
) {
  # Validate input parameters -------------------------------------------------
  if (!is.logical(verbose) || length(verbose) != 1) {
    cli::cli_abort("verbose must be a single logical value (TRUE or FALSE)")
  }

  if (
    !is.numeric(hidden_layers) ||
      any(hidden_layers < 1) ||
      any(hidden_layers != floor(hidden_layers))
  ) {
    cli::cli_abort("hidden_layers must be positive integer(s)")
  }

  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    cli::cli_abort("threshold must be a single positive numeric value")
  }

  if (
    !is.numeric(stepmax) ||
      length(stepmax) != 1 ||
      stepmax < 1 ||
      stepmax != floor(stepmax)
  ) {
    cli::cli_abort("stepmax must be a single positive integer")
  }

  if (
    !is.numeric(cv_folds) ||
      length(cv_folds) != 1 ||
      cv_folds < 2 ||
      cv_folds != floor(cv_folds)
  ) {
    cli::cli_abort("cv_folds must be a single integer >= 2")
  }

  # Validate columns of metrics
  needed_columns <- c(
    "landscape_id",
    "landscape_name",
    "pattern",
    "level",
    "class",
    "metric",
    "value"
  )
  if (!all(needed_columns %in% colnames(metrics))) {
    missing_cols <- needed_columns[!needed_columns %in% colnames(metrics)]
    cli::cli_abort(c(
      "Metrics data is missing required columns",
      "x" = "Missing: {.val {missing_cols}}",
      "i" = "Make sure metrics is calculated by {.fn calculate_metrics}"
    ))
  }

  # Validate cv_method parameter
  cv_method <- tolower(cv_method)
  if (!cv_method %in% c("none", "k-fold", "loo")) {
    cli::cli_abort('cv_method must be one of: "none", "k-fold", or "loo"')
  }

  # Validate na_action parameter
  if (!na_action %in% c("drop_metrics", "drop_landscapes")) {
    cli::cli_abort(
      'na_action must be one of: "drop_metrics" or "drop_landscapes"'
    )
  }

  # Subset selected metrics if provided
  metrics_selected <- selected_metric_names(metrics_selected)
  if (!is.null(metrics_selected)) {
    missing_metrics <- setdiff(metrics_selected, unique(metrics$metric))
    if (length(missing_metrics) > 0) {
      cli::cli_abort(c(
        "Some selected metrics not found in data:",
        "x" = "{.val {missing_metrics}}"
      ))
    }
    metrics <- metrics |> dplyr::filter(metric %in% metrics_selected)
  }

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Deal with NA values -------------------------------------------------------
  predictor_cols <- setdiff(
    colnames(metrics_wide),
    c("landscape_id", "landscape_name", "pattern")
  )

  patterns_before <- unique(metrics_wide$pattern)
  metrics_wide <- remove_incomplete_landscapes(
    metrics_wide,
    predictor_cols,
    na_action = na_action
  )

  # Losing a whole pattern leaves the network with nothing to learn that class
  # from. Stop here if this happens.
  patterns_lost <- setdiff(patterns_before, unique(metrics_wide$pattern))
  if (length(patterns_lost) > 0) {
    cli::cli_abort(c(
      "Removing landscapes with incomplete metrics eliminated {length(patterns_lost)} pattern{?s} entirely",
      "x" = "No landscapes left for: {.val {patterns_lost}}",
      "i" = "Use {.code na_action = \"drop_metrics\"} to drop the affected metrics instead, or supply more landscapes for them"
    ))
  }

  # Summarise the training geometry from the columns calculate_metrics
  # attaches (NULL if the metrics table does not contain the geometry info),
  # using only the landscapes that survived NA-dropping above.
  # Warn if the training landscapes differ in extent or
  # resolution: scale-dependent metrics (e.g. area, edge, patch counts) then
  # conflate pattern with landscape size.
  training_metrics <- if ("landscape_id" %in% colnames(metrics)) {
    dplyr::filter(metrics, landscape_id %in% metrics_wide$landscape_id)
  } else {
    metrics
  }
  training_geometry <- training_geometry_from_metrics(training_metrics)
  if (!is.null(training_geometry) && !training_geometry$homogeneous) {
    cli::cli_warn(c(
      "Training landscapes differ in extent or resolution.",
      "i" = "Scale-dependent metrics (e.g. area, edge, patch counts) conflate pattern with landscape size when training geometry is not uniform.",
      "i" = "Use landscapes of equal size and resolution, or restrict to scale-invariant metrics."
    ))
  }

  # Normalize the predictor variables (remove landscape columns)
  predictors <- metrics_wide |>
    dplyr::select(
      -dplyr::any_of(c(
        "landscape_id",
        "landscape_name",
        "pattern"
      ))
    )
  # Store scaling parameters for future use
  # This will be used to scale new data before prediction. Predictors without
  # usable variation are guarded here so they cannot produce NaN or enormous
  # z-scores (see scaling_stats()).
  scaling_params <- scaling_stats(predictors)

  predictors_scaled <- scale(
    predictors,
    center = scaling_params$center,
    scale = scaling_params$scale
  )

  # Combine the scaled predictors with the target variable
  # Explicitly set factor levels in alphabetical order for consistency. This
  # order must match the neuralnet output columns, which follow the
  # alphabetical order of model.matrix()'s columns
  class_names <- sort(unique(metrics_wide$pattern))

  training_data <- data.frame(
    predictors_scaled,
    pattern = factor(metrics_wide$pattern, levels = class_names)
  )

  # Cross-validation ----------------------------------------------------------
  # Validate and adjust CV parameters
  cv_params <- validate_cv_params(
    patterns = training_data$pattern,
    cv_method = cv_method,
    cv_folds = cv_folds,
    n_predictors = ncol(training_data) - 1
  )

  # Update cv_method and cv_folds based on validation
  cv_method <- cv_params$cv_method
  cv_folds <- cv_params$cv_folds

  # Run model with cross validation --------------------------------------------
  if (cv_method != "none") {
    # Create stratified fold assignments ---------------------------------------
    if (cv_method == "loo") {
      # If method is "loo", each sample is its own fold
      fold_indices <- seq_len(nrow(training_data))
    } else {
      fold_indices <- find_balanced_cv_folds(training_data$pattern, cv_folds)
    }

    # Initialize storage for CV results of each fold
    cv_predictions <- list()
    cv_probabilities <- list()
    cv_actual <- list()
    cv_landscape_ids <- list()

    # Perform k-fold cross-validation or loo by looping over each fold
    for (fold in 1:cv_folds) {
      # Split data into training and validation
      train_indices <- fold_indices != fold
      val_indices <- fold_indices == fold

      # Scale within the fold: fit center/scale on the training rows only and
      # apply them to the validation rows (avoids validation->training leakage)
      fold_scaled <- scale_fold(
        predictors[train_indices, , drop = FALSE],
        predictors[val_indices, , drop = FALSE]
      )
      train_data <- data.frame(
        fold_scaled$train,
        pattern = training_data$pattern[train_indices]
      )
      val_data <- data.frame(
        fold_scaled$val,
        pattern = training_data$pattern[val_indices]
      )

      # Train model on training data
      fold_model <- fit_nn_model(
        data = train_data,
        hidden = hidden_layers,
        threshold = threshold,
        stepmax = stepmax
      )

      # Predict on validation data
      probs_raw <- predict(
        fold_model,
        newdata = val_data[,
          -which(names(val_data) == "pattern"),
          drop = FALSE
        ]
      )

      # Add class names as column names. Output units follow the alphabetical
      # order of the response levels, which is how class_names is built.
      colnames(probs_raw) <- class_names

      # The predicted class comes from the raw outputs, never from the reported
      # scores below, so the reporting step cannot move a class boundary.
      predictions <- class_names[max.col(probs_raw, ties.method = "first")]

      # Map the raw outputs onto the probability simplex for reporting
      probs <- project_simplex_rows(probs_raw)

      # Store results for this fold
      cv_predictions[[fold]] <- predictions
      cv_probabilities[[fold]] <- probs
      cv_actual[[fold]] <- val_data$pattern
      cv_landscape_ids[[fold]] <- metrics_wide$landscape_id[val_indices]
    }

    # Evaluate cv performance -------------------------------------------------
    performance <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = class_names,
      cv_method = cv_method,
      cv_folds = cv_folds,
      verbose = verbose
    )
  }

  # Train final model on all data
  final_model <- fit_nn_model(
    data = training_data,
    hidden = hidden_layers,
    threshold = threshold,
    stepmax = stepmax
  )

  # Prepare return object
  result <- list(
    model = final_model,
    features = colnames(predictors),
    features_level = unique(metrics$level),
    scaling = scaling_params,
    classes = class_names,
    performance = if (cv_method != "none") performance else NULL,
    training_geometry = training_geometry
  )

  return(result)
}


#' Apply Neural Network for Landscape Pattern Classification Based on their Landscape Metrics
#'
#' Applies a trained neural network model to classify new landscapes according to their
#' spatial pattern type. The function automatically calculates the required landscape
#' metrics needed by the model and scales them appropriately.
#'
#' @param landscapes Landscape object (single) or list of landscape objects to classify.
#'   Landscapes must have valid raster data that can be analyzed by landscapemetrics.
#' @param nn_model List. Trained model object returned from train_metric_model().
#'   Must contain elements: model, scaling, classes, features, and features_level.
#' @param evaluate Character. Whether to evaluate the predictions against the
#'   true known classes of the landscapes: \code{"auto"} (default) evaluates when true
#'   classes are available and classifies only otherwise, \code{"required"}
#'   evaluates them and raises an error if it cannot, and \code{"none"} classifies
#'   only without performance evaluation.
#' @param verbose Logical. Show performance summaries when the predictions are
#'   evaluated (default: TRUE). When FALSE, runs silently. Warnings about unknown
#'   classes or incomplete metrics always appear.
#'
#' @return List with two elements:
#'   \describe{
#'     \item{predictions}{Tibble with one row per input landscape, in input
#'       order, and columns:
#'       \describe{
#'         \item{landscape_id}{Numeric landscape identifier}
#'         \item{landscape_name}{Character landscape name (if available)}
#'         \item{actual_class}{True class (if available)}
#'         \item{predicted_class}{Predicted landscape pattern, or NA if the
#'               landscape could not be classified}
#'         \item{score}{Score of the predicted class, i.e. the largest of the
#'               class scores below (not a calibrated probability).
#'               See the "Interpreting the class scores" section.}
#'         \item{<class_name>}{Score for each class the model was trained on. The
#'               raw network outputs are projected onto the probability simplex,
#'               so each row is non-negative and sums to 1.}
#'       }}
#'     \item{performance}{Performance metrics:
#'       confusion matrix, accuracy, and per-class recall/precision/F1. NULL
#'       if nothing was evaluated, which happens when \code{evaluate = "none"},
#'       when no landscape has a known true class, or when some landscape's true
#'       known class was never seen during training.}
#'   }
#'
#'   Landscapes that could not be classified count as incorrect, and appear in
#'   the confusion matrix under "no prediction".
#'
#' @section Interpreting the class scores:
#' \code{predicted_class} is the class with the largest *raw* network output, so
#' it never depends on how those outputs are turned into the scores below.
#'
#' The class scores are non-negative and sum to 1, but they are **not calibrated
#' probabilities**: a score of 0.8 does not mean the prediction is correct
#' 80\% of the time. Calibration would require a separate step fitted on held-out
#' data, which this package does not do (the same caveat applies to
#' \code{\link{apply_pixel_model}}). What the scores do support:
#' \itemize{
#'   \item **Ranking classes within a landscape.** A higher score means the
#'     network supported that class more.
#'   \item **The gap between the leading classes within a landscape.** A
#'     near-tie means the network was torn between them; a wide gap means it was
#'     decisive. The projection shifts every class in a row by the same amount,
#'     so gaps between classes that keep a non-zero score are unchanged.
#'   \item **Ranking landscapes by \code{score}** to decide which ones to
#'     inspect visually. This is a heuristic ordering, not a probability of
#'     being correct.
#' }
#' What they do not support: reading a score as a percentage, or comparing
#' *ratios* of scores ("twice as likely"). The shared shift preserves differences
#' but not ratios, and it differs from landscape to landscape. Gaps involving a
#' class that was pushed to exactly 0 are not meaningful either: several
#' weakly-supported classes collapse onto 0 together, and the projection discards
#' how far below the others they were.
#'
#' @references Wang, W., & Carreira-Perpinan, M. A. (2013). Projection onto the
#'   probability simplex: an efficient algorithm with a simple proof, and an
#'   application. arXiv:1309.1541.
#'
#' @section Landscapes that cannot be classified:
#' The neural network requires a complete set of its features for every landscape. If a
#' required metric cannot be calculated for a landscape, that landscape cannot be
#' classified. This could happen for example when a class is absent from a landscape
#' that was used as a basis for one of the training metrics. The result is
#' still returned, with \code{NA} for \code{predicted_class}, \code{score} and
#' every class probability, and a warning names the affected landscapes. The output
#' therefore always has one row per input landscape. Performance metrics, when
#' requested, are calculated from the classified landscapes only.
#'
#' @section Geometry checks:
#' If the model stores the geometry of its training landscapes (see
#' \code{\link{train_metric_model}}), the application landscapes are compared
#' against it and a warning is issued when they differ substantially in extent,
#' resolution or aspect ratio, since scale-dependent metrics are then unreliable.
#' If the model has no stored training geometry, the checks are skipped with an
#' informative note (suppressed when \code{verbose = FALSE}).
#' @examples
#' \donttest{
#' # Train a model on reference landscapes
#' train_landscapes <- create_landscapes(
#'   n = 18,
#'   patterns = c("random", "sharp", "diffuse")
#' )
#' metrics <- calculate_metrics(train_landscapes, level = "landscape")
#' # find the best 5 metrics for classification
#' best_5 <- evaluate_metrics(metrics, metrics_number = 5)
#' # Train on all data, then evaluate below on a separate test set.
#' model <- train_metric_model(
#'   metrics,
#'   metrics_selected = best_5,
#'   cv_method = "none"
#' )
#' model_file <- tempfile(fileext = ".rds")
#' saveRDS(model, model_file)
#' model <- readRDS(model_file)
#'
#' # Apply to new landscapes
#' new_landscapes <- create_landscapes(
#'   n = 6,
#'   patterns = c("random", "sharp", "diffuse")
#' )
#' results <- apply_metric_model(new_landscapes, model)
#' results$predictions
#'
#' # The true classes are known here, so performance is scored automatically
#' results$performance
#'
#' # Classify without scoring, even though the landscapes carry true classes
#' apply_metric_model(new_landscapes, model, evaluate = "none")$predictions
#'
#' # A model saved earlier is read back with readRDS()
#' saved_model <- readRDS(model_file)
#' apply_metric_model(new_landscapes, saved_model)
#' }
#' @seealso \code{\link{train_metric_model}}, \code{\link{plot_classified_landscapes}}
#' @family neural network application
#' @export
#' @importFrom cli cli_abort cli_alert_warning cli_warn
#' @importFrom dplyr filter select any_of all_of relocate rename bind_cols
#' @importFrom purrr pmap_lgl
#' @importFrom tibble as_tibble
#' @importFrom stats predict
apply_metric_model <- function(
  landscapes,
  nn_model,
  evaluate = "auto",
  verbose = TRUE
) {
  # Input validation ---------------------------------------------------------
  evaluate <- validate_evaluate_param(evaluate)

  if (!is.logical(verbose) || length(verbose) != 1) {
    cli::cli_abort("verbose must be a single logical value")
  }

  if (
    !is.list(nn_model) ||
      !all(
        c("model", "scaling", "classes", "features", "features_level") %in%
          names(nn_model)
      )
  ) {
    cli::cli_abort(
      "'nn_model' must be a trained model from train_metric_model()"
    )
  }

  # Validate landscapes structure
  if (!is.list(landscapes) && !is_landscape(landscapes)) {
    cli::cli_abort(
      "'landscapes' must be a landscape object or list of landscapes"
    )
  }

  if (is_landscape(landscapes)) {
    landscapes <- list(landscapes)
  }

  # Extract required elements from the model
  model <- nn_model$model
  scaling_params <- nn_model$scaling
  class_names <- nn_model$classes
  level <- nn_model$features_level

  # Determine metrics to calculate based on level
  if (level == "landscape") {
    metrics_to_calculate <- nn_model$features
  } else if (level == "class") {
    # Remove the last part after last underscore
    metrics_to_calculate <- gsub("_[^_]+$", "", nn_model$features)
  } else {
    cli::cli_abort(
      "Unsupported features_level '{level}' in nn_model"
    )
  }

  # Calculate the necessary metrics for the input landscape(s)
  metrics <- calculate_metrics(
    landscapes = landscapes,
    metrics = metrics_to_calculate,
    level = level
  )

  # Warn if the application landscapes differ in geometry from the training data
  # (extent, resolution or aspect ratio). Skipped when the model stores no
  # training geometry, e.g. one trained before geometry was recorded.
  check_geometry(
    dplyr::distinct(
      metrics,
      landscape_id,
      n_row,
      n_col,
      cell_size_x,
      cell_size_y
    ),
    nn_model$training_geometry,
    verbose = verbose
  )

  # Filter to only features needed by the model
  metrics <- metrics |> dplyr::filter(metric %in% nn_model$features)

  # Convert metrics to wide format with 1 row per landscape
  metrics_wide <- metrics_to_wide(metrics)

  # Prepare predictors -------------------------------------------------------
  predictor_names <- setdiff(
    colnames(metrics_wide),
    c("landscape_id", "landscape_name", "pattern")
  )

  # Validate we have all required features
  missing_features <- setdiff(nn_model$features, predictor_names)

  if (length(missing_features) > 0) {
    cli::cli_abort(c(
      "Input landscapes missing required metrics",
      "x" = "Missing: {.val {missing_features}}",
      "i" = "Model requires: {.val {nn_model$features}}"
    ))
  }

  # Select only model features in correct order
  predictors <- metrics_wide |>
    dplyr::select(dplyr::all_of(nn_model$features))

  # Deal with NA values -------------------------------------------------------
  # Unlike training, no landscape is be dropped here:
  # Landscapes whose required metrics could not all be calculated are
  # kept and returned unclassified instead. Dropping the metric is not an option,
  # since the network needs exactly the feature set it was trained on.
  incomplete <- rowSums(is.na(predictors)) > 0

  if (all(incomplete)) {
    cli::cli_abort(c(
      "No input landscape has all the metrics the model requires",
      "i" = "Model requires: {.val {nn_model$features}}"
    ))
  }

  if (any(incomplete)) {
    cli::cli_warn(c(
      "Could not classify {sum(incomplete)} landscape{?s}, returned with NA predictions",
      "i" = "Affected: {.val {metrics_wide$landscape_name[incomplete]}}",
      "i" = "At the class level a metric cannot be calculated for a class that is absent from a landscape."
    ))
  }

  # Scale the metrics using the same parameters as during training
  predictors_scaled <- scale(
    predictors[!incomplete, , drop = FALSE],
    center = scaling_params$center,
    scale = scaling_params$scale
  )

  # Make predictions ---------------------------------------------------------
  pred_raw <- predict(
    model,
    newdata = predictors_scaled
  )

  # The predicted class comes from the raw outputs, never from the reported
  # scores, so the reporting step cannot move a class boundary.
  predicted_complete <- class_names[max.col(pred_raw, ties.method = "first")]

  # Map the raw outputs onto the probability simplex for reporting
  pred_complete <- project_simplex_rows(pred_raw)

  # Expand back to one row per input landscape, leaving unclassified rows NA
  pred <- matrix(
    NA_real_,
    nrow = nrow(metrics_wide),
    ncol = length(class_names),
    dimnames = list(NULL, class_names)
  )
  pred[!incomplete, ] <- pred_complete

  # Turn into a tibble and add columns for predicted class and its score.
  predictions <- tibble::as_tibble(pred)

  score <- rep(NA_real_, nrow(pred))
  predicted_class <- rep(NA_character_, nrow(pred))

  # The reported score is the score of the predicted class, i.e. the row maximum.
  score[!incomplete] <- apply(pred_complete, 1, max)
  predicted_class[!incomplete] <- predicted_complete

  predictions$score <- score
  predictions$predicted_class <- predicted_class

  # Reorder the columns
  predictions <- predictions |>
    dplyr::relocate(c(
      predicted_class,
      score
    ))

  # Add all landscape information available to the output
  landscape_info <- metrics_wide |>
    dplyr::select(
      dplyr::any_of(c("landscape_id", "landscape_name", "pattern"))
    )

  # Rename pattern to actual_class if it exists
  if ("pattern" %in% colnames(landscape_info)) {
    landscape_info <- landscape_info |>
      dplyr::rename(actual_class = pattern)
  }

  predictions <- dplyr::bind_cols(landscape_info, predictions)

  # Score against the true classes, when there are any and the caller wants it
  performance <- evaluate_predictions(
    predictions = predictions,
    class_names = class_names,
    evaluate = evaluate,
    verbose = verbose
  )

  list(
    predictions = predictions,
    performance = performance
  )
}
