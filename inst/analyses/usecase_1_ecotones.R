#--------------------------------------------------------------------
# Load all functions in the package and prepare everything
#--------------------------------------------------------------------
devtools::load_all()

library(ggplot2)

set.seed(53)

directory <- "inst/analyses/pics_for_paper/"

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to ecotones (or random)
ecotone_types = c(
  "sharp",
  "diffuse",
  "clustered",
  "fingers",
  "bands",
  "random"
)
n_ecotones <- length(ecotone_types)

#--------------------------------------------------------------------
# Generate landscapes for example figure (each type one landscape)
#--------------------------------------------------------------------

# generate landscapes
landscapes_manuscript <- create_training_landscapes(
  n = n_ecotones,
  patterns = ecotone_types
)
order_index <- match(
  sapply(landscapes_manuscript, function(x) x$pattern),
  ecotone_types
)
landscapes_manuscript <- landscapes_manuscript[order(order_index)]
landscapes_manuscript[[5]]$pattern <- "bands"

fig_sub_letter <- c("a", "b", "c", "d", "e", "f")
for (i in 1:6) {
  landscapes_manuscript[[i]]$pattern <- paste(
    "(",
    fig_sub_letter[i],
    ") ",
    landscapes_manuscript[[i]]$pattern,
    sep = ""
  )
}

# plot all landscapes
fig_ecotones <- plot_landscape_list(
  landscapes_manuscript,
  ncol = n_ecotones,
  show_legend = FALSE
)
fig_ecotones
# save plot
ggsave(
  filename = paste(
    directory,
    "fig_ecotones",
    ".jpg",
    sep = ""
  ),
  plot = fig_ecotones,
  width = 6,
  height = 1.5,
  dpi = 300
)


#--------------------------------------------------------------------
# Generate training landscapes and take a look
#--------------------------------------------------------------------

#generate all training landscapes
ecotone_landscapes <- create_training_landscapes(
  n = 100,
  patterns = ecotone_types
)

# check how many landscapes of each pattern were generated
table(purrr::map_chr(ecotone_landscapes, ~ .x$pattern))

# plot first 20 landscapes
plot_landscape_list(ecotone_landscapes[1:20])

#--------------------------------------------------------------------
# Calculate landscapes metrics and determine best ones
#--------------------------------------------------------------------

# calculate landscape metrics on the landscape level
landscape_metrics <- calculate_landscape_metrics(
  landscapes = ecotone_landscapes,
  level = "landscape"
)

# find the 10 best metrics
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)

landscape_metrics_plot <- landscape_metrics
landscape_metrics_plot$pattern[
  landscape_metrics_plot$pattern == "bands"
] <- "bands"

# plot the 10 best metrics
p_metrics <- plot_metrics(
  metrics = landscape_metrics_plot,
  selected_metrics = best_10,
  force = TRUE
)

p_metrics

ggsave(
  filename = paste(directory, "fig_supp_ecotone_metrics.jpg", sep = ""),
  plot = p_metrics,
  width = 6,
  height = 4.5,
  dpi = 300
)


#--------------------------------------------------------------------
# Train neural network with landscapes metrics
#--------------------------------------------------------------------

# train a network
model_ecotones_lm <- train_nn_metrics(
  metrics = landscape_metrics,
  metrics_selected = best_10,
  hidden_layers = c(8, 8),
  cv_method = "k-fold"
)

# look at the model object
model_ecotones_lm$performance$accuracy

#--------------------------------------------------------------------
# Look at classification results
# -------------------------------------------------------------------

# Plot the landscapes that were misclassified
plot_classified_landscapes(
  classification = model_ecotones_lm$performance$validation_results,
  landscapes = ecotone_landscapes,
  only_misclassified = TRUE
)

# -------------------------------------------------------------------
# Apply the models to new landscapes
# -------------------------------------------------------------------

# generate test landscapes
test_landscapes_ecotone <- create_training_landscapes(
  n = 100,
  add_rotation = TRUE,
  patterns = ecotone_types
)

# apply the model to the test landscapes
validation_results_ecotone_lm <- apply_nn_metrics(
  landscapes = test_landscapes_ecotone,
  nn_model = model_ecotones_lm,
  return_performance = TRUE
)

# show landscapes that are not classified correctly
p_misclass <- plot_classified_landscapes(
  classification = validation_results_ecotone_lm$predictions,
  landscapes = test_landscapes_ecotone,
  only_misclassified = TRUE
)

ggsave(
  filename = paste(directory, "fig_supp_ecotone_misclassified.jpg", sep = ""),
  plot = p_misclass,
  width = 3.5,
  height = 1.5,
  dpi = 300
)
