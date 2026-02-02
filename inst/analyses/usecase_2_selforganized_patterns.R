#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Use Case 1: Self-organized landscape patterns
# The two approaches (neural net using landscape metrics as input and neural net using pixel data)
# are tested different types of self-organized landscapes:
#   bare, spots, labyrinth, gaps, dense.
# In addition, pictures (photographs and satellite) are used for testing.
# The plots from this script are used in initial R package description by Tietjen, Baldauf, Berger (202x).
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Load all functions in the package and prepare everything
#--------------------------------------------------------------------

devtools::load_all()
#additional libraries are required to handle and show the pictures
library(ggplot2)
library(png)
library(magick)
library(colorspace)
library(raster)
library(tibble)
# for reproducibility
set.seed(321)
directory <- "inst/analyses/pics_for_paper/"
#use help function to plot different formats
source("inst/analyses/functions/plot_different_formats.R")

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
# Step 1: General landscape types and their titles (overview figure)
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

# pattern types to be distinguished
selforga_types_general = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)

# plotting for manuscript - create landscapes
landscapes_manuscript <- list()
landscapes_manuscript[[1]] <- create_landscape_random(
  tree_prop = 0.05
)
landscapes_manuscript[[1]]$pattern <- "bare" #type "bare" does not exist in our list
landscapes_manuscript[[2]] <- create_landscape_spots(
  n_spots = 5,
  spot_radius = 18,
  spot_radius_sd = 3,
  radius_noise_fraction = 0.4,
  regular_spots = T
)
landscapes_manuscript[[3]] <- create_landscape_labyrinth(
  frequency = 3,
  veg_threshold = 0.5,
  band_fuzziness = 0.08,
  octaves = 3
)
landscapes_manuscript[[4]] <- create_landscape_gaps(
  n_spots = 3,
  spot_radius = 15,
  spot_radius_sd = 5,
  radius_noise_fraction = 0.5,
  regular_spots = T
)
landscapes_manuscript[[5]] <- create_landscape_random(
  tree_prop = 0.9
)
landscapes_manuscript[[5]]$pattern <- "dense" #type "dense" does not exist in our list

# add letters for figure
fig_sub_letter <- c("a", "b", "c", "d", "e")
for (i in 1:5) {
  landscapes_manuscript[[i]]$pattern <- paste(
    "(",
    fig_sub_letter[i],
    ") ",
    landscapes_manuscript[[i]]$pattern,
    sep = ""
  )
}

# make plot
fig_pattern_selforga <- plot_landscape_list(
  landscapes_manuscript,
  ncol = 5,
  show_legend = F
)
fig_pattern_selforga

# save plot
save_plot_multi(
  plot = fig_pattern_selforga,
  filename_base = "fig_selforga",
  directory = directory,
  width = 5,
  height = 1.5,
  dpi = 300
)

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
# Step 2: Anaylse performance of neural networks for artificial data
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Generate training and testing landscapes for general analysis
#--------------------------------------------------------------------

# for reproducibility
set.seed(42)

training_landscapes_selforga_general <- create_training_landscapes(
  n = 100,
  patterns = selforga_types_general
)

# generate test landscapes
test_landscapes_selforga_general <- create_training_landscapes(
  n = 100,
  patterns = selforga_types_general
)


#----------------------------------------------------------------------------------------
# Approach 1: neural net trained on landscape metrics
#----------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Calculate landscapes metrics and determine best ones
#--------------------------------------------------------------------

landscape_class_metrics_all_general <- calculate_landscape_metrics(
  landscapes = training_landscapes_selforga_general,
  level = "class"
)

#focus on vegetation class only (no bare soil)
metric_class <- 1
landscape_class_metrics_all_general <- landscape_class_metrics_all_general %>%
  filter(class == metric_class)

#determine best 10 metrics to distinguish pattern types
best_10_selforga_general <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics_all_general,
  metrics_number = 10,
  method = "kruskal_p"
)

# plot the 10 best metrics
fig_metrics_selforga_general <- plot_metrics(
  metrics = landscape_class_metrics_all_general,
  selected_metrics = best_10_selforga_general,
  force = TRUE
)
fig_metrics_selforga_general

