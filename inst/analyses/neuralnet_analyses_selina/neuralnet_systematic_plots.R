# Purpose plot accuracy etc. from systematic neuralnet tests for ecotones
# and self-organization landscapes

library(tidyverse)

# Set seed for reproducibility of random tie-breaking
set.seed(123456)

nn_all_systematic_plots <- function(result_path, output_dir) {
  # load functions to extract results in the right format and make the plots
  source(here::here("inst/analyses/functions/plot_systematic_tests.R"))
  source(here::here("inst/analyses/functions/plot_theme.R"))

  # Read results
  all_results_files <- list.files(result_path, full.names = TRUE)

  all_results <- map(all_results_files, read_rds)

  # Put all results into one list instead of a list of lists
  all_results <- flatten(all_results)

  # Prepare the data ---------------------------------------------------------
  # Extract all info from the list and put it in a single table

  df_raw <- map_dfr(all_results, combine_validation_results)

  # Create summaries with neuralnet-specific grouping
  summaries <- create_systematic_summaries(
    df_raw = df_raw,
    grouping_vars = c("n_landscapes", "layers", "metric", "inputmetrics")
  )

  # Add number of layers and neurons for the first layer to the table
  summaries <- map(summaries, function(df) {
    df$neurons <- str_extract(df$layers, "^[0-9]+")
    df$n_layers <- str_count(df$layers, "-") + 1
    return(df)
  })

  # rename column for number of inputs metrics
  summaries <- map(summaries, function(df) {
    df |>
      rename(
        Inputs = inputmetrics
      )
  })

  # Order characters (neurons and layers) numerically
  summaries <- map(summaries, function(df) {
    df$neurons <- factor(
      df$neurons,
      levels = as.character(
        sort(
          as.numeric(
            unique(df$neurons)
          )
        )
      )
    )
    df$n_layers <- factor(
      df$n_layers,
      levels = as.character(
        sort(
          as.numeric(
            unique(df$n_layers)
          )
        )
      )
    )
    return(df)
  })

  df_summary <- summaries$accuracy
  df_worst_summary <- summaries$worst_classes

  # Save the summaries as CSV files
  readr::write_csv(
    df_summary,
    file.path(result_path, "nn_systematic_summary_accuracy.csv")
  )
  readr::write_csv(
    df_worst_summary,
    file.path(result_path, "nn_systematic_summary_worst_classes.csv")
  )

  # Get all unique classes across all worst class columns
  all_classes <- unique(c(
    df_worst_summary$worst_class_precision,
    df_worst_summary$worst_class_recall,
    df_worst_summary$worst_class_f1
  ))

  # Set consistent factor levels for all worst class columns
  df_worst_summary <- df_worst_summary |>
    mutate(
      worst_class_precision = factor(
        worst_class_precision,
        levels = all_classes
      ),
      worst_class_recall = factor(worst_class_recall, levels = all_classes),
      worst_class_f1 = factor(worst_class_f1, levels = all_classes)
    )

  # Create color scale ------------------------------------------------
  scale_params <- create_accuracy_scale(
    range(df_summary$mean_accuracy),
    threshold = 0.8
  )
  # Plot functions ---------------------------------------------------------------
  plot_accuracy <- function(
    data,
    current_n,
    fill_variable,
    fill_name
  ) {
    ggplot(
      data |>
        filter(n_landscapes == current_n),
      aes(x = neurons, y = n_layers, fill = !!sym(fill_variable))
    ) +
      geom_tile(color = "white") +
      ggh4x::facet_nested(
        "Metric selection" + metric ~ "Number of inputs" + Inputs,
        scales = "free_x",
        space = "free"
      ) +
      scale_fill_gradientn(
        colours = scale_params$colours,
        values = scale_params$values,
        limits = scale_params$limits,
        name = fill_name
      ) +
      labs(
        x = "Number of neurons",
        y = "Number of layers",
        title = paste("Training landscapes:", current_n)
      ) +
      theme_systematic_tests()
  }

  # plot class-based results
  plot_class <- function(
    data,
    current_n,
    fill_variable,
    fill_name,
    alpha_variable
  ) {
    # get all levels for consistent coloring
    all_levels <- levels(data[[fill_variable]])

    # Filter the data
    plot_data <- data |> filter(n_landscapes == current_n)

    # Ensure the fill variable has all levels even if not present
    plot_data[[fill_variable]] <- factor(
      plot_data[[fill_variable]],
      levels = all_levels
    )

    ggplot(
      plot_data,
      aes(
        x = neurons,
        y = n_layers,
        fill = !!sym(fill_variable),
        alpha = !!sym(alpha_variable)
      )
    ) +
      geom_tile(color = "white", show.legend = TRUE) +
      ggh4x::facet_nested(
        "Metric selection" + metric ~ "Number of inputs" + Inputs,
        scales = "free_x",
        space = "free"
      ) +
      scale_fill_manual(
        values = class_colors,
        na.value = "grey90",
        drop = FALSE,
        limits = levels(data[[fill_variable]])
      ) +
      scale_alpha(range = c(0.3, 1), guide = "none") +
      labs(
        x = "Number of neurons",
        y = "Number of layers",
        fill = fill_name,
        title = paste("Training landscapes:", current_n),
        caption = "Transparency indicates entropy (consistency) across replicates"
      ) +
      theme_systematic_tests()
  }

  # Plot other continuous variables
  plot_continuous <- function(
    data,
    current_n,
    fill_variable,
    fill_name,
    limits = NULL
  ) {
    ggplot(
      data |> filter(n_landscapes == current_n),
      aes(x = neurons, y = n_layers, fill = !!sym(fill_variable))
    ) +
      geom_tile(color = "white") +
      ggh4x::facet_nested(
        "Metric selection" + metric ~ "Number of inputs" + Inputs,
        scales = "free_x",
        space = "free"
      ) +
      scale_fill_viridis_c(
        option = "viridis",
        direction = -1,
        name = fill_name,
        limits = limits
      ) +
      labs(
        x = "Number of neurons",
        y = "Number of layers",
        title = paste("Training landscapes:", current_n)
      ) +
      theme_systematic_tests()
  }

  # Make the plots (separately for each n_landscapes) ----------------------------
  p_accuracy <- map(unique(df_summary$n_landscapes), function(current_n) {
    plot_accuracy(
      data = df_summary,
      current_n = current_n,
      fill_variable = "mean_accuracy",
      fill_name = "Mean Accuracy"
    )
  })

  p_worst_precision <- map(
    unique(df_worst_summary$n_landscapes),
    function(current_n) {
      plot_class(
        data = df_worst_summary,
        current_n = current_n,
        fill_variable = "worst_class_precision",
        fill_name = "Worst class\n(precision)",
        alpha_variable = "alpha_precision"
      )
    }
  )

  p_worst_recall <- map(
    unique(df_worst_summary$n_landscapes),
    function(current_n) {
      plot_class(
        data = df_worst_summary,
        current_n = current_n,
        fill_variable = "worst_class_recall",
        fill_name = "Worst class\n(recall)",
        alpha_variable = "alpha_recall"
      )
    }
  )

  p_worst_f1 <- map(unique(df_worst_summary$n_landscapes), function(current_n) {
    plot_class(
      data = df_worst_summary,
      current_n = current_n,
      fill_variable = "worst_class_f1",
      fill_name = "Worst class\n(F1)",
      alpha_variable = "alpha_f1"
    )
  })
  # Continuous plots -------------------------------------------------------------
  # Calculate limits once for each variable
  sd_limits <- range(df_summary$sd_accuracy, na.rm = TRUE)
  mean_worst_precision_limits <- range(
    df_worst_summary$mean_worst_precision,
    na.rm = TRUE
  )
  mean_worst_recall_limits <- range(
    df_worst_summary$mean_worst_recall,
    na.rm = TRUE
  )
  mean_worst_f1_limits <- range(df_worst_summary$mean_worst_f1, na.rm = TRUE)

  p_sd_accuracy <- map(unique(df_summary$n_landscapes), function(current_n) {
    plot_continuous(
      data = df_summary,
      current_n = current_n,
      fill_variable = "sd_accuracy",
      fill_name = "SD Accuracy",
      limits = sd_limits
    )
  })
  p_mean_worst_precision <- map(
    unique(df_worst_summary$n_landscapes),
    function(current_n) {
      plot_continuous(
        data = df_worst_summary,
        current_n = current_n,
        fill_variable = "mean_worst_precision",
        fill_name = "Mean Worst\nPrecision",
        limits = mean_worst_precision_limits
      )
    }
  )

  p_mean_worst_recall <- map(
    unique(df_worst_summary$n_landscapes),
    function(current_n) {
      plot_continuous(
        data = df_worst_summary,
        current_n = current_n,
        fill_variable = "mean_worst_recall",
        fill_name = "Mean Worst\nRecall",
        limits = mean_worst_recall_limits
      )
    }
  )

  p_mean_worst_f1 <- map(
    unique(df_worst_summary$n_landscapes),
    function(current_n) {
      plot_continuous(
        data = df_worst_summary,
        current_n = current_n,
        fill_variable = "mean_worst_f1",
        fill_name = "Mean Worst\nF1",
        limits = mean_worst_f1_limits
      )
    }
  )

  # Function to wrap plots into one figure
  wrap_all_plots <- function(plot_list) {
    patchwork::wrap_plots(plot_list) +
      patchwork::plot_layout(
        nrow = 2,
        ncol = 2,
        guides = "collect",
        axes = "collect",
        axis_titles = "collect"
      )
  }

  # Wrap all plots into one figure
  p_accuracy <- wrap_all_plots(p_accuracy)
  p_sd_accuracy <- wrap_all_plots(p_sd_accuracy)
  p_worst_precision <- wrap_all_plots(p_worst_precision)
  p_worst_recall <- wrap_all_plots(p_worst_recall)
  p_worst_f1 <- wrap_all_plots(p_worst_f1)
  p_mean_worst_precision <- wrap_all_plots(p_mean_worst_precision)
  p_mean_worst_recall <- wrap_all_plots(p_mean_worst_recall)
  p_mean_worst_f1 <- wrap_all_plots(p_mean_worst_f1)

  # Save all plots ------------------------------------------------------------

  ggsave(
    filename = file.path(output_dir, "p_accuracy.png"),
    plot = p_accuracy,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_sd_accuracy.png"),
    plot = p_sd_accuracy,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_worst_precision.png"),
    plot = p_worst_precision,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_worst_recall.png"),
    plot = p_worst_recall,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_worst_f1.png"),
    plot = p_worst_f1,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_mean_worst_precision.png"),
    plot = p_mean_worst_precision,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_mean_worst_recall.png"),
    plot = p_mean_worst_recall,
    width = 14,
    height = 10
  )

  ggsave(
    filename = file.path(output_dir, "p_mean_worst_f1.png"),
    plot = p_mean_worst_f1,
    width = 14,
    height = 10
  )
}

result_path <- "inst/analyses/pics_for_paper/systematic_tests/nn_metrics/"
data_path <- "inst/analyses/data/systematic_tests/nn_metrics/"

data_path_ecotones <- file.path(
  data_path,
  "ecotones"
)

data_path_selforg <- file.path(
  data_path,
  "selforg"
)

output_dir_ecotones <- file.path(
  result_path,
  "ecotones"
)
output_dir_selforg <- file.path(
  result_path,
  "selforg"
)

nn_all_systematic_plots(
  result_path = data_path_ecotones,
  output_dir = output_dir_ecotones
)
nn_all_systematic_plots(
  result_path = data_path_selforg,
  output_dir = output_dir_selforg
)
