# -------------------------------------------------------------------
# Apply the model to pictures
# -------------------------------------------------------------------

devtools::load_all()
library(ggplot2)
library(png)
library(magick)
library(colorspace)
library(raster)

set.seed(321)
selforga_types = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)

#create new landscapes for training (20 of each type)
training_landscapes <- list()
for(i in 1:20){
  j <- (i-1)*5+1
  temp_landscape <- create_landscape_gaps(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    n_spots = sample(x=seq(3,5),size=1),
    spot_radius = sample(x=seq(20,25),size=1),
    noise_radius_sd = sample(x=seq(3,8),size=1),
    radius_noise_fraction = runif(n=1,min=0.05,max=0.6),
    regular_spots = T
  )
  plot_landscape(temp_landscape)
  landscape_name <-  paste("landscape_gaps_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j+1
  temp_landscape <- create_landscape_spots(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    n_spots = sample(x=seq(3,5),size=1),
    spot_radius = sample(x=seq(20,25),size=1),
    noise_radius_sd = sample(x=seq(3,8),size=1),
    radius_noise_fraction = runif(n=1,min=0.05,max=0.6),
    regular_spots = T
  )
  landscape_name <-  paste("landscape_spots_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j+1
  wh <- sample(seq(120,150), 1)
  temp_landscape <- create_landscape_labyrinth(
    width = wh,
    height = wh,
    frequency = runif(n=1,min=5,max=10) * wh / 100,
    veg_threshold = runif(n=1,min=0.6, max=0.7),
    band_fuzziness = runif(n=1,min=0.0001,max=0.005),
    octaves = sample(x=seq(3,5),size=1)
  )
  plot_landscape(temp_landscape)
  landscape_name <-  paste("landscape_labyrinth_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j+1
  temp_landscape <- create_landscape_random(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    tree_prop = runif(n=1,min=0.01,max=0.2)
  )
  temp_landscape$pattern <- "bare"
  landscape_name <-  paste("landscape_bare_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  training_landscapes[[j]] <- temp_landscape
  j <- j+1
  temp_landscape <- create_landscape_random(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    tree_prop = runif(n=1,min=0.8,max=0.99)
  )
  temp_landscape$pattern <- "dense"
  landscape_name <-  paste("landscape_dense_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  training_landscapes[[j]] <- temp_landscape
}

# check how many landscapes of each pattern were generated
table(purrr::map_chr(training_landscapes, ~ .x$pattern))

# calculate landscape metrics at the class level
landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = training_landscapes,
  level = "class"
)

#these are just for tests
landscape_class0_metrics <- landscape_class_metrics_all %>% filter(class == 0)
landscape_class1_metrics <- landscape_class_metrics_all %>% filter(class == 1)

# find the 10 best metrics
best_10_0 <- evaluate_landscape_metrics(
  metrics = landscape_class0_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)
best_10_1 <- evaluate_landscape_metrics(
  metrics = landscape_class1_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)
best_10_0
best_10_1
#--> we get slightly different metrics

#this is to use for further purposes
metric_class <- 1
landscape_class_metrics <- landscape_class_metrics_all %>% filter(class == metric_class)

best_10 <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)
#show example landscapes
plot_landscape_list(training_landscapes[1:5])

#--------------------------------------------------------------------
# Train neural network with landscapes metrics
#--------------------------------------------------------------------

# train a network
# use k-fold cross-validation with 3 folds
# warning will tell you that folds need to be reduced to 2
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

pic_dir <- "inst/examples/SelfOrga_Results_Class/Pics/" #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

list_pic_results <- list()
pic_landscapes <- list()
list_pic_types <- list()

for(i in 1:length(pic_names)){
  # lower-case version for matching
  lname <- tolower(pic_names[i])
  # find which class is contained in the filename
  class_found <- NA_character_
  for (cl in selforga_types) {
    if (grepl(cl, lname)) {
      class_found <- cl
      break               # stop after the first match
    }
  }
  list_pic_types[[i]] <- class_found
  # read in file as image and make binary based on brown vs green
  img <- readPNG(paste(pic_dir,pic_names[i],sep=""))
  R <- img[,,1]
  G <- img[,,2]
  B <- img[,,3]
  V <- pmax(R, G, B)
  binary_img <- ifelse(
    (V < 0.1 |   #very dark
       G > R*1.02 & G > B*1.02) |        # normal green
      (G > R*0.75 & G > B*0.75 & V < 0.2),  # dark green
    1, 0
  )

  # convert image to data frame
  x <- rep(1:ncol(binary_img), each = nrow(binary_img))
  y <- rep(nrow(binary_img):1, times = ncol(binary_img))
  fill <- as.vector(binary_img)
  df <- data.frame(x=x, y=y, fill=factor(fill))

  # convert to raster with specific colours
  cols <- c("#E5E59F", "#005C29")
  binary_raster <- as.raster(cols[binary_img + 1])

  # plot original image and binarized version
  pic_veg <- ggplot(df, aes(x, y)) +
    annotation_raster(img, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf) +
    theme_void()
  pic_bin <- ggplot(df, aes(x=x, y=y, fill=fill)) +
    geom_raster() +
    scale_fill_manual(values=cols) +
    theme_void() +
    theme(legend.position="none")
  combined_pic <- pic_veg+pic_bin

  # save plot
  ggsave(
    filename = paste0("inst/examples/SelfOrga_Results_Class/Picture_",pic_names[i],".jpg",sep=""),
    plot = combined_pic,
    width = 10,
    height = 5,
    dpi = 300
  )

  # make raster out of binary image,
  # convert to landscape object and store
  test_raster <- terra::rast(binary_img)
  test_raster_l <- landscape(data = test_raster, name = "test raster")
#  test_raster_l$pattern <- class_found #class type from above
  landscape_name <-  paste("landscape_",i,sep="")
  test_raster_l <- set_landscape_name(test_raster_l,landscape_name)
  pic_landscapes[[i]] <- test_raster_l

  # apply the neural network model to the landscape object
  test_classification <- apply_nn_neuralnet(
    landscapes = test_raster_l,
    nn_model = model_selforga_pics
  )

  # store predicted class and performance
  list_pic_results[[i]] <- list(
    filename = pic_names[i],
    predicted = test_classification$predicted_class,
    confidence = test_classification$confidence
  )

}

list_pic_results
list_pic_types
pic_landscapes

for(i in 1:length(pic_names)){
  print(paste(list_pic_results[[i]]$filename,": ", list_pic_results[[i]]$predicted, " (",round(list_pic_results[[i]]$confidence,3),")",sep=""))
}

#compare metrics for training and test data

training_class_metrics_for_plot <- landscape_class_metrics %>% filter(pattern == "gaps" | pattern == "labyrinth" | pattern == "spots")

ptraining <- plot_metrics(
  metrics = training_class_metrics_for_plot,
  selected_metrics = best_10
)
#ptraining

pic_landscapes_copy <- pic_landscapes
for(i in 1:length(pic_names)){
  pic_landscapes_copy[[i]]$pattern <- list_pic_types[[i]]
}

# calculate landscape metrics at the class level
pic_landscape_class_metrics_all <- calculate_landscape_metrics(
  landscapes = pic_landscapes_copy,
  level = "class"
)
pic_landscape_class_metrics <- pic_landscape_class_metrics_all %>% filter(class == metric_class)
pic_subset <- pic_landscape_class_metrics %>%
  filter(metric %in% best_10) %>%
  mutate(class = as.factor(class))

ptraining +
  geom_point(
    data = pic_subset,
    aes(x = pattern, y = value),
    size = 2.5,
    color = "blue",
    shape = 16
  )

best_10
