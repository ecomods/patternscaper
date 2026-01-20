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
# for reproducibility
set.seed(321)
#directory <- "inst/analyses/selfOrga_results_class/"
directory <- "inst/analyses/pics_for_paper/"
#use help function to plot different formats
source("inst/analyses/functions/plot_different_formats.R")

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# pattern types to be distinguished
selforga_types = c(
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

#--------------------------------------------------------------------
# Generate training and testing landscapes
#--------------------------------------------------------------------

# for reproducibility
set.seed(321)

#size of the landscapes - adjusted to size of pictures
l_size <- 140

# create new landscapes for training (20 of each type)
training_landscapes_selforga <- list()
for (i in 1:20) {
  j <- (i - 1) * 5 + 1
  temp_landscape <- create_landscape_gaps(
    width = l_size,
    height = l_size,
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(15, 20), size = 1),
    spot_radius_sd = sample(x = seq(3, 5), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = T #sample(x = c(T, F), size = 1)
  )
  landscape_name <- paste("landscape_gaps_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_spots(
    width = l_size,
    height = l_size,
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(15, 20), size = 1),
    spot_radius_sd = sample(x = seq(3, 5), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = T #sample(x = c(T, F), size = 1)
  )
  landscape_name <- paste("landscape_spots_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_labyrinth(
    width = l_size,
    height = l_size,
    frequency = runif(n = 1, min = 2.6, max = 3.2),
    veg_threshold = runif(n = 1, min = 0.48, max = 0.52),
    band_fuzziness = runif(n = 1, min = 0.06, max = 0.25),
    octaves = sample(x = seq(2, 3), size = 1)
  )
  landscape_name <- paste("landscape_labyrinth_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = l_size,
    height = l_size,
    tree_prop = runif(n = 1, min = 0.01, max = 0.2)
  )
  temp_landscape$pattern <- "bare"
  landscape_name <- paste("landscape_bare_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = l_size,
    height = l_size,
    tree_prop = runif(n = 1, min = 0.8, max = 0.99)
  )
  temp_landscape$pattern <- "dense"
  landscape_name <- paste("landscape_dense_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes_selforga[[j]] <- temp_landscape
}

# check how many landscapes of each pattern were generated
table(purrr::map_chr(training_landscapes_selforga, ~ .x$pattern))

# look at first 36 landscapes
plot_landscape_list(training_landscapes_selforga)

# generate test landscapes
test_landscapes_selforga <- list()
for (i in 1:20) {
  j <- (i - 1) * 5 + 1
  temp_landscape <- create_landscape_gaps(
    width = l_size,
    height = l_size,
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(15, 20), size = 1),
    spot_radius_sd = sample(x = seq(3, 5), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = T #sample(x = c(T, F), size = 1)
  )
  landscape_name <- paste("landscape_gaps_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  test_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  l_size <- 140 #sample(x = seq(120, 150), size = 1)
  temp_landscape <- create_landscape_spots(
    width = l_size,
    height = l_size,
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(15, 20), size = 1),
    spot_radius_sd = sample(x = seq(3, 5), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = T #sample(x = c(T, F), size = 1)
  )
  landscape_name <- paste("landscape_spots_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  test_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_labyrinth(
    width = l_size,
    height = l_size,
    frequency = runif(n = 1, min = 2.6, max = 3.2),
    veg_threshold = runif(n = 1, min = 0.48, max = 0.52),
    band_fuzziness = runif(n = 1, min = 0.06, max = 0.25),
    octaves = sample(x = seq(2, 3), size = 1)
  )
  landscape_name <- paste("landscape_labyrinth_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  test_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = l_size,
    height = l_size,
    tree_prop = runif(n = 1, min = 0.01, max = 0.2)
  )
  temp_landscape$pattern <- "bare"
  landscape_name <- paste("landscape_bare_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  test_landscapes_selforga[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = l_size,
    height = l_size,
    tree_prop = runif(n = 1, min = 0.8, max = 0.99)
  )
  temp_landscape$pattern <- "dense"
  landscape_name <- paste("landscape_dense_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  test_landscapes_selforga[[j]] <- temp_landscape
}

#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Approach 1: neural net trained on landscape metrics
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Calculate landscapes metrics and determine best ones
#--------------------------------------------------------------------

# calculate landscape metrics at the class level
landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = training_landscapes_selforga,
  level = "class"
)

#focus on vegetation class only
metric_class <- 1
landscape_class_metrics_selforga <- landscape_class_metrics_all %>%
  filter(class == metric_class)

#determine best 10 metrics to distinguish pattern types
best_10_selforga <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics_selforga,
  metrics_number = 10,
  method = "kruskal_p"
)
best_10_selforga

# plot the 10 best metrics
fig_metrics_selforga <- plot_metrics(
  metrics = landscape_class_metrics_selforga,
  selected_metrics = best_10_selforga,
  force = TRUE
)
fig_metrics_selforga

# save into different formats
save_plot_multi(
  plot = fig_metrics_selforga,
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
model_selforga_metrics <- train_nn_metrics(
  metrics = landscape_class_metrics_selforga,
  metrics_selected = best_10_selforga,
  cv_method = "k-fold"
)

# look at the model object
model_selforga_metrics$performance$accuracy

# test model on new data
validation_results_selforga_lm <- apply_nn_metrics(
  landscapes = test_landscapes_selforga,
  nn_model = model_selforga_metrics,
  return_performance = TRUE
)

# accuracy of the neural net for the test data
validation_results_selforga_lm$performance$accuracy

#plot_classification_results(validation_results_selforga_lm)
plot_classified_landscapes(
  validation_results_selforga_lm$predictions,
  test_landscapes_selforga,
  only_misclassified = T
)
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Approach 2: neural net trained on pixel input
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------

#--------------------------------------------------------------------
# Train neural network with the input data itself
#--------------------------------------------------------------------

#save.image(file="usecase_2_all_data.RData")

# train a model
model_selforga_pix <- train_nn_landscapes(
  landscapes = training_landscapes_selforga,
  cv_method = "k-fold",
  cv_folds = 5,
  epochs = 100,
  batch_size = 8,
  dropout_rate = 0.4
)

#does not work!

# check the model accuracy
model_selforga_pix$performance$accuracy

##################################################
##################stopped here####################
##################################################


#--------------------------------------------------------------------
# Read in pictures and evaluate them
#--------------------------------------------------------------------


# -------------------------------------------------------------------
# Apply the model to pictures from
# Meron et al. 2004: doi:10.1016/S0960-0779(03)00049-3
# -------------------------------------------------------------------
pic_dir <- paste(directory, "Pics/", sep = "") #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

author_names <- c("mander", "meron")

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
    filename_base = paste("fig_selforga_binary_",i,sep=""),
    directory = directory,
    width = 5,
    height = 5,
    dpi = 300
  )
  save_plot_multi(
    plot = combined_pic,
    filename_base = paste("fig_selforga_both_",i,sep=""),
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

# apply the neural network model to the landscape object
pic_classification_metrics <- apply_nn_metrics(
  landscapes = pic_landscapes,
  nn_model = model_selforga_metrics
)

pic_classification_metrics

#show landscapes that are not classified correctly
plot_classified_landscapes(
  classification = pic_classification_metrics,
  landscapes = pic_landscapes,
  only_misclassified = FALSE
)

#compare metrics for training and test data
training_class_metrics_for_plot <- landscape_class_metrics_selforga %>%
  filter(pattern == "gaps" | pattern == "labyrinth" | pattern == "spots")

ptraining <- plot_metrics(
  metrics = training_class_metrics_for_plot,
  selected_metrics = best_10_selforga
)

# calculate landscape metrics at the class level
pic_landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = pic_landscapes,
  level = "class"
)
#filter only those metrics that match the best 10
pic_subset1 <- pic_landscape_class_metrics_all %>%
  filter(metric %in% best_10_selforga & landscape_id %in% seq(1, 3)) %>%
  mutate(class = as.factor(class))
pic_subset2 <- pic_landscape_class_metrics_all %>%
  filter(metric %in% best_10_selforga & landscape_id %in% seq(4, 6)) %>%
  mutate(class = as.factor(class))

#generate figure
fig_metrics <- ptraining +
  geom_point(
    data = pic_subset1,
    aes(x = pattern, y = value),
    size = 2,
    color = "royalblue2",
    shape = 15
  ) +
  geom_point(
    data = pic_subset2,
    aes(x = pattern, y = value),
    size = 2,
    color = "purple3",
    shape = 15
  ) +
  theme(legend.position = "none")
fig_metrics
ggsave(
  filename = paste(
    result_figs,
    "supp_fig_metrics_selforga",
    i,
    ".jpg",
    sep = ""
  ),
  plot = fig_metrics,
  width = 8,
  height = 6,
  dpi = 300
)

#save.image(file="usecase_2_all_data.RData")