#' Is the Keras TensorFlow Backend Usable?
#'
#' Reports whether \pkg{keras3} can reach a working TensorFlow backend. Use it
#' to check your setup before running \code{\link{train_pixel_model}} or
#' \code{\link{apply_pixel_model}}.
#'
#' @details
#' Only TensorFlow is checked as a backend; \pkg{keras3} also runs on jax and torch, but the
#' pixel workflow is tested against TensorFlow, which is what
#' \code{\link[keras3]{install_keras}} installs by default.
#'
#' If this returns \code{FALSE}, the backend is missing or is not TensorFlow,
#' and the pixel-based functions cannot run. The metrics-based workflow
#' (\code{\link{train_metric_model}}) is unaffected. To set up the
#' backend, point \pkg{reticulate} at a suitable Python and run
#' \code{keras3::install_keras()}, which
#' \code{vignette("install-keras", package = "patternscaper")} walks
#' through.
#'
#' @return `TRUE` or `FALSE` depending on whether the backend is set up.
#'
#' @seealso \code{\link[keras3]{install_keras}} to set the backend up.
#' @family neural network training
#' @export
#' @examples
#' # TRUE once keras3 has a working TensorFlow backend
#' keras_available()
keras_available <- function() {
  tryCatch(
    identical(keras3::config_backend(), "tensorflow"),
    error = function(e) FALSE
  )
}

#' Set Random Seeds for Neural Network Training
#'
#' Sets random seeds for R and Keras to support reproducible neural network
#' training. This is a convenience wrapper around
#' \code{\link[base]{set.seed}} and \code{\link[keras3]{set_random_seed}}.
#'
#' @param seed Integer seed value.
#'
#' @details
#' Neural network training involves randomness from R (data shuffling and CV fold
#' creation) and Keras/TensorFlow (weight initialization and dropout).
#'
#' Seed both to reproduce a training run as closely as possible. Call this
#' function immediately before each training call because landscape generation
#' and other R operations advance R's random-number stream. Minor variations may
#' still occur across different hardware and software configurations.
#'
#' @return Invisibly returns \code{NULL}. Called for side effects.
#'
#' @family neural network training
#' @export
#' @examplesIf keras_available()
#' # Generate reproducible training data
#' set.seed(42)
#' landscapes <- create_landscapes(n = 6, patterns = c("sharp", "random"))
#'
#' # Reset both random-number generators immediately before training
#' set_random_seed(42)
#' model <- train_pixel_model(landscapes, cv_method = "none", epochs = 5)
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

#' Convert Landscape Metrics from Long to Wide Format
#'
#' Reshapes landscape metrics to one row per landscape and one column per metric
#' for neural-network training.
#'
#' @param metrics A data frame containing landscape metrics in long format.
#'   Expected columns include: `metric`, `class`, `value`, `pattern`.
#'   Must include either `landscape_id` or `landscape_name` for identification.
#' @param return_only_metrics Logical. Whether to return only the metric columns
#'   or retain the identification columns (default: FALSE).
#'
#' @return A data frame in wide format where each metric becomes a column and each
#'   row is a landscape. Metric names already include class IDs when applicable
#'   (format: `metric_class_id`); that folding is done upstream in
#'   \code{\link{calculate_metrics}}, not here.
#' @keywords internal
#' @importFrom dplyr mutate select
#' @importFrom tidyr pivot_wider
metrics_to_wide <- function(metrics, return_only_metrics = FALSE) {
  if (!any(c("landscape_id", "landscape_name") %in% colnames(metrics))) {
    cli::cli_abort(
      "Metrics must contain either 'landscape_id' or 'landscape_name' column"
    )
  }

  metrics <- metrics |>
    dplyr::select(dplyr::any_of(c(
      "landscape_id",
      "landscape_name",
      "metric",
      "value",
      "pattern"
    )))

  metrics_wide <- metrics |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    )

  # Return predictors only when requested
  if (return_only_metrics) {
    metrics_wide <- metrics_wide |>
      dplyr::select(-any_of(c("landscape_id", "landscape_name", "pattern")))
  }
  metrics_wide
}

#' Project a vector onto the probability simplex
#'
#' Returns the closest vector to `v`, in squared Euclidean distance, whose
#' elements are non-negative and sum to 1. It subtracts one shared offset from
#' every element and clips whatever is left below zero.
#'
#' Because the offset is the same for every element, the projection keeps the
#' input order: whichever class scored highest in `v` still scores highest
#' afterwards. The offset also lifts an all-negative vector onto the simplex,
#' which "clip at zero, then divide by the sum" cannot do.
#'
#' The result is a valid probability vector, but that is not evidence that the numbers are calibrated probabilities.
#'
#' @param v Numeric vector of raw scores.
#' @return A numeric vector as long as `v`. For non-empty, finite input it is
#'   non-negative and sums to 1 up to floating-point error. If any element of
#'   `v` is `NA`, `NaN` or infinite, every element of the result is `NA_real_`;
#'   empty input returns `numeric(0)`.
#' @references Wang, W., & Carreira-Perpinan, M. A. (2013). Projection onto the
#'   probability simplex: an efficient algorithm with a simple proof, and an
#'   application. arXiv:1309.1541.
#' @keywords internal
project_simplex <- function(v) {
  if (length(v) == 0) {
    return(numeric(0))
  }

  # Covers NA and NaN, but also Inf: an infinite score makes `running_total`
  # infinite and the threshold test below NaN, which would silently select the
  # wrong active set rather than fail
  if (any(!is.finite(v))) {
    return(rep(NA_real_, length(v)))
  }

  sorted <- sort(v, decreasing = TRUE)
  running_total <- cumsum(sorted)

  # Number of classes that keep positive mass. The j = 1 term is always
  # positive, so this is never empty
  n_positive <- max(which(
    sorted + (1 - running_total) / seq_along(v) > 0
  ))
  theta <- (running_total[n_positive] - 1) / n_positive

  pmax(v - theta, 0)
}

