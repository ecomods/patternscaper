#' Outcome levels of a metrics evaluation
#'
#' The vocabulary of the `outcome` column of a `metrics_evaluation` ranking
#' table, ordered by the pipeline stage at which a metric leaves the selection.
#' `selected_*` and `dropped_*` metrics were scored by the ranking method;
#' `excluded_*` metrics never reached it and have no score or rank.
#'
#' @noRd
metrics_evaluation_outcomes <- c(
  "selected",
  "selected_correlation_fill",
  "dropped_correlated",
  "dropped_below_cutoff",
  "excluded_user",
  "excluded_incomplete",
  "excluded_zero_variance"
)

#' Construct a metrics_evaluation object
#'
#' Internal constructor. Builds the ranking table by starting from the complete
#' set of input metrics and joining what is known about each one, so a metric
#' cannot be lost: `left_join()` from `all_metrics` keeps every row whatever the
#' joined tables contain.
#'
#' @param all_metrics Character vector. Every metric passed to
#'     \code{\link{evaluate_metrics}}, before any filtering.
#' @param metric_bases Character vector, parallel to `all_metrics`. The
#'     unsuffixed abbreviation for each metric, used to look up its full name.
#' @param ranked tibble. Scored metrics (`metric`, `score`) in rank order.
#' @param outcomes tibble. Selection outcome per scored metric (`metric`,
#'     `outcome`, `correlated_with`).
#' @param excluded tibble. Metrics dropped before ranking (`metric`, `outcome`).
#' @param selected_metrics Character vector. The selected names, in selection
#'     order.
#' @param method Character. Ranking method used.
#' @param params List. Arguments that affect the result.
#'
#' @return A `metrics_evaluation` object.
#' @noRd
new_metrics_evaluation <- function(
  all_metrics,
  metric_bases = all_metrics,
  ranked,
  outcomes,
  excluded,
  selected_metrics,
  method,
  params
) {
  # Each metric leaves the pipeline exactly once, so the outcome sources must be
  # disjoint. Overlapping keys would duplicate rows in the join below.
  all_outcomes <- dplyr::bind_rows(excluded, outcomes)
  if (anyDuplicated(all_outcomes$metric) > 0) {
    duplicated_metrics <- unique(
      all_outcomes$metric[duplicated(all_outcomes$metric)]
    )
    cli::cli_abort(c(
      "Internal error: more than one outcome recorded for {length(duplicated_metrics)} metric{?s}.",
      "x" = "{.val {duplicated_metrics}}"
    ))
  }

  ranking <- tibble::tibble(
    metric = all_metrics,
    name = lookup_metric_names(
      all_metrics,
      metric_bases,
      params$level,
      warn = FALSE
    )
  ) |>
    dplyr::left_join(all_outcomes, by = "metric") |>
    dplyr::left_join(
      dplyr::mutate(ranked, rank = dplyr::row_number()),
      by = "metric"
    ) |>
    dplyr::mutate(
      outcome = factor(outcome, levels = metrics_evaluation_outcomes),
      selected = metric %in% selected_metrics
    ) |>
    dplyr::select(
      metric,
      name,
      score,
      rank,
      selected,
      outcome,
      correlated_with
    ) |>
    dplyr::arrange(rank, outcome, metric)

  # A metric with no outcome means a pipeline step dropped it without recording
  # why, which would make the census silently incomplete.
  if (anyNA(ranking$outcome)) {
    unrecorded <- ranking$metric[is.na(ranking$outcome)]
    cli::cli_abort(c(
      "Internal error: no outcome recorded for {length(unrecorded)} metric{?s}.",
      "x" = "{.val {unrecorded}}"
    ))
  }

  structure(
    list(
      selected = selected_metrics,
      ranking = ranking,
      method = method,
      params = params
    ),
    class = "metrics_evaluation"
  )
}

