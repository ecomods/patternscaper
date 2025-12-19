#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Use Case 1: Ecotone transitions
# The two approaches (neural net using landscape metrics as input and neural net using pixel data)
# are tested different transition types in ecotones.
# The plots from this script are used in the manuscript on the R package.
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Load all functions in the package and prepare everything
#--------------------------------------------------------------------

devtools::load_all()
library(ggplot2)
set.seed(53)
directory <- "inst/analyses/pics_for_paper/"

#--------------------------------------------------------------------
# Helper function to save plots in different formats (jpg, png, pdf)
#--------------------------------------------------------------------
save_plot_multi <- function(
  plot,
  directory, 
  filename_base, 
  width = 6, 
  height = 6,
  dpi = 300
) {

  #ensure directory ends with /
  if (!grepl("/$", directory)) {
    directory <- paste0(directory, "/")
  }
  ggsave( #jpg
    filename = paste0(directory, filename_base, ".jpg"),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
  ggsave( #png
    filename = paste0(directory, filename_base, ".png"),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
  ggsave( #pdf
    filename = paste0(directory, filename_base, ".pdf"),
    plot = plot,
    width = width,
    height = height
  )
}

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
# re-order the landscapes
order_index <- match(
  sapply(landscapes_manuscript, function(x) x$pattern),
  ecotone_types
)
landscapes_manuscript <- landscapes_manuscript[order(order_index)]

# set letters for plot
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
save_plot_multi(
  plot = fig_ecotones,
  filename_base = "fig_ecotones",
  directory = directory,
  width = 6,
  height = 1.5,
  dpi = 300
)

#--------------------------------------------------------------------
# Generate training and testing landscapes
#--------------------------------------------------------------------

# generate training landscapes
ecotone_landscapes <- create_training_landscapes(
  n = 100,
  patterns = ecotone_types
)

# generate test landscapes
test_landscapes_ecotone <- create_training_landscapes(
  n = 100,
  add_rotation = TRUE,
  patterns = ecotone_types
)


#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Approach 1: neural net trained on landscape metrics
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------


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

# plot the 10 best metrics
fig_metrics <- plot_metrics(
  metrics = landscape_metrics,
  selected_metrics = best_10,
  force = TRUE
)
fig_metrics

# save into different formats
save_plot_multi(
  plot = fig_metrics,
  filename_base = "fig_supp_ecotone_metrics",
  directory = directory,
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

# plot the landscapes that were misclassified
plot_classified_landscapes(
  classification = model_ecotones_lm$performance$validation_results,
  landscapes = ecotone_landscapes,
  only_misclassified = TRUE
)

# -------------------------------------------------------------------
# Apply the models to new landscapes
# -------------------------------------------------------------------

# apply the model to the test landscapes
validation_results_ecotone_lm <- apply_nn_metrics(
  landscapes = test_landscapes_ecotone,
  nn_model = model_ecotones_lm,
  return_performance = TRUE
)

# accuracy of the neural net for the test data
validation_results_ecotone_lm$performance$accuracy
# confusion matrix (correct/uncorrect classifications)
validation_results_ecotone_lm$performance$confusion_matrix
# per class metrics
validation_results_ecotone_lm$performance$per_class_metrics

# show landscapes that are not classified correctly
fig_misclass <- plot_classified_landscapes(
  classification = validation_results_ecotone_lm$predictions,
  landscapes = test_landscapes_ecotone,
  only_misclassified = TRUE,
  show_legend = F,
  ncol=4
)
fig_misclass

# save into different formats
save_plot_multi(
  plot = fig_misclass,
  filename_base = "fig_supp_ecotone_misclassified",
  directory = directory,
  width = 4.5,
  height = 1.5,
  dpi = 300
)

#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Approach 2: neural net trained on pixel input
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Train neural network with the input data itself
#--------------------------------------------------------------------

# train a model
model_ecotones_pix <- train_nn_landscapes(
  landscapes = ecotone_landscapes,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 100,
)

# check the model accuracy
model_ecotones_pix$performance$accuracy
#--> very low --> increase number of landscapes to 400

# generate new (more!) training landscapes
ecotone_landscapes_400 <- create_training_landscapes(
  n = 400,
  patterns = ecotone_types
)

# train the model again
model_ecotones_pix_400 <- train_nn_landscapes(
  landscapes = ecotone_landscapes_400,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 100,
)

# check the model accuracy
model_ecotones_pix_400$performance$accuracy
#--> higher now

# plot the landscapes that were misclassified
plot_classified_landscapes(
  classification = model_ecotones_pix_400$performance$validation_results,
  landscapes = ecotone_landscapes_400,
  only_misclassified = TRUE,
  show_legend = F,
  ncol = 6
)

# -------------------------------------------------------------------
# Apply the models to new landscapes
# -------------------------------------------------------------------

# apply the model to the test landscapes
validation_results_ecotone_pix_400 <- apply_nn_landscapes(
  landscapes = test_landscapes_ecotone,
  nn_model = model_ecotones_pix_400,
  return_performance = TRUE
)

# accuracy of the neural net for the test data
validation_results_ecotone_pix_400$performance$accuracy
# confusion matrix (correct/uncorrect classifications)
validation_results_ecotone_pix_400$performance$confusion_matrix
# per class metrics
validation_results_ecotone_pix_400$performance$per_class_metrics

# plot the landscapes that were misclassified
fig_misclass_ecotone_pix_400 <- plot_classified_landscapes(
  classification = validation_results_ecotone_pix_400$predictions,
  landscapes = test_landscapes_ecotone,
  only_misclassified = TRUE,
  show_legend = F,
  ncol = 6
)
#--> currently too many!

fig_misclass_ecotone_pix_400

save_plot_multi(
  plot = fig_misclass_ecotone_pix_400,
  filename_base = "fig_supp_ecotone_pixel_misclassified",
  directory = directory,
  width = 4.5,
  height = 1.5,
  dpi = 300
)