#' Row-wise projection onto the probability simplex
#'
#' Applies \code{\link{project_simplex}} to each row of a matrix of raw network
#' outputs, turning them into per-row distributions for reporting.
#'
#' The metric-based network has linear output units trained by squared error
#' against 0/1 class indicators (see \code{\link{fit_nn_model}}), so its outputs
#' already sit close to a probability vector but are unconstrained: they can
#' fall below 0, rise above 1, and not sum to 1. Projection is the smallest
#' correction that fixes that, measured the same way the training loss measures
#' error.
#'
#' @param x Numeric matrix; each row is one landscape's raw class scores.
#' @return A matrix with the same dimensions and dimnames as `x`. Rows of finite
#'   values are non-negative and sum to 1 up to floating-point error; a row
#'   holding any non-finite value comes back as all `NA_real_`.
#' @keywords internal
project_simplex_rows <- function(x) {
  x <- as.matrix(x)

  # Filling a pre-allocated matrix keeps the shape right for any number of rows
  # or classes, including the degenerate ones, without depending on how apply()
  # or vapply() simplify their result
  projected <- matrix(
    NA_real_,
    nrow = nrow(x),
    ncol = ncol(x),
    dimnames = dimnames(x)
  )

  for (i in seq_len(nrow(x))) {
    projected[i, ] <- project_simplex(x[i, ])
  }

  projected
}

#' Detect if the standard deviation is just random noise
#'
#' When comparing the sd of a metric to 0, it could happen that due to floating
#' point summation, there is a small tolerance. E.g. total area across equally sized
#' landscapes: `sd` is `1e-17` rather than exactly `0`.
#' Comparing against zero then fails to catch it and the metric survives the
#' "metric is constant" check. To avoid this, we calculuate the tolerance
#' relative to the magnitude of the values so that it works for metrics measured
#' on very different scales.
#'
#' @param sd_value Numeric vector of standard deviations.
#' @param center Numeric vector of the corresponding means.
#'
#' @return Logical vector; `TRUE` if standard deviation is `NA` or too
#'   small to be meaningful.
#' @keywords internal
is_constant_sd <- function(sd_value, center) {
  tolerance <- sqrt(.Machine$double.eps) * pmax(abs(center), 1)
  is.na(sd_value) | sd_value <= tolerance
}

#' Centring and scaling statistics for a set of predictors
#'
#' Computes the `center`/`scale` used to standardise predictors, guarding
#' columns that carry no variation (see \code{\link{is_constant_sd}}) by giving them
#' `scale = 1`. Those columns become all-zero after centring instead of `NaN`
#' or an enormous z-score.
#'
#' @param predictors Data frame or matrix of predictors.
#'
#' @return List with `center` and `scale`, both named numeric vectors.
#' @keywords internal
#' @importFrom stats sd
scaling_stats <- function(predictors) {
  predictors <- as.matrix(predictors)

  center <- colMeans(predictors)
  scale_sd <- apply(predictors, 2, stats::sd)
  scale_sd[is_constant_sd(scale_sd, center)] <- 1

  list(center = center, scale = scale_sd)
}

#' Scale a validation fold using only the training fold's statistics
#'
#' Fits centering/scaling on the training-fold predictors alone and applies the
#' same statistics to both the training and validation predictors. This keeps
#' the validation rows from contributing to the `center`/`scale` used on them,
#' avoiding the optimistic leakage that arises when the whole dataset is scaled
#' before cross-validation. Columns that are constant within the training fold
#' are given `scale = 1` so they become all-zero after centering instead of
#' `NaN` (see \code{\link{scaling_stats}}).
#'
#' @param train_predictors Data frame or matrix of training-fold predictors.
#' @param val_predictors Data frame or matrix of validation-fold predictors.
#'
#' @return List with `train` and `val`: numeric matrices scaled with the
#'   training-fold center/scale.
#' @keywords internal
scale_fold <- function(train_predictors, val_predictors) {
  stats <- scaling_stats(train_predictors)

  list(
    train = scale(
      as.matrix(train_predictors),
      center = stats$center,
      scale = stats$scale
    ),
    val = scale(
      as.matrix(val_predictors),
      center = stats$center,
      scale = stats$scale
    )
  )
}

