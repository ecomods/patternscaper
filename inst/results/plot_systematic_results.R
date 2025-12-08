library(tidyverse)
library(patchwork)

# input_file <- "inst/analyses/selforga_results_class/Results/systematic_test_neuralnet_selforg_results.rds"
# output_dir <- "inst/analyses/selforga_results_class/Figs/Selina"

input_file <- "inst/analyses/ecotone_results_landscape/Results/systematic_test_neuralnet_ecotone_results.rds"
output_dir <- "inst/analyses/ecotone_results_landscape/Figs/Selina"


ecotone_results <- read_rds(
  input_file
)

extract_meta_information <- function(list_entry) {
  tibble(
    training_size = list_entry$training_size,
    layers = length(list_entry$layers),
    metric = list_entry$metric,
    neurons = list_entry$layers[1],
    inputmetrics = list_entry$inputmetrics,
    replicate = list_entry$replicate
  )
}

# Data frame with:
extract_validation_results <- function(list_entry) {
  tryCatch(
    {
      # Check if validation structure exists
      if (
        is.null(list_entry$validation) ||
          is.null(list_entry$validation$performance) ||
          is.null(list_entry$validation$performance$per_class_metrics)
      ) {
        return(tibble(
          accuracy = NA_real_,
          acc_best = NA_real_,
          acc_worst = NA_real_,
          best_class = NA_character_,
          worst_class = NA_character_
        ))
      }

      per_class <- list_entry$validation$performance$per_class_metrics

      best_val <- max(per_class$precision, na.rm = TRUE)
      worst_val <- min(per_class$precision, na.rm = TRUE)

      best_classes <- per_class$class[per_class$precision == best_val]
      worst_classes <- per_class$class[per_class$precision == worst_val]

      best_class <- if (length(best_classes) > 1) {
        sample(best_classes, 1)
      } else {
        best_classes
      }

      worst_class <- if (length(worst_classes) > 1) {
        sample(worst_classes, 1)
      } else {
        worst_classes
      }

      tibble(
        accuracy = list_entry$validation$performance$accuracy,
        acc_best = best_val,
        acc_worst = worst_val,
        best_class = best_class,
        worst_class = worst_class
      )
    },
    error = function(e) {
      tibble(
        accuracy = NA_real_,
        acc_best = NA_real_,
        acc_worst = NA_real_,
        best_class = NA_character_,
        worst_class = NA_character_
      )
    }
  )
}

df_raw <- map_dfr(
  ecotone_results,
  ~ bind_cols(
    extract_meta_information(.x),
    extract_validation_results(.x)
  )
)

# Summarize the data
df_summary <- df_raw |>
  group_by(training_size, layers, metric, inputmetrics, neurons) |>
  summarise(
    mean_accuracy = mean(accuracy, na.rm = TRUE),
    sd_accuracy = sd(accuracy, na.rm = TRUE),
    n_repl = sum(!is.na(accuracy)),
    .groups = "drop"
  )

custom_colors <- c(
  "low" = "red",
  "mid1" = "orange",
  "mid2" = "yellow",
  "high1" = "#99ccff",
  "high2" = "#001f3f"
)

#ranges of data
z_limits_mean_acc <- range(df_summary$mean_accuracy, na.rm = TRUE)
col_boundaries <- c(
  min(z_limits_mean_acc),
  (min(z_limits_mean_acc) + (0.8 - min(z_limits_mean_acc)) / 3),
  (min(z_limits_mean_acc) + 2 * (0.8 - min(z_limits_mean_acc)) / 3),
  0.8,
  max(z_limits_mean_acc)
)

# Plot accuracy ---------------------------------------------------------------
p_accuracy <- ggplot(
  df_summary,
  aes(x = neurons, y = training_size, fill = mean_accuracy)
) +
  geom_tile() +
  facet_grid(
    metric ~ inputmetrics,
    scales = "free",
    labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
  ) +
  scale_fill_gradientn(
    colours = custom_colors
    #values = scales::rescale(col_boundaries),
    #limits = z_limits_mean_acc
  ) +
  labs(
    x = "Number of neurons",
    y = "Size of training data",
    fill = "Mean accuracy"
  ) +
  theme_minimal(base_size = 13)

# Plot standard deviation ------------------------------------------------------

z_limits_sd_acc <- range(df_summary$sd_accuracy, na.rm = TRUE)

df_plot <- df_summary %>%
  group_by(inputmetrics) %>%
  mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
  ungroup()

p_sd_accuracy <- ggplot(
  df_plot,
  aes(x = neurons, y = training_size, fill = sd_accuracy)
) +
  geom_tile() +
  facet_grid(
    metric ~ inputmetrics,
    scales = "free_x",
    labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
  ) +
  scale_fill_viridis_c(limits = z_limits_sd_acc, direction = -1) +
  labs(
    x = "Number of neurons",
    y = "Size of training data",
    fill = "Sd of accuracy",
  ) +
  theme_minimal(base_size = 13)

# Number of successful runs ----------------------------------------------------
n_repl <- max(df_raw$replicate)
z_limits_n_repl <- c(0, n_repl)

