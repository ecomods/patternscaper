# Freeze the current results as the golden reference.
#
# Run this ONCE on the known-good baseline (git tag `revision-baseline`), and
# re-run it whenever you INTENTIONALLY change results, or when you switch to a
# different machine (the exact metrics/neuralnet values can differ per machine).
#
# Run from the PACKAGE ROOT:  source("dev/golden/capture.R")

source("dev/golden/run_golden.R")

reference <- run_golden()
saveRDS(reference, "dev/golden/reference.rds")

cli::cli_alert_success("Saved golden reference to dev/golden/reference.rds")