#' Print a metrics evaluation
#'
#' Summarises which metrics were selected and what happened to the rest. Prints
#' a summary rather than the ranking table itself, which has one row per metric
#' passed in and is usually too long to read in the console; use `x$ranking` to
#' see it.
#'
#' @param x A `metrics_evaluation` object from \code{\link{evaluate_metrics}}.
#' @param ... Ignored, for compatibility with the generic.
#'
#' @return `x`, invisibly.
#' @examples
#' landscapes <- create_landscapes(n = 10, patterns = c("spots", "random"))
#' metrics <- calculate_metrics(landscapes, level = "landscape")
#' evaluate_metrics(metrics, metrics_number = 5)
#' @family metrics
#' @export
print.metrics_evaluation <- function(x, ...) {
  # cat() rather than cli::, so the summary goes to stdout like the package's
  # other print methods; cli writes to the message stream.
  cat(sprintf(
    "Metrics evaluation: %s [%d candidate metrics]\n",
    x$method,
    nrow(x$ranking)
  ))
  cat("-----------------------------------------\n")

  n_selected <- length(x$selected)
  shown <- x$selected[seq_len(min(10, n_selected))]
  cat(sprintf(
    "Selected (%d): %s\n",
    n_selected,
    paste(shown, collapse = ", ")
  ))
  if (n_selected > length(shown)) {
    cat(sprintf("  ... and %d more\n", n_selected - length(shown)))
  }

  outcome_counts <- table(x$ranking$outcome)
  outcome_counts <- outcome_counts[outcome_counts > 0]
  cat("\nOutcomes:\n")
  cat(
    sprintf("  %-26s %d\n", names(outcome_counts), as.integer(outcome_counts)),
    sep = ""
  )

  cat("\nUse $ranking for scores and per-metric outcomes.\n")

  invisible(x)
}

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
#' @param exclude_incomplete_metrics Logical. Whether to exclude metrics with missing values
#'     (default: TRUE). This covers both metrics that are calculated as NA and metrics
#'     that are not available for every landscape. For example, at the class level a metric cannot
#'     be calculated for a class that is absent from a landscape. Keep this enabled if
#'     the data is later used for model training, which requires a complete predictor
#'     matrix.
#' @param exclude_metrics Character vector. Metric abbreviations to exclude, as
#'     they appear in the `metric` column (default: NULL). Use
#'     \code{\link[landscapemetrics]{list_lsm}} to look up what an abbreviation
#'     stands for.
#' @param correlation_threshold Numeric. Maximum allowed absolute Pearson
#'     correlation between selected metrics (default: 0.7). Correlations are
#'     calculated across all landscapes and pattern types. Candidate metrics are
#'     considered in ranking order. A candidate passes the filter only if its
#'     absolute correlation with every already selected metric does not exceed
#'     the threshold. Set to 1 to disable correlation filtering.
#' @param verbose Logical. Whether to print detailed messages on excluded metrics
#'     or just a summary (default: FALSE).
#' @param fill_correlated Logical. If `TRUE` (default), fills any difference
#'     between the number of metrics that pass the correlation filter and the
#'     requested `metrics_number` with the highest-ranked correlated metrics,
#'     and warn. If `FALSE`, returns only uncorrelated metrics,
#'     which then may be fewer than the requested `metric_number`.
#'
#' @section Ranking Methods:
#' \describe{
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
#' @section The ranking table:
#' `ranking` gives an overview of all metrics ranked: one row per metric,
#' whatever happened to it. Columns:
#' \describe{
#'   \item{\code{metric}}{Metric abbreviation, e.g. "ai". For class-level
#'     metrics the class is appended, e.g. "ai_1".}
#'   \item{\code{name}}{Full metric name from
#'     \code{\link[landscapemetrics]{list_lsm}}, e.g. "Aggregation index".
#'     Metrics that summarise per-patch values get the statistic in brackets,
#'     because `list_lsm()` gives the `_cv`/`_mn`/`_sd` triple a single name:
#'     `area_mn` is "Patch area (mean)". For class-level metrics the class is
#'     added too, e.g. "Patch area (mean, class 1)". Falls back to the
#'     abbreviation for metrics `landscapemetrics` does not document.}
#'   \item{\code{score}}{Score from the ranking `method`, or `NA` for metrics
#'     that were excluded before ranking.}
#'   \item{\code{rank}}{Position in the full ranking, best first, or `NA` for
#'     metrics that were excluded before ranking.}
#'   \item{\code{selected}}{Whether the metric is in `selected`.}
#'   \item{\code{outcome}}{Factor recording what happened to the metric, with
#'     levels ordered by pipeline stage: `selected`,
#'     `selected_correlation_fill` (added despite correlation because too few
#'     uncorrelated metrics existed), `dropped_correlated`,
#'     `dropped_below_cutoff` (scored, but ranked below `metrics_number`),
#'     `excluded_user` (via `exclude_metrics`), `excluded_incomplete` (`NA`
#'     values, or absent for some landscapes), and `excluded_zero_variance`.}
#'   \item{\code{correlated_with}}{For the two correlation outcomes, the already
#'     selected metrics the metric clashed with. `NA` otherwise.}
#' }
#'
#' Ties in `score` are broken by metric name, so the ranking is deterministic
#' for given data regardless of its row order.
#'
#' @return An object of class `metrics_evaluation`, a list with elements:
#'   \describe{
#'     \item{\code{selected}}{Character vector. Names of metrics that best
#'       discriminate between pattern types. With `fill_correlated = TRUE`,
#'       metrics added to fill a correlation gap come last rather than at their
#'       rank position. With `fill_correlated = FALSE`, the vector may contain
#'       fewer than `metrics_number` names.}
#'     \item{\code{ranking}}{tibble. One row per metric passed in, with its score
#'       and outcome. See 'The ranking table' below.}
#'     \item{\code{method}}{Character. The ranking method used.}
#'     \item{\code{params}}{List. The arguments that affect the result.}
#'   }
#'   \code{\link{train_metric_model}} and \code{\link{plot_metrics}} accept
#'   this object directly, so it can be passed straight on.
#' @examples
#' # Most suitable metrics to tell spots and random landscapes apart
#' landscapes <- create_landscapes(n = 10, patterns = c("spots", "random"))
#' metrics <- calculate_metrics(
#'   landscapes,
#'   level = "landscape"
#' )
#' evaluation <- evaluate_metrics(
#'   metrics = metrics,
#'   metrics_number = 5
#' )
#'
#' # The selected metric names, to pass on to a model or a plot
#' evaluation$selected
#'
#' # What happened to every candidate metric
#' evaluation$ranking
#' dplyr::count(evaluation$ranking, outcome)
#'
#' @seealso \code{\link{train_metric_model}},
#'   \code{\link[landscapemetrics]{list_lsm}} for the available metrics and
#'   their full names
#' @family metrics
#' @export
evaluate_metrics <- function(
  metrics,
  metrics_number = 10,
  method = "kruskal_effsize",
  exclude_incomplete_metrics = TRUE,
  exclude_metrics = NULL,
  correlation_threshold = 0.7,
  verbose = FALSE,
  fill_correlated = TRUE
) {
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

  # Only single-level metrics are supported (landscape or class)
  level <- unique(metrics$level)
  if (length(level) != 1) {
    cli::cli_abort(c(
      "{.arg metrics} must contain a single {.field level}.",
      "x" = "Found {length(level)} levels: {.val {level}}."
    ))
  }
  if (!level %in% c("landscape", "class")) {
    cli::cli_abort(
      "Currently only metrics at the {.val landscape} or {.val class} level are supported, not {.val {level}}."
    )
  }

  if (!is.numeric(metrics_number) || metrics_number < 1) {
    cli::cli_abort("metrics_number must be a positive integer")
  }

  valid_methods <- c(
    "mean_groups",
    "fisher_score",
    "kruskal_effsize"
  )
  if (!(method %in% valid_methods)) {
    cli::cli_abort(
      "Invalid method. Choose from: {.val {valid_methods}}"
    )
  }

  if (
    !is.numeric(correlation_threshold) ||
      correlation_threshold < 0 ||
      correlation_threshold > 1
  ) {
    cli::cli_abort(
      "correlation_threshold must be a numeric value between 0 and 1"
    )
  }

  if (
    !is.logical(fill_correlated) ||
      length(fill_correlated) != 1 ||
      is.na(fill_correlated)
  ) {
    cli::cli_abort("fill_correlated must be TRUE or FALSE")
  }

  # Track each input metric through the pipeline so none disappear silently
  # The exclusion vectors are populated as metrics leave
  all_metrics <- unique(metrics$metric)
  excluded_user <- character(0)
  excluded_incomplete <- character(0)

  # Class-level metric identifiers include the class id, while metric_name holds
  # the bare abbreviation used to look up full names; at landscape level they
  # are identical, and metric is the fallback when metric_name is absent
  metric_bases <- if ("metric_name" %in% names(metrics)) {
    as.character(metrics$metric_name[match(all_metrics, metrics$metric)])
  } else {
    all_metrics
  }

  # Recorded before `metrics_number` is capped below, so the object reports what
  # was asked for rather than what was achievable
  params <- list(
    metrics_number = metrics_number,
    correlation_threshold = correlation_threshold,
    fill_correlated = fill_correlated,
    exclude_incomplete_metrics = exclude_incomplete_metrics,
    exclude_metrics = exclude_metrics,
    level = level
  )

  if (!is.null(exclude_metrics)) {
    # Record only excluded names that occur in the input
    excluded_user <- intersect(exclude_metrics, all_metrics)
    metrics <- metrics[!metrics$metric %in% exclude_metrics, ]
    if (nrow(metrics) == 0) {
      cli::cli_abort("No metrics left after exclusion")
    }
  }

  # Training requires complete predictors; a metric is incomplete if its value
  # is NA or if some landscapes have no row for it, as when a class is absent
  if (exclude_incomplete_metrics) {
    na_metrics <- metrics |>
      dplyr::filter(is.na(value)) |>
      dplyr::pull(metric) |>
      unique()

    n_landscapes <- dplyr::n_distinct(metrics$landscape_name)
    incomplete_metrics <- metrics |>
      dplyr::summarize(
        n_present = dplyr::n_distinct(landscape_name),
        .by = metric
      ) |>
      dplyr::filter(n_present < n_landscapes) |>
      dplyr::pull(metric) |>
      setdiff(na_metrics)

    excluded_incomplete <- c(na_metrics, incomplete_metrics)
    nrow_before <- nrow(metrics)
    metrics <- metrics[!metrics$metric %in% excluded_incomplete, ]
    nrow_after <- nrow(metrics)

    if (nrow_after == 0) {
      cli::cli_abort(
        "No metrics left after excluding those with missing values"
      )
    }

    if (length(excluded_incomplete) > 0) {
      excluded_message <- c(
        "Excluded {length(excluded_incomplete)} metric{?s} with missing values ({nrow_before - nrow_after} row{?s} removed)."
      )
      if (length(na_metrics) > 0) {
        excluded_message <- c(
          excluded_message,
          "x" = "NA value for at least one landscape: {.val {na_metrics}}"
        )
      }
      if (length(incomplete_metrics) > 0) {
        excluded_message <- c(
          excluded_message,
          "x" = "Not available for all landscapes: {.val {incomplete_metrics}}",
          "i" = "At the class level this happens when a class is absent from a landscape."
        )
      }
      cli::cli_warn(c(
        excluded_message,
        "i" = "Use {.code exclude_incomplete_metrics = FALSE} to retain them (not recommended for model training)."
      ))
    }
  }

  if (length(unique(metrics$pattern)) < 2) {
    cli::cli_abort(
      "At least two different landscape patterns are required for metric evaluation"
    )
  }

  # Use a relative tolerance to exclude metrics whose apparent variation is
  # only floating-point residue, such as variance near 1e-34
  excluded_zero_variance <- metrics |>
    dplyr::summarize(
      sd_value = sd(value, na.rm = TRUE),
      mean_value = mean(value, na.rm = TRUE),
      .by = metric
    ) |>
    dplyr::filter(is_constant_sd(sd_value, mean_value)) |>
    dplyr::pull(metric)

  if (length(excluded_zero_variance) > 0) {
    metrics <- metrics[!metrics$metric %in% excluded_zero_variance, ]
    cli::cli_warn(
      "Excluded {length(excluded_zero_variance)} metric{?s} with no variation across landscapes: {.val {excluded_zero_variance}}"
    )
  }

  ranking_result <- rank_metrics_by_method(
    metrics = metrics,
    method = method
  )
  ranked_metrics <- ranking_result$ranking$metric

  # A ranking method can discard every metric it cannot score; report that here
  # rather than failing later inside the selection helpers
  if (length(ranked_metrics) == 0) {
    cli::cli_abort(c(
      "No metrics could be ranked with {.arg method} = {.val {method}}.",
      "i" = "Try a different ranking {.arg method}."
    ))
  }

  # Cap only after exclusions and ranking so correlation filling sees the true
  # number of available candidates
  num_metrics <- length(ranked_metrics)
  if (num_metrics < metrics_number) {
    cli::cli_warn(
      "Only {num_metrics} metric{?s} available, returning all instead of requested {metrics_number}"
    )
    metrics_number <- num_metrics
  }

  if (verbose) {
    cli::cli_alert_info("Ranked metrics ({method}): {.val {ranked_metrics}}")
  }

  if (correlation_threshold >= 1) {
    # Without correlation filtering, record outcomes here to keep the metric
    # census complete
    available_count <- min(length(ranked_metrics), metrics_number)
    top_metrics <- ranked_metrics[seq_len(available_count)]
    outcomes <- tibble::tibble(
      metric = ranked_metrics,
      outcome = dplyr::if_else(
        seq_along(ranked_metrics) <= available_count,
        "selected",
        "dropped_below_cutoff"
      ),
      correlated_with = NA_character_
    )
  } else {
    correlation_result <- select_metrics_correlation(
      metric_ranking = ranked_metrics,
      metrics = metrics,
      metrics_number = metrics_number,
      correlation_threshold = correlation_threshold,
      verbose = verbose,
      fill_correlated = fill_correlated
    )
    top_metrics <- correlation_result$selected
    outcomes <- correlation_result$outcomes
  }

  # Collect pre-ranking outcomes; bind_rows ignores the absent excluded element
  # from rankers that score every metric
  excluded <- dplyr::bind_rows(
    tibble::tibble(metric = excluded_user, outcome = "excluded_user"),
    tibble::tibble(
      metric = excluded_incomplete,
      outcome = "excluded_incomplete"
    ),
    tibble::tibble(
      metric = excluded_zero_variance,
      outcome = "excluded_zero_variance"
    ),
    ranking_result$excluded
  )

  new_metrics_evaluation(
    all_metrics = all_metrics,
    metric_bases = metric_bases,
    ranked = ranking_result$ranking,
    outcomes = outcomes,
    excluded = excluded,
    selected_metrics = top_metrics,
    method = method,
    params = params
  )
}

