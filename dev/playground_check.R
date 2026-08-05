# Title: Problems of the ranking methods in evaluate_metrics()
# Date: 2026-07-28
# Author: Selina Baldauf
# Purpose: Demonstrate the failure modes of the three ranking methods offered by
#   evaluate_metrics(). Input for the manuscript revision and discussion.
#   (lin_mod_r2 removed 2026-08-04: proved identical to fisher_score.
#   coeffvar_all removed 2026-08-04 along with its ratio-scale guard; see
#   dev/evaluate_metrics_problems.qmd.)

devtools::load_all()
library(tidyverse)

# Helpers ---------------------------------------------------------------------

all_methods <- c(
  "mean_groups",
  "fisher_score",
  "kruskal_effsize"
)

# Full ranking for one method. The correlation filter is switched off so that
# nothing is dropped and we see the ranking itself. Warnings are suppressed only
# to keep the comparison output readable.
rank_metrics <- function(metrics, method, ...) {
  suppressWarnings(
    evaluate_metrics(
      metrics,
      method = method,
      metrics_number = n_distinct(metrics$metric),
      correlation_threshold = 1,
      ...
    )
  )
}

# Rankings of all three methods side by side
rank_all_methods <- function(metrics) {
  map(set_names(all_methods), \(method) rank_metrics(metrics, method))
}

# Synthetic metrics in the shape calculate_metrics() returns, so that we can
# build data with known properties
make_metrics <- function(..., n_per = 40, patterns = c("A", "B", "C")) {
  tibble(
    landscape_name = sprintf("ls%03d", seq_len(n_per * length(patterns))),
    pattern = rep(patterns, each = n_per)
  ) |>
    bind_cols(as_tibble(list(...))) |>
    pivot_longer(-c(landscape_name, pattern), names_to = "metric") |>
    mutate(level = "landscape")
}

# Fisher score exactly as rank_by_fisher_score() computes it
fisher_score_manual <- function(data) {
  overall_mean <- mean(data$value)
  groups <- data |>
    summarise(
      n = n(),
      mean_val = mean(value),
      sd_val = sd(value),
      .by = pattern
    )
  between_var <- sum(groups$n * (groups$mean_val - overall_mean)^2) /
    (nrow(groups) - 1)
  within_var <- sum((groups$n - 1) * groups$sd_val^2) /
    (sum(groups$n) - nrow(groups))
  between_var / within_var
}

# Test data -------------------------------------------------------------------

# Every demonstration below also works with n = 66 (6 per pattern), which is a
# lot faster if you just want to re-run the checks
set.seed(123)
landscapes <- create_landscapes(n = 200)
metrics <- calculate_metrics(landscapes)

# Visual comparison of what the different methods select
fischer <- evaluate_metrics(
  metrics,
  method = "fisher_score",
  metrics_number = 20
)

plot_metrics(metrics, fischer, force = TRUE) +
  ggtitle("Metrics selected by Fisher score")

# 3 coeffvar_all broke on metrics that cross zero (method removed 2026-08-04) --

# pafrac = 2 / slope of log(area) ~ log(perimeter). With few patches the slope
# is badly estimated and can be near zero (pafrac explodes) or negative
# (pafrac becomes negative), although its theoretical range is [1, 2]. CV =
# sd / mean is meaningless once the mean sits near zero, which is what made
# coeffvar_all rank pafrac first on some real data purely as a numerical
# artefact. A ratio-scale guard was added to exclude such metrics (see
# CHANGELOG 2026-07-30); the method itself was removed 2026-08-04. Full
# demonstration and evidence: dev/evaluate_metrics_problems.qmd.

# 4 mean_groups ignores the within-group spread --------------------------------

# Three metrics with identical group means (1, 2, 3) but very different noise.
# Only the tight one separates the patterns, yet mean_groups sees the same
# relative mean differences in all three and ranks essentially at random.

set.seed(1)
n_per <- 40
metrics_spread <- make_metrics(
  tight = c(
    rnorm(n_per, 1, 0.05),
    rnorm(n_per, 2, 0.05),
    rnorm(n_per, 3, 0.05)
  ),
  medium = c(rnorm(n_per, 1, 1), rnorm(n_per, 2, 1), rnorm(n_per, 3, 1)),
  noisy = c(rnorm(n_per, 1, 8), rnorm(n_per, 2, 8), rnorm(n_per, 3, 8)),
  n_per = n_per
)


