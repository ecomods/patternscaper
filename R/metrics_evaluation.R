#' Evaluate Landscape Metrics
#'
#' Identifies the most informative metrics for discriminating between landscape types.
#'
#' @param calculated_metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_number Integer. Number of top metrics to return (default: 10).
#' @param method Character. Selection method (options: "coeffvar_all", "lin_mod_r2", "mean_groups") (default: "coeffvar_all").
#' @param plot Logical. Whether to generate visualization (default: FALSE).
#' @param exclude_NA_metrics Logical. Whether to exclude metrics with NA values (default: TRUE).
#'     This is recommended if data is later used for model training as this does not
#'     accept missing values.
#' @param exclude_metrics Character vector. Metrics to exclude (default: NULL).
#' @param correlation_threshold Numeric. Maximum allowed correlation between selected metrics (default: 0.7).
#'
#' @return Character vector. Names of most sensitive metrics.
#' @export
evaluate_landscape_metrics <- function(
  calculated_metrics,
  metrics_number = 10,
  method = "coeffvar_all",
  plot = FALSE,
  exclude_NA_metrics = TRUE,
  exclude_metrics = NULL,
  correlation_threshold = 0.7
) {
  # Validate input data
  if (
    !is.data.frame(calculated_metrics) && !tibble::is_tibble(calculated_metrics)
  ) {
    stop("calculated_metrics must be a data frame or tibble")
  }

  if (!all(c("metric", "type", "value") %in% colnames(calculated_metrics))) {
    stop(
      "calculated_metrics must contain columns: landscape, metric, type, and value"
    )
  }

  # Validate method parameter early
  valid_methods <- c(
    "coeffvar_all",
    "lin_mod_p",
    "lin_mod_r2",
    "mean_groups"
  )
  if (!(method %in% valid_methods)) {
    stop(paste(
      "Invalid method. Choose from:",
      paste(valid_methods, collapse = ", ")
    ))
  }

  # Exclude metrics if specified
  if (!is.null(exclude_metrics)) {
    calculated_metrics <- calculated_metrics[
      !calculated_metrics$metric %in% exclude_metrics,
    ]
    if (nrow(calculated_metrics) == 0) {
      stop("No metrics left after exclusion")
    }
  }

  # Exclude metrics with NA values is requested
  if (exclude_NA_metrics) {
    na_metrics <- calculated_metrics |>
      dplyr::filter(is.na(value)) |>
      dplyr::pull(metric) |>
      unique()
    nrow_before <- nrow(calculated_metrics)
    calculated_metrics <- calculated_metrics[
      !calculated_metrics$metric %in% na_metrics,
    ]
    nrow_after <- nrow(calculated_metrics)
    if (nrow_after == 0) {
      stop("No metrics left after excluding those with NA values")
    }
    if (length(na_metrics) > 0) {
      message(paste(
        "Excluded",
        nrow_before - nrow_after,
        "rows due to",
        length(na_metrics),
        "metrics with NA values:",
        paste(na_metrics, collapse = ", "),
        "\n",
        "Use exclude_NA_metrics = FALSE to retain these metrics (not recommended for model training)."
      ))
    }
  }

  # Get unique metrics and types
  metrics_names <- unique(calculated_metrics$metric)
  num_metrics <- length(metrics_names)

  # Check if we have enough metrics
  if (num_metrics < metrics_number) {
    warning(paste(
      "Requested",
      metrics_number,
      "metrics but only",
      num_metrics,
      "are available. Returning all available metrics."
    ))
    metrics_number <- num_metrics
  }

  # Number of landscape types
  landscape_types <- unique(calculated_metrics$type)
  num_types <- length(landscape_types)

  if (num_types < 2) {
    stop(
      "At least two different landscape types are required for metric evaluation"
    )
  }

  # Choose method for metric evaluation
  if (method == "coeffvar_all") {
    # Calculate coefficient of variation directly using group_by and summarize
    cv_result <- calculated_metrics |>
      dplyr::group_by(metric) |>
      dplyr::summarize(
        mean_val = mean(value, na.rm = TRUE),
        sd_val = sd(value, na.rm = TRUE),
        cv = sd_val / mean_val,
        .groups = "drop"
      ) |>
      dplyr::arrange(desc(cv)) |>
      dplyr::filter(is.finite(cv)) # Remove NaN/Inf values

    # Select the best uncorrelated metrics
    top_metrics <- select_metrics_correlation(
      metric_ranking = cv_result$metric,
      calculated_metrics = calculated_metrics,
      metrics_number = metrics_number,
      correlation_threshold = correlation_threshold
    )
  } else if (method == "lin_mod_p") {
    means_types$p <- NA

    for (i in 1:num_metrics) {
      dat <- calculated_metrics[calculated_metrics$metric == metrics_names[i], ]

      # Ensure we have valid data for linear model
      if (nrow(dat) > 0 && !all(is.na(dat$value))) {
        tryCatch(
          {
            model <- lm(data = dat, value ~ type)
            # Get p-value from ANOVA
            means_types$p[i] <- anova(model)$`Pr(>F)`[1]
          },
          error = function(e) {
            warning(paste(
              "Error fitting model for metric",
              metrics_names[i],
              ":",
              e$message
            ))
            means_types$p[i] <- NA
          }
        )
      }
    }

    # Ranking of the smallest p-values
    ranking <- rank(means_types$p, na.last = TRUE)
    top_metrics <- metrics_names[ranking <= metrics_number]
  } else if (method == "lin_mod_r2") {
    # Linear model using R-squared
    means_types$r2 <- NA

    for (i in 1:num_metrics) {
      dat <- calculated_metrics[calculated_metrics$metric == metrics_names[i], ]

      # Ensure we have valid data for linear model
      if (nrow(dat) > 0 && !all(is.na(dat$value))) {
        tryCatch(
          {
            model <- lm(data = dat, value ~ type)
            means_types$r2[i] <- summary(model)$r.squared
          },
          error = function(e) {
            warning(paste(
              "Error fitting model for metric",
              metrics_names[i],
              ":",
              e$message
            ))
            means_types$r2[i] <- NA
          }
        )
      }
    }

    # Ranking of the highest R-squared values
    ranking <- rank(means_types$r2, na.last = TRUE)
    top_metrics <- metrics_names[ranking > (num_metrics - metrics_number)] # take only top x
  }

  #--------------------------------------------------------------------------------------------
  # how strongly do the means vary from the overall mean
  #--------------------------------------------------------------------------------------------
  if (method == "mean_groups") {
    # Calculate relative difference from mean for each type
    rel_mean_diff <- (means_types[, 1:num_types] - means_types$all) /
      means_types$all

    # Handle NaN, Inf values from division by zero or very small numbers
    rel_mean_diff[!is.finite(rel_mean_diff)] <- NA

    # Calculate absolute difference for better comparison
    abs_diff <- abs(rel_mean_diff)

    # Calculate overall importance score for each metric (sum across types)
    importance_scores <- rowSums(abs_diff, na.rm = TRUE)

    # Rank by importance (higher total deviation = better discriminating power)
    ranking <- rank(-importance_scores, na.last = TRUE)

    # Select top metrics based on user-specified count
    top_metrics <- metrics_names[ranking <= metrics_number]

    # If no metrics selected (e.g., all NA), provide a warning
    if (length(top_metrics) == 0) {
      warning("No metrics selected by mean_groups method. Check your data.")
      top_metrics <- metrics_names[1:min(metrics_number, num_metrics)]
    }
  }

  # Plot classification results if requested
  if (plot) {
    plot_classification_results()
  }

  return(top_metrics)
}