#' Resolve Selected Metric Names
#'
#' Internal helper letting functions that need metric names accept either a
#' plain character vector or the object returned by
#' \code{\link{evaluate_metrics}}. Without it, passing that object straight on
#' would fail with a type error about package internals the caller never
#' touched.
#'
#' @param x Character vector, a `metrics_evaluation` object, or NULL.
#'
#' @return Character vector, or NULL if `x` was NULL.
#' @noRd
selected_metric_names <- function(x) {
  if (inherits(x, "metrics_evaluation")) {
    return(x$selected)
  }

  x
}

#' Rank Metrics by Method
#'
#' Internal function that ranks metrics according to different methods.
#'
#' @param metrics tibble. Metrics data.
#' @param method Character. Selection method to use.
#'
#' Every method breaks ties in `score` by metric name. Metrics can be exactly
#' tied and `arrange()` is stable, so without a second key the winner
#' of a tie would be decided by the row order of `metrics`. That order is not
#' stable, which would make
#' the selected metrics change for the same data.
#'
#' @return List with `ranking` (tibble of `metric` and `score`, best first) and,
#'   for methods that can fail to score a metric before ranking, `excluded`
#'   (tibble of `metric` and `outcome`). `bind_rows()` ignores the element for
#'   methods that don't set it.
#' @noRd
rank_metrics_by_method <- function(metrics, method) {
  switch(
    method,
    mean_groups = rank_by_mean_differences(metrics),
    fisher_score = rank_by_fisher_score(metrics),
    kruskal_effsize = rank_by_kruskal(metrics),
    cli::cli_abort("Unknown ranking method: {.val {method}}")
  )
}

