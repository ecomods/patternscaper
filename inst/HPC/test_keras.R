# Minimal keras test to diagnose cache issues

cli::cli_alert_info("Testing keras3 initialization...")

# Try to load keras3
tryCatch(
  {
    library(keras3)
    cli::cli_alert_success("keras3 loaded successfully")

    # Check where reticulate is actually using
    python_path <- reticulate::py_config()$python
    cli::cli_alert_info("Python path: {python_path}")

    # Try a simple keras operation
    model <- keras3::keras_model_sequential() |>
      keras3::layer_dense(units = 10, input_shape = 5)

    cli::cli_alert_success("Created test model successfully")
  },
  error = function(e) {
    cli::cli_alert_danger("Error: {e$message}")
  }
)