# save into different formats
save_plot_multi(
  plot = fig_metrics_selforga_general,
  filename_base = "fig_supp_selforga_metrics",
  directory = directory,
  width = 6,
  height = 4.5,
  dpi = 300
)

#--------------------------------------------------------------------
# Train neural network with landscapes metrics and test
#--------------------------------------------------------------------

# train a network
model_selforga_metrics_general <- train_nn_metrics(
  metrics = landscape_class_metrics_all_general,
  metrics_selected = best_10_selforga_general,
  cv_method = "k-fold"
)

# look at the model object
model_selforga_metrics_general$performance$accuracy
model_selforga_metrics_general$performance$confusion_matrix

# test model on new data
validation_results_selforga_lm_general <- apply_nn_metrics(
  landscapes = test_landscapes_selforga_general,
  nn_model = model_selforga_metrics_general,
  return_performance = TRUE
)

# accuracy of the neural net for the test data
validation_results_selforga_lm_general$performance$accuracy
validation_results_selforga_lm_general$performance$confusion_matrix

#show misclassified landscapes (if any)
fig_supp_selforga_misclassified <- plot_classified_landscapes(
  validation_results_selforga_lm_general$predictions,
  test_landscapes_selforga_general,
  only_misclassified = T
)

# save into different formats
save_plot_multi(
  plot = fig_supp_selforga_misclassified,
  filename_base = "fig_supp_selforga_misclassified",
  directory = directory,
  width = 4.5,
  height = 3,
  dpi = 300
)

#----------------------------------------------------------------------------------------
# Approach 2: neural net trained on pixel data
#----------------------------------------------------------------------------------------

#set seed for Keras (needs to be done separately)
set_random_seed(53)

#--------------------------------------------------------------------
# Train neural network with the input data itself
#--------------------------------------------------------------------

# train a model
model_selforga_pix_general <- train_nn_pixels(
  landscapes = training_landscapes_selforga_general,
  cv_method = "k-fold",
  learning_rate = 0.0001,
  epochs = 20,
)

# check the model accuracy
model_selforga_pix_general$performance$accuracy

#validate model with new landscapes
validation_results_selforga_pix_general <- apply_nn_pixels(
  landscapes = test_landscapes_selforga_general,
  nn_model = model_selforga_pix_general,
  return_performance = T
)

# accuracy of the neural net for the test data
validation_results_selforga_pix_general$performance$accuracy

#show misclassified landscapes (if any)
fig_supp_selforga_misclassified_pix <- plot_classified_landscapes(
  validation_results_selforga_pix_general$predictions,
  test_landscapes_selforga_general,
  only_misclassified = T
)

# save into different formats
save_plot_multi(
  plot = fig_supp_selforga_misclassified_pix,
  filename_base = "fig_supp_selforga_misclassified_pix",
  directory = directory,
  width = 4.5,
  height = 3,
  dpi = 300
)

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
# Step 3: Train and test models for photographs
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# Generate training landscapes
#-------------------------------------------------------------------------------------

# for reproducibility
set.seed(321)

selforga_types = c(
  "random",
  "spots",
  "labyrinth",
  "gaps"
)

n_landscapes_per_type <- c(20, 40, 80, 160)
# number of models
n_models <- length(n_landscapes_per_type)
# number of landscapes
pred_numbers <- length(selforga_types) * n_landscapes_per_type

# create new landscapes for training
training_landscapes_selforga <- list(list())

