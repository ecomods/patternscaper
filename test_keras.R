# Check python installation (should be 3.10 because later does not support tensorflow)
library(reticulate)
py_discover_config()
# Install if not already installed
# install.packages("keras")
library(keras)

# Install TensorFlow backend (only needed once)
# Also creates a venv r-tensorflow
# install_keras()

# Activate venv with tensorflow installed
# otherwise a version of python is used that does not have tensorflow installed
use_virtualenv("r-tensorflow", required = TRUE)


# Tutorial -----------------------------
fashion_mnist <- dataset_fashion_mnist()

c(train_images, train_labels) %<-% fashion_mnist$train
c(test_images, test_labels) %<-% fashion_mnist$test

class_names <- c(
  "T-shirt/top",
  "Trouser",
  "Pullover",
  "Dress",
  "Coat",
  "Sandal",
  "Shirt",
  "Sneaker",
  "Bag",
  "Ankle boot"
)

# Plot a test image
library(tidyr)
library(ggplot2)

image_1 <- as.data.frame(train_images[1, , ])
colnames(image_1) <- seq_len(ncol(image_1))
image_1$y <- seq_len(nrow(image_1))
image_1 <- gather(image_1, "x", "value", -y)
image_1$x <- as.integer(image_1$x)

ggplot(image_1, aes(x = x, y = y, fill = value)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "black", na.value = NA) +
  scale_y_reverse() +
  theme_minimal() +
  theme(panel.grid = element_blank()) +
  theme(aspect.ratio = 1) +
  xlab("") +
  ylab("")

# Convert to valus between 0 and 1
train_images <- train_images / 255
test_images <- test_images / 255

par(mfcol = c(5, 5))
par(mar = c(0, 0, 1.5, 0), xaxs = "i", yaxs = "i")
for (i in 1:25) {
  img <- train_images[i, , ]
  img <- t(apply(img, 2, rev))
  image(1:28, 1:28, img,
    col = gray((0:255) / 255), xaxt = "n", yaxt = "n",
    main = paste(class_names[train_labels[i] + 1])
  )
}

# Build model
model <- keras_model_sequential()
model %>%
  layer_flatten(input_shape = c(28, 28)) %>%
  layer_dense(units = 128, activation = "relu") %>%
  layer_dense(units = 10, activation = "softmax")

model %>% compile(
  optimizer = "adam",
  loss = "sparse_categorical_crossentropy",
  metrics = c("accuracy")
)
model %>% fit(train_images, train_labels, epochs = 5, verbose = 2)

# Evaluate the accuracy
score <- model %>% evaluate(test_images, test_labels, verbose = 0)

cat("Test loss:", score["loss"], "\n")
cat("Test accuracy:", score["accuracy"], "\n")

# Make predictions
predictions <- model %>% predict(test_images)
# plot some predictions
par(mfcol = c(5, 5))
par(mar = c(0, 0, 1.5, 0), xaxs = "i", yaxs = "i")
for (i in 1:25) {
  img <- test_images[i, , ]
  img <- t(apply(img, 2, rev))
  # subtract 1 as labels go from 0 to 9
  predicted_label <- which.max(predictions[i, ]) - 1
  true_label <- test_labels[i]
  if (predicted_label == true_label) {
    color <- "#008800"
  } else {
    color <- "#bb0000"
  }
  image(1:28, 1:28, img,
    col = gray((0:255) / 255), xaxt = "n", yaxt = "n",
    main = paste0(
      class_names[predicted_label + 1], " (",
      class_names[true_label + 1], ")"
    ),
    col.main = color
  )
}
# predict for a single image (error for some reason)
# Grab an image from the test dataset
# take care to keep the batch dimension, as this is expected by the model
img <- test_images[1, , , drop = FALSE]
dim(img)
prediction_single <- model %>% predict(img)
predictions <- model %>% predict(img)

# Test for our images ----------------------------------------------------------
devtools::load_all()

training_landscapes <- generate_training_landscapes(
  seed = 42,
  n = 120,
  add_rotation = TRUE
)

str(training_landscapes)

training_labels <- purrr::map_chr(training_landscapes, ~ .x$type)
training_plots <- purrr::map(training_landscapes, ~ .x$landscape)

# Convert all plots to arrays
training_arrays <- lapply(training_plots, function(r) {
  terra::as.array(r)
})

# separate into training and validation data
labels_train <- training_labels[1:100]
labels_val <- training_labels[101:120]
training_plots_train <- training_arrays[1:100]
training_plots_val <- training_arrays[101:120]

# stack training arrays to a 4d tensor
# Stack all 3D arrays into one 4D array
x_data <- abind::abind(training_plots_train, along = 0)
x_data_val <- abind::abind(training_plots_val, along = 0)
dim(x_data)
dim(x_data_val)

# Prepare labels
# Get the unique class names
class_names <- sort(unique(labels_train))
# Convert labels to integers: 0, 1, 2, ...
y_int <- as.integer(factor(labels_train, levels = class_names)) - 1
# One-hot encode (for multi-class classification)
y_data <- to_categorical(y_int)


# Build a model
input_shape <- c(100, 100, 1) # grayscale

model <- keras_model_sequential() %>%
  layer_conv_2d(filters = 32, kernel_size = c(3, 3), activation = "relu", input_shape = input_shape) %>%
  layer_max_pooling_2d(pool_size = c(2, 2)) %>%
  layer_conv_2d(filters = 64, kernel_size = c(3, 3), activation = "relu") %>%
  layer_max_pooling_2d(pool_size = c(2, 2)) %>%
  layer_flatten() %>%
  layer_dense(units = 128, activation = "relu") %>%
  layer_dense(units = length(class_names), activation = "softmax") # Multi-class output

# Compile the model
model %>% compile(
  loss = "categorical_crossentropy",
  optimizer = optimizer_adam(),
  metrics = c("accuracy")
)

# Train the model
model %>% fit(
  x = x_data,
  y = y_data,
  epochs = 20,
  batch_size = 16,
  validation_split = 0.2
)

# Predict on the test data
predictions <- model %>% predict(x_data_val)

# get class labels
# Get index of max probability for each sample
predicted_indices <- apply(predictions, 1, which.max)

# Get the class names
predicted_classes <- class_names[predicted_indices]

# View predictions
predicted_classes

# compare to true labels (confusion matrix)
true_classes <- labels_val
table(Predicted = predicted_classes, Actual = true_classes)

# create plot title with predicted classes and make them red if false and green if true
# using markdown syntax from ggtext
predicted_titles <- ifelse(predicted_classes == true_classes,
  paste0("<span style='color:forestgreen'>", predicted_classes, "</span>"),
  paste0("<span style='color:red'>", predicted_classes, "</span>")
)

# combine the actual and predicted lables to a single title in the form
#<actual>b<br><predicted>#
titles <- paste0(true_classes, "<br>", predicted_titles)

plot_validation <- training_plots[101:120] |> plot_landscape_list(titles = titles)
