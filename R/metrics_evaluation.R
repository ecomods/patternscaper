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
#'
#' @return Character vector. Names of most sensitive metrics.
#' @export
evaluate_landscape_metrics <- function(
  calculated_metrics,
  metrics_number = 10,
  method = "coeffvar_all",
  plot = FALSE,
  exclude_NA_metrics = TRUE,
  exclude_metrics = NULL
) {
  # Validate input data
  if (
    !is.data.frame(calculated_metrics) && !tibble::is_tibble(calculated_metrics)
  ) {
    stop("calculated_metrics must be a data frame or tibble")
  }

  if (!all(c("metric", "type", "value") %in% colnames(calculated_metrics))) {
    stop("calculated_metrics must contain columns: metric, type, and value")
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

  # Initialize top_metrics
  top_metrics <- NULL

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

  # Calculate coefficient of variation for each metric
  # Once for each landscape type separately, and once jointly
  means_types <- as.data.frame(tapply(
    calculated_metrics$value,
    list(
      as.factor(calculated_metrics$metric),
      as.factor(calculated_metrics$type)
    ),
    mean,
    na.rm = TRUE
  ))

  means_types$all <- tapply(
    calculated_metrics$value,
    as.factor(calculated_metrics$metric),
    mean,
    na.rm = TRUE
  )

  sd_types <- as.data.frame(tapply(
    calculated_metrics$value,
    list(
      as.factor(calculated_metrics$metric),
      as.factor(calculated_metrics$type)
    ),
    sd,
    na.rm = TRUE
  ))

  sd_types$all <- tapply(
    calculated_metrics$value,
    as.factor(calculated_metrics$metric),
    sd,
    na.rm = TRUE
  )

  # Choose method for metric evaluation
  if (method == "coeffvar_all") {
    # Coefficient of variation for all data
    cv_values <- sd_types$all / means_types$all

    # Handle zero means or NAs
    cv_values[!is.finite(cv_values)] <- NA

    # Rank metrics by coefficient of variation
    ranking <- rank(cv_values, na.last = TRUE)
    top_metrics <- metrics_names[ranking > (num_metrics - metrics_number)]
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
    top_metrics <- metrics_names[ranking > (num_metrics - metrics_number)] #take only top x
  }

  #--------------------------------------------------------------------------------------------
  #how strongly do the means vary from the overall mean
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
