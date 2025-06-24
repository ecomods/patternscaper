#' Evaluate Landscape Metrics
#'
#' Identifies the most informative metrics for discriminating between landscape types.
#'
#' @param calculated_metrics tibble. Metrics from calculate_landscape_metrics().
#' @param metrics_number Integer. Number of top metrics to return (default: 10).
#' @param method Character. Selection method (options: "coeffvar_all", "linmod", "lin_mod_r2", "mean_groups") (default: "coeffvar_all").
#' @param plot Logical. Whether to generate visualization (default: FALSE).
#' @param exclude_metrics Character vector. Metrics to exclude (default: NULL).
#'
#' @return Character vector. Names of most sensitive metrics.
#' @export
evaluate_landscape_metrics <- function(
  calculated_metrics,
  metrics_number = 10,
  method = "coeffvar_all",
  plot = FALSE,
  exclude_metrics = NULL
) {
  #metrics list not used yet
  top_metrics <- NA

  #number of metrics
  metrics_names <- unique(calculated_metrics$metric)
  num_metrics <- length(metrics_names)
  #number of landscape types
  num_types <- length(unique(calculated_metrics$type))

  #calculate coefficient of variation for each metric
  #once for each landscape separate, and once jointly
  means_types <- data.frame(tapply(
    calculated_metrics$value,
    list(
      as.factor(calculated_metrics$metric),
      as.factor(calculated_metrics$type)
    ),
    mean,
    na.rm = T
  ))
  means_types$all <- tapply(
    calculated_metrics$value,
    as.factor(calculated_metrics$metric),
    mean,
    na.rm = T
  )
  sd_types <- data.frame(tapply(
    calculated_metrics$value,
    list(
      as.factor(calculated_metrics$metric),
      as.factor(calculated_metrics$type)
    ),
    sd,
    na.rm = T
  ))
  sd_types$all <- tapply(
    calculated_metrics$value,
    as.factor(calculated_metrics$metric),
    sd,
    na.rm = T
  )

  #--------------------------------------------------------------------------------------------
  #coefficient of variation for all data
  #however, we do not now, if this comes from a high variation across landscape types or
  #across landscapes in general (e.g. within fingers)
  #--------------------------------------------------------------------------------------------
  if (method == "coeffvar_all") {
    ranking <- rank(sd_types$all / means_types$all, na.last = FALSE)
    top_metrics <- metrics_names[ranking > (num_metrics - metrics_number)] #take only top x
  }

  #--------------------------------------------------------------------------------------------
  #for which metrics do the landscape types significantly differ from each other
  #(with linear model using the smallest p-value)
  #--------------------------------------------------------------------------------------------
  if (method == "lin_mod_p") {
    means_types$p <- NA
    for (i in 1:num_metrics) {
      dat <- calculated_metrics[calculated_metrics$metric == metrics_names[i], ]
      if (!is.na(dat$value[i])) {
        model <- lm(data = dat, value ~ type)
        means_types$p[i] <- anova(model)$`Pr(>F)`[1]
      }
    }
    #ranking of the smallest p-values
    ranking <- rank(means_types$p, na.last = TRUE)
    top_metrics <- metrics_names[ranking <= metrics_number] #take only top x
  }

  #--------------------------------------------------------------------------------------------
  #for which metrics do the landscape types significantly differ from each other
  #(with linear model using the smallest p-value)
  #--------------------------------------------------------------------------------------------
  if (method == "lin_mod_r2") {
    means_types$r2 <- NA
    for (i in 1:num_metrics) {
      dat <- calculated_metrics[calculated_metrics$metric == metrics_names[i], ]
      if (!is.na(dat$value[i])) {
        model <- lm(data = dat, value ~ type)
        means_types$r2[i] <- summary(model)$r.squared
      }
    }
    #ranking of the smallest p-values
    ranking <- rank(means_types$r2, na.last = FALSE)
    top_metrics <- metrics_names[ranking > (num_metrics - metrics_number)] #take only top x
  }

  #--------------------------------------------------------------------------------------------
  #how strongly do the means vary from the overall mean
  #take four metrics for each landscape types (problem number does not match metrics_number)
  #--------------------------------------------------------------------------------------------
  if (method == "mean_groups") {
    rel_mean_diff <- (means_types[, 1:num_types] - means_types$all) /
      means_types$all

    #for each type, take the two lowest and highest differences from mean
    #problem: sometimes, indices have the same ranking, here I randomly take a sample of two
    mymetrics <- array(data = NA, dim = 4 * num_types)
    for (t in 1:num_types) {
      ranking <- as.integer(rank(rel_mean_diff[, t], na.last = TRUE))
      mymetrics[(t * 4 - 3):(t * 4 - 2)] <- sample(
        metrics_names[ranking <= 2],
        2
      )
      ranking <- as.integer(rank(rel_mean_diff[, t], na.last = FALSE))
      mymetrics[(t * 4 - 1):(t * 4)] <- sample(metrics_names[
        ranking > (num_metrics - 2)
      ])
    }
    top_metrics <- sort(unique(mymetrics))
  }

  # Plot classification results if requested
  if (plot) {
    plot_classification_results()
  }

  return(top_metrics)
}
