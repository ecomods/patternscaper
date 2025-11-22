library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(patchwork)

#result files
eval_dir <- "inst/examples/Ecotone_Results_Landscape/Results/"
fig_dir <- "inst/examples/Ecotone_Results_Landscape/Figs/"
file_names <- list.files(eval_dir)

df_raw <- list()

#collect all result files
for (i in seq_along(file_names)) {

  env <- new.env()
  load(paste0(eval_dir, file_names[i]), envir = env)
  results_list <- env$results_list

  #and collect within the result files
  for (rl in seq_along(results_list)) {

    res <- results_list[[rl]]

    if (is.null(res$acc)) next
    if (is.null(res$df1)) next
    if (nrow(res$df1) == 0) next
    if (!"precision" %in% names(res$df1)) next
    if (all(is.na(res$df1$precision))) next

    # Anzahl Neuronen = erster Eintrag in layers (alle hidden layers gleich)
    neurons <- res$layers[1]

    best_val  <- max(res$df1$precision, na.rm = TRUE)
    worst_val <- min(res$df1$precision, na.rm = TRUE)

    best_classes  <- res$df1$class[res$df1$precision == best_val]
    worst_classes <- res$df1$class[res$df1$precision == worst_val]

    best_class  <- if (length(best_classes) > 1) sample(best_classes, 1) else best_classes
    worst_class <- if (length(worst_classes) > 1) sample(worst_classes, 1) else worst_classes

    df_raw[[length(df_raw)+1]] <- data.frame(
      training_size = res$training_size,
      layers        = length(res$layers),
      metric        = res$metric,
      inputmetrics  = res$inputmetrics,
      neurons       = neurons,
      replicate     = res$replicate,
      accuracy      = res$acc,
      acc_best      = best_val,
      acc_worst     = worst_val,
      best_class    = best_class,
      worst_class   = worst_class,
      stringsAsFactors = FALSE
    )
  }
}

df_raw <- bind_rows(df_raw)
n_repl <-  max(df_raw$replicate)

#calculate mean, sd and number of na's and results
df_summary <- df_raw %>%
  group_by(training_size, layers, metric, inputmetrics, neurons) %>%
  summarise(
    mean_accuracy = mean(accuracy, na.rm = TRUE),
    sd_accuracy   = sd(accuracy, na.rm = TRUE),
    n_repl = sum(!is.na(accuracy)),
    .groups = "drop"
  )
#get training sizes
ts_unique <- sort(unique(df_summary$training_size))
df_summary$training_size <- factor(
  df_summary$training_size,
  levels = ts_unique
)
df_summary <- df_summary %>%
  mutate(
    neurons_label = paste0(neurons, " (", inputmetrics, " metrics)"),
    neurons_label = factor(neurons_label, levels = unique(neurons_label))
  )
summary(df_summary)

#-------------------------
# Accuracy
#-------------------------
custom_colors <- c(
  "low"   = "red",
  "mid1"  = "orange",
  "mid2"  = "yellow",
  "high1" = "#99ccff",
  "high2" = "#001f3f"
)

#best results for 50 training landscape (for manuscript)
df_50 <- df_summary %>% filter(training_size == 50)
range(df_50$mean_accuracy, na.rm = TRUE)

#ranges of data
z_limits_mean_acc <- range(df_summary$mean_accuracy, na.rm = TRUE)
col_boundaries <- c(min(z_limits_mean_acc),(min(z_limits_mean_acc)+(0.8-min(z_limits_mean_acc))/3),(min(z_limits_mean_acc)+2*(0.8-min(z_limits_mean_acc))/3), 0.8,max(z_limits_mean_acc))

#make heat meaps for mean accuracy
make_acc_mean_plot <- function(df, training_val) {
  df_plot <- df %>% filter(training_size == training_val)

  df_plot <- df_plot %>%
    group_by(inputmetrics) %>%
    mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
    ungroup()

  ggplot(df_plot, aes(x = neurons, y = layers, fill = mean_accuracy)) +
    geom_tile() +
    facet_grid(
      metric ~ inputmetrics,
      scales = "free_x",
      labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
    ) +
    scale_fill_gradientn(
      colours = custom_colors,
      values = scales::rescale(col_boundaries),
      limits = z_limits_mean_acc
    )   +
    labs(
      x = "Number of neurons",
      y = "Number of layers",
      fill = "Mean accuracy",
      title = paste("Training =", training_val)
    ) +
    theme_minimal(base_size = 13)
}