#size of the landscapes - adjusted to size of pictures
l_size <- 200
for (n_l in 1:n_models) {
  print(paste(
    "number of landscapes: ",
    length(selforga_types) * n_landscapes_per_type[n_l],
    sep = ""
  ))
  training_landscapes_selforga[[n_l]] <- vector(
    "list",
    n_landscapes_per_type[n_l]
  )
  for (i in 1:n_landscapes_per_type[n_l]) {
    j <- (i - 1) * length(selforga_types) + 1
    n_sp <- sample(x = seq(3, 20), size = 1)
    n_rad <- sample(x = seq(round(90 / n_sp), round(250 / n_sp)), size = 1) #sample(x = seq(round(45/n_sp), round(150/n_sp)), size = 1)
    temp_landscape <- create_landscape_gaps(
      width = l_size,
      height = l_size,
      n_spots = n_sp,
      spot_radius = n_rad,
      spot_radius_sd = sample(x = seq(3, 5), size = 1),
      radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.4),
      regular_spots = T #sample(x = c(T, F), size = 1)
    )
    landscape_name <- paste("landscape_gaps_", n_l, "_", i, sep = "")
    temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
    training_landscapes_selforga[[n_l]][[j]] <- temp_landscape
    j <- j + 1
    n_sp <- sample(x = seq(3, 20), size = 1)
    n_rad <- sample(x = seq(round(90 / n_sp), round(250 / n_sp)), size = 1) #sample(x = seq(round(45/n_sp), round(150/n_sp)), size = 1)
    temp_landscape <- create_landscape_spots(
      width = l_size,
      height = l_size,
      n_spots = n_sp,
      spot_radius = n_rad,
      spot_radius_sd = sample(x = seq(3, 5), size = 1),
      radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.4),
      regular_spots = T #sample(x = c(T, F), size = 1)
    )
    landscape_name <- paste("landscape_spots_", n_l, "_", i, sep = "")
    temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
    training_landscapes_selforga[[n_l]][[j]] <- temp_landscape
    j <- j + 1
    temp_landscape <- create_landscape_labyrinth(
      width = l_size,
      height = l_size,
      frequency = runif(n = 1, min = 2.6, max = 3.2),
      veg_threshold = runif(n = 1, min = 0.48, max = 0.52),
      band_fuzziness = runif(n = 1, min = 0.06, max = 0.2),
      octaves = sample(x = seq(2, 4), size = 1)
    )
    landscape_name <- paste("landscape_labyrinth_", n_l, "_", i, sep = "")
    temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
    training_landscapes_selforga[[n_l]][[j]] <- temp_landscape
    j <- j + 1
    temp_landscape <- create_landscape_random(
      width = l_size,
      height = l_size,
      tree_prop = runif(n = 1, min = 0.01, max = 0.99)
    )
    temp_landscape$pattern <- "random"
    landscape_name <- paste("landscape_random_", n_l, "_", i, sep = "")
    temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
    training_landscapes_selforga[[n_l]][[j]] <- temp_landscape
  }
}

# check how many landscapes of each pattern were generated
table(purrr::map_chr(training_landscapes_selforga[[1]], ~ .x$pattern))

# look at first landscapes
plot_landscape_list(training_landscapes_selforga[[1]])

#----------------------------------------------------------------------------------------
# Approach 1: neural net trained on landscape metrics
#----------------------------------------------------------------------------------------

# make lists for different results (different number of training landscapes)
landscape_class_metrics_all <- list()
best_10_selforga <- list()
landscape_class_metrics_selforga <- list()
fig_metrics_selforga <- list()

# calculate landscape metrics at the class level
for (n_l in 1:n_models) {
  print(paste(
    "number of landscapes: ",
    length(selforga_types) * n_landscapes_per_type[n_l],
    sep = ""
  ))
  landscape_class_metrics_all[[n_l]] <- calculate_landscape_metrics(
    landscapes = training_landscapes_selforga[[n_l]],
    level = "class"
  )
  #focus on vegetation class only (no bare soil)
  metric_class <- 1
  landscape_class_metrics_selforga[[n_l]] <- landscape_class_metrics_all[[
    n_l
  ]] %>%
    filter(class == metric_class)

  #determine best 10 metrics to distinguish pattern types
  best_10_selforga[[n_l]] <- evaluate_landscape_metrics(
    metrics = landscape_class_metrics_selforga[[n_l]],
    metrics_number = 10,
    method = "kruskal_p"
  )

  # plot the 10 best metrics
  fig_metrics_selforga[[n_l]] <- plot_metrics(
    metrics = landscape_class_metrics_selforga[[n_l]],
    selected_metrics = best_10_selforga[[n_l]],
    force = TRUE
  )

  # save into different formats
  save_plot_multi(
    plot = fig_metrics_selforga[[n_l]],
    filename_base = paste(
      "fig_supp_selforga_metrics_",
      length(selforga_types) * n_landscapes_per_type[n_l],
      sep = ""
    ),
    directory = directory,
    width = 6,
    height = 4.5,
    dpi = 300
  )
}

#make lists for different results (different number of training landscapes)
model_selforga_metrics <- list()

