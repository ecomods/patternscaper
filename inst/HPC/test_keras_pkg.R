# Simplified test using ecotoneClassifyR keras functions

cli::cli_alert_info("Loading ecotoneClassifyR package...")
devtools::load_all()

cli::cli_alert_info("Testing keras3 initialization...")

# Test 1: Generate minimal training data
cli::cli_alert_info("Creating 12 training landscapes (2 per pattern)...")

training_landscapes <- create_training_landscapes(
  patterns = c("random", "sharp", "diffuse", "fingers", "clustered", "bands"),
  n = 12,
  width = 100,
  height = 100
)

cli::cli_alert_success("Generated {length(training_landscapes)} landscapes")

# Test 2: Train a minimal model
cli::cli_alert_info("Training minimal keras model (5 epochs)...")

tryCatch(
  {
    model <- train_nn_landscapes(
      landscapes = training_landscapes,
      cv_method = "none",
      validation_split = 0.2,
      epochs = 5,
      batch_size = 4,
      learning_rate = 0.001,
      dropout_rate = 0.4,
      dense_units = 64,
      optimizer = "adam",
      patience = 3,
      verbose = 1
    )

    cli::cli_alert_success("Model training completed!")

    # Test 3: Apply model
    cli::cli_alert_info("Testing model application...")

    test_landscape <- create_landscape(
      pattern = "sharp",
      width = 100,
      height = 100
    )

    prediction <- apply_nn_landscapes(
      landscapes = list(test_landscape),
      nn_model = model
    )

    cli::cli_alert_success("All tests passed!")
  },
  error = function(e) {
    cli::cli_alert_danger("Error occurred: {e$message}")
    cli::cli_alert_danger("Full error:")
    print(e)
  }
)
