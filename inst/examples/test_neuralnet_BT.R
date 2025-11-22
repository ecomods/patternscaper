#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

library("tidyverse")

# For reproducibility, you have to set the seed
set.seed(12345)

#https://www.datacamp.com/tutorial/neural-network-models-r

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

ntraining <- c(50, 100, 200, 300)
nlayers <- list(c(8), c(10, 8), c(9, 8, 7))


# only those types that refer to ecotones (or random)
selforganization_types = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)
n_so_types <- length(selforganization_types)

#----------------------------------------------------------
#training landscapes and their metrics
#----------------------------------------------------------
#generate all training landscapes
training_landscapes <- create_training_landscapes(
  n = 100, #ntraining[1],
  patterns = selforganization_types
)

#plot_landscape_list(training_landscapes)

# calculate landscape metrics on the landscape level
training_metrics <- calculate_landscape_metrics(
  training_landscapes,
  level = "class"
)

training_metrics <- training_metrics %>% filter(class == 0)

# find the 10 best metrics based on coefficient of variation
best_10 <- evaluate_landscape_metrics(
  metrics = training_metrics,
  method = "coeffvar_all",
  metrics_number = 10,
#  correlation_threshold = 0.95,
#  verbose=T
)

best_10
#best_10_plus <- c(best_10,"shape_mn")
#best_10_plus

#----------------------------------------------------------
# Train neural network model
#----------------------------------------------------------

# train a network (by default running with 5-fold cross-validation)
#rule of thumb: number of neurons in hidden layers between input and output layer
model_neuralnet <- train_nn_neuralnet(
  metrics = training_metrics,
  metrics_selected = best_10,
  hidden_layers = c(8,8)#nlayers[[2]],
#  cv_method = "none"
)

# look at the model object
#model_neuralnet

#plot(model_neuralnet$model, rep = "best")

# Plot the wrong landscapes from the cross-validation
#plot_classified_landscapes(
#  classification = model_neuralnet$performance$validation_results,
#  landscapes = training_landscapes,
#  only_misclassified = F
#)

#----------------------------------------------------------
#test landscapes and their metrics (only 10 best)
#----------------------------------------------------------
test_landscapes <- create_training_landscapes(
  n = 100,
  patterns = selforganization_types
)

#--------------------------------------------------------------------
# Test neural network model
#--------------------------------------------------------------------

validation <- apply_nn_neuralnet(
  landscapes = test_landscapes,
  nn_model = model_neuralnet
)

# Check out the info for validation:
validation

# Plot misclassified results
plot_classified_landscapes(
  classification = validation$predictions,
  landscapes = test_landscapes,
  only_misclassified = TRUE
)


#----------------------------------------------------------
# Train neural network model with two hidden layers
#----------------------------------------------------------

# train a network (by default running with 5-fold cross-validation)
#rule of thumb: number of neurons in hidden layers between input and output layer
model_neuralnet2 <- train_nn_neuralnet(
  metrics = training_metrics,
  metrics_selected = best,
  hidden_layers = c(10, 8),
  seed = 42
)

# look at the model object
#model_neuralnet2

plot(model_neuralnet2$model, rep = "best")

# Plot the wrong landscapes from the cross-validation
plot_nn_classification_landscapes(
  classification = model_neuralnet2$performance$validation_results,
  landscapes = training_landscapes,
  only_misclassified = TRUE
)

#--------------------------------------------------------------------
# Test neural network model
#--------------------------------------------------------------------

validation2 <- apply_nn_neuralnet(
  landscapes = test_landscapes,
  nn_model = model_neuralnet2
)

# Check out the info for validation:
validation2

# Plot misclassified results
plot_nn_classification_landscapes(
  classification = validation2$predictions,
  landscapes = test_landscapes,
  only_misclassified = TRUE
)


validation$performance$per_class_metrics
validation2$performance$per_class_metrics

validation$performance$confusion_matrix
validation2$performance$confusion_matrix

validation$performance$accuracy
validation2$performance$accuracy


#--------------------------------------------------------------------
# Test picture
#--------------------------------------------------------------------

# Read in the satellite image
pic_dir <- "inst/examples/Ecotone/" #folder name
pic_names <- list.files(pic_dir) #file names
pic_names

i <- 1
image <- terra::rast(paste(pic_dir, pic_names[i], sep = ""))
# If it's a multi-band image
band1 <- image[[1]]
# Apply threshold
binary_class <- band1 < 70 #this parameter determines the sensitivity towards
#classification as vegetation - the higher the more vegetation
test_matrix <- as.matrix(binary_class, wide = TRUE)
test_raster <- terra::rast(test_matrix)

#test plotting of binary categorization
par(mfrow = c(1, 2), pty = "s")
raster::plot(
  raster::flip(band1),
  col = terrain.colors(25),
  main = "Initial Landscape"
)
raster::plot(
  raster::flip(test_raster),
  col = c(terrain.colors(25)[25], terrain.colors(25)[1]),
  main = "Binary Landscape"
)
par(mfrow = c(1, 1))

# Bring the test raster in the right format for package functions
test_raster_l <- landscape(data = test_raster, name = "test raster")

# apply the neural network model to the picture
test_classification <- apply_nn_neuralnet(
  landscapes = test_raster_l,
  nn_model = model_neuralnet
)