# train the neural network model
for (n_l in 1:n_models) {
  print(paste(
    "number of landscapes: ",
    length(selforga_types) * n_landscapes_per_type[n_l],
    sep = ""
  ))
  # train a network
  model_selforga_metrics[[n_l]] <- train_nn_metrics(
    metrics = landscape_class_metrics_selforga[[n_l]],
    metrics_selected = best_10_selforga[[n_l]],
    cv_method = "k-fold"
  )
}

#----------------------------------------------------------------------------------------
# Approach 2: neural net trained on pixel input
#----------------------------------------------------------------------------------------

#set seed for Keras (needs to be done separately)
set_random_seed(123456)

model_selforga_pix <- list()

# train the neural network model
for (n_l in 1:n_models) {
  print(paste(
    "number of landscapes: ",
    length(selforga_types) * n_landscapes_per_type[n_l],
    sep = ""
  ))
  # train a model
  model_selforga_pix[[n_l]] <- train_nn_pixels(
    landscapes = training_landscapes_selforga[[n_l]],
    cv_method = "k-fold",
    learning_rate = 0.0001,
    epochs = 20,
  )
}


#----------------------------------------------------------------------------------------
# Apply the model to pictures from
# Meron et al. 2004: doi: 10.1016/S0960-0779(03)00049-3 and
# Mander et al. 2017: doi: 10.1098/rsos.160443
#----------------------------------------------------------------------------------------

#directory of pictures (all pictures within this folder will be used)
pic_dir <- paste(directory, "Pics/", sep = "") #folder name
pic_names <- list.files(pic_dir) #file names
pic_names
author_names <- c("mander", "meron")

# read in pictures automatically
# binarize pictures (differently for mander and meron)
pic_landscapes <- list()
for (i in 1:length(pic_names)) {
  # lower-case version for matching
  lname <- tolower(pic_names[i])
  # find which class is contained in the file name
  class_found <- NA_character_
  for (cl in selforga_types) {
    if (grepl(cl, lname)) {
      class_found <- cl
      break # stop after the first match
    }
  }
  # find which author is contained in the file name
  author <- NA_character_
  for (au in author_names) {
    if (grepl(au, lname)) {
      author <- au
      break # stop after the first match
    }
  }
  if (author == author_names[2]) {
    # read in file as image and make binary based on brown vs green
    img <- readPNG(paste(pic_dir, pic_names[i], sep = ""))
    R <- img[,, 1]
    G <- img[,, 2]
    B <- img[,, 3]
    V <- pmax(R, G, B)

    binary_img <- ifelse(
      (V < 0.1 | #very dark
        G > R * 1.02 & G > B * 1.02) | # normal green
        (G > R * 0.75 & G > B * 0.75 & V < 0.2), # dark green
      1,
      0
    )
  } else {
    # read in file as image and make binary based on brown vs green
    img <- readPNG(paste(pic_dir, pic_names[i], sep = ""))
    R <- img[,, 1]
    G <- img[,, 2]
    B <- img[,, 3]
    V <- pmax(R, G, B)

    binary_img <- ifelse(
      (V < 0.65),
      1,
      0
    )
  }

  # convert image to data frame
  x <- rep(1:ncol(binary_img), each = nrow(binary_img))
  y <- rep(nrow(binary_img):1, times = ncol(binary_img))
  fill <- as.vector(binary_img)
  df <- data.frame(x = x, y = y, fill = factor(fill))

  # convert to raster with specific colors
  cols <- c("#E5E59F", "#005C29")
  binary_raster <- as.raster(cols[binary_img + 1])

  # plot original image and binarized version
  pic_veg <- ggplot(df, aes(x, y)) +
    annotation_raster(img, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf) +
    theme_void()
  pic_bin <- ggplot(df, aes(x = x, y = y, fill = fill)) +
    geom_raster() +
    scale_fill_manual(values = cols) +
    theme_void() +
    theme(legend.position = "none")
  combined_pic <- pic_veg + pic_bin

  #save plots
  save_plot_multi(
    plot = pic_bin,
    filename_base = paste("fig_selforga_binary_", i, sep = ""),
    directory = directory,
    width = 5,
    height = 5,
    dpi = 300
  )
  save_plot_multi(
    plot = combined_pic,
    filename_base = paste("fig_selforga_both_", i, sep = ""),
    directory = directory,
    width = 5,
    height = 5,
    dpi = 300
  )

  # make raster out of binary image,
  # convert to landscape object and store
  test_raster <- terra::rast(binary_img)
  test_raster_l <- landscape(data = test_raster, name = "test raster")
  test_raster_l$pattern <- class_found #class type from above
  landscape_name <- paste("landscape_", i, sep = "")
  test_raster_l <- set_landscape_name(test_raster_l, landscape_name)
  pic_landscapes[[i]] <- test_raster_l
}

