#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

library(ggplot2)

set.seed(123)
#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to ecotones (or random)
selforga_types = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)
n_selforga <- length(selforga_types)

#--------------------------------------------------------------------
# Generate landscapes for example figure (each type one landscape)
#--------------------------------------------------------------------

# generate landscapes
landscapes_manuscript2 <- create_training_landscapes(
  n = n_selforga,
  patterns = selforga_types
)

# plot all landscapes
plot_landscape_list(
  landscapes_manuscript2,
  ncol = n_selforga,
  show_legend = FALSE
)

#--------------------------------------------------------------------
# Generate training landscapes and take a look
#--------------------------------------------------------------------

#generate all training landscapes
selforga_landscapes <- create_training_landscapes(
  n = 100,
  patterns = selforga_types
)

# check how many landscapes of each pattern were generated
table(purrr::map_chr(selforga_landscapes, ~ .x$pattern))

# plot first 20 landscapes
plot_landscape_list(selforga_landscapes[1:20])

#--------------------------------------------------------------------
# Calculate landscapes metrics and determine best ones
#--------------------------------------------------------------------

# calculate landscape metrics at the class level
landscape_class_metrics <- calculate_landscape_metrics(
  landscapes = selforga_landscapes,
  level = "class"
)
landscape_class_metrics <- landscape_class_metrics %>% filter(class == 0)


# find the 10 best metrics
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)

# plot the 10 best metrics
#p_metrics <- plot_metrics(
#  metrics = landscape_class_metrics,
#  selected_metrics = best_10
#)
#
#ggsave(
#  filename = paste0("Supp_plot_metrics.jpg",sep=""),
#  plot = p_metrics,
#  width = 8,
#  height = 6,
#  dpi = 300
#)

#--------------------------------------------------------------------
# Train neural network with landscapes metrics
#--------------------------------------------------------------------

# train a network
# use k-fold cross-validation with 3 folds
# warning will tell you that folds need to be reduced to 2
model_selforga_lm <- train_nn_metrics(
  metrics = landscape_class_metrics,
  metrics_selected = best_10,
  cv_method = "k-fold"
)

# look at the model object
model_selforga_lm$performance$accuracy

# -------------------------------------------------------------------
# Apply the models to new landscapes
# -------------------------------------------------------------------

# generate test landscapes
test_landscapes_selforga <- create_training_landscapes(
  n = 100,
  add_rotation = TRUE,
  patterns = selforga_types
)

# apply the model to the test landscapes
validation_results_selforga_lm <- apply_nn_metrics(
  landscapes = test_landscapes_selforga,
  nn_model = model_selforga_lm,
  return_performance = TRUE
)

validation_results_selforga_lm

#show landscapes that are not classified correctly
plot_classified_landscapes(
  classification = validation_results_selforga_lm$predictions,
  landscapes = test_landscapes_selforga,
  only_misclassified = TRUE
)
