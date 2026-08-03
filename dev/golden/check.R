# Compare the current code against the frozen golden reference.
#
# Run from the PACKAGE ROOT:
#   source("dev/golden/check.R")
#
# Both workflows are compared with a tolerance, just at different magnitudes,
# because neither is bit-reproducible. What IS stable in both -- selected metric
# names, predicted class labels, confusion-matrix counts -- is categorical or
# integer, so it is effectively exact regardless of the tolerance (a real change
# there differs by a whole label or count, not by a fraction).

source("dev/golden/run_golden.R")

pixel_values <- c("pix_accuracy", "pix_confusion", "pix_predictions")

# Absorbs TensorFlow installation differences (~1e-7 observed across machines)
# while staying far below any shift a real code regression would produce.
pixel_tolerance <- 1e-5

# The metrics workflow is structurally deterministic, but neuralnet's matrix
# maths runs through (often multithreaded) BLAS, so the class scores can differ
# by ~1e-16 (one ULP) even between two runs on the same machine. This tight
# tolerance absorbs that ordering noise; a genuine change moves values far more,
# and metric selection / class labels / counts are compared categorically anyway.
metrics_tolerance <- 1e-8

reference <- readRDS("dev/golden/reference.rds")
current <- run_golden()

metrics_values <- setdiff(names(reference), pixel_values)

# Compare both workflows ------------------------------------------------------
diff_metrics <- waldo::compare(
  reference[metrics_values],
  current[metrics_values],
  x_arg = "reference",
  y_arg = "current",
  tolerance = metrics_tolerance
)

diff_pixel <- waldo::compare(
  reference[pixel_values],
  current[pixel_values],
  x_arg = "reference",
  y_arg = "current",
  tolerance = pixel_tolerance
)

# Report ----------------------------------------------------------------------
if (length(diff_metrics) == 0) {
  cli::cli_alert_success(
    "Metrics workflow: matches the reference within tolerance {metrics_tolerance}."
  )
} else {
  cli::cli_alert_danger(
    "Metrics workflow: {length(diff_metrics)} difference{?s} from the reference."
  )
  print(diff_metrics)
}

if (length(diff_pixel) == 0) {
  cli::cli_alert_success(
    "Pixel workflow: matches the reference within tolerance {pixel_tolerance}."
  )
} else {
  cli::cli_alert_danger(
    "Pixel workflow: {length(diff_pixel)} difference{?s} beyond tolerance {pixel_tolerance}."
  )
  print(diff_pixel)
}
