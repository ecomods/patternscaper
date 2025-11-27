devtools::load_all()
library(tidyverse)
library(landscapemetrics)

training_landscapes <- create_training_landscapes(
  n = 500,
  add_rotation = TRUE
)

# Example of one landscape by class
lsm_c_enn_sd(training_landscapes[[3]]$data)

# calculate metrics at the class level
landscape_class_metrics <- calculate_landscape_metrics(
  landscapes = training_landscapes,
  metrics = "ai",
  level = "class"
)

landscape_class_metrics <- read_csv("inst/extdata/landscape_class_metrics.csv")

# readr::write_csv(
#   landscape_class_metrics,
#   file = "inst/extdata/landscape_class_metrics.csv"
# )

# Add a metric_unique column
landscape_class_metrics <- landscape_class_metrics |>
  mutate(
    metric_unique = paste0(metric, "_class", class)
  )

# Remove all from the value column
landscape_class_metrics <- landscape_class_metrics |>
  drop_na(value)


corr_0_1 <- landscape_class_metrics |>
  select(
    landscape_id,
    class,
    metric,
    value,
    pattern
  ) |>
  pivot_wider(names_from = class, values_from = value) |>
  select(-landscape_id, -metric) |>
  group_by(pattern) |>
  nest() |>
  mutate(
    cor_matrix = map(data, ~ cor(.x, use = "pairwise.complete.obs"))
  ) |>
  mutate(
    corr_plot = list(ggcorrplot::ggcorrplot(
      cor_matrix[[1]],
      lab = TRUE,
      title = pattern
    ))
  )

corr_plot_list <- corr_0_1$corr_plot

patchwork::wrap_plots(corr_plot_list) +
  patchwork::plot_layout(guides = "collect") &
  scale_x_continuous(breaks = c(0, 1)) &
  scale_y_continuous(breaks = c(0, 1))

corr_scatter <- landscape_class_metrics |>
  select(
    landscape_id,
    class,
    metric,
    value,
    pattern
  ) |>
  pivot_wider(names_from = class, values_from = value, names_prefix = "c")

ggplot(corr_scatter, aes(x = c0, y = c1, color = pattern)) +
  geom_point(size = .3) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.5) +
  scale_color_viridis_d(option = 1) +
  facet_wrap(~metric, scales = "free") +
  theme_bw() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid.minor = element_blank()
  )


correlation_summary <- corr_scatter |>
  group_by(pattern, metric) |>
  summarize(
    correlation = cor(c0, c1, use = "pairwise.complete.obs"),
    n_obs = sum(!is.na(c0) & !is.na(c1)),
    .groups = "drop"
  ) |>
  arrange(desc(abs(correlation)))


ggplot(
  correlation_summary,
  aes(x = metric, y = abs(correlation), fill = pattern)
) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 0.7, linetype = "dashed", color = "red") +
  coord_flip() +
  labs(
    title = "Correlation (absolute values) between Class 0 and Class 1 metrics",
    subtitle = "Dashed lines indicate ±0.7 corr threshold",
    x = "Metric",
    y = "Correlation (Pearson's r)"
  ) +
  facet_wrap(~pattern, nrow = 1) +
  scale_y_continuous(breaks = c(0, 0.5, 1)) +
  scale_fill_viridis_d(option = 1) +
  theme_bw() +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank()
  )
