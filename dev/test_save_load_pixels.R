library(spatPatClassifyR)

# Train and save a model --------------------------------------------------------
# Small, fast training run. 3 classes, few landscapes, few epochs.
set.seed(1)
train_landscapes <- create_landscapes(
  n = 12,
  patterns = c("random", "sharp", "diffuse")
)

model <- train_nn_pixels(
  landscapes = train_landscapes,
  cv_method = "none",
  epochs = 5,
  # writes .keras + _metadata.rds automatically (you can also omit .keras, it will be added)
  model_path = "test_pixel_model.keras"
)

# Read and apply a model ------------------------------------------------------

# Read in a saved model
# Reattach the keras object to the metadata list.
reloaded <- readRDS(metadata_file)
reloaded$model <- keras3::load_model(model_file)

# Apply to new landscapes
test_landscapes <- create_landscapes(
  n = 6,
  patterns = c("random", "sharp", "diffuse")
)

results <- apply_nn_pixels(
  landscapes = test_landscapes,
  nn_model = reloaded,
  return_performance = TRUE
)