#' Abort if any landscape contains NA cells
#'
#' The CNN has no representation for a missing cell. How an NA reaches the
#' network depends on the raster's type: as `NaN` for a float raster, as a
#' corrupted integer for the integer rasters \code{\link{create_landscapes}}
#' Neither raises an error on its own, so training or prediction
#' runs to completion on meaningless pixel values. Used by both
#' \code{\link{train_pixel_model}} and \code{\link{apply_pixel_model}} so the two
#' refuse the same input.
#'
#' @param landscapes List of landscape objects.
#' @param action Character. Verb naming what the caller was about to do, used in
#'   the error message ("train on", "classify").
#'
#' @return Invisibly `NULL`. Called for the error.
#'
#' @keywords internal
#' @importFrom cli cli_abort
abort_on_na_cells <- function(landscapes, action) {
  na_counts <- vapply(
    landscapes,
    function(l) sum(is.na(terra::values(l$data))),
    numeric(1)
  )

  if (any(na_counts > 0)) {
    bad <- which(na_counts > 0)
    landscape_names <- vapply(
      landscapes,
      function(l) if (!is.null(l$name)) l$name else NA_character_,
      character(1)
    )
    labels <- ifelse(
      is.na(landscape_names[bad]),
      paste0("landscape ", bad),
      landscape_names[bad]
    )
    detail <- paste0(labels, " (", na_counts[bad], " NA)")
    cli::cli_abort(c(
      "Cannot {action} landscapes that contain NA cells.",
      "x" = "Affected: {.val {detail}}",
      "i" = "NA cells do not survive conversion to the array the CNN uses, so the result is based on meaningless pixel values.",
      "i" = "Crop to a rectangular region without NA. Do not fill NA with 0, which fabricates bare ground."
    ))
  }

  invisible(NULL)
}

#' Reject multi-layer landscapes in the pixel workflow
#'
#' @param landscapes List of landscape objects.
#' @param action Character. Verb naming what the caller was about to do, used in
#'   the error message.
#'
#' @return Invisibly `NULL`. Called for the error.
#'
#' @keywords internal
abort_on_multilayer_landscapes <- function(landscapes, action) {
  layer_counts <- vapply(
    landscapes,
    function(l) terra::nlyr(l$data),
    numeric(1)
  )

  if (any(layer_counts != 1)) {
    bad <- which(layer_counts != 1)
    cli::cli_abort(c(
      "Cannot {action} multi-layer landscapes.",
      "x" = "Found {.val {layer_counts[bad]}} raster layers at index(es): {paste(bad, collapse = ', ')}",
      "i" = "The pixel workflow currently requires one categorical raster layer per landscape."
    ))
  }

  invisible(NULL)
}

#' Check that cell values are categorical
#'
#' The pixel workflow reads raw cell values and we need to ensure that they are
#' categorical in nature. We accept whole numbers but warn if there are too many
#' as many distinct whole values are legal but usually mean integer-coded continuous data
#' (e.g. elevation in whole metres).
#' Used by both \code{\link{train_pixel_model}} and \code{\link{apply_pixel_model}}
#' so the two refuse the same input.
#'
#' @param landscapes List of landscape objects.
#' @param action Character. Verb naming what the caller was about to do, used in
#'   the message ("train on", "classify").
#' @param max_distinct Integer. Distinct-value count above which the input is
#'   reported as probably continuous (default: 20). Chosen to sit above any
#'   land-cover classification scheme in practical use and far below the hundreds
#'   or thousands of levels continuous data carries.
#'
#' @return Invisibly `NULL`. Called for the error and the warning.
#'
#' @keywords internal
#' @importFrom cli cli_abort cli_warn
check_categorical_values <- function(landscapes, action, max_distinct = 20) {
  # Unique per landscape first, so the union stays small for large training sets
  distinct_values <- unique(unlist(lapply(
    landscapes,
    function(l) unique(terra::values(l$data))
  )))
  distinct_values <- distinct_values[!is.na(distinct_values)]

  if (!is.numeric(distinct_values)) {
    cli::cli_abort(c(
      "Cannot {action} landscapes with non-numeric cell values.",
      "i" = "Use whole numbers as category codes, for example 1 for forest and 2 for lake."
    ))
  }

  non_finite <- distinct_values[!is.finite(distinct_values)]
  if (length(non_finite) > 0) {
    cli::cli_abort(c(
      "Cannot {action} landscapes with non-finite cell values.",
      "x" = "Found {.val {non_finite}}.",
      "i" = "Use finite whole numbers as category codes."
    ))
  }

  non_whole <- sort(distinct_values[distinct_values != round(distinct_values)])
  if (length(non_whole) > 0) {
    shown <- non_whole[seq_len(min(5, length(non_whole)))]
    cli::cli_abort(c(
      "Cannot {action} landscapes with continuous cell values.",
      "x" = "Found {length(non_whole)} non-whole value{?s}, including {.val {shown}}",
      "i" = "The pixel workflow reads cell values as class labels, so it requires categorical data.",
      "i" = "Classify continuous data, such as elevation or a vegetation index, into discrete types first."
    ))
  }

  if (length(distinct_values) > max_distinct) {
    cli::cli_warn(c(
      "Landscapes hold {length(distinct_values)} distinct cell values.",
      "i" = "Categorical land-cover data usually has a handful of classes. Make sure your data is valid.",
      "i" = "Integer-coded continuous data, for example elevation in whole metres, passes the check but is meaningless to use in the model."
    ))
  }

  invisible(NULL)
}

