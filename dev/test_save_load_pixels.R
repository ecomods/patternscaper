library(patternscaper)

# Train and save a model --------------------------------------------------------
# Small, fast training run. 3 classes, few landscapes, few epochs.
set.seed(1)
train_landscapes <- create_landscapes(
  n = 12,
  patterns = c("random", "sharp", "diffuse")
)

set_random_seed(1)
model <- train_pixel_model(
  landscapes = train_landscapes,
  cv_method = "none",
  epochs = 5
)

# Save, read, and apply a model -----------------------------------------------

model_bundle <- tempfile("test-pixel-model-")
save_pixel_model(model, model_bundle)
reloaded <- load_pixel_model(model_bundle)

# Apply to new landscapes
test_landscapes <- create_landscapes(
  n = 6,
  patterns = c("random", "sharp", "diffuse")
)

results <- apply_pixel_model(
  landscapes = test_landscapes,
  model = reloaded
)

unlink(model_bundle, recursive = TRUE)
