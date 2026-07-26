# Freeze the current results as the golden reference.
#
# Run this ONCE on the known-good baseline (git tag `revision-baseline`), and
# re-run it only when you INTENTIONALLY change results. Switching machines does
# NOT require a re-capture: the metrics workflow is portable, and check.R
# compares the pixel workflow with a tolerance that absorbs TensorFlow
# installation differences.
#
# Run from the PACKAGE ROOT:  source("dev/golden/capture.R")

source("dev/golden/run_golden.R")

reference <- run_golden()
saveRDS(reference, "dev/golden/reference.rds")

cli::cli_alert_success("Saved golden reference to dev/golden/reference.rds")