plot_landscape_list(pic_landscapes)

#-------------------------------------------------------------------
# apply the neural network models to the landscape object
#-------------------------------------------------------------------

pic_classification_metrics <- list()
pic_classification_pix <- list()

for (n_l in 1:n_models) {
  # a) metrics model
  pic_classification_metrics[[n_l]] <- apply_nn_metrics(
    landscapes = pic_landscapes,
    nn_model = model_selforga_metrics[[n_l]]
  )

  # b) pixel model
  pic_classification_pix[[n_l]] <- apply_nn_pixels(
    landscapes = pic_landscapes,
    nn_model = model_selforga_pix[[n_l]]
  )
}

# initialize result tables
result_table_metrics <- tibble(
  actual_class = pic_classification_metrics[[1]][[3]]
)
result_table_pix <- tibble(
  actual_class = pic_classification_metrics[[1]][[3]]
)

# add predicted values
for (i in 1:n_models) {
  result_table_metrics[[paste0("predicted_", pred_numbers[i])]] <-
    pic_classification_metrics[[i]][[4]]
  result_table_pix[[paste0("predicted_", pred_numbers[i])]] <-
    pic_classification_pix[[i]][[3]]
}

# look at predicted classifications
result_table_metrics
result_table_pix

#-------------------------------------------------------------------
# show landscapes and classification
#-------------------------------------------------------------------
# a) metrics model
plot_classified_landscapes(
  classification = pic_classification_metrics[[1]],
  landscapes = pic_landscapes,
  only_misclassified = FALSE,
  show_legend = F
)

# b) pixel model
for (n_l in 1:n_models) {
  pic_classification_pix[[n_l]]$actual_class <- pic_classification_metrics[[
    1
  ]]$actual_class
}

plot_classified_landscapes(
  classification = pic_classification_pix[[1]],
  landscapes = pic_landscapes,
  only_misclassified = FALSE,
  show_legend = F
)

#-------------------------------------------------------------------
# further analyses for metrics network
#-------------------------------------------------------------------
# compare metrics for training and test data

t <- 1
training_class_metrics_for_plot <- landscape_class_metrics_selforga[[t]] %>%
  filter(pattern == "gaps" | pattern == "labyrinth" | pattern == "spots")

ptraining <- plot_metrics(
  metrics = training_class_metrics_for_plot,
  selected_metrics = best_10_selforga[[t]]
)

# calculate landscape metrics at the class level
pic_landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = pic_landscapes,
  level = "class"
)
#filter only those metrics that match the best 10 (first and second set of pics)
pic_subset1 <- pic_landscape_class_metrics_all %>%
  filter(metric %in% best_10_selforga[[t]] & landscape_id %in% seq(1, 3)) %>%
  mutate(class = as.factor(class))
pic_subset2 <- pic_landscape_class_metrics_all %>%
  filter(metric %in% best_10_selforga[[t]] & landscape_id %in% seq(4, 6)) %>%
  mutate(class = as.factor(class))

#generate figure
fig_metrics <- ptraining +
  geom_point(
    data = pic_subset1,
    aes(x = pattern, y = value),
    size = 4,
    color = "skyblue", # first set of pictures
    shape = 15
  ) +
  geom_point(
    data = pic_subset2,
    aes(x = pattern, y = value),
    size = 4,
    color = "purple3", # second set of pictures
    shape = 17
  ) +
  theme(legend.position = "none")
fig_metrics

save_plot_multi(
  plot = fig_metrics,
  filename_base = paste(
    "fig_supp_selforga_pics_metrics_",
    length(selforga_types) * n_landscapes_per_type[t],
    sep = ""
  ),
  directory = directory,
  width = 8,
  height = 6,
  dpi = 300
)

#save.image(file = "usecase_2_everything.RData")