#' Rank by Mean Differences
#'
#' Ranks metrics by their ability to differentiate between landscape types
#' based on the differences in means across patterns.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return List with `ranking` (metrics by importance score, highest first).
#' @noRd
rank_by_mean_differences <- function(metrics) {
  # Calculate overall mean for each metric
  means_all <- metrics |>
    dplyr::summarize(
      mean_all = mean(value, na.rm = TRUE),
      .by = metric
    )

  # Calculate pattern-specific means and importance scores
  ranking <- metrics |>
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
      score = sum(rel_mean_diff, na.rm = TRUE),
      .by = metric
    ) |>
    dplyr::arrange(dplyr::desc(score), metric)

  list(ranking = ranking)
}

#' Rank by Fisher Score
#'
#' Ranks metrics by Fisher score (ratio of between-group to within-group variance).
#' Higher scores indicate better separation between pattern types.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return List with `ranking` (metrics by Fisher score, highest first).
#' @noRd
rank_by_fisher_score <- function(metrics) {
  ranking <- metrics |>
    tidyr::nest(.by = metric) |>
    dplyr::mutate(
      score = purrr::map_dbl(data, \(df) {
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
        within_ss <- (group_stats$n - 1) * (group_stats$sd_val^2)
        within_ss[group_stats$n == 1] <- 0
        within_var <- sum(within_ss) /
          (sum(group_stats$n) - nrow(group_stats))

        return(between_var / within_var)
      })
    ) |>
    dplyr::arrange(dplyr::desc(score), metric) |>
    dplyr::select(metric, score)

  list(ranking = ranking)
}