training_values <- unique(df_summary$training_size)

plots_acc <- lapply(training_values, function(tr) {
  make_acc_mean_plot(df_summary, tr)
})

#show plots
#plots_acc[[1]]

# combine plots for saving and store
combined_plot1 <- (plots_acc[[1]] + plots_acc[[2]]) /
  (plots_acc[[3]] + plots_acc[[4]])

ggsave(
  filename = paste0(fig_dir,"plot_mean_accuracy.jpg",sep=""),
  plot = combined_plot1 + plot_layout(guides = "collect"),
  width = 15,
  height = 10,
  dpi = 300
)

#-------------------------
# Standard deviation of accuracy
#-------------------------

z_limits_sd_acc <- range(df_summary$sd_accuracy, na.rm = TRUE)

make_acc_sd_plot <- function(df, training_val) {

  df_plot <- df %>% filter(training_size == training_val)

  df_plot <- df_plot %>%
    group_by(inputmetrics) %>%
    mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
    ungroup()

  ggplot(df_plot, aes(x = neurons, y = layers, fill = sd_accuracy)) +
    geom_tile() +
    facet_grid(
      metric ~ inputmetrics,
      scales = "free_x",
      labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
    ) +
    scale_fill_viridis_c(limits = z_limits_sd_acc, direction = -1) +
    labs(
      x = "Number of neurons",
      y = "Number of layers",
      fill = "Sd of accuracy",
      title = paste("Training =", training_val)
    ) +
    theme_minimal(base_size = 13)
}

training_values <- unique(df_summary$training_size)

plots_acc_sd <- lapply(training_values, function(tr) {
  make_acc_sd_plot(df_summary, tr)
})

#show plots
#plots_acc_sd[[1]]

# combine plots for saving and store
combined_plot2 <- (plots_acc_sd[[1]] + plots_acc_sd[[2]]) /
  (plots_acc_sd[[3]] + plots_acc_sd[[4]])
ggsave(
  filename = paste0(fig_dir,"plot_sd_accuracy.jpg",sep=""),
  plot = combined_plot2 + plot_layout(guides = "collect"),
  width = 15,
  height = 10,
  dpi = 300
)



#-------------------------
# Number of successful runs
#-------------------------

z_limits_n_repl <- c(0,n_repl)

make_plot <- function(df, training_val) {

  df_plot <- df %>% filter(training_size == training_val)

  df_plot <- df_plot %>%
    group_by(inputmetrics) %>%
    mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
    ungroup()

  ggplot(df_plot, aes(x = neurons, y = layers, fill = n_repl)) +
    geom_tile() +
    facet_grid(
      metric ~ inputmetrics,
      scales = "free_x",
      labeller = labeller(inputmetrics = function(x) paste0("Inputs = ", x))
    ) +
    scale_fill_gradientn(
      colours = colorRampPalette(
        c("#f0f8ff", "#c6dbef", "#6baed6", "#2171b5", "#001f3f")
      )(n_repl+1),
      limits = z_limits_n_repl,
     breaks = seq(z_limits_n_repl[1],z_limits_n_repl[2],by=2)
    ) +
    labs(
      x = "Number of neurons",
      y = "Number of layers",
      fill = "Successful Runs",
      title = paste("Training =", training_val)
    ) +
    theme_minimal(base_size = 13)
}

training_values <- unique(df_summary$training_size)

plots_nsuc <- lapply(training_values, function(tr) {
  make_plot(df_summary, tr)
})

#show plots
#plots_nsuc[[1]]

# combine plots for saving and store
combined_plot3 <- (plots_nsuc[[1]] + plots_nsuc[[2]]) /
  (plots_nsuc[[3]] + plots_nsuc[[4]])
ggsave(
  filename = paste0(fig_dir,"plot_successful_runs.jpg",sep=""),
  plot = combined_plot3 + plot_layout(guides = "collect"),
  width = 15,
  height = 10,
  dpi = 300
)


#-------------------------
# Worst classes
#-------------------------

#which is worst class (random if several)
mode_random <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA)
  tab <- table(x)
  max_freq <- max(tab)
  candidates <- names(tab)[tab == max_freq]
  sample(candidates, 1)
}

