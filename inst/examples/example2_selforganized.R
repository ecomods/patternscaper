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
  nn_model = model_selforga_lm
)

validation_results_selforga_lm

#show landscapes that are not classified correctly
plot_classified_landscapes(
  classification = validation_results_selforga_lm$predictions,
  landscapes = test_landscapes_selforga,
  only_misclassified = TRUE
)

# -------------------------------------------------------------------
# Apply the model to pictures
# -------------------------------------------------------------------

#create new, smaller landscapes
set.seed(321)
small_landscapes <- list()
for(i in 1:20){
  j <- (i-1)*5+1
  temp_landscape <- create_landscape_gaps(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    n_spots = sample(x=seq(3,5),size=1),
    spot_radius = sample(x=seq(20,25),size=1),
    noise_radius_sd = 3,
    radius_noise_fraction = 0.1,
    regular_spots = T
  )
  plot_landscape(temp_landscape)
  landscape_name <-  paste("landscape_gaps_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  small_landscapes[[j]] <- temp_landscape
  j <- j+1
  temp_landscape <- create_landscape_spots(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    n_spots = sample(x=seq(3,5),size=1),
    spot_radius = sample(x=seq(20,25),size=1),
    noise_radius_sd = 3,
    radius_noise_fraction = 0.1,
    regular_spots = T
  )
  landscape_name <-  paste("landscape_spots_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  small_landscapes[[j]] <- temp_landscape
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
  small_landscapes[[j]] <- temp_landscape
  j <- j+1
  temp_landscape <- create_landscape_random(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    tree_prop = runif(n=1,min=0.01,max=0.2)
  )
  temp_landscape$pattern <- "bare"
  landscape_name <-  paste("landscape_bare_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  small_landscapes[[j]] <- temp_landscape
  j <- j+1
  temp_landscape <- create_landscape_random(
    width = sample(x=seq(120,150),size=1),
    height = sample(x=seq(120,150),size=1),
    tree_prop = runif(n=1,min=0.8,max=0.99)
  )
  temp_landscape$pattern <- "dense"
  landscape_name <-  paste("landscape_dense_",i,sep="")
  temp_landscape <- set_landscape_name(temp_landscape,landscape_name)
  small_landscapes[[j]] <- temp_landscape
}

# check how many landscapes of each pattern were generated
table(purrr::map_chr(small_landscapes, ~ .x$pattern))

# calculate landscape metrics at the class level
landscape_class_metrics <- calculate_landscape_metrics(
  landscapes = small_landscapes,
  level = "class"
)
landscape_class_metrics <- landscape_class_metrics %>% filter(class == 0)


# find the 10 best metrics
best_10 <- evaluate_landscape_metrics(
  metrics = landscape_class_metrics,
  metrics_number = 10,
  method = "kruskal_p"
)

#show example landscapes
plot_landscape_list(small_landscapes[1:5])

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


library(png)
library(magick)
library(colorspace)
library(raster)

pic_dir <- "inst/examples/SelfOrga_Results_Class/Pics/" #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

list_pic_results <- list()

for(i in 1:length(pic_names)){
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

  x <- rep(1:ncol(binary_img), each = nrow(binary_img))
  y <- rep(nrow(binary_img):1, times = ncol(binary_img))
  fill <- as.vector(binary_img)
  df <- data.frame(x=x, y=y, fill=factor(fill))

  cols <- c("#E5E59F", "#005C29")
  binary_raster <- as.raster(cols[binary_img + 1])


  pic_veg <- ggplot(df, aes(x, y)) +
    annotation_raster(img, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf) +
    theme_void()

  pic_bin <- ggplot(df, aes(x=x, y=y, fill=fill)) +
    geom_raster() +
    scale_fill_manual(values=cols) +
    theme_void() +
    theme(legend.position="none")


  combined_pic <- pic_veg+pic_bin

  #combined_pic

  ggsave(
    filename = paste0("inst/examples/SelfOrga_Results_Class/Picture_",pic_names[i],".jpg",sep=""),
    plot = combined_pic,
    width = 10,
    height = 5,
    dpi = 300
  )

  test_raster <- terra::rast(binary_img)
  test_raster_l <- landscape(data = test_raster, name = "test raster")

  #plot_landscape(test_raster_l)

  # apply the neural network model to the picture
  test_classification <- apply_nn_neuralnet(
    landscapes = test_raster_l,
    nn_model = model_selforga_pics
  )
  test_classification$predicted_class
  test_classification$confidence

  list_pic_results[[i]] <- list(
    filename = pic_names[i],
    predicted = test_classification$predicted_class,
    confidence = test_classification$confidence
  )

}

list_pic_results