#' Select Uncorrelated Metrics
#'
#' Selects metrics with low correlation from a set of ranked metrics.
#' This helps ensure the selected metrics provide diverse information.
#'
#' @param metric_ranking Character vector. Names of metrics in order of their ranking
#'   (most important first).
#' @param calculated_metrics Data frame. The calculated metrics data used to compute correlations.
#'   Must contain columns 'landscape', 'metric', and 'value'.
#' @param metrics_number Integer. Number of metrics to select.
#' @param correlation_threshold Numeric. Maximum allowed correlation between selected metrics (default: 0.7).
#' @param verbose Logical. Whether to print progress messages (default: FALSE).
#'
#' @return Character vector. Names of selected uncorrelated metrics.
select_metrics_correlation <- function(
  metric_ranking,
  calculated_metrics,
  metrics_number,
  correlation_threshold = 0.7,
  verbose = FALSE
) {
  # Input validation
  if (!is.character(metric_ranking) || length(metric_ranking) == 0) {
    stop("metric_ranking must be a non-empty character vector of metric names")
  }

  if (
    !is.data.frame(calculated_metrics) ||
      !all(c("landscape", "metric", "value") %in% colnames(calculated_metrics))
  ) {
    stop(
      "calculated_metrics must be a data frame with 'landscape', 'metric', and 'value' columns"
    )
  }

  if (!is.numeric(metrics_number) || metrics_number < 1) {
    stop("metrics_number must be a positive integer")
  }

  # Calculate correlation between metrics
  metrics_correlation <- calculated_metrics |>
    dplyr::select(landscape, metric, value) |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    ) |>
    dplyr::select(-landscape) |>
    stats::cor(use = "pairwise.complete.obs")

  # Use the ranked metrics vector directly
  metric_options <- metric_ranking

  # Check if all metrics in ranking exist in correlation matrix
  missing_metrics <- setdiff(metric_options, rownames(metrics_correlation))
  if (length(missing_metrics) > 0) {
    warning(paste(
      "The following metrics are missing from the correlation matrix:",
      paste(missing_metrics, collapse = ", ")
    ))
    metric_options <- intersect(metric_options, rownames(metrics_correlation))
  }

  # Initialize results
  top_metrics <- character(0)

  # Select metrics with low correlation
  i <- 0
  while (TRUE) {
    i <- i + 1
    if (length(top_metrics) >= metrics_number || i > length(metric_options)) {
      break
    }

    current_metric <- metric_options[i]

    # Skip if already selected
    if (current_metric %in% top_metrics) {
      next
    }

    # Skip if not in correlation matrix
    if (!current_metric %in% rownames(metrics_correlation)) {
      warning(paste(
        "Metric",
        current_metric,
        "not found in correlation matrix. Skipping."
      ))
      next
    }

    # Check correlation with all previously selected metrics
    if (length(top_metrics) > 0) {
      cor_values <- abs(metrics_correlation[current_metric, top_metrics])

      if (verbose) {
        message(paste(
          "Correlation values:",
          paste(cor_values, collapse = ", ")
        ))
      }

      # Check if any correlation exceeds threshold
      if (any(cor_values > correlation_threshold, na.rm = TRUE)) {
        # Determine which correlations are too high
        high_correlations <- which(cor_values > correlation_threshold)

        message(paste(
          "Skipping metric",
          current_metric,
          "due to high correlation with:",
          paste(top_metrics[high_correlations], collapse = ", ")
        ))
        next
      }
    }

    # Add metric to selected list
    top_metrics <- c(top_metrics, current_metric)

    if (verbose) {
      message(paste(
        "Selected metrics so far:",
        paste(top_metrics, collapse = ", ")
      ))
    }
  }

  # Fill up with remaining metrics if needed
  if (length(top_metrics) < metrics_number) {
    warning(paste(
      "Only",
      length(top_metrics),
      "uncorrelated metrics found.",
      "Filling up to",
      metrics_number,
      "with next best correlated metrics."
    ))

    # Get remaining metrics in order of importance
    additional_metrics <- setdiff(metric_options, top_metrics)
    needed_count <- min(
      length(additional_metrics),
      metrics_number - length(top_metrics)
    )

    top_metrics <- c(
      top_metrics,
      additional_metrics[1:needed_count]
    )
  }

  return(top_metrics)
}
