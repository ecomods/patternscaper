#' Evaluate Landscape Metrics
#'
#' Identifies the most informative metrics for discriminating between landscape_name types.
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
#'     If you don't want to filter based on correlation, set to 1.
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

  if (
    !all(
      c("landscape_name", "metric", "pattern", "value") %in%
        colnames(calculated_metrics)
    )
  ) {
    stop(
      "calculated_metrics must contain columns: landscape_name, metric, pattern, and value"
    )
  }

  # Validate method parameter early
  valid_methods <- c(
    "coeffvar_all",
    "lin_mod_r2",
    "mean_groups",
    "fisher_score",
    "kruskal_p"
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

  # Check if we have enough metrics to supply the requested number
  num_metrics <- length(unique(calculated_metrics$metric))
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

  # Check if we have at least two landscape_name types
  if (length(unique(calculated_metrics$pattern)) < 2) {
    stop(
      "At least two different landscape_name patternes are required for metric evaluation"
    )
  }

  # Get ranked metrics using the selected method
  ranked_metrics <- rank_metrics_by_method(
    calculated_metrics = calculated_metrics,
    method = method
  )

  # Select metrics with low correlation if requested
  if (correlation_threshold < 1) {
    top_metrics <- select_metrics_correlation(
      metric_ranking = ranked_metrics,
      calculated_metrics = calculated_metrics,
      metrics_number = metrics_number,
      correlation_threshold = correlation_threshold
    )
  } else {
    top_metrics <- ranked_metrics[1:metrics_number]
  }

  return(top_metrics)
}

#' Rank Metrics by Method
#'
#' Internal function that ranks metrics according to different methods.
#'
#' @param calculated_metrics tibble. Metrics data.
#' @param method Character. Selection method to use.
#'
#' @return Character vector. Metrics ranked from best to worst according to method.
#' @noRd

rank_metrics_by_method <- function(calculated_metrics, method) {
  if (method == "coeffvar_all") {
    return(rank_by_coefficient_variation(calculated_metrics))
  } else if (method == "lin_mod_r2") {
    return(rank_by_linear_model(calculated_metrics))
  } else if (method == "mean_groups") {
    return(rank_by_mean_differences(calculated_metrics))
  } else if (method == "fisher_score") {
    return(rank_by_fisher_score(calculated_metrics))
  } else if (method == "kruskal_p") {
    return(rank_by_kruskal(calculated_metrics))
  } else {
    stop(paste("Unknown method:", method))
  }
}

#' Rank by Coefficient of Variation
#'
#' Ranks metrics by their coefficient of variation (CV)
#'
#' @param calculated_metrics tibble. Metrics data.
#'
#' @return Character vector. Metrics ranked by CV (highest first).
#' @noRd
rank_by_coefficient_variation <- function(calculated_metrics) {
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

  return(cv_result$metric)
}

#' Rank by Linear Model Statistics
#'
#' Ranks metrics by R-squared from linear models
#'
#' @param calculated_metrics tibble. Metrics data.
#'
#' @return Character vector. Metrics ranked by the specified statistic.
#' @noRd
rank_by_linear_model <- function(
  calculated_metrics
) {
  # Create a nested dataframe with data for each metric
  metric_models <- calculated_metrics |>
    dplyr::group_by(metric) |>
    tidyr::nest() |>
    dplyr::mutate(
      # Fit linear model for each metric
      model = purrr::map(data, function(df) {
        tryCatch(
          lm(value ~ type, data = df),
          error = function(e) NULL
        )
      }),
      r2 = purrr::map_dbl(model, function(m) {
        if (is.null(m)) {
          return(NA_real_)
        }
        tryCatch(
          summary(m)$r.squared,
          error = function(e) NA_real_
        )
      })
    )

  # Sort by R2-value
    metric_models <- metric_models |>
    dplyr::arrange(dplyr::desc(r2)) # Largest R² first

  return(metric_models$metric)
}

