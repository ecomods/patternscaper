# Compare the current code against the frozen golden reference.
#
# Run from the PACKAGE ROOT:
#   source("dev/golden/check.R")
#
# The two workflows are compared differently on purpose. The metrics workflow is
# deterministic and portable across machines, so it is compared exactly. The
# pixel workflow drifts in the last decimals between TensorFlow installations,
# so it is compared with a tolerance -- without it the check fails on every
# machine switch and the harness stops being a usable gate. Class labels and
# confusion matrices are still compared exactly, because the tolerance only
# applies to numeric values.

source("dev/golden/run_golden.R")

pixel_values <- c("pix_accuracy", "pix_confusion", "pix_predictions")

# Absorbs TensorFlow installation differences (~1e-7 observed across machines)
# while staying far below any shift a real code regression would produce.
pixel_tolerance <- 1e-5

reference <- readRDS("dev/golden/reference.rds")
current <- run_golden()

metrics_values <- setdiff(names(reference), pixel_values)

# Compare both workflows ------------------------------------------------------
diff_metrics <- waldo::compare(
  reference[metrics_values],
  current[metrics_values],
  x_arg = "reference",
  y_arg = "current"
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
  cli::cli_alert_success("Metrics workflow: identical to the reference.")
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