ggplot(metrics_spread, aes(x = pattern, y = value)) +
  geom_boxplot() +
  facet_wrap(~metric, scales = "free_y") +
  ggtitle("Metrics with identical group means but different noise")

rank_all_methods(metrics_spread)

### All three scores are around 1 and differ only through sampling noise in the
### group means, so which one comes first is arbitrary
metrics_spread |>
  summarise(mean_all = mean(value), .by = metric) |>
  left_join(
    metrics_spread |>
      summarise(mean_type = mean(value), .by = c(metric, pattern)),
    by = "metric"
  ) |>
  summarise(
    importance_score = sum(abs((mean_type - mean_all) / mean_all)),
    .by = metric
  )

# 5 a single outlier destroys the moment-based rankings ------------------------

# One extreme value in the best metric. fisher_score demotes it from first to
# last; kruskal_effsize is unaffected because it only sees ranks.

metrics_outlier <- metrics_spread |>
  mutate(
    value = if_else(metric == "tight" & landscape_name == "ls001", 500, value)
  )

ggplot(metrics_outlier, aes(x = pattern, y = value)) +
  geom_boxplot() +
  facet_wrap(~metric, scales = "free_y") +
  ggtitle("Metrics with identical group means but different noise")

rank_all_methods(metrics_outlier)

# 6 mean_groups explodes when the overall mean is near zero --------------------

# rel_mean_diff divides by the overall mean. A metric centred on zero gets a huge
# score even though it is pure noise, and mean_groups ranks it above a
# genuinely informative metric.

set.seed(2)
metrics_zero <- make_metrics(
  informative = c(
    rnorm(n_per, 1, 0.2),
    rnorm(n_per, 2, 0.2),
    rnorm(n_per, 3, 0.2)
  ),
  noise_at_zero = c(
    rnorm(n_per, -0.01, 1),
    rnorm(n_per, 0, 1),
    rnorm(n_per, 0.01, 1)
  ),
  n_per = n_per
)

ggplot(metrics_zero, aes(x = pattern, y = value)) +
  geom_boxplot() +
  facet_wrap(~metric, scales = "free_y") +
  ggtitle("Metrics with identical group means but different noise")

rank_all_methods(metrics_zero)

# 7 the correlation filter pools all pattern types -----------------------------

# Two metrics that are independent within every pattern, but both shift with
# pattern. Pooled across patterns they look almost perfectly correlated, so the
# filter discards one although it carries independent information.

set.seed(3)
pattern_shift <- rep(c(0, 5, 10), each = n_per)
metrics_pooled <- make_metrics(
  shifted_a = pattern_shift + rnorm(3 * n_per),
  shifted_b = pattern_shift + rnorm(3 * n_per),
  independent = rnorm(3 * n_per),
  n_per = n_per
)

metrics_wide <- metrics_pooled |>
  pivot_wider(names_from = metric, values_from = value)

# overall correlation
cor(metrics_wide$shifted_a, metrics_wide$shifted_b)
# within-pattern correlation
metrics_wide |> summarise(within_cor = cor(shifted_a, shifted_b), .by = pattern)

ggplot(metrics_pooled, aes(x = pattern, y = value)) +
  geom_boxplot() +
  facet_wrap(~metric, scales = "free_y") +
  ggtitle("Metrics that are independent within patterns but correlated across")


### shifted_b is dropped although it is uncorrelated with shifted_a within patterns
evaluate_metrics(metrics_pooled, metrics_number = 2)

# 8 correlated metrics are silently added to fill the requested number ---------

# Four mutually correlated metrics, three requested. Only one survives the
# filter, so two correlated ones are appended. They land at the END of the
# returned vector, which is the only way to tell which ones they were.

set.seed(4)
base_signal <- pattern_shift + rnorm(3 * n_per)
metrics_correlated <- make_metrics(
  m1 = base_signal + rnorm(3 * n_per, 0, 0.1),
  m2 = base_signal + rnorm(3 * n_per, 0, 0.1),
  m3 = base_signal + rnorm(3 * n_per, 0, 0.1),
  m4 = base_signal + rnorm(3 * n_per, 0, 0.1),
  n_per = n_per
)

evaluate_metrics(metrics_correlated, metrics_number = 3)
