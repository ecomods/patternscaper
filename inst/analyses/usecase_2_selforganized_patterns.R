# -------------------------------------------------------------------
# Apply the model to pictures from
# Meron et al. 2004: doi:10.1016/S0960-0779(03)00049-3
# -------------------------------------------------------------------

devtools::load_all()
library(ggplot2)
library(png)
library(magick)
library(colorspace)
library(raster)

#for reproducibility
set.seed(321)

directory <- "inst/analyses/selfOrga_results_class/"
result_figs <- "inst/analyses/pics_for_paper/"

#pattern types to be distinguished
selforga_types = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)

#plotting for manuscript
landscapes_manuscript <- list()
landscapes_manuscript[[1]]  <- create_landscape_random(
  tree_prop = 0.05
)
landscapes_manuscript[[1]]$pattern <- "bare"
landscapes_manuscript[[2]] <- create_landscape_spots(
  n_spots = 5,
  spot_radius = 18,
  noise_radius_sd = 3,
  radius_noise_fraction = 0.4,
  regular_spots = T
)
landscapes_manuscript[[3]]  <- create_landscape_labyrinth(
  frequency = 4,
  veg_threshold = 0.6,
  band_fuzziness = 0.02,
  octaves = 6
)
landscapes_manuscript[[4]] <- create_landscape_gaps(
  n_spots = 3,
  spot_radius = 15,
  noise_radius_sd = 5,
  radius_noise_fraction = 0.5,
  regular_spots = T
)
landscapes_manuscript[[5]] <- create_landscape_random(
  tree_prop = 0.9
)
landscapes_manuscript[[5]]$pattern <- "dense"

fig_sub_letter <- c("a","b","c","d","e")
for(i in 1:5){
  landscapes_manuscript[[i]]$pattern <- paste("(", fig_sub_letter[i], ") ", landscapes_manuscript[[i]]$pattern,sep="")
}

fig_pattern_selforga <- plot_landscape_list(landscapes_manuscript,ncol=5,show_legend=F)

ggsave(
  filename = paste(
    result_figs,"fig_selforga",
    ".jpg",
    sep = ""
  ),
  plot = fig_pattern_selforga,
  width = 8,
  height = 2,
  dpi = 300
)


#for reproducibility
set.seed(321)


#create new landscapes for training (20 of each type)
training_landscapes <- list()
for (i in 1:20) {
  j <- (i - 1) * 5 + 1
  temp_landscape <- create_landscape_gaps(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(20, 25), size = 1),
    noise_radius_sd = sample(x = seq(3, 8), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = sample(x=c(T,F), size = 1)
  )
  plot_landscape(temp_landscape)
  landscape_name <- paste("landscape_gaps_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_spots(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    n_spots = sample(x = seq(3, 5), size = 1),
    spot_radius = sample(x = seq(20, 25), size = 1),
    noise_radius_sd = sample(x = seq(3, 8), size = 1),
    radius_noise_fraction = runif(n = 1, min = 0.05, max = 0.6),
    regular_spots = sample(x=c(T,F), size = 1)
  )
  landscape_name <- paste("landscape_spots_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  wh <- sample(seq(120, 150), 1)
  temp_landscape <- create_landscape_labyrinth(
    width = wh,
    height = wh,
    frequency = runif(n = 1, min = 1, max = 10) * wh / 100,
    veg_threshold = runif(n = 1, min = 0.5, max = 0.7),
    band_fuzziness = runif(n = 1, min = 0, max = 0.005),
    octaves = sample(x = seq(1, 5), size = 1)
  )
  landscape_name <- paste("landscape_labyrinth_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    tree_prop = runif(n = 1, min = 0.01, max = 0.2)
  )
  temp_landscape$pattern <- "bare"
  landscape_name <- paste("landscape_bare_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j + 1
  temp_landscape <- create_landscape_random(
    width = sample(x = seq(120, 150), size = 1),
    height = sample(x = seq(120, 150), size = 1),
    tree_prop = runif(n = 1, min = 0.8, max = 0.99)
  )
  temp_landscape$pattern <- "dense"
  landscape_name <- paste("landscape_dense_", i, sep = "")
  temp_landscape <- set_landscape_name(temp_landscape, landscape_name)
  training_landscapes[[j]] <- temp_landscape
}

# check how many landscapes of each pattern were generated
table(purrr::map_chr(training_landscapes, ~ .x$pattern))

# calculate landscape metrics at the class level
landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = training_landscapes,
  level = "class"
)

#focus on vegetation class only
metric_class <- 1
landscape_class_metrics <- landscape_class_metrics_all %>%
  filter(class == metric_class)

#determine best 10 metrics to distinguish pattern types
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)
best_10



#--------------------------------------------------------------------
# Train neural network with landscapes metrics
#--------------------------------------------------------------------

# train a network
model_selforga_pics <- train_nn_metrics(
  metrics = landscape_class_metrics,
  metrics_selected = best_10,
  cv_method = "k-fold"
)

# look at the model object
model_selforga_pics$performance$accuracy

#--------------------------------------------------------------------
# Read in pictures and evaluate them
#--------------------------------------------------------------------

pic_dir <- paste(directory,"Pics/",sep="") #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

author_names <- c("mander","meron")

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

  if(author == author_names[2]){
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

#  combined_pic

  # save plots
  ggsave(
    filename = paste(
      result_figs,"fig_selforga_binary_",
      i,
      ".jpg",
      sep = ""
    ),
    plot = pic_bin,
    width = 5,
    height = 5,
    dpi = 300
  )
  ggsave(
    filename = paste(
      result_figs,"fig_selforga_both_",
      i,
      ".jpg",
      sep = ""
    ),
    plot = combined_pic,
    width = 10,
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
pic_classification <- apply_nn_metrics(
  landscapes = pic_landscapes,
  nn_model = model_selforga_pics
)

pic_classification

#show landscapes that are not classified correctly
plot_classified_landscapes(
  classification = pic_classification,
  landscapes = pic_landscapes,
  only_misclassified = FALSE
)

#compare metrics for training and test data
training_class_metrics_for_plot <- landscape_class_metrics %>%
  filter(pattern == "gaps" | pattern == "labyrinth" | pattern == "spots")

ptraining <- plot_metrics(
  metrics = training_class_metrics_for_plot,
  selected_metrics = best_10
)

# calculate landscape metrics at the class level
pic_landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = pic_landscapes,
  level = "class"
)
#filter only those metrics that match the best 10
pic_subset1 <- pic_landscape_class_metrics_all %>%
  filter(metric %in% best_10 & landscape_id %in% seq(1,3)) %>%
  mutate(class = as.factor(class))
pic_subset2 <- pic_landscape_class_metrics_all %>%
  filter(metric %in% best_10 & landscape_id %in% seq(4,6)) %>%
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
  )  +
  theme(legend.position = "none")
ggsave(
  filename = paste(
    result_figs,"supp_fig_metrics_selforga",
    i,
    ".jpg",
    sep = ""
  ),
  plot = fig_metrics,
  width = 8,
  height = 6,
  dpi = 300
)
