#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#install.packages("neuralnet")
library("neuralnet")
library("tidyverse")

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# only those types that refer to ecotones (or random)
ecotone_types = c(
  "random",
  "sharp",
  "diffuse",
  "curvyfingers",
  "clustered",
  "sine_bands"
)
n_ecotones <- length(ecotone_types)

#----------------------------------------------------------
#training landscapes and their metrics
#----------------------------------------------------------
#generate all training landscapes
training_landscapes <- create_training_landscapes(
  n = 30,
  seed = 42,
  patterns = ecotone_types
)

# calculate landscape metrics on the landscape level
landscape_metrics <- calculate_landscape_metrics(
  ecotone_landscapes,
  level = "landscape"
)

# find the 10 best metrics based on coefficient of variation
best_10 <- evaluate_landscape_metrics(
  calculated_metrics = landscape_metrics,
  method = "lin_mod_r2",
  metrics_number = 10
)

#----------------------------------------------------------
#test landscapes and their metrics (only 10 best)
#----------------------------------------------------------
test_landscapes <- create_training_landscapes(
  n = 30,
  seed = 100,
  patterns = ecotone_types
)

# calculate selected landscape metrics on the landscape level
test_metrics <- calculate_landscape_metrics(
  test_landscapes,
  metrics = best_10,
  level = "landscape"
)


# train a network
model_ecotones_nn <- train_nn_neuralnet(
  metrics = test_metrics,
  metrics_selected = best_10,
  hidden_layers = c(5,5),
  seed = 42
)

# look at the model object
model_ecotones_nn
plot(model_ecotones_nn,rep = "best")

#--------------------------------------------------------------------
# Test neural network model
#--------------------------------------------------------------------

test_nn_neuralnet(
  test_metrics = test_metrics,
  metrics_selected = best_10,
  nn_model = model_ecotones_nn
)

