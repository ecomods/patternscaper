library(tidyverse)


keras_all_systematic_plots <- function(result_path, output_dir) {
  # load functions to extract results in the right format and make the plots
  source(here::here("inst/analyses/functions/plot_systematic_tests.R"))
  source(here::here("inst/analyses/functions/plot_theme.R"))

  all_results <- read_rds(result_path)

  # Prepare the data ---------------------------------------------------------
  # Extract all info from the list and put it in a single table

  df_raw <- map_dfr(all_results, combine_validation_results)

  # Plot accuracy
  df_summary <- df_raw |>
    summarize(
      mean_accuracy = mean(validation_accuracy),
      sd_accuracy = sd(validation_accuracy),
      .by = c(n_landscapes, epochs, learning_rate, batch_size, dropout_rate)
    ) |>
    mutate(
      n_landscapes = factor(n_landscapes),
      epochs = factor(epochs)
    )

  # Find the worst classes across all metrics
  df_worst_summary <- df_raw |>
    summarize(
      # Precision-based worst class
      worst_class_precision = mode_random(worst_class_precision),
      worst_precision_entropy = entropy(worst_class_precision),
      mean_worst_precision = mean(worst_precision, na.rm = TRUE),

      # Recall-based worst class
      worst_class_recall = mode_random(worst_class_recall),
      worst_recall_entropy = entropy(worst_class_recall),
      mean_worst_recall = mean(worst_recall, na.rm = TRUE),

      # F1-based worst class
      worst_class_f1 = mode_random(worst_class_f1),
      worst_f1_entropy = entropy(worst_class_f1),
      mean_worst_f1 = mean(worst_f1, na.rm = TRUE),

      .by = c(n_landscapes, epochs, learning_rate, batch_size, dropout_rate)
    ) |>
    mutate(
      n_landscapes = factor(n_landscapes),
      epochs = factor(epochs),

      # Normalized entropy for alpha mapping (one per metric)
      precision_entropy_norm = worst_precision_entropy /
        max(worst_precision_entropy, na.rm = TRUE),
      recall_entropy_norm = worst_recall_entropy /
        max(worst_recall_entropy, na.rm = TRUE),
      f1_entropy_norm = worst_f1_entropy / max(worst_f1_entropy, na.rm = TRUE),

      # Alpha values (high entropy = low alpha = more transparent)
      alpha_precision = 1 - precision_entropy_norm,
      alpha_recall = 1 - recall_entropy_norm,
      alpha_f1 = 1 - f1_entropy_norm
    )

  # Plot accuracy ---------------------------------------------------------------

  # Create color scale
  scale_params <- create_accuracy_scale(
    range(df_summary$mean_accuracy),
    threshold = 0.8
  )

  p_accuracy <- ggplot(
    df_summary,
    aes(x = epochs, y = n_landscapes, fill = mean_accuracy)
  ) +
    geom_tile() +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_gradientn(
      colours = scale_params$colours,
      values = scale_params$values,
      limits = scale_params$limits
    ) +
    labs(
      x = "Epochs",
      y = "Number of training landscapes"
    )

  # Plot standard deviation ------------------------------------------------------
  p_sd_accuracy <- ggplot(
    df_summary,
    aes(x = epochs, y = n_landscapes, fill = sd_accuracy)
  ) +
    geom_tile() +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_viridis_c(
      option = "viridis",
      direction = -1,
      name = "SD Accuracy"
    ) +
    labs(
      x = "Epochs",
      y = "Number of Landscapes"
    ) +
    theme_bw() +
    theme(
      panel.grid = element_blank()
    )

  # Accuracy of worst class -------------------------------------------------------
  p_worst_class <- ggplot(
    df_worst_summary,
    aes(
      x = epochs,
      y = n_landscapes,
      fill = most_common_worst,
      alpha = alpha_val
    )
  ) +
    geom_tile(color = "white") +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_manual(
      values = class_colors,
      na.value = "grey90",
      drop = FALSE
    ) +
    scale_alpha(range = c(0.3, 1), guide = "none") +
    labs(
      x = "Epochs",
      y = "Number of Landscapes",
      fill = "Worst class (mode)",
      caption = "Transparency indicates entropy (consistency) across replicates"
    ) +
    theme_bw() +
    theme(
      panel.grid = element_blank(),
      strip.text = element_text(face = "bold")
    )

  # Accuracy of worst classes - mean accuracy ----------------------------------
  p_mean_acc_worst <- ggplot(
    df_worst_summary,
    aes(x = epochs, y = n_landscapes, fill = mean_acc_worst)
  ) +
    geom_tile() +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_gradientn(
      colours = colorRampPalette(
        c("#f0f8ff", "#c6dbef", "#6baed6", "#2171b5", "#001f3f")
      )(11),
      limits = c(0, 1),
      breaks = seq(0, 1, by = 0.2),
      name = "Mean Worst Accuracy"
    ) +
    labs(
      x = "Epochs",
      y = "Number of Landscapes"
    ) +
    theme_bw() +
    theme(
      panel.grid = element_blank()
    )

  # Precision-based worst class plot
  p_worst_precision <- ggplot(
    df_worst_summary,
    aes(
      x = epochs,
      y = n_landscapes,
      fill = worst_class_precision,
      alpha = alpha_precision
    )
  ) +
    geom_tile(color = "white") +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_manual(
      values = class_colors,
      na.value = "grey90",
      drop = FALSE
    ) +
    scale_alpha(range = c(0.3, 1), guide = "none") +
    labs(
      x = "Epochs",
      y = "Number of Landscapes",
      fill = "Worst class (precision)",
      caption = "Transparency indicates entropy (consistency) across replicates"
    )

  # F1-based worst class plot
  p_worst_f1 <- ggplot(
    df_worst_summary,
    aes(
      x = epochs,
      y = n_landscapes,
      fill = worst_class_f1,
      alpha = alpha_f1
    )
  ) +
    geom_tile(color = "white") +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_manual(
      values = class_colors,
      na.value = "grey90",
      drop = FALSE
    ) +
    scale_alpha(range = c(0.3, 1), guide = "none") +
    labs(
      x = "Epochs",
      y = "Number of Landscapes",
      fill = "Worst class (F1)",
      caption = "Transparency indicates entropy (consistency) across replicates"
    )

  # Mean accuracy plots for each metric
  p_mean_worst_precision <- ggplot(
    df_worst_summary,
    aes(x = epochs, y = n_landscapes, fill = mean_worst_precision)
  ) +
    geom_tile() +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_viridis_c(option = "viridis", direction = -1)

  p_mean_worst_f1 <- ggplot(
    df_worst_summary,
    aes(x = epochs, y = n_landscapes, fill = mean_worst_f1)
  ) +
    geom_tile() +
    facet_wrap(vars(learning_rate), labeller = label_both) +
    scale_fill_viridis_c(option = "viridis", direction = -1)

  # Save all plots ------------------------------------------------------------

  ggsave(
    filename = file.path(output_dir, "p_accuracy.png"),
    plot = p_accuracy,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_sd_accuracy.png"),
    plot = p_sd_accuracy,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_worst_class.png"),
    plot = p_worst_class,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_mean_acc_worst.png"),
    plot = p_mean_acc_worst,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_worst_precision.png"),
    plot = p_worst_precision,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_worst_f1.png"),
    plot = p_worst_f1,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_mean_worst_precision.png"),
    plot = p_mean_worst_precision,
    width = 10,
    height = 7
  )

  ggsave(
    filename = file.path(output_dir, "p_mean_worst_f1.png"),
    plot = p_mean_worst_f1,
    width = 10,
    height = 7
  )
}


result_path <- "inst/analyses/keras_systematic_tests/data/systematic_test_results_keras_ecotones.rds"
result_path_selforg <- "inst/analyses/keras_systematic_tests/data/systematic_test_results_keras_selforg.rds"
output_dir <- file.path(result_path, "figures")
