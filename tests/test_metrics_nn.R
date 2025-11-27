#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

# ecotone types
selforganization_types = c(
  "bare",
  "spots",
  "labyrinth",
  "gaps",
  "dense"
)

metrics_choice <- c("coeffvar_all", "mean_groups", "fisher_score", "kruskal_p")
nmetrics_choice <- length(metrics_choice)

set.seed(12)

#----------------------------------------------------------
#Training landscapes and their metrics
#----------------------------------------------------------

test_landscapes <- create_training_landscapes(
  n = 100,
  patterns = selforganization_types
)
#--> lots of warnings, produces 100 landscapes

#same landscapes for different architectures of the neural net
training_landscapes <- create_training_landscapes(
  n = 100,
  patterns = selforganization_types
)
#--> lots of warnings, produces only 98 landscapes

# calculate landscape metrics on the class/landscape level
training_metrics_c <- calculate_landscape_metrics(
  training_landscapes,
  level = "class"
)
training_metrics_c <- training_metrics_c %>% filter(class == 0)

training_metrics_l <- calculate_landscape_metrics(
  training_landscapes,
  level = "landscape"
)

# find the best metrics
best_ones_c <- evaluate_landscape_metrics(
  metrics = training_metrics_c,
  method = metrics_choice[1],
  metrics_number = 10
)
best_ones_l <- evaluate_landscape_metrics(
  metrics = training_metrics_l,
  method = metrics_choice[1],
  metrics_number = 10
)

#----------------------------------------------------------
# Train neural network model
#----------------------------------------------------------

# train a network
model_neuralnet_c <- train_nn_metrics(
  metrics = training_metrics_c,
  metrics_selected = best_ones_c,
  hidden_layers = 1
)
model_neuralnet_l <- train_nn_metrics(
  metrics = training_metrics_l,
  metrics_selected = best_ones_l,
  hidden_layers = 1
)


#--------------------------------------------------------------------
# Test neural network model
#--------------------------------------------------------------------

validation_c <- apply_nn_metrics(
  landscapes = test_landscapes,
  nn_model = model_neuralnet_c
)
validation_l <- apply_nn_metrics(
  landscapes = test_landscapes,
  nn_model = model_neuralnet_l
)
model_neuralnet_c$model$model.list$variables
model_neuralnet_l$model$model.list$variables
