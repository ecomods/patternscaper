#' Evaluate Landscape Metrics
#'
#' Identifies the metrics most suitable for discriminating between different pattern types
#' based on a specified selection method. The choice of method affects the ranking:
#' parametric methods assume linear relationships and normally distributed residuals,
#' while non-parametric methods are more robust to outliers and deviations from normality.
#' This function is useful for selecting informative metrics to train the
#' metric-based neural network.
#'
#' @param metrics tibble. Metrics from calculate_metrics().
#' @param metrics_number Integer. Number of top metrics to return (default: 10).
#' @param method Character. Selection method to use (default: "kruskal_effsize").
#'     See 'Ranking Methods' section below for details.
#' @param exclude_NA_metrics Logical. Whether to exclude metrics with NA values (default: TRUE).
#'     This is recommended if data is later used for model training as this does not
#'     accept missing values.
#' @param exclude_metrics Character vector. Metrics to exclude (default: NULL).
#' @param correlation_threshold Numeric. Maximum allowed correlation between selected metrics (default: 0.7).
#'     If you do not want to filter based on correlation, set to 1.
#' @param verbose Logical. Whether to print detailed messages on excluded metrics
#'     or just a summary (default: FALSE).
#'
#' @section Ranking Methods:
#' \describe{
#'   \item{\code{coeffvar_all}}{Coefficient of Variation (CV = SD/mean). Ranks metrics by
#'     their relative variability across landscapes. Higher CV indicates greater spread.
#'     Best for identifying metrics with high variability regardless of pattern type.}
#'   \item{\code{lin_mod_r2}}{Linear Model R-squared. Fits \code{value ~ pattern} for each
#'     metric and ranks by R². Higher values indicate better ability to predict pattern
#'     types. Assumes linear relationships and normally distributed residuals.}
#'   \item{\code{mean_groups}}{Mean Differences. Calculates relative differences between
#'     pattern-specific means and overall mean, then sums across patterns. Higher scores
#'     indicate better discrimination between pattern types.}
#'   \item{\code{fisher_score}}{Fisher Score (ratio of between-group to within-group variance).
#'     Higher scores indicate better separation between pattern types. Assumes normally
#'     distributed data within groups.}
#'   \item{\code{kruskal_effsize}}{Kruskal-Wallis H test effect sizes. Non-parametric test for differences
#'     between groups. Higher effect sizes indicate better discrimination between pattern types.}
#' }
#'
#' @return Character vector. Names of metrics that best discriminate between pattern types.
#' @examples
#' # Calculate most suitable metrics to discriminate between spots and random landscapes
#' landscapes <- create_landscapes(n = 50, patterns = c("spots","random"))
#' metrics <- calculate_metrics(
#'   landscapes,
#'   level = "landscape"
#' )
#' metric_list <- evaluate_landscape_metrics(
#'   metrics = metrics,
#'   metrics_number = 5,
#'   method = "coeffvar_all"
#' )
#'
#' @seealso \code{\link{train_metrics_model}}
#' @family metrics
#' @export
evaluate_landscape_metrics <- function(
  metrics,
  metrics_number = 10,
  method = "kruskal_effsize",
  exclude_NA_metrics = TRUE,
  exclude_metrics = NULL,
  correlation_threshold = 0.7,
  verbose = FALSE
) {
  # Validate input data
  if (!is.data.frame(metrics) && !tibble::is_tibble(metrics)) {
    cli::cli_abort("metrics must be a data frame or tibble")
  }

  if (
    !all(
      c("landscape_name", "metric", "pattern", "value", "level") %in%
        colnames(metrics)
    )
  ) {
    cli::cli_abort(
      "metrics must contain columns: {.field landscape_name}, {.field metric}, {.field pattern}, {.field value}, and {.field level}"
    )
  }

  # Check if the level is landscape. If not abort and tell the user that
  # currently only the landscape level is supported
  if (!unique(metrics$level) %in% c("landscape", "class")) {
    cli::cli_abort(
      "Currently only metrics calculated at the landscape or class level are supported. Please calculate metrics at the landscape level."
    )
  }

  if (!is.numeric(metrics_number) || metrics_number < 1) {
    cli::cli_abort("metrics_number must be a positive integer")
  }

  # Validate method parameter
  valid_methods <- c(
    "coeffvar_all",
    "lin_mod_r2",
    "mean_groups",
    "fisher_score",
    "kruskal_effsize"
  )
  if (!(method %in% valid_methods)) {
    cli::cli_abort(
      "Invalid method. Choose from: {.val {valid_methods}}"
    )
  }

  # Validate correlation_threshold
  if (
    !is.numeric(correlation_threshold) ||
      correlation_threshold < 0 ||
      correlation_threshold > 1
  ) {
    cli::cli_abort(
      "correlation_threshold must be a numeric value between 0 and 1"
    )
  }

  # Exclude metrics if specified
  if (!is.null(exclude_metrics)) {
    metrics <- metrics[!metrics$metric %in% exclude_metrics, ]
    if (nrow(metrics) == 0) {
      cli::cli_abort("No metrics left after exclusion")
    }
  }

  # Exclude metrics with NA values if the user requests it
  # as they can't be used for model training
  if (exclude_NA_metrics) {
    na_metrics <- metrics |>
      dplyr::filter(is.na(value)) |>
      dplyr::pull(metric) |>
      unique()
    nrow_before <- nrow(metrics)
    metrics <- metrics[!metrics$metric %in% na_metrics, ]
    nrow_after <- nrow(metrics)

    if (nrow_after == 0) {
      cli::cli_abort("No metrics left after excluding those with NA values")
    }

    if (length(na_metrics) > 0) {
      cli::cli_warn(
        "Excluded {nrow_before - nrow_after} rows containing {length(na_metrics)} metrics with NA values. Metrics removed: {.val {na_metrics}} \nUse {.code exclude_NA_metrics = FALSE} to retain (not recommended for model training) "
      )
    }
  }

  # Check if we have enough metrics
  num_metrics <- length(unique(metrics$metric))
  if (num_metrics < metrics_number) {
    cli::cli_warn(
      "Only {num_metrics} metric{?s} available, returning all instead of requested {metrics_number}"
    )
    metrics_number <- num_metrics
  }

  # Check patterns
  if (length(unique(metrics$pattern)) < 2) {
    cli::cli_abort(
      "At least two different landscape patterns are required for metric evaluation"
    )
  }

  # Remove metrics with zero variance as they cannot be used to distinguish
  # landscapes
  zero_var_metrics <- metrics |>
    dplyr::summarize(var_value = var(value, na.rm = TRUE), .by = metric) |>
    dplyr::filter(var_value == 0) |>
    dplyr::pull(metric)

  if (length(zero_var_metrics) > 0) {
    metrics <- metrics[!metrics$metric %in% zero_var_metrics, ]
    cli::cli_warn(
      "Excluded {length(zero_var_metrics)} metrics with zero variance: {.val {zero_var_metrics}}"
    )
  }

  # Get ranked metrics
  ranked_metrics <- rank_metrics_by_method(
    metrics = metrics,
    method = method
  )

  # Verbose output
  if (verbose) {
    cli::cli_alert_info("Ranked metrics ({method}): {.val {ranked_metrics}}")
  }

  # Return early if no correlation filtering needed
  if (correlation_threshold >= 1) {
    available_count <- min(length(ranked_metrics), metrics_number)
    return(ranked_metrics[seq_len(available_count)])
  }

  # Select metrics with low correlation - messages handled inside function
  top_metrics <- select_metrics_correlation(
    metric_ranking = ranked_metrics,
    metrics = metrics,
    metrics_number = metrics_number,
    correlation_threshold = correlation_threshold,
    verbose = verbose
  )

  return(top_metrics)
}