# how save is this across replicates
entropy <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) <= 1) return(0)
  tab <- table(x) / length(x)
  -sum(tab * log2(tab))
}

#summarize in new data frame
df_worst_summary <- df_raw %>%
  group_by(training_size, layers, metric, inputmetrics, neurons) %>%
  summarise(
    most_common_worst = mode_random(worst_class),
    entropy_worst = entropy(worst_class),
    mean_acc_worst = mean(acc_worst, na.rm = TRUE),  # hier die mittlere Accuracy
    .groups = "drop"
  )

df_50_worst_curvyfingers <- df_worst_summary %>% filter(training_size == 50) %>% filter(inputmetrics >= 10)
range(df_50_worst_curvyfingers$mean_acc_worst, na.rm = TRUE)

df_100_worst <- df_worst_summary %>% filter(training_size == 100) %>% filter(most_common_worst == "curvyfingers")
range(df_100_worst$mean_acc_worst, na.rm = TRUE)

# colours for classes (colour-blind friendly)
class_colors <- c(
  "curvyfingers" = "#000000",
  "sharp"        = "#E69F00",
  "diffuse"      = "#56B4E9",
  "clustered"    = "#009E73",
  "sine_bands"   = "#F0E442",
  "random"       = "#CC79A7"
)

plot_worstclass <- function(df_worst_summary, training_val) {

  df_plot <- df_worst_summary %>%
    filter(training_size == training_val) %>%
    mutate(
      neurons = factor(neurons, levels = sort(unique(neurons))),
      # Entropie normalisieren: 0 = klare Aussage, 1 = komplettes Chaos
      entropy_norm = entropy_worst / max(entropy_worst, na.rm = TRUE),
      alpha_val = 1 - entropy_norm
    )

  ggplot(df_plot,
         aes(x = neurons, y = layers,
             fill = most_common_worst,
             alpha = alpha_val)) +
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
      y = "Number of layers",
      fill = "Worst class (mode)",
      title = paste("Training =", training_val),
      subtitle = "Transparency indicates entropy (consistency) across replicates"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      strip.text.x = element_text(face = "bold"),
      strip.text.y = element_text(face = "bold"),
      plot.title = element_text(size = 15, face = "bold")
    )
}

training_values <- unique(df_worst_summary$training_size)

plots_worst <- lapply(training_values, function(tr) {
  plot_worstclass(df_worst_summary, tr)
})

#plots_worst[[1]]

# combine plots for saving and store
combined_plot4 <- (plots_worst[[1]] + plots_worst[[2]]) /
  (plots_worst[[3]] + plots_worst[[4]])
ggsave(
  filename = paste0(fig_dir,"plot_worst_class.jpg",sep=""),
  plot = combined_plot4 + plot_layout(guides = "collect"),
  width = 15,
  height = 10,
  dpi = 300
)

#-------------------------
# Accuracy of worst classes
#-------------------------

#z_limits_worst_acc <- range(df_worst_summary$mean_acc_worst, na.rm = TRUE)

plot_worst_acc <- function(df, training_val) {

  df_plot <- df %>% filter(training_size == training_val)

  df_plot <- df_plot %>%
    group_by(inputmetrics) %>%
    mutate(neurons = factor(neurons, levels = sort(unique(neurons)))) %>%
    ungroup()

  ggplot(df_plot, aes(x = neurons, y = layers, fill = mean_acc_worst)) +
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
      breaks = seq(0,1,by=0.2)
    ) +
     labs(
      x = "Number of neurons",
      y = "Number of layers",
      fill = "Mean worst accuracy",
      title = paste("Training =", training_val)
    ) +
    theme_minimal(base_size = 13)
}


plots_worst_acc <- lapply(training_values, function(tr) {
  plot_worst_acc(df_worst_summary, tr)
})

#plots_worst_acc[[1]]

# combine plots for saving and store
combined_plot5 <- (plots_worst_acc[[1]] + plots_worst_acc[[2]]) /
  (plots_worst_acc[[3]] + plots_worst_acc[[4]])
ggsave(
  filename = paste0(fig_dir,"plot_acc_worst_class.jpg",sep=""),
  plot = combined_plot5 + plot_layout(guides = "collect"),
  width = 15,
  height = 10,
  dpi = 300
)
