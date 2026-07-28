library(tidyverse)
devtools::load_all()

set.seed(1)
n <- 40

# Group means 101, 102, 103. The offset keeps every value positive, like real
# landscape metrics, so the problem below cannot be blamed on negative values.
group_mean <- rep(c(1, 2, 3), each = n) + 100

# Two metrics with the SAME group means. They differ only in noise.
metrics <- tibble(
  landscape_name = sprintf("ls%03d", 1:(3 * n)),
  pattern = rep(c("A", "B", "C"), each = n),
  level = "landscape",
  tight = rnorm(3 * n, group_mean, sd = 0.1),
  noisy = rnorm(3 * n, group_mean, sd = 5)
) |>
  pivot_longer(c(tight, noisy), names_to = "metric")

min(metrics$value) # all positive

# Only `tight` separates the three patterns
ggplot(metrics, aes(pattern, value)) +
  geom_boxplot() +
  facet_wrap(~metric, scales = "free_y") +
  theme_minimal()

# Which metric does each method consider best?
evaluate_metrics(metrics, metrics_number = 1, method = "mean_groups")
evaluate_metrics(metrics, metrics_number = 1, method = "kruskal_effsize")

# The formula ------------------------------------------------------------------

# mean_groups scores a metric as
#   sum over patterns of  |group_mean - overall_mean| / overall_mean
# The spread within a pattern never appears in it.

# In theory both metrics score exactly the same, because both have group means
# 101, 102, 103 and an overall mean of 102. Only the group means enter, so the
# answer is the same no matter how much the values scatter:
sum(abs(c(101, 102, 103) - 102) / 102)

# The same formula on the actual data, one row per pattern
overall <- metrics |>
  summarise(overall_mean = mean(value), .by = metric)

contributions <- metrics |>
  summarise(group_mean = mean(value), .by = c(metric, pattern)) |>
  left_join(overall, by = "metric") |>
  mutate(contribution = abs(group_mean - overall_mean) / overall_mean)

# Pattern B sits at the overall mean, so it should contribute 0. It does for
# `tight`. For `noisy` the estimated group means are far off, and every wobble
# adds to the score because of the abs() - errors inflate it, never cancel.
contributions |> arrange(metric, pattern)

# Summing the contributions gives the score that decides the ranking
contributions |>
  summarise(score = sum(contribution), .by = metric)

# Not a lucky seed --------------------------------------------------------------

pick_best_metric <- function(seed) {
  set.seed(seed)
  tibble(
    landscape_name = sprintf("ls%03d", 1:(3 * n)),
    pattern = rep(c("A", "B", "C"), each = n),
    level = "landscape",
    tight = rnorm(3 * n, group_mean, sd = 0.1),
    noisy = rnorm(3 * n, group_mean, sd = 5)
  ) |>
    pivot_longer(c(tight, noisy), names_to = "metric") |>
    evaluate_metrics(metrics_number = 1, method = "mean_groups")
}

map_chr(1:100, pick_best_metric) |> table()

# The sign of the values is irrelevant -----------------------------------------

# The bias sits in the numerator: abs() turns every estimation error into a
# positive contribution, so noise can only inflate the sum. The denominator is
# the same for both metrics and cancels out of the comparison. Shifting the
# whole scale changes the size of the scores but not the ranking.

compare_offsets <- function(offset) {
  picks <- map_chr(1:100, \(seed) {
    set.seed(seed)
    tibble(
      landscape_name = sprintf("ls%03d", 1:(3 * n)),
      pattern = rep(c("A", "B", "C"), each = n),
      level = "landscape",
      tight = rnorm(3 * n, rep(c(1, 2, 3), each = n) + offset, sd = 0.1),
      noisy = rnorm(3 * n, rep(c(1, 2, 3), each = n) + offset, sd = 5)
    ) |>
      pivot_longer(c(tight, noisy), names_to = "metric") |>
      evaluate_metrics(metrics_number = 1, method = "mean_groups")
  })
  tibble(
    offset = offset,
    noisy_ranked_first = sum(picks == "noisy"),
    tight_ranked_first = sum(picks == "tight")
  )
}

map(c(0, 100, 1000), compare_offsets) |> list_rbind()