#' Fit the Land-Cover Encoding for a Pixel Model
#'
#' Finds the numeric land-cover codes present across the training landscapes
#' and fixes their order for one-hot encoding.
#'
#' @param landscapes List of landscape objects.
#'
#' @return Sorted numeric vector of land-cover codes.
#'
#' @keywords internal
fit_land_cover_values <- function(landscapes) {
  sort(unique(unlist(lapply(
    landscapes,
    function(l) terra::values(l$data)
  ))))
}

#' One-Hot Encode a Land-Cover Raster
#'
#' Converts one numeric categorical raster layer into one binary array channel
#' per fitted land-cover code.
#'
#' @param landscape_data Single-layer SpatRaster.
#' @param land_cover_values Numeric vector fixing the channel order.
#'
#' @return Numeric array with dimensions rows by columns by land-cover channels.
#'
#' @keywords internal
encode_land_cover_raster <- function(landscape_data, land_cover_values) {
  raster_array <- terra::as.array(landscape_data)
  encoded <- array(
    0,
    dim = c(
      dim(raster_array)[1],
      dim(raster_array)[2],
      length(land_cover_values)
    )
  )

  for (i in seq_along(land_cover_values)) {
    encoded[,, i] <- raster_array[,, 1] == land_cover_values[i]
  }

  encoded
}