#' Rank Metrics by Method
#'
#' Internal function that ranks metrics according to different methods.
#'
#' @param metrics tibble. Metrics data.
#' @param method Character. Selection method to use.
#'
#' @return Character vector. Metrics ranked from best to worst according to method.
#' @noRd
rank_metrics_by_method <- function(metrics, method) {
  switch(
    method,
    coeffvar_all = rank_by_coefficient_variation(metrics),
    lin_mod_r2 = rank_by_linear_model(metrics),
    mean_groups = rank_by_mean_differences(metrics),
    fisher_score = rank_by_fisher_score(metrics),
    kruskal_effsize = rank_by_kruskal(metrics),
    cli::cli_abort("Unknown ranking method: {.val {method}}")
  )
}

#' Rank by Coefficient of Variation
#'
#' Ranks metrics by their coefficient of variation (CV = SD/mean).
#' Higher CV indicates greater relative variability across landscapes.
#'
#' @param metrics tibble. Metrics data with columns 'metric' and 'value'.
#'
#' @return Character vector. Metrics ranked by CV (highest first).
#' @importFrom dplyr group_by summarize filter arrange pull
#' @noRd
rank_by_coefficient_variation <- function(metrics) {
  metrics |>
    dplyr::group_by(metric) |>
    dplyr::summarize(
      cv = sd(value, na.rm = TRUE) / mean(value, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::filter(is.finite(cv)) |>
    dplyr::arrange(desc(cv)) |>
    dplyr::pull(metric)
}

#' Rank by Linear Model R-squared
#'
#' Ranks metrics by R² from linear models fitting value ~ pattern.
#' Higher R² indicates the metric better explains variance across landscape patterns.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return Character vector. Metrics ranked by R² (highest first).
#' @importFrom dplyr group_by arrange desc mutate
#' @importFrom tidyr nest
#' @importFrom purrr map_dbl
#' @importFrom stats lm
#' @noRd
rank_by_linear_model <- function(
  metrics
) {
  # Create a nested dataframe with data for each metric
  metric_models <- metrics |>
    dplyr::group_by(metric) |>
    tidyr::nest() |>
    dplyr::mutate(
      r2 = purrr::map_dbl(data, \(df) {
        tryCatch(
          {
            model <- lm(value ~ pattern, data = df)
            summary(model)$r.squared
          },
          error = \(e) NA_real_
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
#' Ranks metrics by their ability to differentiate between landscape types
#' based on the differences in means across patterns.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return Character vector. Metrics ranked by importance score (highest first).
#' @noRd
rank_by_mean_differences <- function(metrics) {
  # Calculate overall mean for each metric
  means_all <- metrics |>
    dplyr::summarize(
      mean_all = mean(value, na.rm = TRUE),
      .by = metric
    )

  # Calculate pattern-specific means and importance scores
  scores <- metrics |>
    dplyr::summarize(
      mean_type = mean(value, na.rm = TRUE),
      .by = c(metric, pattern)
    ) |>
    dplyr::left_join(means_all, by = "metric") |>
    dplyr::mutate(
      rel_mean_diff = abs((mean_type - mean_all) / mean_all),
      rel_mean_diff = dplyr::if_else(
        is.finite(rel_mean_diff),
        rel_mean_diff,
        NA_real_
      )
    ) |>
    dplyr::summarize(
      importance_score = sum(rel_mean_diff, na.rm = TRUE),
      .by = metric
    ) |>
    dplyr::arrange(desc(importance_score))

  return(scores$metric)
}

#' Rank by Fisher Score
#'
#' Ranks metrics by Fisher score (ratio of between-group to within-group variance).
#' Higher scores indicate better separation between pattern types.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return Character vector. Metrics ranked by Fisher score (highest first).
#' @noRd
rank_by_fisher_score <- function(metrics) {
  fisher_results <- metrics |>
    dplyr::group_by(metric) |>
    tidyr::nest() |>
    dplyr::mutate(
      fisher_score = purrr::map_dbl(data, \(df) {
        df <- df[!is.na(df$value), ]
        # Check if at least two patterns exist for this metric
        if (length(unique(df$pattern)) < 2) {
          return(NA_real_)
        }

        overall_mean <- mean(df$value)

        group_stats <- df |>
          dplyr::group_by(pattern) |>
          dplyr::summarize(
            n = dplyr::n(),
            mean_val = mean(value),
            sd_val = sd(value),
            .groups = "drop"
          )

        # Between-group variance
        between_var <- sum(
          group_stats$n * (group_stats$mean_val - overall_mean)^2
        ) /
          (nrow(group_stats) - 1)

        # Within-group variance
        within_var <- sum((group_stats$n - 1) * (group_stats$sd_val^2)) /
          (sum(group_stats$n) - nrow(group_stats))

        return(between_var / within_var)
      })
    ) |>
    dplyr::arrange(dplyr::desc(fisher_score))

  return(fisher_results$metric)
}

#' Rank by Kruskal-Wallis H test
#'
#' Ranks metrics using Kruskal-Wallis H test effect sizes.
#' Higher effect sizes indicate better discrimination between pattern types.
#' More robust to non-normality than Fisher score.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return Character vector. Metrics ranked by effect size (largest first).
#' @noRd
rank_by_kruskal <- function(metrics) {
  kruskal_results <- metrics |>
    dplyr::group_by(metric) |>
    tidyr::nest() |>
    dplyr::mutate(
      kruskal_effsize = purrr::map_dbl(data, \(df) {
        df <- df[!is.na(df$value), ]
        if (length(unique(df$pattern)) < 2) {
          return(NA_real_)
        }
        tryCatch(
          kruskal_effsize(df, value ~ pattern),
          error = function(e) NA_real_
        )
      })
    ) |>
    dplyr::arrange(dplyr::desc(kruskal_effsize))

  return(kruskal_results$metric)
}

#' Calculate Kruskal-Wallis Effect Size (Epsilon-Squared)
#'
#' Computes epsilon-squared effect size for Kruskal-Wallis test.
#'
#' @param data Data frame containing the data.
#' @param formula Formula specifying the model (e.g., value ~ group).
#'
#' @return Numeric. The epsilon-squared effect size.
#' @importFrom stats kruskal.test
#' @noRd
kruskal_effsize <- function(data, formula) {
  # Run Kruskal-Wallis test
  kt <- stats::kruskal.test(formula, data = data)

  # Calculate epsilon-squared using H statistic
  n <- nrow(data)
  effsize <- kt$statistic / ((n^2 - 1) / (n + 1))

  as.numeric(effsize)
}


#' Select Uncorrelated Metrics
#'
#' Selects metrics with low correlation from a set of ranked metrics.
#' This helps ensure the selected metrics provide diverse information.
#'
#' @param metric_ranking Character vector. Names of metrics in order of their ranking
#'   (most important first).
#' @param metrics Data frame. The calculated metrics data used to compute correlations.
#'   Must contain columns 'landscape_name', 'metric', and 'value'.
#' @param metrics_number Integer. Number of metrics to select.
#' @param correlation_threshold Numeric. Maximum allowed correlation between selected metrics (default: 0.7).
#' @param verbose Logical. Whether to print progress messages (default: FALSE).
#'
#' @return Character vector. Names of selected uncorrelated metrics.
#' @noRd
select_metrics_correlation <- function(
  metric_ranking,
  metrics,
  metrics_number,
  correlation_threshold = 0.7,
  verbose = FALSE
) {
  # Input validation
  if (!is.character(metric_ranking) || length(metric_ranking) == 0) {
    cli::cli_abort(
      "metric_ranking must be a non-empty character vector of metric names"
    )
  }

  if (!is.numeric(metrics_number) || metrics_number < 1) {
    cli::cli_abort("metrics_number must be a positive integer")
  }

  # Calculate correlation between metrics
  metrics_correlation <- metrics |>
    dplyr::select(landscape_name, metric, value) |>
    tidyr::pivot_wider(
      names_from = metric,
      values_from = value
    ) |>
    dplyr::select(-landscape_name) |>
    stats::cor(use = "pairwise.complete.obs")

  # Initialize results
  top_metrics <- character(0)

  # Select metrics with low correlation
  for (current_metric in metric_ranking) {
    if (length(top_metrics) >= metrics_number) {
      break
    }

    # Skip if already selected
    if (current_metric %in% top_metrics) {
      next
    }

    # Skip if not in correlation matrix
    if (!current_metric %in% rownames(metrics_correlation)) {
      if (verbose) {
        cli::cli_alert_warning(
          "Metric {.val {current_metric}} not found in correlation matrix. Skipping."
        )
      }
      next
    }

    # Check correlation with all previously selected metrics
    if (length(top_metrics) > 0) {
      cor_values <- abs(metrics_correlation[current_metric, top_metrics])

      if (verbose) {
        cli::cli_alert_info(
          "Correlation values for {.val {current_metric}}: {.val {round(cor_values, 3)}}"
        )
      }

      # Check if any correlation exceeds threshold
      if (any(cor_values > correlation_threshold, na.rm = TRUE)) {
        high_correlations <- which(cor_values > correlation_threshold)

        if (verbose) {
          cli::cli_alert_warning(
            "Skipping metric {.val {current_metric}} due to high correlation with: {.val {top_metrics[high_correlations]}}"
          )
        }
        next
      }
    }

    # Add metric to selected list
    top_metrics <- c(top_metrics, current_metric)

    if (verbose) {
      cli::cli_alert_info("Selected metrics so far: {.val {top_metrics}}")
    }
  }

  # Fill up with remaining metrics if needed
  if (length(top_metrics) < metrics_number) {
    cli::cli_alert_warning(
      "Only {length(top_metrics)} uncorrelated metric{?s} found. Filling to {metrics_number} with correlated metrics."
    )

    additional_metrics <- setdiff(metric_ranking, top_metrics)
    needed_count <- min(
      length(additional_metrics),
      metrics_number - length(top_metrics)
    )

    top_metrics <- c(top_metrics, additional_metrics[seq_len(needed_count)])
  }

  return(top_metrics)
}