#' Rank by Mean Differences
#'
#' Ranks metrics by their ability to differentiate between landscape_name types
#' based on the differences in means across types.
#'
#' @param calculated_metrics tibble. Metrics data.
#'
#' @return Character vector. Metrics ranked by mean differences (highest first).
#' @noRd
rank_by_mean_differences <- function(calculated_metrics) {
  # Calculate means across all data and by type
  means_all <- calculated_metrics |>
    dplyr::summarize(
      mean_all = mean(value, na.rm = TRUE),
      .by = metric
    )
  means_types <- calculated_metrics |>
    dplyr::summarize(
      mean_type = mean(value, na.rm = TRUE),
      .by = c(metric, pattern)
    )

  means_groups <- means_types |>
    dplyr::left_join(means_all, by = "metric")

  # Calculate relative difference from mean for each type
  means_groups <- means_groups |>
    dplyr::mutate(rel_mean_diff = abs((mean_type - mean_all) / mean_all)) |>
    # Handle cases where mean_all is zero to avoid Inf values
    dplyr::mutate(
      rel_mean_diff = ifelse(
        is.finite(rel_mean_diff),
        rel_mean_diff,
        NA_real_
      )
    )

  # Calculate overall importance score for each metric (sum across types)
  ranking <- dplyr::summarize(
    means_groups,
    importance_scores = sum(rel_mean_diff, na.rm = TRUE),
    .by = metric
  ) |>
    # Rank by importance (higher total deviation = better discriminating power)
    dplyr::arrange(desc(importance_scores))

  return(ranking$metric)
}

#' Rank by Fisher Score
#'
#' Ranks metrics by their within variance compared to the variance between groups
#'
#' @param calculated_metrics tibble. Metrics data.
#'
#' @return Character vector. Metrics ranked by mean differences (highest first).
#' @noRd
rank_by_fisher_score <- function(calculated_metrics) {
  fisher_results <- calculated_metrics |>
    dplyr::group_by(metric) |>
    tidyr::nest() |>
    dplyr::mutate(
      fisher_score = purrr::map_dbl(data, function(df) {
        df <- df[!is.na(df$value), ]
        if (length(unique(df$pattern)) < 2) return(NA_real_)
        overall_mean <- mean(df$value)
        group_stats <- df |>
          dplyr::group_by(pattern) |>
          dplyr::summarize(
            n = dplyr::n(),
            mean_val = mean(value),
            sd_val = sd(value),
            .groups = "drop"
          )
        sb <- sum(group_stats$n * (group_stats$mean_val - overall_mean)^2) /
          (nrow(group_stats) - 1)
        sw <- sum((group_stats$n - 1) * (group_stats$sd_val^2)) /
          (sum(group_stats$n) - nrow(group_stats))
        return(sb / sw)
      })
    ) |>
    dplyr::arrange(dplyr::desc(fisher_score))

  return(fisher_results$metric)
}


#' Rank by Kruskal-Wallis H
#'
#' Similar as Fisher score, but more robust towards non-normality
#'
#' @param calculated_metrics tibble. Metrics data.
#'
#' @return Character vector. Metrics ranked by mean differences (highest first).
#' @noRd
rank_by_kruskal <- function(calculated_metrics) {
  kruskal_results <- calculated_metrics |>
    dplyr::group_by(metric) |>
    tidyr::nest() |>
    dplyr::mutate(
      kruskal_p = purrr::map_dbl(data, function(df) {
        df <- df[!is.na(df$value), ]
        if (length(unique(df$pattern)) < 2) return(NA_real_)
        tryCatch(
          kruskal.test(value ~ pattern, data = df)$p.value,
          error = function(e) NA_real_
        )
      })
    ) |>
    dplyr::arrange(kruskal_p)

  return(kruskal_results$metric)
}

#' Select Uncorrelated Metrics
#'
#' Selects metrics with low correlation from a set of ranked metrics.
#' This helps ensure the selected metrics provide diverse information.
#'
#' @param metric_ranking Character vector. Names of metrics in order of their ranking
#'   (most important first).
#' @param calculated_metrics Data frame. The calculated metrics data used to compute correlations.
#'   Must contain columns 'landscape_name', 'metric', and 'value'.
#' @param metrics_number Integer. Number of metrics to select.
#' @param correlation_threshold Numeric. Maximum allowed correlation between selected metrics (default: 0.7).
#' @param verbose Logical. Whether to print progress messages (default: FALSE).
#'
#' @return Character vector. Names of selected uncorrelated metrics.
#' @noRd
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
      !all(
        c("landscape_name", "metric", "value") %in% colnames(calculated_metrics)
      )
  ) {
    stop(
      "calculated_metrics must be a data frame with 'landscape_name', 'metric', and 'value' columns"
    )
  }

  if (!is.numeric(metrics_number) || metrics_number < 1) {
    stop("metrics_number must be a positive integer")
  }

  # Calculate correlation between metrics
  metrics_correlation <- calculated_metrics |>
    dplyr::select(landscape_name, metric, value) |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    ) |>
    dplyr::select(-landscape_name) |>
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
