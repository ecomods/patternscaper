devtools::load_all()

# Get binarized images as variable pics_landscapes
source("inst/analyses/functions/binarize_images.R")

set.seed(12345)

training_landscapes <- create_training_landscapes(
  n = 800,
  patterns = c(
    "bare",
    "spots",
    "labyrinth",
    "gaps",
    "dense"
  ),
  width = 100,
  height = 100,
  add_rotation = TRUE
)

test_landscapes <- create_training_landscapes(
  n = 100,
  patterns = c(
    "bare",
    "spots",
    "labyrinth",
    "gaps",
    "dense"
  ),
  width = 100,
  height = 100
)

# Train a model
model <- train_nn_pixels(
  landscapes = training_landscapes,
  cv_method = "none",
  learning_rate = 0.001,
  epochs = 100
)

# Validate on the test landscapes
validation <- apply_nn_pixels(
  nn_model = model,
  landscape = test_landscapes,
  return_performance = TRUE
)

# Read in real pictures ------------------------------------------------------
plot_landscape_list(pics_landscapes, titles = "both")

# Apply the model to the pictures
picture_classification <- apply_nn_pixels(
  nn_model = model,
  landscape = pics_landscapes
)

#show landscapes that are not classified correctly
plot_classified_landscapes(
  classification = picture_classification,
  landscapes = pic_landscapes,
  only_misclassified = FALSE
)

# Save the classification results
write_csv(
  picture_classification,
  file = "inst/analyses/keras_analyses/results/selforg_from_pics_classification.csv"
)

plot_classified_landscapes(
  classification = picture_classification,
  landscapes = pics_landscapes
)