df_plot <- df_summary %>%
  group_by(inputmetrics) %>%
  mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
  ungroup()

p_n_success <- ggplot(
  df_plot,
  aes(x = neurons, y = training_size, fill = n_repl)
) +
  geom_tile() +
  facet_grid(
    metric ~ inputmetrics,
    scales = "free_x",
    labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
  ) +
  scale_fill_gradientn(
    colours = colorRampPalette(
      c("#f0f8ff", "#c6dbef", "#6baed6", "#2171b5", "#001f3f")
    )(n_repl + 1),
    limits = z_limits_n_repl,
    breaks = seq(z_limits_n_repl[1], z_limits_n_repl[2], by = 2)
  ) +
  labs(
    x = "Number of neurons",
    y = "Size of training data",
    fill = "Successful Runs"
  ) +
  theme_minimal(base_size = 13)

# Accuracy of worst class -------------------------------------------------------
#which is worst class (random if several)
mode_random <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA)
  }
  tab <- table(x)
  max_freq <- max(tab)
  candidates <- names(tab)[tab == max_freq]
  sample(candidates, 1)
}

# how save is this across replicates
entropy <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) <= 1) {
    return(0)
  }
  tab <- table(x) / length(x)
  -sum(tab * log2(tab))
}

#summarize in new data frame
df_worst_summary <- df_raw %>%
  group_by(training_size, layers, metric, inputmetrics, neurons) %>%
  summarise(
    most_common_worst = mode_random(worst_class),
    entropy_worst = entropy(worst_class),
    mean_acc_worst = mean(acc_worst, na.rm = TRUE), # hier die mittlere Accuracy
    .groups = "drop"
  )

# colours for classes (colour-blind friendly)
class_colors <- c(
  "fingers" = "#000000",
  "sharp" = "#E69F00",
  "diffuse" = "#56B4E9",
  "clustered" = "#009E73",
  "bands" = "#F0E442",
  "random" = "#CC79A7",
  # For self organized
  "bare" = "#E69F00",
  "spots" = "#CC79A7",
  "labyrinth" = "#009E73",
  "gaps" = "#56B4E9",
  "dense" = "#000000"
)

df_plot <- df_worst_summary %>%
  mutate(
    neurons = factor(neurons, levels = sort(unique(neurons))),
    # Entropie normalisieren: 0 = klare Aussage, 1 = komplettes Chaos
    entropy_norm = entropy_worst / max(entropy_worst, na.rm = TRUE),
    alpha_val = 1 - entropy_norm
  )

p_worst_class <- ggplot(
  df_plot,
  aes(
    x = neurons,
    y = training_size,
    fill = most_common_worst,
    alpha = alpha_val
  )
) +
  geom_tile(color = "white") +
  facet_grid(
    metric ~ inputmetrics,
    scales = "free_x",
    labeller = labeller(
      inputmetrics = function(x) paste0("Inputs = ", x)
    )
  ) +
  scale_fill_manual(
    values = class_colors,
    na.value = "grey90",
    drop = FALSE
  ) +
  scale_alpha(range = c(0.3, 1), guide = "none") +
  labs(
    x = "Number of neurons",
    y = "Size of training data",
    fill = "Worst class (mode)",
    caption = "Transparency indicates entropy (consistency) across replicates"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    strip.text.x = element_text(face = "bold"),
    strip.text.y = element_text(face = "bold"),
    plot.title = element_text(size = 15, face = "bold")
  )

# Accuracy of worst classes - mean accuracy ----------------------------------

df_plot <- df_worst_summary %>%
  group_by(inputmetrics) %>%
  mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
  ungroup()

p_mean_acc_worst <- ggplot(
  df_plot,
  aes(x = neurons, y = training_size, fill = mean_acc_worst)
) +
  geom_tile() +
  facet_grid(
    metric ~ inputmetrics,
    scales = "free_x",
    labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
  ) +
  scale_fill_gradientn(
    colours = colorRampPalette(
      c("#f0f8ff", "#c6dbef", "#6baed6", "#2171b5", "#001f3f")
    )(11),
    limits = c(0, 1),
    breaks = seq(0, 1, by = 0.2)
  ) +
  labs(
    x = "Number of neurons",
    y = "Size of training data",
    fill = "Mean worst accuracy"
  ) +
  theme_minimal(base_size = 13)

# Save all plots ------------------------------------------------------------

ggsave(
  filename = file.path(output_dir, "p_accuracy.png"),
  plot = p_accuracy,
  width = 10,
  height = 8
)

ggsave(
  filename = file.path(output_dir, "p_sd_accuracy.png"),
  plot = p_sd_accuracy,
  width = 10,
  height = 8
)

ggsave(
  filename = file.path(output_dir, "p_n_success.png"),
  plot = p_n_success,
  width = 10,
  height = 8
)

ggsave(
  filename = file.path(output_dir, "p_mean_acc_worst.png"),
  plot = p_mean_acc_worst,
  width = 10,
  height = 8
)
ggsave(
  filename = file.path(output_dir, "p_worst_class.png"),
  plot = p_worst_class,
  width = 10,
  height = 8
)