#' Check Land-Cover Codes Against a Fitted Pixel Model
#'
#' @param landscapes List of landscape objects to classify.
#' @param land_cover_values Numeric land-cover codes fitted during training.
#' @param action User-facing verb describing the attempted operation.
#'
#' @return Invisibly `NULL`.
#'
#' @keywords internal
abort_on_unseen_land_cover_values <- function(
  landscapes,
  land_cover_values,
  action = "classify"
) {
  unseen <- lapply(landscapes, function(l) {
    setdiff(unique(terra::values(l$data)), land_cover_values)
  })
  invalid <- which(lengths(unseen) > 0)

  if (length(invalid) > 0) {
    details <- vapply(
      invalid,
      function(i) {
        paste0(i, ": ", paste(sort(unseen[[i]]), collapse = ", "))
      },
      character(1)
    )
    cli::cli_abort(c(
      "Cannot {action} landscapes with land-cover codes not seen during training.",
      "x" = "Unknown value{?s} by landscape index: {paste(details, collapse = '; ')}.",
      "i" = "The model was trained with land-cover codes {.val {land_cover_values}}."
    ))
  }

  invisible(NULL)
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
#'   k-fold CV, and the count below which a class is reported as small for any
#'   CV method (default: 3).
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
  class_counts <- table(patterns)
  min_class_count <- min(class_counts)
  total_samples <- length(patterns)

  # Report class composition even when cross-validation is disabled
  if (!is.null(n_predictors)) {
    samples_per_predictor <- total_samples / n_predictors
    if (samples_per_predictor < 5) {
      cli::cli_alert_info(
        "Low sample-to-predictor ratio ({round(samples_per_predictor, 1)}:1). Consider LOO CV or reducing features."
      )
    }
  }

  imbalance_ratio <- max(class_counts) / min(class_counts)
  if (imbalance_ratio > 5) {
    cli::cli_alert_info(
      "Severe class imbalance detected (ratio {round(imbalance_ratio, 1)}:1). Minority classes may be classified unreliably."
    )
  }

  small_classes <- names(class_counts[class_counts < min_samples_per_fold])
  if (length(small_classes) > 0) {
    cli::cli_alert_info(
      "Some classes have few samples (< {min_samples_per_fold}): {.val {small_classes}}. The model may not learn these classes reliably."
    )
  }

  if (cv_method == "none") {
    return(list(
      cv_method = cv_method,
      cv_folds = 1L,
      class_counts = class_counts,
      total_samples = total_samples
    ))
  }

  # Validate and adjust k-fold parameters
  if (cv_method == "k-fold") {
    # Reduce k as needed to preserve the minimum class count per fold
    max_suitable_folds <- floor(min_class_count / min_samples_per_fold)

    # If we can't maintain enough samples even with 2 folds
    if (max_suitable_folds < 2) {
      cli::cli_warn(
        "Cannot maintain {min_samples_per_fold} samples per class per fold (smallest class: {min_class_count}). Switching to LOO CV."
      )
      cv_method <- "loo"
      cv_folds <- total_samples
    } else if (cv_folds > max_suitable_folds) {
      cli::cli_warn(
        "Reducing CV folds from {cv_folds} to {max_suitable_folds} to maintain {min_samples_per_fold} samples per class per fold."
      )
      cv_folds <- max_suitable_folds
    }
  }

  if (cv_method == "loo") {
    # LOO requires at least two samples per class
    if (any(class_counts == 1)) {
      singleton_classes <- names(class_counts[class_counts == 1])
      cli::cli_abort(
        "Cannot perform LOO CV: class{?es} {.val {singleton_classes}} ha{?s/ve} only 1 sample. Need at least 2 per class."
      )
    }

    # LOO fits one model per sample, so large datasets are expensive
    if (total_samples > 100) {
      cli::cli_alert_info(
        "LOO CV with {total_samples} samples may be slow. Consider k-fold CV instead."
      )
    }

    cv_folds <- total_samples
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

  # Stratify by cycling shuffled fold ids within each class
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

#' Create a Stratified Training and Validation Split
#'
#' Selects validation landscapes separately within each pattern class. Every
#' class retains at least one training landscape and contributes at least one
#' validation landscape.
#'
#' @param patterns Character or factor vector of pattern labels.
#' @param validation_split Requested fraction assigned to validation.
#'
#' @return List with integer vectors \code{training} and \code{validation}.
#'
#' @keywords internal
find_stratified_validation_split <- function(patterns, validation_split) {
  class_counts <- table(patterns)
  singleton_classes <- names(class_counts[class_counts < 2])

  if (length(singleton_classes) > 0) {
    cli::cli_abort(c(
      "Cannot create a validation split because each class needs at least two landscapes.",
      "x" = "Class{?es} {.val {singleton_classes}} ha{?s/ve} fewer than two landscapes.",
      "i" = "Add landscapes or supply a separate validation set."
    ))
  }

  validation <- integer()
  for (class_name in names(class_counts)) {
    class_indices <- which(patterns == class_name)
    n_validation <- round(length(class_indices) * validation_split)
    n_validation <- max(1L, min(n_validation, length(class_indices) - 1L))
    validation <- c(
      validation,
      sample(class_indices, size = n_validation, replace = FALSE)
    )
  }

  validation <- sort(validation)
  list(
    training = setdiff(seq_along(patterns), validation),
    validation = validation
  )
}

#' Validate Landscapes Used for Pixel-Model Validation
#'
#' Checks that validation landscapes can be encoded with a fitted pixel model
#' and that every trained pattern class is represented.
#'
#' @param validation_landscapes List of landscape objects.
#' @param expected_dimensions Integer vector with rows and columns.
#' @param class_names Character vector of trained pattern classes.
#' @param land_cover_values Numeric vector of land-cover codes fitted on the training
#'   landscapes.
#'
#' @return Character vector of validation pattern labels.
#'
#' @keywords internal
validate_pixel_validation_landscapes <- function(
  validation_landscapes,
  expected_dimensions,
  class_names,
  land_cover_values
) {
  if (is_landscape(validation_landscapes)) {
    cli::cli_abort(c(
      "{.arg validation_landscapes} must be a list of landscape objects.",
      "x" = "A single landscape object was passed."
    ))
  }
  if (!is.list(validation_landscapes) || length(validation_landscapes) == 0) {
    cli::cli_abort(
      "validation_landscapes must be a non-empty list of landscape objects"
    )
  }

  valid_landscapes <- vapply(
    validation_landscapes,
    is_landscape,
    logical(1)
  )
  if (any(!valid_landscapes)) {
    invalid_indices <- which(!valid_landscapes)
    cli::cli_abort(c(
      "All validation elements must be landscape objects.",
      "x" = "Invalid element(s) at index(es): {paste(invalid_indices, collapse = ', ')}"
    ))
  }

  abort_on_multilayer_landscapes(validation_landscapes, "validate on")

  dimensions <- lapply(validation_landscapes, function(l) {
    c(terra::nrow(l$data), terra::ncol(l$data))
  })
  wrong_dimensions <- which(
    !vapply(
      dimensions,
      function(x) identical(as.integer(x), as.integer(expected_dimensions)),
      logical(1)
    )
  )
  if (length(wrong_dimensions) > 0) {
    cli::cli_abort(c(
      "Validation landscapes must have the same dimensions as the training landscapes.",
      "x" = "Expected {expected_dimensions[1]}x{expected_dimensions[2]} rows x columns.",
      "x" = "Different dimensions at validation index(es): {paste(wrong_dimensions, collapse = ', ')}."
    ))
  }

  validation_labels <- vapply(
    validation_landscapes,
    function(l) as.character(l$pattern),
    character(1)
  )
  invalid_labels <- which(is.na(validation_labels))
  if (length(invalid_labels) > 0) {
    cli::cli_abort(c(
      "All validation landscapes must have known pattern classes.",
      "x" = "Invalid label(s) at index(es): {paste(invalid_labels, collapse = ', ')}."
    ))
  }

  unknown_classes <- setdiff(unique(validation_labels), class_names)
  missing_classes <- setdiff(class_names, unique(validation_labels))
  if (length(unknown_classes) > 0 || length(missing_classes) > 0) {
    details <- character()
    if (length(unknown_classes) > 0) {
      details <- c(
        details,
        "x" = "Not present in training: {.val {unknown_classes}}."
      )
    }
    if (length(missing_classes) > 0) {
      details <- c(
        details,
        "x" = "Missing from validation: {.val {missing_classes}}."
      )
    }
    cli::cli_abort(c(
      "Training and validation data must contain the same pattern classes.",
      details
    ))
  }

  abort_on_na_cells(validation_landscapes, "validate on")
  check_categorical_values(validation_landscapes, "validate on")
  abort_on_unseen_land_cover_values(
    validation_landscapes,
    land_cover_values,
    action = "validate"
  )

  validation_labels
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
#'     \item{per_class_metrics}{Tibble with per-class recall, precision, and F1
#'       scores. A class the model knows but that does not occur in the
#'       evaluation data gets NA throughout its row.}
#'     \item{cv_method}{CV method used (character)}
#'     \item{cv_folds}{Number of folds used (integer)}
#'     \item{class_counts}{Sample counts per class (integer vector). NA for a
#'       class the model knows but that does not occur in the evaluation data.}
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
  if (length(cv_predictions) != length(cv_actual)) {
    cli::cli_abort("Length of cv_predictions and cv_actual must be the same")
  }
  if (length(cv_probabilities) != length(cv_actual)) {
    cli::cli_abort("Length of cv_probabilities and cv_actual must be the same")
  }

  if (
    !all(
      vapply(cv_probabilities, is.matrix, logical(1)) |
        vapply(cv_probabilities, is.data.frame, logical(1))
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

  # Create confusion matrix. A landscape the model could not classify counts as
  # a failure, so it gets its own row rather than dropping out of the table
  no_prediction_label <- "no prediction"
  predicted_vec <- unlist(cv_predictions)
  predicted_levels <- class_names

  if (anyNA(predicted_vec)) {
    predicted_vec[is.na(predicted_vec)] <- no_prediction_label
    predicted_levels <- c(class_names, no_prediction_label)
  }

  conf_matrix <- table(
    Predicted = factor(predicted_vec, levels = predicted_levels),
    Actual = factor(unlist(cv_actual), levels = class_names)
  )

  # Get class counts. A class the model knows but that never occurs in
  # cv_actual is absent from this table, so indexing by class_names gives NA
  # for it rather than a count of 0 landscapes actually seen
  class_counts <- table(unlist(cv_actual))
  class_counts <- stats::setNames(
    as.numeric(class_counts[class_names]),
    class_names
  )
  absent_classes <- class_names[is.na(class_counts)]

  # Square known-class block, whose diagonal holds the correct predictions. The
  # "no prediction" row sits outside it, so it lowers recall but not precision
  conf_known <- conf_matrix[class_names, , drop = FALSE]

  # Check for known classes that were never correctly predicted. Classes
  # absent from the evaluation data are reported separately below instead
  correctly_predicted <- diag(conf_known)
  never_predicted_classes <- setdiff(
    class_names[correctly_predicted == 0],
    absent_classes
  )

  if (length(never_predicted_classes) > 0) {
    cli::cli_warn(
      "Some classes were never correctly predicted during evaluation: {.val {never_predicted_classes}}. Results for these classes are unreliable."
    )
  }

  if (length(absent_classes) > 0) {
    cli::cli_warn(
      "Some classes known to the model do not occur in the evaluation data: {.val {absent_classes}}. Their count, recall, precision and F1 score are reported as NA (not evaluated, not a failure)."
    )
  }

  # Calculate accuracy over the whole table so landscapes with no
  # prediction count against it
  accuracy <- sum(correctly_predicted) / sum(conf_matrix)

  # Recall divides by every landscape of that class, precision only by the ones
  # the model assigned to it
  class_recall <- correctly_predicted / colSums(conf_matrix)
  class_precision <- correctly_predicted / rowSums(conf_known)

  # Handle divisions by zero for classes that do occur in the evaluation data
  # but that the model never guesses
  class_precision[is.na(class_precision)] <- 0
  class_recall[is.na(class_recall)] <- 0

  # Calculate F1 scores
  class_f1 <- 2 *
    class_precision *
    class_recall /
    (class_precision + class_recall)
  class_f1[is.na(class_f1)] <- 0

  # Classes absent from the evaluation data were never evaluated: report NA
  # instead of the 0 the divide-by-zero handling above assigned them
  class_recall[absent_classes] <- NA
  class_precision[absent_classes] <- NA
  class_f1[absent_classes] <- NA

  # Combine into per-class metrics table
  per_class_metrics <- tibble::tibble(
    class = class_names,
    count = as.vector(class_counts),
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
      score = apply(dplyr::across(dplyr::all_of(class_names)), 1, max)
    ) |>
    dplyr::relocate(c(
      landscape_id,
      fold,
      actual_class,
      predicted_class,
      score
    ))

  if (verbose) {
    cli::cli_h2("Cross-validation results")

    cv_label <- ifelse(
      cv_method == "loo",
      "leave-one-out",
      paste0(cv_folds, "-fold")
    )
    cli::cli_alert_info("Method: {cv_label} cross-validation")
    cli::cli_alert_info("Overall accuracy: {round(accuracy * 100, 2)}%")

    cli::cli_h3("Confusion matrix")
    print(conf_matrix)

    cli::cli_h3("Per-class performance")
    print(per_class_metrics)
  }

  result <- list(
    confusion_matrix = conf_matrix,
    accuracy = accuracy,
    per_class_metrics = per_class_metrics,
    cv_method = cv_method,
    cv_folds = cv_folds,
    class_counts = as.vector(class_counts)
  )
  if (return_predictions) {
    result$validation_results <- validation_results
  }

  return(result)
}

#' Validate the `evaluate` argument of the apply functions
#'
#' @param evaluate Value supplied by the user.
#'
#' @return The validated value, lowercased.
#'
#' @keywords internal
validate_evaluate_param <- function(evaluate) {
  valid <- c("auto", "required", "none")

  if (is.character(evaluate) && length(evaluate) == 1) {
    evaluate <- tolower(evaluate)
  }

  if (
    !is.character(evaluate) || length(evaluate) != 1 || !evaluate %in% valid
  ) {
    cli::cli_abort('evaluate must be one of: "auto", "required", or "none"')
  }

  evaluate
}

#' Evaluate predictions against their true classes
#'
#' Used in both \code{apply_metric_model()} and
#' \code{apply_pixel_model()} to evaluate model performance.
#' Decides whether performance can and should be evaluated,
#' then evaluates it on the landscapes by comparing the predicted with the actual
#' class.
#'
#' Landscapes with no actual class are excluded. Landscapes whose actual class
#' the model was never trained on are different: the model cannot produce that
#' label, so they are guaranteed wrong, and scoring only the rest would report a
#' higher accuracy than the batch achieved. Nothing is evaluated in that case,
#' the result is NULL, and the user is warned.
#'
#' @param predictions Tibble of predictions from the calling
#'   \code{apply_*} function. Must carry \code{predicted_class} and, to be
#'   scorable at all, an \code{actual_class} column.
#' @param class_names Character vector of the classes the model was trained on.
#' @param evaluate Character. One of "auto", "required" or "none". See
#'   \code{\link{apply_metric_model}}.
#' @param verbose Logical. Show the performance summary and the note about
#'   landscapes skipped for having no true class.
#'
#' @return List of performance metrics from \code{evaluate_cv_performance()}, or
#'   NULL when nothing was scored.
#'
#' @keywords internal
evaluate_predictions <- function(
  predictions,
  class_names,
  evaluate = "auto",
  verbose = TRUE
) {
  if (evaluate == "none") {
    return(NULL)
  }

  actual_class <- predictions[["actual_class"]]
  scorable <- !is.na(actual_class)

  if (!any(scorable)) {
    if (evaluate == "required") {
      cli::cli_abort(c(
        "Cannot evaluate performance: no landscape has a known true class.",
        "i" = "Use {.code evaluate = \"none\"} to classify without evaluating."
      ))
    }
    return(NULL)
  }

  if (verbose && !all(scorable)) {
    cli::cli_alert_info(
      "Evaluating performance on {sum(scorable)}/{length(scorable)} landscapes with known classes"
    )
  }

  scored <- predictions[scorable, ]
  unknown_classes <- setdiff(unique(scored$actual_class), class_names)

  if (length(unknown_classes) > 0) {
    detail <- c(
      "x" = "{.val {unknown_classes}}",
      "i" = "Model trained on: {.val {class_names}}"
    )

    if (evaluate == "required") {
      cli::cli_abort(c(
        "Cannot evaluate performance: some landscapes have a true class the model never saw.",
        detail
      ))
    }

    cli::cli_warn(c(
      "Input landscapes contain classes not seen during training:",
      detail,
      "i" = "Performance is not evaluated for any landscape to avoid inflating accuracy.",
      "i" = "Predictions are still returned for every landscape."
    ))

    return(NULL)
  }

  n_unpredicted <- sum(is.na(scored$predicted_class))

  if (n_unpredicted > 0) {
    cli::cli_warn(
      "{n_unpredicted} landscape{?s} could not be classified and {?is/are} counted as incorrect in the performance metrics."
    )
  }

  evaluate_cv_performance(
    cv_predictions = list(scored$predicted_class),
    cv_probabilities = list(as.matrix(
      scored |> dplyr::select(dplyr::all_of(class_names))
    )),
    cv_actual = list(scored$actual_class),
    cv_landscape_ids = list(scored$landscape_id),
    class_names = class_names,
    cv_method = "none",
    cv_folds = 1,
    verbose = verbose,
    return_predictions = FALSE
  )
}

#' Remove landscapes with incomplete metrics
#'
#' Removes missing data in three steps, from least to most consequential.
#' First drops any predictor columns that are NA for every landscape (metrics
#' that are undefined for the given landscapes carry no information and would
#' otherwise remove the entire dataset). Then drops the row-wise counterpart:
#' landscapes that are NA for every remaining predictor, which carry no
#' information either. Only then resolves values missing from some, but not all,
#' landscapes. Issues warnings listing
#' dropped metrics and removed landscapes, and aborts if no usable predictors
#' or landscapes remain.
#'
#' @param metrics_wide Data frame in wide format. Output from metrics_to_wide().
#' @param predictor_cols Character vector. Names of predictor columns to check for NAs.
#' @param na_action Character. How to resolve values that are missing for some but
#'   not all landscapes: \code{"drop_metrics"} removes the
#'   affected metrics and keeps every landscape; \code{"drop_landscapes"}
#'   removes the affected landscapes and keeps every metric.
#'
#' @return Data frame after resolving incomplete predictors according to
#'   \code{na_action}.
#'
#' @keywords internal
#' @importFrom cli cli_warn cli_abort
remove_incomplete_landscapes <- function(
  metrics_wide,
  predictor_cols,
  na_action = "drop_metrics"
) {
  # Drop predictor columns that are NA for every landscape. These metrics are
  # undefined for the given landscapes (e.g. iji or rpr for two-class
  # landscapes) and carry no information. If left in place they would flag
  # every landscape as incomplete and remove the entire dataset
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

  # No predictor columns means there is nothing to train or predict on
  if (length(predictor_cols) == 0) {
    cli::cli_abort(c(
      "No landscapes remaining after removing those with incomplete metrics",
      "i" = "All required features were NA for every landscape"
    ))
  }

  # Landscapes with no usable metric carry no information; remove them before
  # partially missing values determine which metrics or landscapes to drop
  all_na_rows <- rowSums(is.na(metrics_wide[, predictor_cols, drop = FALSE])) ==
    length(predictor_cols)

  if (any(all_na_rows)) {
    removed_names <- metrics_wide$landscape_name[all_na_rows]

    cli::cli_warn(c(
      "Removed {sum(all_na_rows)} landscape{?s} where every required metric was NA",
      "i" = "Removed: {.val {removed_names}}"
    ))

    metrics_wide <- metrics_wide[!all_na_rows, ]

    if (nrow(metrics_wide) == 0) {
      cli::cli_abort(c(
        "No landscapes remaining after removing those with incomplete metrics",
        "i" = "Every landscape was NA for all required metrics"
      ))
    }
  }

  # What remains are values missing for some but not all landscapes
  # The user decides how to proceed in this case: dropping the metric costs one
  # predictor, dropping the landscapes costs training samples. Report both costs
  # and let na_action decide
  na_rows <- rowSums(is.na(metrics_wide[, predictor_cols, drop = FALSE])) > 0
  incomplete_cols <- predictor_cols[vapply(
    predictor_cols,
    function(col) any(is.na(metrics_wide[[col]])),
    logical(1)
  )]

  if (any(na_rows)) {
    n_landscapes <- sum(na_rows)
    n_metrics <- length(incomplete_cols)

    if (na_action == "drop_metrics") {
      if (length(setdiff(predictor_cols, incomplete_cols)) == 0) {
        cli::cli_abort(c(
          "No metrics remaining after dropping those with missing values",
          "i" = "All {n_metrics} remaining metric{?s} had an NA for at least one landscape",
          "i" = "Use {.code na_action = \"drop_landscapes\"} to drop the {n_landscapes} affected landscape{?s} instead"
        ))
      }

      cli::cli_warn(c(
        "Dropped {n_metrics} metric{?s} that {?is/are} missing for some landscapes",
        "i" = "Dropped: {.val {incomplete_cols}}",
        "i" = "Use {.code na_action = \"drop_landscapes\"} to keep them and drop {n_landscapes} landscape{?s} instead"
      ))

      metrics_wide <- metrics_wide[,
        setdiff(colnames(metrics_wide), incomplete_cols),
        drop = FALSE
      ]
    } else {
      removed_names <- metrics_wide$landscape_name[na_rows]

      cli::cli_warn(c(
        "Removed {n_landscapes} landscape{?s} with incomplete metrics",
        "i" = "Removed: {.val {removed_names}}",
        "i" = "Use {.code na_action = \"drop_metrics\"} to keep them and drop {n_metrics} metric{?s} instead"
      ))

      metrics_wide <- metrics_wide[!na_rows, ]

      if (nrow(metrics_wide) == 0) {
        cli::cli_abort(c(
          "No landscapes remaining after removing those with incomplete metrics",
          "i" = "All {n_landscapes} landscape{?s} had NA values in required features"
        ))
      }
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
  model <- tryCatch(
    neuralnet::neuralnet(
      formula = pattern ~ .,
      data = data,
      hidden = hidden,
      threshold = threshold,
      stepmax = stepmax
    ),
    error = function(e) {
      if (
        grepl(
          "error derivative contains a NA",
          conditionMessage(e),
          fixed = TRUE
        )
      ) {
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

  # Failure to converge is only a warning in neuralnet, and the object it
  # returns has no weights. Left alone it looks like a trained model and only
  # fails much later, inside predict(), with a message about non-numeric
  # arguments to a matrix product, so fail with context here
  if (is.null(model$weights)) {
    cli::cli_abort(c(
      "Neural network training did not converge.",
      "x" = "{.pkg neuralnet} stopped after {stepmax} steps without reaching the error threshold of {threshold}.",
      "i" = "Increase {.arg stepmax} or relax {.arg threshold} in {.fn train_metric_model}.",
      "i" = "Or select fewer metrics with {.fn evaluate_metrics} and pass them via {.arg metrics_selected} as many correlated predictors could prevent convergence."
    ))
  }

  model
}
