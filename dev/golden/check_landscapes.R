# Compare current landscape-generation output against the frozen golden
# reference, for all 11 patterns.
#
# Run from the PACKAGE ROOT:
#   source("dev/golden/check_landscapes.R")
#
# Unlike check.R (classification results, compared with a tolerance because
# neither workflow is bit-reproducible), landscape generation is pure
# deterministic R -- RNG draws plus array manipulation, no BLAS/keras noise --
# so this comparison is EXACT. Any diff here means generated landscapes
# actually changed, not numerical noise.

source("dev/golden/run_golden_landscapes.R")

reference <- readRDS("dev/golden/reference_landscapes.rds")
current <- run_golden_landscapes()

diff <- waldo::compare(
  reference,
  current,
  x_arg = "reference",
  y_arg = "current"
)

if (length(diff) == 0) {
  cli::cli_alert_success(
    "Landscape generation: matches the reference exactly (all 11 patterns)."
  )
} else {
  cli::cli_alert_danger(
    "Landscape generation: {length(diff)} difference{?s} from the reference."
  )
  print(diff)
}