#' Rank by Kruskal-Wallis H test
#'
#' Ranks metrics using Kruskal-Wallis H test effect sizes.
#' Higher effect sizes indicate better discrimination between pattern types.
#' More robust to non-normality than Fisher score.
#'
#' @param metrics tibble. Metrics data with columns 'metric', 'pattern', and 'value'.
#'
#' @return List with `ranking` (metrics by effect size, largest first).
#' @noRd
rank_by_kruskal <- function(metrics) {
  ranking <- metrics |>
    tidyr::nest(.by = metric) |>
    dplyr::mutate(
      score = purrr::map_dbl(data, \(df) {
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
    dplyr::arrange(dplyr::desc(score), metric) |>
    dplyr::select(metric, score)

  list(ranking = ranking)
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
#' @param correlation_threshold Numeric. Maximum allowed absolute Pearson
#'   correlation between selected metrics (default: 0.7).
#' @param verbose Logical. Whether to print progress messages (default: FALSE).
#' @param fill_correlated Logical. Whether to fill a shortfall with correlated
#'   metrics or return only those that pass the correlation filter.
#'
#' @return List with `selected` (character vector of selected metric names, in
#'   selection order) and `outcomes` (tibble with one row per ranked metric,
#'   columns `metric`, `outcome` and `correlated_with`).
#' @noRd
select_metrics_correlation <- function(
  metric_ranking,
  metrics,
  metrics_number,
  correlation_threshold = 0.7,
  verbose = FALSE,
  fill_correlated = TRUE
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

  # Initialize results. Every ranked metric ends up with an outcome. Metrics the
  # loop never reaches keep the default, as do metrics missing from the
  # correlation matrix, which cannot happen for data coming from the ranker.
  top_metrics <- character(0)
  outcome <- rep("dropped_below_cutoff", length(metric_ranking))
  clashes <- rep(NA_character_, length(metric_ranking))
  names(outcome) <- metric_ranking
  names(clashes) <- metric_ranking

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
        outcome[current_metric] <- "dropped_correlated"
        clashes[current_metric] <- paste(
          top_metrics[high_correlations],
          collapse = ", "
        )

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
    outcome[current_metric] <- "selected"

    if (verbose) {
      cli::cli_alert_info("Selected metrics so far: {.val {top_metrics}}")
    }
  }

  if (length(top_metrics) < metrics_number) {
    n_uncorrelated <- length(top_metrics)

    if (fill_correlated) {
      additional_metrics <- setdiff(metric_ranking, top_metrics)
      needed_count <- min(
        length(additional_metrics),
        metrics_number - length(top_metrics)
      )
      filled <- additional_metrics[seq_len(needed_count)]
      outcome[filled] <- "selected_correlation_fill"

      # Appended, so gap-filled metrics land at the end of the selection rather
      # than at their position in the ranking. `selected` therefore preserves
      # the order callers have always seen, which is not the ranking order.
      top_metrics <- c(top_metrics, filled)

      cli::cli_warn(c(
        "Only {n_uncorrelated} uncorrelated metric{?s} found. Filling to {metrics_number} with correlated metrics.",
        "i" = "Added: {.val {filled}}"
      ))
    } else {
      cli::cli_warn(
        "Only {n_uncorrelated} uncorrelated metric{?s} found; returning {n_uncorrelated} because {.arg fill_correlated} is {.code FALSE}."
      )
    }
  }

  list(
    selected = top_metrics,
    outcomes = tibble::tibble(
      metric = metric_ranking,
      outcome = unname(outcome),
      correlated_with = unname(clashes)
    )
  )
}
