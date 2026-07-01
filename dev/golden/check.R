# Compare the current code against the frozen golden reference.
#
# Run from the PACKAGE ROOT, on the SAME machine the reference was captured on:
#   source("dev/golden/check.R")
#
# A behaviour-preserving refactor should report "identical". Any difference is a
# red flag (unless you changed results on purpose -- then re-run capture.R).

source("dev/golden/run_golden.R")

reference <- readRDS("dev/golden/reference.rds")
current   <- run_golden()

difference <- waldo::compare(reference, current, x_arg = "reference", y_arg = "current")

if (length(difference) == 0) {
  cli::cli_alert_success("Golden check passed: results are identical to the reference.")
} else {
  cli::cli_alert_danger("Golden check FAILED: {length(difference)} difference(s) from the reference.")
  print(difference)
}
