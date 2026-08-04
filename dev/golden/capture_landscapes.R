# Freeze the current landscape-generation output as the golden reference.
#
# Run this ONCE on the known-good baseline, and re-run it only when you
# INTENTIONALLY change what create_landscape()/create_landscapes() generate.
#
# Run from the PACKAGE ROOT:  source("dev/golden/capture_landscapes.R")

source("dev/golden/run_golden_landscapes.R")

reference <- run_golden_landscapes()
saveRDS(reference, "dev/golden/reference_landscapes.rds")

cli::cli_alert_success(
  "Saved golden landscape reference to dev/golden/reference_landscapes.rds"
)
