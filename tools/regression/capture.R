# Freeze the current results as the golden reference.
#
# Run this ONCE on the known-good baseline (git tag `revision-baseline`), and
# re-run it only when you INTENTIONALLY change results. Switching machines does
# NOT require a re-capture: the metrics workflow is portable, and check.R
# compares the pixel workflow with a tolerance that absorbs TensorFlow
# installation differences.
#
# Run from the PACKAGE ROOT:  source("tools/regression/capture.R")

source("tools/regression/run_golden.R")

reference <- run_golden()
saveRDS(reference, "tools/regression/reference.rds")

cli::cli_alert_success("Saved golden reference to tools/regression/reference.rds")
